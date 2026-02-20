/*! luna router-hybrid v1 - Fetch + Swap Navigation */

import { getNavigationRouter, NavigateEvent } from './navigation';

export interface HybridRouterOptions {
  /** Selector for the main content container (default: "#app") */
  containerSelector?: string;
  /** Header to request fragment responses (default: "X-Luna-Fragment") */
  fragmentHeader?: string;
  /** Cache TTL in ms (default: 5 minutes) */
  cacheTTL?: number;
  /** Enable scroll restoration (default: true) */
  scrollRestoration?: boolean;
}

interface ScrollPosition {
  x: number;
  y: number;
}

/**
 * HybridRouter implements Turbo/HTMX-style navigation
 * - Fetches HTML from server
 * - Swaps content into container
 * - Supports fragment responses
 * - Designed to be < 1KB gzipped
 */
export class HybridRouter {
  private options: Required<HybridRouterOptions>;
  private cache = new Map<string, string>();
  private scrollPositions = new Map<string, ScrollPosition>();
  private isNavigating = false;
  private unsubscribe: (() => void) | null = null;

  constructor(options: HybridRouterOptions = {}) {
    this.options = {
      containerSelector: options.containerSelector ?? '#app',
      fragmentHeader: options.fragmentHeader ?? 'X-Luna-Fragment',
      cacheTTL: options.cacheTTL ?? 5 * 60 * 1000,
      scrollRestoration: options.scrollRestoration ?? true,
    };
  }

  /**
   * Start hybrid navigation
   */
  start(): void {
    // Enable manual scroll restoration
    if (this.options.scrollRestoration && 'scrollRestoration' in history) {
      history.scrollRestoration = 'manual';
    }

    const router = getNavigationRouter();
    this.unsubscribe = router.onNavigate(this.handleNavigate);
  }

  /**
   * Stop hybrid navigation
   */
  stop(): void {
    this.unsubscribe?.();
    this.unsubscribe = null;
  }

  /**
   * Get cached HTML for a path
   */
  getCached(path: string): string | undefined {
    return this.cache.get(path);
  }

  /**
   * Clear cache
   */
  clearCache(): void {
    this.cache.clear();
  }

  private handleNavigate = async (event: NavigateEvent): Promise<void> => {
    const { path, isPopState } = event;
    if (this.isNavigating) return;
    this.isNavigating = true;

    try {
      // Save current scroll position before navigation
      if (this.options.scrollRestoration && !isPopState) {
        const currentPath = window.location.pathname;
        this.scrollPositions.set(currentPath, {
          x: window.scrollX,
          y: window.scrollY,
        });
      }

      // Try cache first (SWR pattern)
      const cachedHtml = this.cache.get(path);
      if (cachedHtml) {
        this.updateDOM(cachedHtml);
      }

      // Fetch fresh content
      const response = await fetch(path, {
        headers: { [this.options.fragmentHeader]: 'true' },
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const html = await response.text();

      // Check if fragment response
      const isFragment = response.headers.get(`${this.options.fragmentHeader}-Response`) === 'true';
      if (isFragment) {
        this.cacheResponse(path, html);
      }

      // Update DOM if content changed or no cache
      if (!cachedHtml || html !== cachedHtml) {
        this.updateDOM(html);
      }

      // Restore or reset scroll position
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
      // Fallback to full page load
      window.location.href = path;
    } finally {
      this.isNavigating = false;
    }
  };

  private updateDOM(html: string): void {
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, 'text/html');

    // Check for fragment templates
    const templates = doc.querySelectorAll<HTMLTemplateElement>('template[data-outlet]');

    if (templates.length > 0) {
      // Fragment response - update each outlet
      templates.forEach(tpl => {
        const name = tpl.dataset.outlet;
        const target = document.querySelector<HTMLElement>(`[data-outlet="${name}"]`);
        if (target) {
          this.setHTML(target, tpl.innerHTML);
        }
      });

      // Update title
      const titleTpl = doc.querySelector<HTMLTemplateElement>('template[data-title]');
      if (titleTpl?.textContent) {
        document.title = titleTpl.textContent;
      }
    } else {
      // Full page response - extract container content
      const source = doc.querySelector(this.options.containerSelector);
      const target = document.querySelector<HTMLElement>(this.options.containerSelector);
      if (source && target) {
        this.setHTML(target, source.innerHTML);
      }

      // Update title
      const title = doc.querySelector('title');
      if (title?.textContent) {
        document.title = title.textContent;
      }
    }

    // Trigger custom event for island hydration
    window.dispatchEvent(new CustomEvent('luna:navigation-complete'));
  }

  private setHTML(target: HTMLElement, html: string): void {
    // Use setHTMLUnsafe if available (supports Declarative Shadow DOM)
    const setHTMLUnsafe = (target as any).setHTMLUnsafe;
    if (typeof setHTMLUnsafe === 'function') {
      setHTMLUnsafe.call(target, html);
    } else {
      target.innerHTML = html;
    }
  }

  private cacheResponse(path: string, html: string): void {
    this.cache.set(path, html);
    setTimeout(() => this.cache.delete(path), this.options.cacheTTL);
  }
}

// Global singleton
let globalHybridRouter: HybridRouter | null = null;

/**
 * Get or create the hybrid router
 */
export function getHybridRouter(options?: HybridRouterOptions): HybridRouter {
  if (!globalHybridRouter) {
    globalHybridRouter = new HybridRouter(options);
  }
  return globalHybridRouter;
}

/**
 * Start hybrid navigation
 */
export function startHybridRouter(options?: HybridRouterOptions): HybridRouter {
  const router = getHybridRouter(options);
  router.start();
  return router;
}
