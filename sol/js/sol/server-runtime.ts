/**
 * Sol Framework Server Runtime for TypeScript
 *
 * Registers TypeScript routes with Hono and handles SSR rendering
 * Supports ISR (Incremental Static Regeneration) with stale-while-revalidate
 */

import type { Context, Hono } from 'hono';
import type {
  SolRoute,
  PageProps,
  RouteParams,
  PageRoute,
  LayoutRoute,
  GetRoute,
  PostRoute,
  WithMiddlewareRoute,
  Middleware,
  RouterConfig,
} from './routes';
import { DEFAULT_ROOT_TEMPLATE } from './routes';
import {
  ISRCacheManager,
  MemoryCacheAdapter,
  CloudflareKVAdapter,
  CloudflareCacheAdapter,
  type CacheAdapter,
  type CloudflareKVNamespace,
} from './cache';

// ============================================================================
// Types
// ============================================================================

interface CompiledRoute {
  method: 'GET' | 'POST';
  path: string;
  handler: (c: Context) => Promise<Response>;
}

/** Extended router config with ISR options */
export interface ISRRouterConfig extends RouterConfig {
  /** Enable ISR caching */
  enableISR?: boolean;
  /** Cache adapter (auto-detected if not provided) */
  cacheAdapter?: CacheAdapter;
  /** Default revalidate time in seconds */
  defaultRevalidate?: number;
}

/** Cloudflare Workers execution context */
interface ExecutionContext {
  waitUntil(promise: Promise<unknown>): void;
  passThroughOnException(): void;
}

/** Cloudflare Workers environment bindings */
interface CloudflareEnv {
  SOL_CACHE?: CloudflareKVNamespace;
  [key: string]: unknown;
}

// ============================================================================
// Route Compilation
// ============================================================================

/**
 * Extract route parameters from Hono context
 */
function extractParams(c: Context): RouteParams {
  const url = new URL(c.req.url);
  const params: [string, string][] = Object.entries(c.req.param() || {});
  const query: [string, string][] = Array.from(url.searchParams.entries());

  return {
    params,
    query,
    path: url.pathname,
    get_param: (name: string) => params.find(([k]) => k === name)?.[1],
    get_query: (name: string) => query.find(([k]) => k === name)?.[1],
  };
}

/**
 * Check if request is a fragment request (CSR navigation)
 */
function isFragmentRequest(c: Context): boolean {
  return c.req.header('X-Sol-Fragment') === 'true';
}

/**
 * Wrap HTML content in the root template
 */
function wrapInTemplate(
  html: string,
  title: string,
  config: RouterConfig,
  meta?: [string, string][]
): string {
  const template = config.rootTemplate || DEFAULT_ROOT_TEMPLATE;
  const fullTitle = config.titlePrefix
    ? `${config.titlePrefix} | ${title}`
    : title;

  // Build meta tags
  const metaHtml = meta
    ? meta
        .map(([name, content]) => `<meta name="${name}" content="${content}">`)
        .join('\n  ')
    : '';

  return template
    .replace('__LUNA_TITLE__', fullTitle)
    .replace('__LUNA_HEAD__', config.defaultHead || '')
    .replace('__LUNA_PRELOAD__', '')
    .replace('__LUNA_MAIN__', html)
    .replace('__LUNA_META__', metaHtml);
}

/**
 * Generate cache key for a page request
 */
function generateCacheKey(c: Context, pageRoute: PageRoute): string {
  const url = new URL(c.req.url);
  // Include path and query params in cache key
  return `page:${url.pathname}${url.search}`;
}

/**
 * Add cache headers to response
 */
