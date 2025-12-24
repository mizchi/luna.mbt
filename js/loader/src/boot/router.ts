/*! luna boot/router v1 - Minimal CSR router */

import { getLoader } from './loader';

export interface RouterOptions {
  /** Selector for interceptable links (default: "a[href]") */
  linkSelector?: string;
  /** Attribute to check for internal links (default: none) */
  linkAttribute?: string;
  /** Enable prefetch on hover (default: true) */
  prefetchOnHover?: boolean;
  /** Prefetch delay in ms (default: 50) */
  prefetchDelay?: number;
}

export type NavigateHandler = (path: string, isPopState: boolean) => void | Promise<void>;

/**
 * MinimalRouter handles link interception and navigation
 * Designed to be < 1KB gzipped
 */
export class MinimalRouter {
  private options: Required<RouterOptions>;
  private handlers: Set<NavigateHandler> = new Set();
  private prefetchTimers = new Map<string, number>();

  constructor(options: RouterOptions = {}) {
    this.options = {
      linkSelector: options.linkSelector ?? 'a[href]',
      linkAttribute: options.linkAttribute ?? '',
      prefetchOnHover: options.prefetchOnHover ?? true,
      prefetchDelay: options.prefetchDelay ?? 50,
    };
  }

  /**
   * Start intercepting links
   */
  start(): void {
    document.addEventListener('click', this.handleClick);
    if (this.options.prefetchOnHover) {
      document.addEventListener('mouseenter', this.handleHover, { capture: true });
      document.addEventListener('mouseleave', this.handleLeave, { capture: true });
    }
    window.addEventListener('popstate', this.handlePopState);
  }

  /**
   * Stop intercepting links
   */
  stop(): void {
    document.removeEventListener('click', this.handleClick);
    document.removeEventListener('mouseenter', this.handleHover, { capture: true });
    document.removeEventListener('mouseleave', this.handleLeave, { capture: true });
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
    // Load required chunks first
    const loader = getLoader();
    await loader.loadForPath(path);

    // Update history
    if (options.replace) {
      history.replaceState({ luna: true }, '', path);
    } else {
      history.pushState({ luna: true }, '', path);
    }

    // Notify handlers
    await this.notifyHandlers(path, false);
  }

  /**
   * Prefetch a path (load chunks without navigating)
   */
  prefetch(path: string): void {
    const loader = getLoader();
    loader.prefetch(path);
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
    const timer = window.setTimeout(() => {
      this.prefetch(href);
      this.prefetchTimers.delete(href);
    }, this.options.prefetchDelay);

    this.prefetchTimers.set(href, timer);
  };

  private handleLeave = (e: MouseEvent): void => {
    const target = e.target as Element | null;
    if (!target?.closest) return;

    const link = target.closest<HTMLAnchorElement>(this.options.linkSelector);
    if (!link) return;

    const href = link.getAttribute('href');
    if (!href) return;

    // Cancel pending prefetch
    const timer = this.prefetchTimers.get(href);
    if (timer) {
      clearTimeout(timer);
      this.prefetchTimers.delete(href);
    }
  };

  private handlePopState = async (e: PopStateEvent): Promise<void> => {
    // Handle browser back/forward
    const path = window.location.pathname;
    const loader = getLoader();
    await loader.loadForPath(path);
    await this.notifyHandlers(path, true);
  };

  private async notifyHandlers(path: string, isPopState: boolean): Promise<void> {
    const handlers = Array.from(this.handlers);
    for (let i = 0; i < handlers.length; i++) {
      await handlers[i](path, isPopState);
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

// Expose on window for debugging
declare global {
  interface Window {
    __LUNA_ROUTER__?: MinimalRouter;
  }
}

if (typeof window !== 'undefined') {
  window.__LUNA_ROUTER__ = getRouter();
}
