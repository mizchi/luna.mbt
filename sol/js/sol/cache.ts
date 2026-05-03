/**
 * Sol Framework Cache Abstraction for ISR
 *
 * Supports:
 * - Cloudflare KV (production)
 * - Cloudflare Cache API (edge caching)
 * - In-memory LRU cache (development/Node.js)
 */

// ============================================================================
// Types
// ============================================================================

export interface CacheEntry<T = string> {
  value: T;
  generatedAt: number;
  revalidateAfter?: number;
}

export interface CacheMetadata {
  generatedAt: number;
  revalidateAfter?: number;
  etag?: string;
}

export interface ISRCacheOptions {
  /** Time in seconds before content is considered stale */
  revalidate?: number;
  /** Tags for cache invalidation */
  tags?: string[];
}

export interface CacheAdapter {
  get(key: string): Promise<CacheEntry | null>;
  set(key: string, value: string, options?: ISRCacheOptions): Promise<void>;
  delete(key: string): Promise<void>;
  /** Invalidate all entries with a specific tag */
  invalidateTag?(tag: string): Promise<void>;
}

// ============================================================================
// Cloudflare KV Adapter
// ============================================================================

export interface CloudflareKVNamespace {
  get(key: string, options?: { type?: 'text' | 'json' | 'arrayBuffer' }): Promise<string | null>;
  put(key: string, value: string, options?: { expirationTtl?: number; metadata?: unknown }): Promise<void>;
  delete(key: string): Promise<void>;
  getWithMetadata<T>(key: string, options?: { type?: 'text' }): Promise<{ value: string | null; metadata: T | null }>;
}

export class CloudflareKVAdapter implements CacheAdapter {
  constructor(private kv: CloudflareKVNamespace) {}

  async get(key: string): Promise<CacheEntry | null> {
    const result = await this.kv.getWithMetadata<CacheMetadata>(key, { type: 'text' });

    if (!result.value) {
      return null;
    }

    return {
      value: result.value,
      generatedAt: result.metadata?.generatedAt ?? Date.now(),
      revalidateAfter: result.metadata?.revalidateAfter,
    };
  }

  async set(key: string, value: string, options?: ISRCacheOptions): Promise<void> {
    const metadata: CacheMetadata = {
      generatedAt: Date.now(),
      revalidateAfter: options?.revalidate
        ? Date.now() + options.revalidate * 1000
        : undefined,
    };

    // Store with TTL of 24 hours (KV will auto-delete)
    // The revalidate time is for stale-while-revalidate logic
    await this.kv.put(key, value, {
      expirationTtl: 86400, // 24 hours max TTL
      metadata,
    });

    // Store tag mappings for invalidation
    if (options?.tags) {
      for (const tag of options.tags) {
        const tagKey = `__tag:${tag}`;
        const existing = await this.kv.get(tagKey, { type: 'text' });
        const keys = existing ? JSON.parse(existing) : [];
        if (!keys.includes(key)) {
          keys.push(key);
          await this.kv.put(tagKey, JSON.stringify(keys), { expirationTtl: 86400 });
        }
      }
    }
  }

  async delete(key: string): Promise<void> {
    await this.kv.delete(key);
  }

  async invalidateTag(tag: string): Promise<void> {
    const tagKey = `__tag:${tag}`;
    const existing = await this.kv.get(tagKey, { type: 'text' });
    if (existing) {
      const keys: string[] = JSON.parse(existing);
      await Promise.all(keys.map((key) => this.kv.delete(key)));
      await this.kv.delete(tagKey);
    }
  }
}

// ============================================================================
// Cloudflare Cache API Adapter
// ============================================================================

export class CloudflareCacheAdapter implements CacheAdapter {
  private cache: Cache | null = null;
  private cachePromise: Promise<Cache> | null = null;

  constructor(private cacheName: string = 'sol-isr') {}

  private async getCache(): Promise<Cache> {
    if (this.cache) return this.cache;
    if (this.cachePromise) return this.cachePromise;

    this.cachePromise = caches.open(this.cacheName);
    this.cache = await this.cachePromise;
    return this.cache;
  }

  async get(key: string): Promise<CacheEntry | null> {
    const cache = await this.getCache();
    const request = new Request(`https://sol-cache/${encodeURIComponent(key)}`);
    const response = await cache.match(request);

    if (!response) {
      return null;
    }

    const generatedAt = parseInt(response.headers.get('X-Sol-Generated-At') || '0', 10);
    const revalidateAfter = response.headers.get('X-Sol-Revalidate-After');

    return {
      value: await response.text(),
      generatedAt,
      revalidateAfter: revalidateAfter ? parseInt(revalidateAfter, 10) : undefined,
    };
  }

  async set(key: string, value: string, options?: ISRCacheOptions): Promise<void> {
    const cache = await this.getCache();
    const request = new Request(`https://sol-cache/${encodeURIComponent(key)}`);

    const headers = new Headers({
      'Content-Type': 'text/html; charset=utf-8',
      'X-Sol-Generated-At': String(Date.now()),
      'Cache-Control': `public, max-age=${options?.revalidate || 3600}`,
    });

    if (options?.revalidate) {
      headers.set('X-Sol-Revalidate-After', String(Date.now() + options.revalidate * 1000));
    }

    const response = new Response(value, { headers });
    await cache.put(request, response);
  }

