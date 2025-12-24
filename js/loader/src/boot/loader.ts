/*! luna boot/loader v1 - Chunk loading based on manifest */

/**
 * Manifest structure for chunk dependencies
 * Maps route paths to required chunk names
 */
export interface ChunkManifest {
  /** Map of route paths to required chunks */
  routes: Record<string, string[]>;
  /** Map of chunk names to their hashed file paths */
  chunks: Record<string, string>;
  /** Base path for chunk loading (default: "/_luna/") */
  base?: string;
}

/**
 * ChunkLoader manages dynamic chunk loading based on manifest
 */
export class ChunkLoader {
  private loaded = new Set<string>();
  private loading = new Map<string, Promise<unknown>>();
  private manifest: ChunkManifest | null = null;
  private base = '/_luna/';

  /**
   * Initialize loader with manifest
   * Can be called with inline manifest or fetch from URL
   */
  async init(manifestOrUrl: ChunkManifest | string = '/_luna/manifest.json'): Promise<void> {
    if (typeof manifestOrUrl === 'string') {
      const res = await fetch(manifestOrUrl);
      this.manifest = await res.json();
    } else {
      this.manifest = manifestOrUrl;
    }
    if (this.manifest.base) {
      this.base = this.manifest.base;
    }
  }

  /**
   * Get chunks required for a path
   */
  getChunksForPath(path: string): string[] {
    if (!this.manifest) return [];

    // Exact match
    if (this.manifest.routes[path]) {
      return this.manifest.routes[path];
    }

    // Try wildcard match (e.g., "/app/*" matches "/app/settings")
    for (const [pattern, chunks] of Object.entries(this.manifest.routes)) {
      if (pattern.endsWith('/*')) {
        const prefix = pattern.slice(0, -1); // Remove *
        if (path.startsWith(prefix)) {
          return chunks;
        }
      }
    }

    // Fallback to default if exists
    return this.manifest.routes['*'] ?? [];
  }

  /**
   * Load chunks for a specific path
   * Returns chunks that were newly loaded
   */
  async loadForPath(path: string): Promise<string[]> {
    const chunks = this.getChunksForPath(path);
    const missing = chunks.filter(c => !this.loaded.has(c));

    await Promise.all(missing.map(c => this.loadChunk(c)));

    return missing;
  }

  /**
   * Load a specific chunk by name
   */
  async loadChunk(name: string): Promise<unknown> {
    if (this.loaded.has(name)) {
      return;
    }

    // Check if already loading
    const pending = this.loading.get(name);
    if (pending) {
      return pending;
    }

    // Resolve chunk URL
    const url = this.resolveChunkUrl(name);

    // Start loading
    const promise = import(/* @vite-ignore */ url).then(mod => {
      this.loaded.add(name);
      this.loading.delete(name);
      return mod;
    }).catch(err => {
      this.loading.delete(name);
      throw err;
    });

    this.loading.set(name, promise);
    return promise;
  }

  /**
   * Resolve chunk name to URL
   */
  private resolveChunkUrl(name: string): string {
    if (!this.manifest) {
      return `${this.base}${name}.js`;
    }

    const hashedPath = this.manifest.chunks[name];
    if (hashedPath) {
      return hashedPath.startsWith('/') ? hashedPath : `${this.base}${hashedPath}`;
    }

    return `${this.base}${name}.js`;
  }

  /**
   * Prefetch chunks for a path (non-blocking)
   */
  prefetch(path: string): void {
    const chunks = this.getChunksForPath(path);
    const missing = chunks.filter(c => !this.loaded.has(c) && !this.loading.has(c));

    for (const chunk of missing) {
      const url = this.resolveChunkUrl(chunk);
      // Use link prefetch for better browser integration
      const link = document.createElement('link');
      link.rel = 'modulepreload';
      link.href = url;
      document.head.appendChild(link);
    }
  }

  /**
   * Check if a chunk is loaded
   */
  isLoaded(name: string): boolean {
    return this.loaded.has(name);
  }

  /**
   * Get all loaded chunk names
   */
  getLoaded(): string[] {
    return Array.from(this.loaded);
  }

  /**
   * Clear loaded state (for testing)
   */
  clear(): void {
    this.loaded.clear();
    this.loading.clear();
  }
}

// Global singleton instance
let globalLoader: ChunkLoader | null = null;

/**
 * Get or create the global ChunkLoader instance
 */
export function getLoader(): ChunkLoader {
  if (!globalLoader) {
    globalLoader = new ChunkLoader();
  }
  return globalLoader;
}

/**
 * Initialize the global loader
 */
export async function initLoader(manifestOrUrl?: ChunkManifest | string): Promise<ChunkLoader> {
  const loader = getLoader();
  await loader.init(manifestOrUrl);
  return loader;
}

// Expose on window for debugging
declare global {
  interface Window {
    __LUNA_LOADER__?: ChunkLoader;
  }
}

if (typeof window !== 'undefined') {
  window.__LUNA_LOADER__ = getLoader();
}
