/*! luna boot/router v2 - SPA-aware CSR router */

import { getLoader, RouteMatch } from './loader';
import { setNavigationRouter } from '../router/navigation';
import type {
  NavigateEvent,
  NavigateHandler,
  NavigationRouter,
} from '../router/navigation';

export type { NavigateEvent, NavigateHandler } from '../router/navigation';

export interface RouterOptions {
  /** Selector for interceptable links (default: "a[href]") */
  linkSelector?: string;
  /** Attribute to check for internal links (default: none) */
  linkAttribute?: string;
  /** Enable prefetch on hover (default: true) */
  prefetchOnHover?: boolean;
  /** Prefetch delay in ms (default: 50) */
  prefetchDelay?: number;
  /** Enable SPA mode for specific segments */
  spaSegments?: string[];
}

/**
 * MinimalRouter handles link interception and navigation
 * Supports SPA fallback for hierarchical manifests
 */
export class MinimalRouter implements NavigationRouter {
  private options: Required<RouterOptions>;
  private handlers: Set<NavigateHandler> = new Set();

  constructor(options: RouterOptions = {}) {
    this.options = {
      linkSelector: options.linkSelector ?? 'a[href]',
      linkAttribute: options.linkAttribute ?? '',
      prefetchOnHover: options.prefetchOnHover ?? true,
      prefetchDelay: options.prefetchDelay ?? 50,
      spaSegments: options.spaSegments ?? [],
    };
  }

  /**
   * Start intercepting links
   */
  start(): void {
    document.addEventListener('click', this.handleClick);
    if (this.options.prefetchOnHover) {
      document.addEventListener('mouseenter', this.handleHover, { capture: true });
    }
    window.addEventListener('popstate', this.handlePopState);
  }

  /**
   * Stop intercepting links
   */
  stop(): void {
    document.removeEventListener('click', this.handleClick);
    document.removeEventListener('mouseenter', this.handleHover, { capture: true });
    window.removeEventListener('popstate', this.handlePopState);
  }

  /**
   * Register a navigation handler
   */
  onNavigate(handler: NavigateHandler): () => void {
    this.handlers.add(handler);
    return () => this.handlers.delete(handler);
  }

  /**
   * Navigate to a path
   */
  async navigate(path: string, options: { replace?: boolean } = {}): Promise<void> {
    const loader = getLoader();

    // Match path and load chunks
    const match = await loader.matchPath(path);
    if (!match) {
      // No match - let browser handle it (404)
      window.location.href = path;
      return;
    }

    // Load required chunks
    const missing = match.chunks.filter(c => !loader.isLoaded(c));
    await Promise.all(missing.map(c => loader.loadChunk(c)));

    // Update history
    if (options.replace) {
      history.replaceState({ luna: true, match }, '', path);
    } else {
      history.pushState({ luna: true, match }, '', path);
    }

    // Notify handlers
    await this.notifyHandlers({
      path,
      params: match.params,
      segment: match.segment,
      isSpa: match.isSpa,
      isPopState: false,
    });
  }

  /**
   * Prefetch a path (load chunks without navigating)
   */
  prefetch(path: string): void {
    const loader = getLoader();
    loader.prefetch(path);

    // Also prefetch segment manifest if hierarchical
    const segmentInfo = loader.getSegmentInfo(path);
    if (segmentInfo) {
      const segment = path.split('/').filter(Boolean)[0];
      if (segment) {
        loader.prefetchSegment(segment);
      }
    }
  }

  private handleClick = (e: MouseEvent): void => {
    const target = e.target as Element | null;
    const link = target?.closest<HTMLAnchorElement>(this.options.linkSelector);
    if (!link) return;

    // Check link attribute if specified
    if (this.options.linkAttribute && !link.hasAttribute(this.options.linkAttribute)) {
      return;
    }

    const href = link.getAttribute('href');
    if (!href) return;

    // Skip external links
    if (!this.isInternalLink(href)) return;

    // Skip if modifier key pressed
    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

    // Skip if target specified
    if (link.getAttribute('target')) return;

    // Check if this segment is SPA-enabled
    const loader = getLoader();
    const segmentInfo = loader.getSegmentInfo(href);
    const currentSegment = loader.getSegmentInfo(window.location.pathname);

    // If navigating within same SPA segment, use client-side routing
    // If navigating to/from non-SPA segment, let browser handle it
    const isSpaNavigation = segmentInfo?.spa ||
      currentSegment?.spa ||
      this.options.spaSegments.some(s => href.startsWith(`/${s}/`));

    if (!isSpaNavigation && !loader.isHierarchical()) {
      // Not a SPA navigation and not hierarchical - use traditional navigation
      // Only intercept if we have matching routes
      const chunks = loader.getChunksForPath(href);
      if (chunks.length === 0) return;
    }

    e.preventDefault();
    const replace = link.hasAttribute('data-replace');
    this.navigate(href, { replace });
  };

  private handleHover = (e: MouseEvent): void => {
    const target = e.target as Element | null;
    if (!target?.closest) return;

    const link = target.closest<HTMLAnchorElement>(this.options.linkSelector);
    if (!link) return;

    // Check link attribute if specified
    if (this.options.linkAttribute && !link.hasAttribute(this.options.linkAttribute)) {
      return;
    }

    const href = link.getAttribute('href');
    if (!href || !this.isInternalLink(href)) return;

    // Delay prefetch to avoid unnecessary loads
    window.setTimeout(() => {
      this.prefetch(href);
    }, this.options.prefetchDelay);
  };

  private handlePopState = async (e: PopStateEvent): Promise<void> => {
    const path = window.location.pathname;
    const loader = getLoader();

    // Try to get match from state
    let match = e.state?.match as RouteMatch | undefined;

    // If no match in state, resolve it
    if (!match) {
      match = await loader.matchPath(path) ?? undefined;
    }

    if (match) {
      await loader.loadForPath(path);

      await this.notifyHandlers({
        path,
        params: match.params,
        segment: match.segment,
        isSpa: match.isSpa,
        isPopState: true,
      });
    } else {
      // No match - reload the page
      window.location.reload();
    }
  };

  private async notifyHandlers(event: NavigateEvent): Promise<void> {
    const handlers = Array.from(this.handlers);
    for (let i = 0; i < handlers.length; i++) {
      await handlers[i](event);
    }
  }

  private isInternalLink(href: string): boolean {
    if (href.startsWith('http://') || href.startsWith('https://') || href.startsWith('//')) {
      try {
        const url = new URL(href, window.location.origin);
        return url.origin === window.location.origin;
      } catch {
        return false;
      }
    }
    // Relative or absolute path
    return href.startsWith('/') || !href.includes(':');
  }
}

// Global singleton instance
let globalRouter: MinimalRouter | null = null;

/**
 * Get or create the global router instance
 */
export function getRouter(options?: RouterOptions): MinimalRouter {
  if (!globalRouter) {
    globalRouter = new MinimalRouter(options);
    setNavigationRouter(globalRouter);
  }
  return globalRouter;
}

/**
 * Start the global router
 */
export function startRouter(options?: RouterOptions): MinimalRouter {
  const router = getRouter(options);
  router.start();
  return router;
}
