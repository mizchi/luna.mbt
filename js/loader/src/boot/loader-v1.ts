import type { ChunkManifest, RouteMatch } from "./loader";

export function matchPathV1(path: string, manifest: ChunkManifest): RouteMatch | null {
  // Exact match
  if (manifest.routes[path]) {
    return { chunks: manifest.routes[path], params: {} };
  }

  // Try wildcard match
  for (const [pattern, chunks] of Object.entries(manifest.routes)) {
    if (pattern.endsWith("/*")) {
      const prefix = pattern.slice(0, -1);
      if (path.startsWith(prefix)) {
        return { chunks, params: {} };
      }
    }
  }

  // Fallback
  if (manifest.routes["*"]) {
    return { chunks: manifest.routes["*"], params: {} };
  }

  return null;
}

export function getChunksForPathV1(path: string, manifest: ChunkManifest): string[] {
  if (manifest.routes[path]) {
    return manifest.routes[path];
  }

  for (const [pattern, chunks] of Object.entries(manifest.routes)) {
    if (pattern.endsWith("/*")) {
      const prefix = pattern.slice(0, -1);
      if (path.startsWith(prefix)) {
        return chunks;
      }
    }
  }

  return manifest.routes["*"] ?? [];
}
