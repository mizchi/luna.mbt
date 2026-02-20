/*! luna boot/loader v2 - Hierarchical chunk loading */

/**
 * V1 Manifest structure (backward compatible)
 */
export interface ChunkManifest {
  routes: Record<string, string[]>;
  chunks: Record<string, string>;
  base?: string;
}

/**
 * V2 Hierarchical manifest structure
 */
export interface HierarchicalManifest {
  version: 2;
  base: string;
  segments: Record<string, SegmentRef>;
  chunks: Record<string, string>;
  routes: Record<string, string[]>;
}

export interface SegmentRef {
  path: string;      // "routes/docs.json"
  pattern: string;   // "/docs/*"
  spa: boolean;
  preload: boolean;
}

export interface SegmentManifest {
  base: string;
  routes: Record<string, string[]>;
  dynamic: DynamicPattern[];
  fallback: 'spa' | '404';
}

export interface DynamicPattern {
  pattern: string;   // "/:slug"
  regex: string;     // "^/([^/]+)$"
  params: string[];
  catch_all: boolean;
}

export interface RouteMatch {
  chunks: string[];
  params: Record<string, string>;
  segment?: string;
  isSpa?: boolean;
}

type Manifest = ChunkManifest | HierarchicalManifest;
type V1CompatModule = typeof import("./loader-v1");

function isV2Manifest(m: Manifest): m is HierarchicalManifest {
  return (m as HierarchicalManifest).version === 2;
}

/**
 * ChunkLoader manages dynamic chunk loading based on manifest
 * Supports both v1 (flat) and v2 (hierarchical) manifests
 */
export class ChunkLoader {
  private loaded = new Set<string>();
  private loading = new Map<string, Promise<unknown>>();
  private manifest: Manifest | null = null;
  private v1Compat: V1CompatModule | null = null;
  private base = '/_luna/';
  private segments = new Map<string, SegmentManifest>();
  private segmentLoading = new Map<string, Promise<SegmentManifest>>();

  /**
   * Initialize loader with manifest
   */
  async init(manifestOrUrl: Manifest | string = '/_luna/manifest.json'): Promise<void> {
    if (typeof manifestOrUrl === 'string') {
      const res = await fetch(manifestOrUrl);
      this.manifest = await res.json();
    } else {
      this.manifest = manifestOrUrl;
    }
    if (this.manifest?.base) {
      this.base = this.manifest.base;
    }
    if (this.manifest && !isV2Manifest(this.manifest)) {
      await this.ensureV1Compat();
    }
  }

  /**
   * Get chunks required for a path
   * Returns match info including params for dynamic routes
   */
  async matchPath(path: string): Promise<RouteMatch | null> {
    if (!this.manifest) return null;

    if (isV2Manifest(this.manifest)) {
      return this.matchPathV2(path, this.manifest);
    } else {
      const compat = await this.ensureV1Compat();
      return compat.matchPathV1(path, this.manifest);
    }
  }

  /**
   * V2 path matching (hierarchical manifest)
   */
  private async matchPathV2(path: string, manifest: HierarchicalManifest): Promise<RouteMatch | null> {
    // Try inline routes first
    if (manifest.routes[path]) {
      return { chunks: manifest.routes[path], params: {} };
    }

    // Try with/without trailing slash
    const normalized = path.endsWith('/') ? path : path + '/';
    const withoutSlash = path.replace(/\/$/, '') || '/';

    if (manifest.routes[normalized]) {
      return { chunks: manifest.routes[normalized], params: {} };
    }
    if (manifest.routes[withoutSlash]) {
      return { chunks: manifest.routes[withoutSlash], params: {} };
    }

    // Find matching segment
    const segmentName = this.extractFirstSegment(path);
    if (!segmentName) return null;

    const segmentRef = manifest.segments[segmentName];
    if (!segmentRef) return null;

    // Load segment manifest
    const segmentManifest = await this.loadSegment(segmentName, segmentRef.path);
    if (!segmentManifest) return null;

    // Match within segment
    const relativePath = this.getRelativePath(path, segmentName);

    // Try static routes in segment
    if (segmentManifest.routes[relativePath]) {
      return {
        chunks: segmentManifest.routes[relativePath],
        params: {},
        segment: segmentName,
        isSpa: segmentRef.spa,
      };
    }

    // Try dynamic patterns
    for (const pattern of segmentManifest.dynamic) {
      const match = this.matchDynamicPattern(relativePath, pattern);
      if (match) {
        const chunks = segmentManifest.routes[pattern.pattern] ?? ['boot'];
        return {
          chunks,
          params: match,
          segment: segmentName,
          isSpa: segmentRef.spa,
        };
      }
    }

    // SPA fallback
    if (segmentRef.spa && segmentManifest.fallback === 'spa') {
      return {
        chunks: ['boot', 'router'],
        params: {},
        segment: segmentName,
        isSpa: true,
      };
    }

    return null;
  }

  /**
   * Match path against dynamic pattern
   */
  private matchDynamicPattern(path: string, pattern: DynamicPattern): Record<string, string> | null {
    try {
      const regex = new RegExp(pattern.regex);
      const match = path.match(regex);
      if (!match) return null;

      const params: Record<string, string> = {};
      pattern.params.forEach((name, i) => {
        params[name] = match[i + 1] || '';
      });
      return params;
    } catch {
      return null;
    }
  }

