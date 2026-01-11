import type { CleanupFn } from './types';
import { on } from './dom';

/**
 * Handle keyboard events on an element
 */
export function onKey(
  el: Element,
  key: string,
  handler: (e: KeyboardEvent) => void
): CleanupFn {
  return on(el as HTMLElement, 'keydown', (e) => {
    if (e.key === key) handler(e);
  });
}

/**
 * Handle Escape key
 */
export function onEscape(el: Element | Document, handler: () => void): CleanupFn {
  return on(el as HTMLElement, 'keydown', (e) => {
    if (e.key === 'Escape') {
      e.preventDefault();
      handler();
    }
  });
}

/**
 * Handle Enter/Space key (for button-like behavior)
 */
export function onActivate(el: Element, handler: (e: KeyboardEvent) => void): CleanupFn {
  return on(el as HTMLElement, 'keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handler(e);
    }
  });
}

/**
 * Arrow key navigation within a list
 */
export function onArrowNav(
  container: Element,
  selector: string,
  options: {
    orientation?: 'horizontal' | 'vertical' | 'both';
    loop?: boolean;
  } = {}
): CleanupFn {
  const { orientation = 'vertical', loop = true } = options;

  return on(container as HTMLElement, 'keydown', (e) => {
    const items = Array.from(container.querySelectorAll<HTMLElement>(selector));
    if (items.length === 0) return;

    const current = document.activeElement as HTMLElement;
    const idx = items.indexOf(current);
    if (idx === -1) return;

    let next = idx;
    const isVertical = orientation === 'vertical' || orientation === 'both';
    const isHorizontal = orientation === 'horizontal' || orientation === 'both';

    if ((e.key === 'ArrowDown' && isVertical) || (e.key === 'ArrowRight' && isHorizontal)) {
      e.preventDefault();
      next = loop ? (idx + 1) % items.length : Math.min(idx + 1, items.length - 1);
    } else if ((e.key === 'ArrowUp' && isVertical) || (e.key === 'ArrowLeft' && isHorizontal)) {
      e.preventDefault();
      next = loop ? (idx - 1 + items.length) % items.length : Math.max(idx - 1, 0);
    } else if (e.key === 'Home') {
      e.preventDefault();
      next = 0;
    } else if (e.key === 'End') {
      e.preventDefault();
      next = items.length - 1;
    }

    if (next !== idx) {
      items[next].focus();
    }
  });
}