  async delete(key: string): Promise<void> {
    const cache = await this.getCache();
    const request = new Request(`https://sol-cache/${encodeURIComponent(key)}`);
    await cache.delete(request);
  }
}

// ============================================================================
// In-Memory LRU Cache (for Node.js / Development)
// ============================================================================

export class MemoryCacheAdapter implements CacheAdapter {
  private cache = new Map<string, CacheEntry>();
  private accessOrder: string[] = [];

  constructor(private maxSize: number = 1000) {}

  async get(key: string): Promise<CacheEntry | null> {
    const entry = this.cache.get(key);
    if (!entry) return null;

    // Move to end of access order (LRU)
    const idx = this.accessOrder.indexOf(key);
    if (idx > -1) {
      this.accessOrder.splice(idx, 1);
      this.accessOrder.push(key);
    }

    return entry;
  }

  async set(key: string, value: string, options?: ISRCacheOptions): Promise<void> {
    // Evict oldest if at capacity
    while (this.cache.size >= this.maxSize && this.accessOrder.length > 0) {
      const oldest = this.accessOrder.shift();
      if (oldest) {
        this.cache.delete(oldest);
      }
    }

    const entry: CacheEntry = {
      value,
      generatedAt: Date.now(),
      revalidateAfter: options?.revalidate
        ? Date.now() + options.revalidate * 1000
        : undefined,
    };

    this.cache.set(key, entry);
    this.accessOrder.push(key);
  }

  async delete(key: string): Promise<void> {
    this.cache.delete(key);
    const idx = this.accessOrder.indexOf(key);
    if (idx > -1) {
      this.accessOrder.splice(idx, 1);
    }
  }

  /** Clear all cache entries */
  clear(): void {
    this.cache.clear();
    this.accessOrder = [];
  }

  /** Get cache stats */
  stats(): { size: number; maxSize: number } {
    return { size: this.cache.size, maxSize: this.maxSize };
  }
}

// ============================================================================
// ISR Cache Manager
// ============================================================================

export interface ISRResult {
  html: string;
  status: 'hit' | 'stale' | 'miss';
  age: number;
}

export interface ISRContext {
  /** Function to regenerate page in background */
  waitUntil?: (promise: Promise<unknown>) => void;
}

export class ISRCacheManager {
  constructor(private adapter: CacheAdapter) {}

  /**
   * Get cached page with ISR logic
   *
   * Returns:
   * - hit: Fresh cache, no regeneration needed
   * - stale: Returning stale content, regeneration triggered in background
   * - miss: No cache, needs generation
   */
  async get(key: string): Promise<ISRResult | null> {
    const entry = await this.adapter.get(key);

    if (!entry) {
      return null;
    }

    const now = Date.now();
    const age = now - entry.generatedAt;

    // Check if content is stale
    if (entry.revalidateAfter && now > entry.revalidateAfter) {
      return {
        html: entry.value,
        status: 'stale',
        age,
      };
    }

    return {
      html: entry.value,
      status: 'hit',
      age,
    };
  }

  /**
   * Store generated page in cache
   */
  async set(key: string, html: string, options?: ISRCacheOptions): Promise<void> {
    await this.adapter.set(key, html, options);
  }

  /**
   * Delete cached page
   */
  async delete(key: string): Promise<void> {
    await this.adapter.delete(key);
  }

  /**
   * Invalidate all pages with a specific tag
   */
  async invalidateTag(tag: string): Promise<void> {
    if (this.adapter.invalidateTag) {
      await this.adapter.invalidateTag(tag);
    }
  }

  /**
   * Handle ISR request with stale-while-revalidate
   */
  async handleISR(
    key: string,
    generateFn: () => Promise<string>,
    options: ISRCacheOptions & ISRContext = {}
  ): Promise<ISRResult> {
    const cached = await this.get(key);

    if (cached) {
      if (cached.status === 'stale' && options.waitUntil) {
        // Return stale content and regenerate in background
        options.waitUntil(
          (async () => {
            const html = await generateFn();
            await this.set(key, html, options);
          })()
        );
      }

      return cached;
    }

    // Cache miss - generate and cache
    const html = await generateFn();
    await this.set(key, html, options);

    return {
      html,
      status: 'miss',
      age: 0,
    };
  }
}

// ============================================================================
// Factory Functions
// ============================================================================

/** Global cache instance for the current runtime */
let globalCache: ISRCacheManager | null = null;

/**
 * Create appropriate cache adapter based on environment
 */
export function createCacheAdapter(env?: {
  SOL_CACHE?: CloudflareKVNamespace;
}): CacheAdapter {
  // Cloudflare Workers with KV binding
  if (env?.SOL_CACHE) {
    return new CloudflareKVAdapter(env.SOL_CACHE);
  }

  // Cloudflare Workers with Cache API
  if (typeof caches !== 'undefined') {
    return new CloudflareCacheAdapter();
  }

  // Node.js / Development - use memory cache
  return new MemoryCacheAdapter();
}

/**
 * Get or create global ISR cache manager
 */
export function getISRCache(env?: { SOL_CACHE?: CloudflareKVNamespace }): ISRCacheManager {
  if (!globalCache) {
    globalCache = new ISRCacheManager(createCacheAdapter(env));
  }
  return globalCache;
}

/**
 * Reset global cache (for testing)
 */
export function resetISRCache(): void {
  globalCache = null;
}
