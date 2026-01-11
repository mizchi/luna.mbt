// =============================================================================
// Types
// =============================================================================

/**
 * Cleanup function returned by setup functions
 */
export type CleanupFn = () => void;

/**
 * Generic setup function signature
 */
export type SetupFn<T = void> = (el: Element, options?: T) => CleanupFn;

/**
 * Checkbox state
 */
export type CheckboxState = 'checked' | 'unchecked' | 'indeterminate';

/**
 * Combine multiple cleanup functions into one
 */
export function combine(...fns: (CleanupFn | undefined)[]): CleanupFn {
  return () => {
    for (const fn of fns) fn?.();
  };
}

// =============================================================================
// DOM Utilities
// =============================================================================

/**
 * Add event listener with cleanup
 */
export function on<K extends keyof HTMLElementEventMap>(
  el: Element | Document,
  type: K,
  handler: (e: HTMLElementEventMap[K]) => void,
  options?: AddEventListenerOptions
): CleanupFn {
  el.addEventListener(type, handler as EventListener, options);
  return () => el.removeEventListener(type, handler as EventListener, options);
}

/**
 * Query selector with type safety
 */
export function query<E extends Element = Element>(
  el: Element | Document,
  selector: string
): E | null {
  return el.querySelector<E>(selector);
}

/**
 * Query all with type safety
 */
export function queryAll<E extends Element = Element>(
  el: Element | Document,
  selector: string
): E[] {
  return Array.from(el.querySelectorAll<E>(selector));
}

/**
 * Get/set attribute helper
 */
export function attr(el: Element, name: string): string | null;
export function attr(el: Element, name: string, value: string): void;
export function attr(el: Element, name: string, value?: string): string | null | void {
  if (value === undefined) {
    return el.getAttribute(name);
  }
  el.setAttribute(name, value);
}

/**
 * Toggle data-state attribute between values
 */
export function toggleState(el: Element, states: readonly string[]): string {
  const current = attr(el, 'data-state') ?? states[0];
  const idx = states.indexOf(current);
  const next = states[(idx + 1) % states.length];
  attr(el, 'data-state', next);
  return next;
}

/**
 * Read current data-state
 */
export function readState(el: Element): string | null {
  return attr(el, 'data-state');
}

// =============================================================================
// Keyboard Utilities
// =============================================================================

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

// =============================================================================
// Focus Utilities
// =============================================================================

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
