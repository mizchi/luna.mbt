/*! luna router-spa v1 - Full Client-Side Rendering Router */

import { getNavigationRouter, NavigateEvent } from './navigation';

export interface SpaRouteConfig {
  /** Route path pattern (e.g., "/app", "/app/*") */
  path: string;
  /** Render function for the route */
  render: (params: RouteParams) => void | Promise<void>;
  /** Pattern for dynamic segments (optional) */
  pattern?: RegExp;
}

export interface RouteParams {
  /** URL path */
  path: string;
  /** Path parameters from dynamic segments */
  params: Record<string, string>;
  /** Search params */
  query: URLSearchParams;
}

export interface SpaRouterOptions {
  /** Container selector for rendering (default: "#app") */
  containerSelector?: string;
  /** Enable scroll restoration (default: true) */
  scrollRestoration?: boolean;
  /** Fallback route path (default: none) */
  fallbackPath?: string;
}

interface ScrollPosition {
  x: number;
  y: number;
}

/**
 * SpaRouter handles client-side rendered routes
 * - Route matching with dynamic segments
 * - Client-side rendering
 * - Designed for SPA sections within a larger site
 */
export class SpaRouter {
  private options: Required<Omit<SpaRouterOptions, 'fallbackPath'>> & Pick<SpaRouterOptions, 'fallbackPath'>;
  private routeConfigs: SpaRouteConfig[] = [];
  private scrollPositions = new Map<string, ScrollPosition>();
  private unsubscribe: (() => void) | null = null;
  private currentPath: string = '';

  constructor(options: SpaRouterOptions = {}) {
    this.options = {
      containerSelector: options.containerSelector ?? '#app',
      scrollRestoration: options.scrollRestoration ?? true,
      fallbackPath: options.fallbackPath,
    };
  }

  /**
   * Register a route
   */
  route(config: SpaRouteConfig): this {
    // Convert path pattern to regex if not provided
    if (!config.pattern) {
      config.pattern = this.pathToRegex(config.path);
    }
    this.routeConfigs.push(config);
    return this;
  }

  /**
   * Register multiple routes
   */
  routes(configs: SpaRouteConfig[]): this {
    configs.forEach(config => this.route(config));
    return this;
  }

  /**
   * Start the SPA router
   */
  start(): void {
    // Enable manual scroll restoration
    if (this.options.scrollRestoration && 'scrollRestoration' in history) {
      history.scrollRestoration = 'manual';
    }

    const router = getNavigationRouter();
    this.unsubscribe = router.onNavigate(this.handleNavigate);

    // Handle initial route
    this.handleNavigate({
      path: window.location.pathname,
      params: {},
      isPopState: false,
    });
  }

  /**
   * Stop the SPA router
   */
  stop(): void {
    this.unsubscribe?.();
    this.unsubscribe = null;
  }

  /**
   * Get the container element
   */
  getContainer(): HTMLElement | null {
    return document.querySelector(this.options.containerSelector);
  }

  private handleNavigate = async (event: NavigateEvent): Promise<void> => {
    const { path, isPopState } = event;
    // Save scroll position before navigation
    if (this.options.scrollRestoration && !isPopState && this.currentPath) {
      this.scrollPositions.set(this.currentPath, {
        x: window.scrollX,
        y: window.scrollY,
      });
    }

    this.currentPath = path;

    // Find matching route
    const match = this.matchRoute(path);

    if (match) {
      const params = this.extractParams(match.route, path);
      const query = new URLSearchParams(window.location.search);

      try {
        await match.route.render({ path, params, query });

        // Dispatch navigation complete event
        window.dispatchEvent(new CustomEvent('luna:navigation-complete', {
          detail: { path, params, query },
        }));

        // Handle scroll
        if (this.options.scrollRestoration) {
          if (isPopState) {
            const saved = this.scrollPositions.get(path);
            if (saved) {
              window.scrollTo(saved.x, saved.y);
            }
          } else {
            window.scrollTo(0, 0);
          }
        }
      } catch {
        // Dispatch error event
        window.dispatchEvent(new CustomEvent('luna:navigation-error', {
          detail: { path },
        }));
      }
    } else if (this.options.fallbackPath) {
      // Redirect to fallback
      const router = getNavigationRouter();
      router.navigate(this.options.fallbackPath, { replace: true });
    }
  };

  private matchRoute(path: string): { route: SpaRouteConfig } | null {
    for (const route of this.routeConfigs) {
      if (route.pattern?.test(path)) {
        return { route };
      }
    }
    return null;
  }

  private extractParams(route: SpaRouteConfig, path: string): Record<string, string> {
    const params: Record<string, string> = {};

    if (!route.pattern) return params;

    const match = path.match(route.pattern);
    if (!match?.groups) return params;

    // Extract named groups
    for (const [key, value] of Object.entries(match.groups)) {
      if (value !== undefined) {
        params[key] = value;
      }
    }

    return params;
  }

  private pathToRegex(path: string): RegExp {
    // Convert path pattern to regex
    // /app -> ^/app$
    // /app/* -> ^/app/.*$
    // /app/:id -> ^/app/(?<id>[^/]+)$
    // /app/:id/* -> ^/app/(?<id>[^/]+)/.*$

    let pattern = path
      // Escape special regex chars except * and :
      .replace(/[.+?^${}()|[\]\\]/g, '\\$&')
      // Convert :param to named group
      .replace(/:([a-zA-Z_][a-zA-Z0-9_]*)/g, '(?<$1>[^/]+)')
      // Convert /* to wildcard
      .replace(/\*/g, '.*');

    // Ensure full match
    if (!pattern.endsWith('.*')) {
      pattern += '/?';
    }

    return new RegExp(`^${pattern}$`);
  }
}

// Global singleton
let globalSpaRouter: SpaRouter | null = null;

/**
 * Get or create the SPA router
 */
export function getSpaRouter(options?: SpaRouterOptions): SpaRouter {
  if (!globalSpaRouter) {
    globalSpaRouter = new SpaRouter(options);
  }
  return globalSpaRouter;
}

/**
 * Create and start a SPA router with routes
 */
export function createSpaRouter(
  routes: SpaRouteConfig[],
  options?: SpaRouterOptions
): SpaRouter {
  const router = getSpaRouter(options);
  router.routes(routes);
  router.start();
  return router;
}
