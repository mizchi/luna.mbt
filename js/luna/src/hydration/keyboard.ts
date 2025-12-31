/**
 * keyboard - Keyboard event handler helper
 *
 * Map keyboard keys to handler functions.
 */

export type KeyboardHandlers = {
  [key: string]: (event: KeyboardEvent) => void;
};

/**
 * Set up keyboard handlers on an element or document
 *
 * @example
 * ```ts
 * // Handle Escape on document
 * keyboard(document, {
 *   Escape: () => close()
 * });
 *
 * // Handle arrow keys on a specific element
 * keyboard(slider, {
 *   ArrowUp: () => increment(),
 *   ArrowDown: () => decrement(),
 *   ArrowLeft: () => decrement(),
 *   ArrowRight: () => increment()
 * });
 * ```
 */
export function keyboard(
  target: Element | Document | null,
  handlers: KeyboardHandlers
): () => void {
  if (!target) return () => {};

  const handler = (e: Event) => {
    const key = (e as KeyboardEvent).key;
    const fn = handlers[key];
    if (fn) {
      fn(e as KeyboardEvent);
    }
  };

  target.addEventListener('keydown', handler);

  // Return cleanup function
  return () => {
    target.removeEventListener('keydown', handler);
  };
}

/**
 * Handle Escape key to close something
 *
 * @example
 * ```ts
 * onEscape(() => {
 *   dialog.dataset.state = 'closed';
 * });
 * ```
 */
export function onEscape(handler: () => void): () => void {
  return keyboard(document, { Escape: handler });
}