  /**
   * Load segment manifest
   */
  private async loadSegment(name: string, path: string): Promise<SegmentManifest | null> {
    // Check cache
    const cached = this.segments.get(name);
    if (cached) return cached;

    // Check if loading
    const pending = this.segmentLoading.get(name);
    if (pending) return pending;

    // Load
    const url = `${this.base}${path}`;
    const promise = fetch(url)
      .then(res => res.json())
      .then((manifest: SegmentManifest) => {
        this.segments.set(name, manifest);
        this.segmentLoading.delete(name);
        return manifest;
      })
      .catch(() => {
        this.segmentLoading.delete(name);
        return null;
      });

    this.segmentLoading.set(name, promise as Promise<SegmentManifest>);
    return promise;
  }

  /**
   * Extract first segment from path
   */
  private extractFirstSegment(path: string): string {
    const parts = path.split('/').filter(Boolean);
    return parts[0] || '';
  }

  /**
   * Get path relative to segment
   */
  private getRelativePath(path: string, segment: string): string {
    const prefix = `/${segment}`;
    if (path.startsWith(prefix)) {
      const rest = path.slice(prefix.length);
      return rest || '/';
    }
    return path;
  }

  private async ensureV1Compat(): Promise<V1CompatModule> {
    if (this.v1Compat) return this.v1Compat;
    this.v1Compat = await import("./loader-v1");
    return this.v1Compat;
  }

  /**
   * Get chunks for a path (backward compatible)
   */
  getChunksForPath(path: string): string[] {
    if (!this.manifest) return [];

    if (isV2Manifest(this.manifest)) {
      // For sync access, only check inline routes
      if (this.manifest.routes[path]) {
        return this.manifest.routes[path];
      }
      return ['boot'];
    }

    if (this.v1Compat) {
      return this.v1Compat.getChunksForPathV1(path, this.manifest);
    }

    return this.manifest.routes[path] ?? this.manifest.routes['*'] ?? [];
  }

  /**
   * Load chunks for a specific path
   */
  async loadForPath(path: string): Promise<string[]> {
    const match = await this.matchPath(path);
    if (!match) return [];

    const missing = match.chunks.filter(c => !this.loaded.has(c));
    await Promise.all(missing.map(c => this.loadChunk(c)));
    return missing;
  }

  /**
   * Load a specific chunk by name
   */
  async loadChunk(name: string): Promise<unknown> {
    if (this.loaded.has(name)) return;

    const pending = this.loading.get(name);
    if (pending) return pending;

    const url = this.resolveChunkUrl(name);
    const promise = import(/* @vite-ignore */ url)
      .then(mod => {
        this.loaded.add(name);
        this.loading.delete(name);
        return mod;
      })
      .catch(err => {
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

    const chunks = isV2Manifest(this.manifest)
      ? this.manifest.chunks
      : this.manifest.chunks;

    const hashedPath = chunks[name];
    if (hashedPath) {
      return hashedPath.startsWith('/') ? hashedPath : `${this.base}${hashedPath}`;
    }

    return `${this.base}${name}.js`;
  }

  /**
   * Prefetch chunks for a path
   */
  prefetch(path: string): void {
    const chunks = this.getChunksForPath(path);
    const missing = chunks.filter(c => !this.loaded.has(c) && !this.loading.has(c));

    for (const chunk of missing) {
      const url = this.resolveChunkUrl(chunk);
      const link = document.createElement('link');
      link.rel = 'modulepreload';
      link.href = url;
      document.head.appendChild(link);
    }
  }

  /**
   * Prefetch a segment manifest
   */
  prefetchSegment(segment: string): void {
    if (!this.manifest || !isV2Manifest(this.manifest)) return;

    const segmentRef = this.manifest.segments[segment];
    if (segmentRef && !this.segments.has(segment) && !this.segmentLoading.has(segment)) {
      this.loadSegment(segment, segmentRef.path);
    }
  }

  /**
   * Check if manifest is v2 (hierarchical)
   */
  isHierarchical(): boolean {
    return this.manifest !== null && isV2Manifest(this.manifest);
  }

  /**
   * Get segment info for a path
   */
  getSegmentInfo(path: string): SegmentRef | null {
    if (!this.manifest || !isV2Manifest(this.manifest)) return null;

    const segmentName = this.extractFirstSegment(path);
    return this.manifest.segments[segmentName] ?? null;
  }

  isLoaded(name: string): boolean {
    return this.loaded.has(name);
  }

  getLoaded(): string[] {
    return Array.from(this.loaded);
  }

  clear(): void {
    this.loaded.clear();
    this.loading.clear();
    this.segments.clear();
    this.segmentLoading.clear();
  }
}

// Global singleton
let globalLoader: ChunkLoader | null = null;

export function getLoader(): ChunkLoader {
  if (!globalLoader) {
    globalLoader = new ChunkLoader();
  }
  return globalLoader;
}

export async function initLoader(manifestOrUrl?: Manifest | string): Promise<ChunkLoader> {
  const loader = getLoader();
  await loader.init(manifestOrUrl);
  return loader;
}
