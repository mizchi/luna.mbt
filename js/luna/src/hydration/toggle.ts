/**
 * toggle - Binary state toggle helper
 *
 * Toggles between two states on click, using data-* or aria-* attributes.
 * CSS handles visual changes via attribute selectors.
 */

export interface ToggleOptions {
  /**
   * Selector for the element to toggle state on.
   * If not provided, the trigger element itself is used.
   * Use closest() to find ancestor.
   */
  target?: string;

  /**
   * The two states to toggle between.
   * @default ['open', 'closed'] for data-state
   * @default ['true', 'false'] for aria-checked
   */
  states?: [string, string];

  /**
   * Attribute to update.
   * @default 'data-state'
   */
  attribute?: string;

  /**
   * Callback when state changes.
   */
  onChange?: (state: string, element: Element) => void;
}

/**
 * Set up click-to-toggle behavior on matching elements
 *
 * @example
 * ```ts
 * // Toggle data-state on parent [data-accordion-item]
 * toggle(el, '[data-accordion-trigger]', {
 *   target: '[data-accordion-item]',
 *   states: ['open', 'closed']
 * });
 *
 * // Toggle aria-checked on the button itself
 * toggle(el, '[data-switch-toggle]', {
 *   attribute: 'aria-checked',
 *   states: ['true', 'false']
 * });
 * ```
 */
export function toggle(
  root: Element,
  selector: string,
  options: ToggleOptions = {}
): () => void {
  const {
    target,
    attribute = 'data-state',
    states = attribute === 'aria-checked' ? ['true', 'false'] : ['open', 'closed'],
    onChange,
  } = options;

  const [stateA, stateB] = states;
  const handlers: Array<{ el: Element; handler: EventListener }> = [];

  root.querySelectorAll(selector).forEach((trigger) => {
    const handler = () => {
      // Find target element
      const targetEl = target
        ? trigger.closest(target)
        : trigger;

      if (!targetEl) return;

      // Get current state and toggle
      const current = targetEl.getAttribute(attribute);
      const next = current === stateA ? stateB : stateA;

      targetEl.setAttribute(attribute, next);

      // Also update aria-checked if toggling data-state on a button
      if (attribute === 'data-state' && targetEl.tagName === 'BUTTON') {
        targetEl.setAttribute('aria-checked', next === stateA ? 'true' : 'false');
      }

      onChange?.(next, targetEl);
    };

    trigger.addEventListener('click', handler);
    handlers.push({ el: trigger, handler });
  });

  // Return cleanup function
  return () => {
    handlers.forEach(({ el, handler }) => {
      el.removeEventListener('click', handler);
    });
  };
}
