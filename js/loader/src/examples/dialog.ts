/**
 * Dialog component hydration example using @luna_ui/luna-loader/hydration
 *
 * This demonstrates how to use the hydration utilities for a modal dialog component.
 */
import {
  createHydrator,
  delegate,
} from '../hydration';

interface DialogElements {
  dialog: HTMLElement;
  overlay: HTMLElement | null;
  content: HTMLElement | null;
}

function getDialogElements(element: Element): DialogElements | null {
  const dialog = element.querySelector('[data-dialog]') as HTMLElement;
  if (!dialog) return null;

  return {
    dialog,
    overlay: element.querySelector('[data-dialog-overlay]') as HTMLElement,
    content: element.querySelector('[data-dialog-content]') as HTMLElement,
  };
}

function openDialog(els: DialogElements): void {
  els.dialog.dataset.state = 'open';
  if (els.overlay) els.overlay.style.display = 'block';
  if (els.content) els.content.style.display = 'block';
  document.body.style.overflow = 'hidden';
}

function closeDialog(els: DialogElements): void {
  els.dialog.dataset.state = 'closed';
  if (els.overlay) els.overlay.style.display = 'none';
  if (els.content) els.content.style.display = 'none';
  document.body.style.overflow = '';
}

/**
 * Dialog hydration using createHydrator factory
 */
export const hydrate = createHydrator((element) => {
  const els = getDialogElements(element);
  if (!els) return;

  // Open dialog trigger
  delegate(element, 'click', '[data-dialog-trigger]', () => {
    openDialog(els);
  });

  // Close on overlay click
  if (els.overlay) {
    els.overlay.onclick = () => closeDialog(els);
  }

  // Close buttons
  delegate(element, 'click', '[data-dialog-close]', () => {
    closeDialog(els);
  });

  // Prevent clicks inside content from closing
  if (els.content) {
    els.content.onclick = (e) => e.stopPropagation();
  }

  // Close on Escape key
  const escapeHandler = (e: KeyboardEvent) => {
    if (e.key === 'Escape' && els.dialog.dataset.state === 'open') {
      closeDialog(els);
    }
  };
  document.addEventListener('keydown', escapeHandler);

  // Return cleanup function (optional, for SPA navigation)
  return () => {
    document.removeEventListener('keydown', escapeHandler);
  };
});

export default hydrate;