function addCacheHeaders(
  response: Response,
  options: {
    revalidate?: number;
    status: 'hit' | 'stale' | 'miss';
    age?: number;
  }
): Response {
  const headers = new Headers(response.headers);

  // Add Sol-specific headers
  headers.set('X-Sol-Cache', options.status);
  if (options.age !== undefined) {
    headers.set('X-Sol-Cache-Age', String(Math.floor(options.age / 1000)));
  }

  // Add standard cache headers
  if (options.revalidate) {
    headers.set(
      'Cache-Control',
      `public, s-maxage=${options.revalidate}, stale-while-revalidate=${options.revalidate * 2}`
    );
  }

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

/**
 * Compile a single route into Hono handlers
 */
function compileRoute(
  route: SolRoute,
  config: ISRRouterConfig,
  getCacheManager: (c: Context) => ISRCacheManager | null,
  layouts: LayoutRoute[] = [],
  middlewares: Middleware[] = []
): CompiledRoute[] {
  const results: CompiledRoute[] = [];

  switch (route.type) {
    case 'page': {
      const pageRoute = route as PageRoute;
      const shouldCache = config.enableISR && (pageRoute.revalidate !== undefined || config.defaultRevalidate);
      const revalidateTime = pageRoute.revalidate ?? config.defaultRevalidate;

      results.push({
        method: 'GET',
        path: pageRoute.path,
        handler: async (c: Context) => {
          const props: PageProps = {
            ctx: c,
            params: extractParams(c),
            is_fragment: isFragmentRequest(c),
          };

          // Generate page content
          const generatePage = async (): Promise<string> => {
            let html = await pageRoute.handler(props);

            // Apply layouts from innermost to outermost
            for (let i = layouts.length - 1; i >= 0; i--) {
              html = await layouts[i].layout(props, html);
            }

            // For fragment requests, return just the content
            if (props.is_fragment) {
              return html;
            }

            // Wrap in full HTML template
            return wrapInTemplate(html, pageRoute.title, config, pageRoute.meta);
          };

          // Apply middlewares
          const executeWithMiddleware = async (): Promise<Response> => {
            if (middlewares.length > 0) {
              let idx = 0;
              const runMiddleware = async (): Promise<Response> => {
                if (idx < middlewares.length) {
                  const middleware = middlewares[idx++];
                  return await middleware(c, runMiddleware);
                }
                // No ISR for middleware-protected routes (might have auth)
                const html = await generatePage();
                return c.html(html);
              };
              return await runMiddleware();
            }

            // ISR handling (only for non-middleware routes)
            const cacheManager = getCacheManager(c);
            if (shouldCache && cacheManager && !props.is_fragment) {
              const cacheKey = generateCacheKey(c, pageRoute);

              // Try to get execution context for background revalidation (Cloudflare Workers only)
              let waitUntil: ((p: Promise<unknown>) => void) | undefined;
              try {
                // Hono provides executionCtx as a getter in Cloudflare Workers
                const executionCtx = c.executionCtx as ExecutionContext | undefined;
                waitUntil = executionCtx?.waitUntil?.bind(executionCtx);
              } catch {
                // executionCtx not available in Node.js - regeneration will be synchronous
              }

              const result = await cacheManager.handleISR(cacheKey, generatePage, {
                revalidate: revalidateTime,
                waitUntil,
              });

              const response = c.html(result.html);
              return addCacheHeaders(response, {
                revalidate: revalidateTime,
                status: result.status,
                age: result.age,
              });
            }

            // No caching - just render
            const html = await generatePage();
            return c.html(html);
          };

          return executeWithMiddleware();
        },
      });
      break;
    }

    case 'layout': {
      const layoutRoute = route as LayoutRoute;
      // Add this layout to the stack and compile children
      for (const child of layoutRoute.children) {
        results.push(
          ...compileRoute(child, config, getCacheManager, [...layouts, layoutRoute], middlewares)
        );
      }
      break;
    }

    case 'get': {
      const getRoute = route as GetRoute;
      results.push({
        method: 'GET',
        path: getRoute.path,
        handler: async (c: Context) => {
          const props: PageProps = {
            ctx: c,
            params: extractParams(c),
            is_fragment: false,
          };

          const result = await getRoute.handler(props);
          // If handler returns a Response, return it directly
          if (result instanceof Response) {
            return result;
          }
          return c.json(result);
        },
      });
      break;
    }

    case 'post': {
      const postRoute = route as PostRoute;
      results.push({
        method: 'POST',
        path: postRoute.path,
        handler: async (c: Context) => {
          const props: PageProps = {
            ctx: c,
            params: extractParams(c),
            is_fragment: false,
          };

          const result = await postRoute.handler(props);
          // If handler returns a Response, return it directly
          if (result instanceof Response) {
            return result;
          }
          return c.json(result);
        },
      });
      break;
    }

    case 'withMiddleware': {
      const mwRoute = route as WithMiddlewareRoute;
      // Add middlewares to the stack and compile children
      for (const child of mwRoute.children) {
        results.push(
          ...compileRoute(child, config, getCacheManager, layouts, [
            ...middlewares,
            ...mwRoute.middleware,
          ])
        );
      }
      break;
    }
  }

  return results;
}

/**
 * Compile all routes into flat list of handlers
 */
function compileRoutes(
  routes: SolRoute[],
  config: ISRRouterConfig,
  getCacheManager: (c: Context) => ISRCacheManager | null
): CompiledRoute[] {
  const results: CompiledRoute[] = [];
  for (const route of routes) {
    results.push(...compileRoute(route, config, getCacheManager));
  }
  return results;
}

/**
 * Create cache adapter based on environment
 */
function createCacheAdapter(config: ISRRouterConfig, env?: CloudflareEnv): CacheAdapter {
  // Use provided adapter
  if (config.cacheAdapter) {
    return config.cacheAdapter;
  }

  // Cloudflare KV
  if (env?.SOL_CACHE) {
    return new CloudflareKVAdapter(env.SOL_CACHE);
  }

  // Cloudflare Cache API (check if we're in a Worker)
  if (typeof caches !== 'undefined') {
    try {
      return new CloudflareCacheAdapter();
    } catch {
      // Fall through to memory cache
    }
  }

  // Default: in-memory cache
  return new MemoryCacheAdapter();
}

// ============================================================================
// Public API
// ============================================================================

/**
 * Register TypeScript routes with a Hono app
 *
 * @param app - Hono application instance
 * @param routes - Array of SolRoute definitions
 * @param config - Router configuration including ISR options
 */
export function registerRoutes<T extends Hono>(
  app: T,
  routes: SolRoute[],
  config: ISRRouterConfig = {}
): T {
  // For Cloudflare Workers, we need to create cache manager per-request
  // because env bindings are only available at request time
  const getCacheManager = (c: Context): ISRCacheManager | null => {
    if (!config.enableISR) return null;

    // Try to get KV binding from Hono context (Cloudflare Workers)
    const env = c.env as CloudflareEnv | undefined;
    const adapter = createCacheAdapter(config, env);
    return new ISRCacheManager(adapter);
  };

  const compiled = compileRoutes(routes, config, getCacheManager);

  for (const route of compiled) {
    switch (route.method) {
      case 'GET':
        app.get(route.path, route.handler);
        break;
      case 'POST':
        app.post(route.path, route.handler);
        break;
    }
  }

  return app;
}

/**
 * Create Hono app with ISR-enabled routes for Cloudflare Workers
 *
 * @example
 * ```typescript
 * // worker.ts
 * import { createWorkerApp } from '@sol/core/server-runtime';
 * import { routes, config } from './app/server/routes';
 *
 * export default {
 *   fetch: createWorkerApp(routes, config),
 * };
 * ```
 */
export function createWorkerApp(
  routesFn: () => SolRoute[],
  configFn: () => ISRRouterConfig,
  HonoConstructor: new () => Hono
): (request: Request, env: CloudflareEnv, ctx: ExecutionContext) => Promise<Response> {
  return async (request, env, ctx) => {
    const app = new HonoConstructor();
    const routes = routesFn();
    const config = configFn();

    // Hono automatically provides c.env and c.executionCtx in Cloudflare Workers
    registerRoutes(app, routes, config);

    return app.fetch(request, env, ctx);
  };
}

/**
 * Create a new Hono app with routes registered
 */
export async function createApp(
  routesModule: {
    routes: () => SolRoute[] | Promise<SolRoute[]>;
    config?: () => ISRRouterConfig | Promise<ISRRouterConfig>;
  },
  HonoConstructor: new () => Hono
): Promise<Hono> {
  const app = new HonoConstructor();
  const routes = await routesModule.routes();
  const config = routesModule.config ? await routesModule.config() : {};

  return registerRoutes(app, routes, config);
}

/**
 * Middleware to add ISR cache invalidation API
 *
 * Adds POST /api/revalidate endpoint for on-demand revalidation
 */
export function revalidateMiddleware(
  cacheManager: ISRCacheManager
): Middleware {
  return async (c, next) => {
    if (c.req.method === 'POST' && c.req.path === '/api/revalidate') {
      try {
        const body = await c.req.json<{ path?: string; tag?: string }>();

        if (body.path) {
          await cacheManager.delete(`page:${body.path}`);
          return c.json({ revalidated: true, path: body.path });
        }

        if (body.tag) {
          await cacheManager.invalidateTag(body.tag);
          return c.json({ revalidated: true, tag: body.tag });
        }

        return c.json({ error: 'Provide path or tag to revalidate' }, 400);
      } catch (e) {
        return c.json({ error: 'Invalid request' }, 400);
      }
    }

    return next();
  };
}

export { extractParams, isFragmentRequest, wrapInTemplate };
export type { ISRRouterConfig, CloudflareEnv, ExecutionContext };
