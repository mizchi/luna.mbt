/**
 * @luna_ui/luna-loader/hydration
 *
 * Framework-agnostic SSR + Hydration utilities.
 * Works with any SSR output: Luna (MoonBit), React, Preact, or plain HTML.
 *
 * ## Design Principles
 *
 * 1. **DOM-first**: Adopt existing server-rendered HTML
 * 2. **Attribute-only**: Only update data-* and aria-* attributes (no inline styles)
 * 3. **CSS in SSR**: All styling via CSS selectors on attributes
 * 4. **Cleanup always**: All setup functions return cleanup functions
 * 5. **Framework-agnostic**: Works with any SSR renderer
 *
 * ## CSS Convention
 *
 * ```css
 * [data-state="open"] [data-content] { max-height: 200px; }
 * [data-state="closed"] [data-content] { max-height: 0; }
 * [aria-checked="true"] { background: var(--primary); }
 * [aria-checked="false"] { background: var(--muted); }
 * ```
 */

// =============================================================================
// Types
// =============================================================================

/** Standard hydration function signature */
export type HydrateFn = (element: Element, state: unknown, name: string) => void;

/** Cleanup function for SPA navigation */
export type CleanupFn = () => void;

/** Setup function that returns cleanup */
export type SetupFn<S = unknown> = (
  element: Element,
  state: S,
  name: string
) => CleanupFn;

// =============================================================================
// Core: Hydration Factory
// =============================================================================

/**
 * Create a hydration function with automatic hydrated marking.
 *
 * @example
 * ```ts
 * export const hydrate = createHydrator((element) => {
 *   const cleanup = onClick(element, '[data-trigger]', () => {
 *     toggle(element, 'data-state', ['open', 'closed']);
 *   });
 *   return cleanup;
 * });
 * ```
 */
export function createHydrator<S = unknown>(setup: SetupFn<S>): HydrateFn {
  return (element, state, name) => {
    if (isHydrated(element)) return;
    markHydrated(element);
    setup(element, state as S, name);
  };
}

// =============================================================================
// Attribute Operations
// =============================================================================

/**
 * Toggle an attribute between two values.
 *
 * @example
 * ```ts
 * toggle(item, 'data-state', ['open', 'closed']);
 * // 'open' -> 'closed', 'closed' -> 'open'
 * ```
 */
export function toggle(
  element: Element,
  attr: string,
  values: [string, string]
): string {
  const current = element.getAttribute(attr);
  const next = current === values[0] ? values[1] : values[0];
  element.setAttribute(attr, next);
  return next;
}

/**
 * Toggle aria-checked attribute.
 *
 * @example
 * ```ts
 * toggleChecked(button);
 * // 'true' -> 'false', 'false' -> 'true'
 * ```
 */
export function toggleChecked(element: Element): boolean {
  const checked = element.getAttribute('aria-checked') !== 'true';
  element.setAttribute('aria-checked', String(checked));
  return checked;
}

/**
 * Set data-state attribute.
 */
export function setState(element: Element, state: string): void {
  (element as HTMLElement).dataset.state = state;
}

/**
 * Get data-state attribute.
 */
export function getState(element: Element): string | undefined {
  return (element as HTMLElement).dataset.state;
}

/**
 * Set aria-checked attribute.
 */
export function setChecked(element: Element, checked: boolean): void {
  element.setAttribute('aria-checked', String(checked));
}

/**
 * Get aria-checked attribute.
 */
export function getChecked(element: Element): boolean {
  return element.getAttribute('aria-checked') === 'true';
}

/**
 * Set aria-valuenow attribute.
 */
export function setValue(element: Element, value: number): void {
  element.setAttribute('aria-valuenow', String(value));
  (element as HTMLElement).dataset.value = String(value);
}

/**
 * Get aria-valuenow attribute.
 */
export function getValue(element: Element, defaultValue = 0): number {
  const value = element.getAttribute('aria-valuenow');
  return value ? parseInt(value, 10) : defaultValue;
}

