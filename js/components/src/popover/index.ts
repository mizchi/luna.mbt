import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query } from '../core/dom';
import { onEscape } from '../core/keyboard';
import { trapFocus, focusFirst, saveFocus } from '../core/focus';

export interface PopoverOptions {
  /**
   * Callback when open state changes
   */
  onOpenChange?: (open: boolean) => void;

  /**
   * Close when clicking outside
   */
  closeOnOutsideClick?: boolean;

  /**
   * Trap focus within popover
   */
  trapFocus?: boolean;
}

/**
 * Setup popover behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-popover>
 *   <button data-popover-trigger aria-haspopup="dialog" aria-expanded="false">
 *     Open Popover
 *   </button>
 *   <div data-popover-content role="dialog" aria-hidden="true">
 *     <button data-popover-close>Close</button>
 *     Popover content
 *   </div>
 * </div>
 * ```
 */
export function setupPopover(el: Element, options: PopoverOptions = {}): CleanupFn {
  const { onOpenChange, closeOnOutsideClick = true, trapFocus: shouldTrap = false } = options;

  const trigger = query(el, '[data-popover-trigger]');
  const content = query(el, '[data-popover-content]');
  const closeBtn = query(el, '[data-popover-close]');

  if (!trigger || !content) return () => {};

  let focusCleanup: CleanupFn | undefined;
  let trapCleanup: CleanupFn | undefined;

  const open = () => {
    focusCleanup = saveFocus();
    setOpen(el, true);
    onOpenChange?.(true);

    if (shouldTrap) {
      focusFirst(content);
      trapCleanup = trapFocus(content);
    }
  };

  const close = () => {
    setOpen(el, false);
    onOpenChange?.(false);
    trapCleanup?.();
    focusCleanup?.();
  };

  const toggle = () => {
    if (isOpen(el)) {
      close();
    } else {
      open();
    }
  };

  const handleOutsideClick = (e: Event) => {
    if (closeOnOutsideClick && isOpen(el) && !el.contains(e.target as Node)) {
      close();
    }
  };

  const cleanups: CleanupFn[] = [];

  cleanups.push(on(trigger as HTMLElement, 'click', toggle));
  if (closeBtn) {
    cleanups.push(on(closeBtn as HTMLElement, 'click', close));
  }
  cleanups.push(onEscape(el, close));
  cleanups.push(on(document, 'click', handleOutsideClick));

  return combine(...cleanups, () => {
    trapCleanup?.();
    focusCleanup?.();
  });
}

/**
 * Check if popover is open
 */
export function isOpen(popover: Element): boolean {
  const trigger = query(popover, '[data-popover-trigger]');
  return trigger ? attr(trigger, 'aria-expanded') === 'true' : false;
}

/**
 * Set open state
 */
export function setOpen(popover: Element, open: boolean): void {
  const trigger = query(popover, '[data-popover-trigger]');
  const content = query(popover, '[data-popover-content]');

  if (trigger) {
    attr(trigger, 'aria-expanded', open ? 'true' : 'false');
  }
  if (content) {
    attr(content, 'aria-hidden', open ? 'false' : 'true');
    attr(content, 'data-state', open ? 'open' : 'closed');
  }
  attr(popover, 'data-state', open ? 'open' : 'closed');
}
