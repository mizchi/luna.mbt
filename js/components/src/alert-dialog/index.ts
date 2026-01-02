import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query } from '../core/dom';
import { onEscape } from '../core/keyboard';
import { trapFocus, focusFirst, saveFocus } from '../core/focus';

export interface AlertDialogOptions {
  /**
   * Callback when dialog is closed
   */
  onClose?: () => void;

  /**
   * Callback when confirmed
   */
  onConfirm?: () => void;

  /**
   * Callback when cancelled
   */
  onCancel?: () => void;
}

/**
 * Setup alert dialog behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-alert-dialog role="alertdialog" aria-modal="true" aria-hidden="true">
 *   <div data-alert-dialog-overlay></div>
 *   <div data-alert-dialog-content>
 *     <h2 data-alert-dialog-title>Are you sure?</h2>
 *     <p data-alert-dialog-description>This action cannot be undone.</p>
 *     <div data-alert-dialog-actions>
 *       <button data-alert-dialog-cancel>Cancel</button>
 *       <button data-alert-dialog-confirm>Confirm</button>
 *     </div>
 *   </div>
 * </div>
 * ```
 */
export function setupAlertDialog(el: Element, options: AlertDialogOptions = {}): CleanupFn {
  const { onClose, onConfirm, onCancel } = options;

  const content = query(el, '[data-alert-dialog-content]');
  const overlay = query(el, '[data-alert-dialog-overlay]');
  const confirmBtn = query(el, '[data-alert-dialog-confirm]');
  const cancelBtn = query(el, '[data-alert-dialog-cancel]');

  let focusCleanup: CleanupFn | undefined;
  let trapCleanup: CleanupFn | undefined;

  const close = () => {
    setOpen(el, false);
    trapCleanup?.();
    focusCleanup?.();
    onClose?.();
  };

  const confirm = () => {
    onConfirm?.();
    close();
  };

  const cancel = () => {
    onCancel?.();
    close();
  };

  const open = () => {
    focusCleanup = saveFocus();
    setOpen(el, true);

    if (content) {
      // Focus cancel button by default (safer action)
      const focusTarget = cancelBtn ?? query(content, 'button');
      if (focusTarget) {
        (focusTarget as HTMLElement).focus();
      } else {
        focusFirst(content);
      }
      trapCleanup = trapFocus(content);
    }
  };

  const cleanups: CleanupFn[] = [];

  if (confirmBtn) {
    cleanups.push(on(confirmBtn as HTMLElement, 'click', confirm));
  }
  if (cancelBtn) {
    cleanups.push(on(cancelBtn as HTMLElement, 'click', cancel));
  }
  // Alert dialogs should NOT close on overlay click (intentional)
  // But we add escape as cancel
  cleanups.push(onEscape(el, cancel));

  // Expose open/close on element
  (el as any).__alertDialogOpen = open;
  (el as any).__alertDialogClose = close;

  return combine(...cleanups, () => {
    trapCleanup?.();
    focusCleanup?.();
    delete (el as any).__alertDialogOpen;
    delete (el as any).__alertDialogClose;
  });
}

/**
 * Check if dialog is open
 */
export function isOpen(dialog: Element): boolean {
  return attr(dialog, 'aria-hidden') === 'false';
}

/**
 * Set open state
 */
export function setOpen(dialog: Element, open: boolean): void {
  attr(dialog, 'aria-hidden', open ? 'false' : 'true');
  attr(dialog, 'data-state', open ? 'open' : 'closed');
}

/**
 * Open dialog programmatically
 */
export function openAlertDialog(dialog: Element): void {
  const fn = (dialog as any).__alertDialogOpen;
  if (fn) fn();
  else setOpen(dialog, true);
}

/**
 * Close dialog programmatically
 */
export function closeAlertDialog(dialog: Element): void {
  const fn = (dialog as any).__alertDialogClose;
  if (fn) fn();
  else setOpen(dialog, false);
}