// =============================================================================
// State Reading: Extract initial state from SSR-rendered DOM
// =============================================================================

/**
 * Read data-state values from items.
 *
 * @contract SSR HTML must have:
 * - `[itemAttr]` with unique ID value
 * - `data-state` attribute
 *
 * @example
 * ```html
 * <div data-item="a" data-state="open">...</div>
 * <div data-item="b" data-state="closed">...</div>
 * ```
 * ```ts
 * const states = readStates(element, 'data-item');
 * // Map { 'a' => 'open', 'b' => 'closed' }
 * ```
 */
export function readStates(element: Element, itemAttr: string): Map<string, string> {
  const states = new Map<string, string>();
  const attrName = toCamelCase(itemAttr.replace('data-', ''));
  element.querySelectorAll(`[${itemAttr}]`).forEach(item => {
    const id = (item as HTMLElement).dataset[attrName];
    const state = (item as HTMLElement).dataset.state;
    if (id && state) states.set(id, state);
  });
  return states;
}

/**
 * Read aria-checked values from items.
 *
 * @contract SSR HTML must have:
 * - `[itemAttr]` with unique ID value
 * - `aria-checked` attribute
 *
 * @example
 * ```html
 * <button data-switch="a" aria-checked="true">...</button>
 * <button data-switch="b" aria-checked="false">...</button>
 * ```
 * ```ts
 * const checked = readChecked(element, 'data-switch');
 * // Map { 'a' => true, 'b' => false }
 * ```
 */
export function readChecked(element: Element, itemAttr: string): Map<string, boolean> {
  const states = new Map<string, boolean>();
  const attrName = toCamelCase(itemAttr.replace('data-', ''));
  element.querySelectorAll(`[${itemAttr}]`).forEach(el => {
    const id = (el as HTMLElement).dataset[attrName];
    const checked = el.getAttribute('aria-checked') === 'true';
    if (id) states.set(id, checked);
  });
  return states;
}

/**
 * Read numeric attributes from element.
 */
export function readNumber(element: Element, attr: string, defaultValue = 0): number {
  const value = element.getAttribute(attr);
  return value ? parseFloat(value) : defaultValue;
}

/**
 * Read min/max/value from slider-like element.
 *
 * @contract SSR HTML must have:
 * - `aria-valuemin` or `data-min`
 * - `aria-valuemax` or `data-max`
 * - `aria-valuenow` or `data-value`
 */
export function readRange(element: Element): { min: number; max: number; value: number } {
  return {
    min: readNumber(element, 'aria-valuemin') || readNumber(element, 'data-min') || 0,
    max: readNumber(element, 'aria-valuemax') || readNumber(element, 'data-max') || 100,
    value: readNumber(element, 'aria-valuenow') || readNumber(element, 'data-value') || 0,
  };
}

// =============================================================================
// Event Handling
// =============================================================================

/**
 * Add click handler with event delegation.
 *
 * @returns Cleanup function
 *
 * @example
 * ```ts
 * const cleanup = onClick(element, '[data-trigger]', (e, target) => {
 *   const itemId = target.closest('[data-item]')?.dataset.item;
 *   // ...
 * });
 * ```
 */
export function onClick(
  element: Element,
  selector: string,
  handler: (event: MouseEvent, target: Element) => void
): CleanupFn {
  return on(element, 'click', selector, handler);
}

/**
 * Add event handler with delegation.
 *
 * @returns Cleanup function
 */
export function on<E extends Event = Event>(
  element: Element,
  eventType: string,
  selector: string,
  handler: (event: E, target: Element) => void
): CleanupFn {
  const listener = (event: Event) => {
    const target = (event.target as Element).closest(selector);
    if (target && element.contains(target)) {
      handler(event as E, target);
    }
  };
  element.addEventListener(eventType, listener);
  return () => element.removeEventListener(eventType, listener);
}

