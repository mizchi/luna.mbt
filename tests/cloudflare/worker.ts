// Test worker for Cloudflare Workers Vitest tests
// This worker simulates the routing behavior of a Cloudflare Pages deployment

export interface Env {
  TEST_MODE: string;
}

export interface RoutesJson {
  version: number;
  include: string[];
  exclude: string[];
}

// Simple pattern matcher for _routes.json patterns
function matchesPattern(path: string, pattern: string): boolean {
  // Handle wildcard patterns
  if (pattern.endsWith("/*")) {
    const prefix = pattern.slice(0, -2);
    return path.startsWith(prefix);
  }
  if (pattern.startsWith("/*.")) {
    const ext = pattern.slice(2);
    return path.endsWith(ext);
  }
  if (pattern === "/*") {
    return true;
  }
  // Exact match
  return path === pattern;
}

// Determine if a request should be handled by the worker or static assets
export function shouldHandleRequest(
  path: string,
  routes: RoutesJson
): { handled: boolean; reason: string } {
  // Check exclude patterns first (static assets)
  for (const pattern of routes.exclude) {
    if (matchesPattern(path, pattern)) {
      return { handled: false, reason: `Excluded by pattern: ${pattern}` };
    }
  }

  // Check include patterns (worker handles)
  for (const pattern of routes.include) {
    if (matchesPattern(path, pattern)) {
      return { handled: true, reason: `Included by pattern: ${pattern}` };
    }
  }

  // Default: not handled by worker (static fallback)
  return { handled: false, reason: "No matching include pattern" };
}

// Parse and validate _routes.json
export function parseRoutesJson(content: string): RoutesJson | null {
  try {
    const json = JSON.parse(content);
    if (
      typeof json.version !== "number" ||
      !Array.isArray(json.include) ||
      !Array.isArray(json.exclude)
    ) {
      return null;
    }
    return json as RoutesJson;
  } catch {
    return null;
  }
}

export default {
  async fetch(
    request: Request,
    env: Env,
    _ctx: ExecutionContext
  ): Promise<Response> {
    const url = new URL(request.url);

    // For testing, return info about how the request would be routed
    return new Response(
      JSON.stringify({
        path: url.pathname,
        testMode: env.TEST_MODE,
        message: "Test worker active",
      }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  },
};
