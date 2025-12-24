/*! luna boot v1 - Minimal client runtime */

export { ChunkLoader, getLoader, initLoader, type ChunkManifest } from './loader';
export { MinimalRouter, getRouter, startRouter, type RouterOptions, type NavigateHandler } from './router';

import { initLoader } from './loader';
import { startRouter, getRouter } from './router';
import { onReady } from '../lib';

/**
 * Boot options for initialization
 */
export interface BootOptions {
  /** Manifest URL or inline manifest (default: "/_luna/manifest.json") */
  manifest?: string | import('./loader').ChunkManifest;
  /** Router options */
  router?: import('./router').RouterOptions;
  /** Skip manifest loading (for static-only sites) */
  skipManifest?: boolean;
  /** Skip router (for MPA mode) */
  skipRouter?: boolean;
}

/**
 * Initialize Luna boot runtime
 * Loads manifest and starts router
 */
export async function boot(options: BootOptions = {}): Promise<void> {
  // Initialize chunk loader with manifest
  if (!options.skipManifest) {
    await initLoader(options.manifest);
  }

  // Start router for link interception
  if (!options.skipRouter) {
    startRouter(options.router);
  }
}

/**
 * Auto-boot when DOM is ready (for script tag usage)
 * Reads config from script tag data attributes
 */
export function autoBoot(): void {
  onReady(async () => {
    // Find boot script
    const script = document.querySelector<HTMLScriptElement>('script[data-luna-boot]');
    if (!script) {
      // Default boot
      await boot({ skipManifest: true });
      return;
    }

    // Parse options from data attributes
    const manifest = script.dataset.lunaManifest;
    const skipRouter = script.dataset.lunaSkipRouter === 'true';
    const linkSelector = script.dataset.lunaLinkSelector;
    const linkAttribute = script.dataset.lunaLinkAttribute;

    await boot({
      manifest,
      skipManifest: !manifest,
      skipRouter,
      router: {
        linkSelector,
        linkAttribute,
      },
    });
  });
}

// Expose boot function globally
declare global {
  interface Window {
    __LUNA_BOOT__?: typeof boot;
  }
}

if (typeof window !== 'undefined') {
  window.__LUNA_BOOT__ = boot;
}
