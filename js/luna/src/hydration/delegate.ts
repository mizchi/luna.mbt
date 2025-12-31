/**
 * onDelegate - Event delegation helper
 *
 * Attach event handlers using event delegation pattern.
 * Efficient for multiple similar elements.
 */

/**
 * Set up delegated event handling
 *
 * @example
 * ```ts
 * onDelegate(el, 'click', '[data-dialog-trigger]', () => {
 *   dialog.dataset.state = 'open';
 * });
 *
 * onDelegate(el, 'click', '[data-dialog-close]', (e, target) => {
 *   dialog.dataset.state = 'closed';
 * });
 * ```
 */
export function onDelegate<K extends keyof HTMLElementEventMap>(
  root: Element,
  event: K,
  selector: string,
  handler: (event: HTMLElementEventMap[K], target: Element) => void
): () => void {
  const delegateHandler = (e: Event) => {
    const target = (e.target as Element)?.closest(selector);
    if (target && root.contains(target)) {
      handler(e as HTMLElementEventMap[K], target);
    }
  };

  root.addEventListener(event, delegateHandler);

  // Return cleanup function
  return () => {
    root.removeEventListener(event, delegateHandler);
  };
}

/**
 * Attach click handler to multiple elements matching selector
 *
 * @example
 * ```ts
 * onClick(el, '[data-tab-trigger]', (target) => {
 *   const tabId = target.dataset.tabId;
 *   // activate tab...
 * });
 * ```
 */
export function onClick(
  root: Element,
  selector: string,
  handler: (target: Element, event: MouseEvent) => void
): () => void {
  return onDelegate(root, 'click', selector, (e, target) => {
    handler(target, e);
  });
}
