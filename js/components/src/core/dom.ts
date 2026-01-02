import type { CleanupFn } from './types';

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
