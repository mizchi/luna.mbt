import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query } from '../core/dom';
import { onEscape } from '../core/keyboard';
import { trapFocus, focusFirst, saveFocus } from '../core/focus';

export interface DialogOptions {
  /**
   * Callback when dialog is closed
   */
  onClose?: () => void;

  /**
   * Close on Escape key (default: true)
   */
  closeOnEscape?: boolean;

  /**
   * Close when clicking overlay (default: true)
   */
  closeOnOverlay?: boolean;

  /**
   * Trap focus within dialog (default: true)
   */
  trapFocus?: boolean;
}

/**
 * Setup dialog behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-dialog role="dialog" aria-modal="true" aria-hidden="true">
 *   <div data-dialog-overlay></div>
 *   <div data-dialog-content>
 *     <button data-dialog-close>Close</button>
 *     <!-- dialog content -->
 *   </div>
 * </div>
 * ```
 */
export function setupDialog(el: Element, options: DialogOptions = {}): CleanupFn {
  const {
    onClose,
    closeOnEscape = true,
    closeOnOverlay = true,
    trapFocus: shouldTrapFocus = true
  } = options;

  const cleanups: CleanupFn[] = [];
  let focusCleanup: CleanupFn | undefined;
  let trapCleanup: CleanupFn | undefined;

  const close = () => {
    setOpen(el, false);
    focusCleanup?.();
    trapCleanup?.();
    onClose?.();
  };

  const open = () => {
    // Save focus before opening
    focusCleanup = saveFocus();

    setOpen(el, true);

    // Focus first element in dialog
    const content = query(el, '[data-dialog-content]');
    if (content) {
      focusFirst(content);

      // Setup focus trap
      if (shouldTrapFocus) {
        trapCleanup = trapFocus(content);
      }
    }
  };

  // Close button
  const closeBtn = query(el, '[data-dialog-close]');
  if (closeBtn) {
    cleanups.push(on(closeBtn as HTMLElement, 'click', close));
  }

  // Escape key
  if (closeOnEscape) {
    cleanups.push(onEscape(el, close));
  }

  // Overlay click
  if (closeOnOverlay) {
    const overlay = query(el, '[data-dialog-overlay]');
    if (overlay) {
      cleanups.push(on(overlay as HTMLElement, 'click', close));
    }
  }

  // Expose open/close functions on element
  (el as any).__dialogOpen = open;
  (el as any).__dialogClose = close;

  return combine(...cleanups, () => {
    focusCleanup?.();
    trapCleanup?.();
    delete (el as any).__dialogOpen;
    delete (el as any).__dialogClose;
  });
}

/**
 * Check if dialog is open
 */
export function isOpen(dialog: Element): boolean {
  const ariaHidden = attr(dialog, 'aria-hidden');
  if (ariaHidden === 'false') return true;
  if (ariaHidden === 'true') return false;

  const state = attr(dialog, 'data-state');
  return state === 'open';
}

/**
 * Set dialog open state
 */
export function setOpen(dialog: Element, open: boolean): void {
  attr(dialog, 'aria-hidden', open ? 'false' : 'true');
  attr(dialog, 'data-state', open ? 'open' : 'closed');
}

/**
 * Open a dialog programmatically
 */
export function openDialog(dialog: Element): void {
  const fn = (dialog as any).__dialogOpen;
  if (fn) fn();
  else setOpen(dialog, true);
}

/**
 * Close a dialog programmatically
 */
export function closeDialog(dialog: Element): void {
  const fn = (dialog as any).__dialogClose;
  if (fn) fn();
  else setOpen(dialog, false);
}
