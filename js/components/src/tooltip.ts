import type { CleanupFn } from './core';
import { combine, on, attr, query } from './core';

export interface TooltipOptions {
  /**
   * Delay before showing tooltip (ms)
   */
  showDelay?: number;

  /**
   * Delay before hiding tooltip (ms)
   */
  hideDelay?: number;

  /**
   * Callback when tooltip visibility changes
   */
  onChange?: (visible: boolean) => void;
}

/**
 * Setup tooltip behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-tooltip>
 *   <button data-tooltip-trigger>Hover me</button>
 *   <div data-tooltip-content role="tooltip" aria-hidden="true">
 *     Tooltip text
 *   </div>
 * </div>
 * ```
 */
export function setupTooltip(el: Element, options: TooltipOptions = {}): CleanupFn {
  const { showDelay = 300, hideDelay = 100, onChange } = options;

  const trigger = query(el, '[data-tooltip-trigger]');
  const content = query(el, '[data-tooltip-content]');

  if (!trigger || !content) return () => {};

  let showTimeout: ReturnType<typeof setTimeout> | null = null;
  let hideTimeout: ReturnType<typeof setTimeout> | null = null;

  const show = () => {
    if (hideTimeout) {
      clearTimeout(hideTimeout);
      hideTimeout = null;
    }
    showTimeout = setTimeout(() => {
      setVisible(el, true);
      onChange?.(true);
    }, showDelay);
  };

  const hide = () => {
    if (showTimeout) {
      clearTimeout(showTimeout);
      showTimeout = null;
    }
    hideTimeout = setTimeout(() => {
      setVisible(el, false);
      onChange?.(false);
    }, hideDelay);
  };

  const hideImmediate = () => {
    if (showTimeout) clearTimeout(showTimeout);
    if (hideTimeout) clearTimeout(hideTimeout);
    setVisible(el, false);
    onChange?.(false);
  };

  const cleanups: CleanupFn[] = [];

  // Mouse events
  cleanups.push(on(trigger as HTMLElement, 'mouseenter', show));
  cleanups.push(on(trigger as HTMLElement, 'mouseleave', hide));

  // Focus events
  cleanups.push(on(trigger as HTMLElement, 'focus', show));
  cleanups.push(on(trigger as HTMLElement, 'blur', hide));

  // Escape key hides immediately
  cleanups.push(on(trigger as HTMLElement, 'keydown', (e) => {
    if (e.key === 'Escape') hideImmediate();
  }));

  // Keep tooltip open when hovering content
  cleanups.push(on(content as HTMLElement, 'mouseenter', () => {
    if (hideTimeout) {
      clearTimeout(hideTimeout);
      hideTimeout = null;
    }
  }));
  cleanups.push(on(content as HTMLElement, 'mouseleave', hide));

  return combine(...cleanups, () => {
    if (showTimeout) clearTimeout(showTimeout);
    if (hideTimeout) clearTimeout(hideTimeout);
  });
}

/**
 * Check if tooltip is visible
 */
export function isVisible(tooltip: Element): boolean {
  const content = query(tooltip, '[data-tooltip-content]');
  return content ? attr(content, 'aria-hidden') === 'false' : false;
}

/**
 * Set tooltip visibility
 */
export function setVisible(tooltip: Element, visible: boolean): void {
  const content = query(tooltip, '[data-tooltip-content]');
  if (content) {
    attr(content, 'aria-hidden', visible ? 'false' : 'true');
    attr(content, 'data-state', visible ? 'open' : 'closed');
  }
  attr(tooltip, 'data-state', visible ? 'open' : 'closed');
}
