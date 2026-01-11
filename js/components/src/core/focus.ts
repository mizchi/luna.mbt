import type { CleanupFn } from './types';
import { on, queryAll } from './dom';

const FOCUSABLE_SELECTOR = [
  'a[href]',
  'button:not([disabled])',
  'input:not([disabled])',
  'select:not([disabled])',
  'textarea:not([disabled])',
  '[tabindex]:not([tabindex="-1"])',
].join(',');

/**
 * Get all focusable elements within a container
 */
export function getFocusable(container: Element): HTMLElement[] {
  return queryAll<HTMLElement>(container, FOCUSABLE_SELECTOR);
}

/**
 * Trap focus within a container
 */
export function trapFocus(container: Element): CleanupFn {
  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key !== 'Tab') return;

    const focusable = getFocusable(container);
    if (focusable.length === 0) return;

    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    const active = document.activeElement;

    if (e.shiftKey && active === first) {
      e.preventDefault();
      last.focus();
    } else if (!e.shiftKey && active === last) {
      e.preventDefault();
      first.focus();
    }
  };

  return on(container as HTMLElement, 'keydown', handleKeyDown);
}

/**
 * Focus the first focusable element in a container
 */
export function focusFirst(container: Element): void {
  const focusable = getFocusable(container);
  if (focusable.length > 0) {
    focusable[0].focus();
  }
}

/**
 * Save and restore focus
 */
export function saveFocus(): CleanupFn {
  const prev = document.activeElement as HTMLElement | null;
  return () => prev?.focus();
}
