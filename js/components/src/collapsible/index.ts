import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query } from '../core/dom';
import { onActivate } from '../core/keyboard';

export interface CollapsibleOptions {
  /**
   * Callback when open state changes
   */
  onChange?: (open: boolean) => void;

  /**
   * Default open state
   */
  defaultOpen?: boolean;
}

/**
 * Setup collapsible behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-collapsible data-state="closed">
 *   <button data-collapsible-trigger aria-expanded="false">
 *     Toggle
 *   </button>
 *   <div data-collapsible-content aria-hidden="true">
 *     Content here
 *   </div>
 * </div>
 * ```
 */
export function setupCollapsible(el: Element, options: CollapsibleOptions = {}): CleanupFn {
  const { onChange, defaultOpen = false } = options;

  const trigger = query(el, '[data-collapsible-trigger]');
  const content = query(el, '[data-collapsible-content]');

  if (!trigger) return () => {};

  // Initialize state
  if (defaultOpen) {
    setOpen(el, true);
  }

  const toggle = () => {
    const currentOpen = isOpen(el);
    setOpen(el, !currentOpen);
    onChange?.(!currentOpen);
  };

  return combine(
    on(trigger as HTMLElement, 'click', toggle),
    onActivate(trigger, toggle)
  );
}

/**
 * Check if collapsible is open
 */
export function isOpen(collapsible: Element): boolean {
  const trigger = query(collapsible, '[data-collapsible-trigger]');
  if (trigger) {
    return attr(trigger, 'aria-expanded') === 'true';
  }
  return attr(collapsible, 'data-state') === 'open';
}

/**
 * Set open state
 */
export function setOpen(collapsible: Element, open: boolean): void {
  const trigger = query(collapsible, '[data-collapsible-trigger]');
  const content = query(collapsible, '[data-collapsible-content]');

  attr(collapsible, 'data-state', open ? 'open' : 'closed');

  if (trigger) {
    attr(trigger, 'aria-expanded', open ? 'true' : 'false');
  }

  if (content) {
    attr(content, 'aria-hidden', open ? 'false' : 'true');
    attr(content, 'data-state', open ? 'open' : 'closed');
  }
}

/**
 * Toggle open state
 */
export function toggle(collapsible: Element): boolean {
  const open = !isOpen(collapsible);
  setOpen(collapsible, open);
  return open;
}