/**
 * Add keyboard handler.
 *
 * @returns Cleanup function
 */
export function onKey(
  element: Element | Document,
  key: string,
  handler: (event: KeyboardEvent) => void,
  options?: { condition?: () => boolean }
): CleanupFn {
  const listener = (event: Event) => {
    const e = event as KeyboardEvent;
    if (e.key === key && (!options?.condition || options.condition())) {
      handler(e);
    }
  };
  element.addEventListener('keydown', listener);
  return () => element.removeEventListener('keydown', listener);
}

/**
 * Add drag handlers (mouse + touch).
 *
 * @returns Cleanup function
 */
export function onDrag(
  element: Element,
  handlers: {
    onStart?: (x: number, y: number) => void;
    onMove: (x: number, y: number) => void;
    onEnd?: () => void;
  }
): CleanupFn {
  const getXY = (e: MouseEvent | TouchEvent): [number, number] => {
    if ('touches' in e) {
      return [e.touches[0].clientX, e.touches[0].clientY];
    }
    return [e.clientX, e.clientY];
  };

  const start = (e: MouseEvent | TouchEvent) => {
    e.preventDefault();
    const [x, y] = getXY(e);
    handlers.onStart?.(x, y);
    handlers.onMove(x, y);

    const move = (e: MouseEvent | TouchEvent) => {
      const [x, y] = getXY(e);
      handlers.onMove(x, y);
    };

    const end = () => {
      handlers.onEnd?.();
      document.removeEventListener('mousemove', move);
      document.removeEventListener('mouseup', end);
      document.removeEventListener('touchmove', move);
      document.removeEventListener('touchend', end);
    };

    document.addEventListener('mousemove', move);
    document.addEventListener('mouseup', end);
    document.addEventListener('touchmove', move);
    document.addEventListener('touchend', end);
  };

  element.addEventListener('mousedown', start as EventListener);
  element.addEventListener('touchstart', start as EventListener);

  return () => {
    element.removeEventListener('mousedown', start as EventListener);
    element.removeEventListener('touchstart', start as EventListener);
  };
}

// =============================================================================
// Transitions
// =============================================================================

/**
 * Enable CSS transitions after hydration.
 * Call this in requestAnimationFrame to prevent initial animation flash.
 *
 * @example
 * ```ts
 * requestAnimationFrame(() => {
 *   enableTransition(element, '[data-content]', 'max-height 0.3s ease');
 * });
 * ```
 */
export function enableTransition(
  element: Element,
  selector: string,
  transition: string
): void {
  element.querySelectorAll(selector).forEach(el => {
    (el as HTMLElement).style.transition = transition;
  });
}

// =============================================================================
// Hydration State
// =============================================================================

/**
 * Mark element as hydrated.
 */
export function markHydrated(element: Element): void {
  (element as HTMLElement).dataset.hydrated = 'true';
}

/**
 * Check if element is hydrated.
 */
export function isHydrated(element: Element): boolean {
  return (element as HTMLElement).dataset.hydrated === 'true';
}

// =============================================================================
// Utilities
// =============================================================================

/** Query single element */
export function $(element: Element, selector: string): HTMLElement | null {
  return element.querySelector(selector);
}

/** Query all elements */
export function $$(element: Element, selector: string): HTMLElement[] {
  return Array.from(element.querySelectorAll(selector));
}

/** Find closest ancestor matching selector */
export function closest(element: Element, selector: string): HTMLElement | null {
  return element.closest(selector);
}

/** Get dataset value */
export function data(element: Element, key: string): string | undefined {
  return (element as HTMLElement).dataset[key];
}

/** Combine multiple cleanup functions */
export function combine(...cleanups: CleanupFn[]): CleanupFn {
  return () => cleanups.forEach(fn => fn());
}

// =============================================================================
// Internal
// =============================================================================

function toCamelCase(str: string): string {
  return str.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}
