/**
 * @luna_ui/luna-loader/hydration
 *
 * Framework-agnostic SSR + Hydration utilities.
 * Works with any SSR output: Luna (MoonBit), React, Preact, or plain HTML.
 *
 * Design principles:
 * - DOM-first: Adopt existing server-rendered HTML
 * - Convention-based: Use data-* attributes for state
 * - Lightweight: No dependencies, tree-shakeable
 * - Framework-agnostic: Works with any SSR renderer
 */

// =============================================================================
// Types
// =============================================================================

/** Standard hydration function signature */
export type HydrateFn = (element: Element, state: unknown, name: string) => void;

/** Cleanup function for SPA navigation */
export type CleanupFn = () => void;

/** Setup function that may return cleanup */
export type SetupFn<S = unknown> = (
  element: Element,
  state: S,
  name: string
) => void | CleanupFn;

// =============================================================================
// Core: Hydration Factory
// =============================================================================

/**
 * Create a hydration function with automatic hydrated marking and deduplication.
 *
 * @example
 * ```ts
 * export const hydrate = createHydrator((element) => {
 *   element.querySelector('button').onclick = () => alert('clicked');
 * });
 * ```
 */
export function createHydrator<S = unknown>(setup: SetupFn<S>): HydrateFn {
  return (element, state, name) => {
    if (isHydrated(element)) return;
    setup(element, state as S, name);
    markHydrated(element);
  };
}

// =============================================================================
// State Reading: Extract initial state from SSR-rendered DOM
// =============================================================================

/**
 * Read open/closed states from elements with data-state attribute.
 *
 * @example SSR HTML:
 * ```html
 * <div data-accordion-item="item-1" data-state="open">...</div>
 * <div data-accordion-item="item-2" data-state="closed">...</div>
 * ```
 *
 * @example Usage:
 * ```ts
 * const openItems = readOpenStates(element, 'data-accordion-item');
 * // Set { 'item-1' }
 * ```
 */
export function readOpenStates(element: Element, itemAttr: string): Set<string> {
  const openItems = new Set<string>();
  const attrName = itemAttr.replace('data-', '');
  element.querySelectorAll(`[${itemAttr}][data-state="open"]`).forEach(item => {
    const id = (item as HTMLElement).dataset[toCamelCase(attrName)];
    if (id) openItems.add(id);
  });
  return openItems;
}

/**
 * Read checked states from elements with aria-checked attribute.
 *
 * @example SSR HTML:
 * ```html
 * <button data-switch="notifications" aria-checked="true">...</button>
 * <button data-switch="darkMode" aria-checked="false">...</button>
 * ```
 */
export function readCheckedStates(element: Element, itemAttr: string): Map<string, boolean> {
  const states = new Map<string, boolean>();
  const attrName = itemAttr.replace('data-', '');
  element.querySelectorAll(`[${itemAttr}]`).forEach(el => {
    const id = (el as HTMLElement).dataset[toCamelCase(attrName)];
    const checked = el.getAttribute('aria-checked') === 'true';
    if (id) states.set(id, checked);
  });
  return states;
}

/**
 * Read numeric value from element attribute.
 */
export function readNumericValue(
  element: Element,
  attr = 'data-value',
  defaultValue = 0
): number {
  const value = element.getAttribute(attr);
  return value ? parseInt(value, 10) : defaultValue;
}

// =============================================================================
// Transitions: Enable CSS transitions after hydration
// =============================================================================

/**
 * Enable CSS transition on elements after next frame.
 * Prevents initial animation flash when hydrating SSR content.
 *
 * @example
 * ```ts
 * enableTransitions(element, '[data-content]', 'max-height', '0.3s');
 * ```
 */
export function enableTransitions(
  element: Element,
  selector: string,
  property: string,
  duration = '0.3s',
  easing = 'ease'
): void {
  requestAnimationFrame(() => {
    element.querySelectorAll(selector).forEach(el => {
      (el as HTMLElement).style.transition = `${property} ${duration} ${easing}`;
    });
  });
}

/**
 * Enable multiple transitions at once.
 *
 * @example
 * ```ts
 * enableMultipleTransitions(element, [
 *   { selector: '[data-content]', property: 'max-height' },
 *   { selector: '[data-chevron]', property: 'transform', duration: '0.2s' },
 * ]);
 * ```
 */
export function enableMultipleTransitions(
  element: Element,
  configs: Array<{
    selector: string;
    property: string;
    duration?: string;
    easing?: string;
  }>
): void {
  requestAnimationFrame(() => {
    configs.forEach(({ selector, property, duration = '0.3s', easing = 'ease' }) => {
      element.querySelectorAll(selector).forEach(el => {
        (el as HTMLElement).style.transition = `${property} ${duration} ${easing}`;
      });
    });
  });
}

// =============================================================================
// Event Handling: Delegate and attach handlers
// =============================================================================

/**
 * Event delegation helper.
 * Attach handler to parent, delegate to matching children.
 *
 * @returns Cleanup function to remove listener
 *
 * @example
 * ```ts
 * const cleanup = delegate(element, 'click', '[data-trigger]', (e, target) => {
 *   console.log('Clicked:', target.dataset.action);
 * });
 * ```
 */
export function delegate<E extends Event = Event>(
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
 * Attach click handlers directly to elements.
 *
 * @example
 * ```ts
 * attachTriggers(element, '[data-button]', (trigger, data) => {
 *   console.log('Button:', data.action);
 * });
 * ```
 */
export function attachTriggers(
  element: Element,
  triggerSelector: string,
  handler: (trigger: Element, data: DOMStringMap) => void
): void {
  element.querySelectorAll(triggerSelector).forEach(trigger => {
    (trigger as HTMLElement).onclick = () => {
      handler(trigger, (trigger as HTMLElement).dataset);
    };
  });
}

// =============================================================================
// State Updates: Visual state manipulation
// =============================================================================

/**
 * Update open/close state for accordion-like components.
 *
 * @example
 * ```ts
 * updateOpenState(item, isOpen, {
 *   contentSelector: '[data-content]',
 *   chevronSelector: '[data-chevron]',
 *   openHeight: '200px',
 * });
 * ```
 */
export function updateOpenState(
  item: Element,
  isOpen: boolean,
  options: {
    contentSelector?: string;
    chevronSelector?: string;
    openHeight?: string;
  } = {}
): void {
  const { contentSelector, chevronSelector, openHeight = '200px' } = options;

  (item as HTMLElement).dataset.state = isOpen ? 'open' : 'closed';

  if (contentSelector) {
    const content = item.querySelector(contentSelector) as HTMLElement;
    if (content) {
      content.style.maxHeight = isOpen ? openHeight : '0';
    }
  }

  if (chevronSelector) {
    const chevron = item.querySelector(chevronSelector) as HTMLElement;
    if (chevron) {
      chevron.style.transform = isOpen ? 'rotate(180deg)' : 'rotate(0deg)';
    }
  }
}

/**
 * Update checked state for switch/checkbox components.
 *
 * @example
 * ```ts
 * updateCheckedState(button, checked, {
 *   thumbSelector: '[data-thumb]',
 *   checkedBackground: 'var(--primary-color)',
 * });
 * ```
 */
export function updateCheckedState(
  element: Element,
  checked: boolean,
  options: {
    thumbSelector?: string;
    checkedBackground?: string;
    uncheckedBackground?: string;
    thumbOnPosition?: string;
    thumbOffPosition?: string;
  } = {}
): void {
  const {
    thumbSelector,
    checkedBackground = 'var(--primary-color, #6366f1)',
    uncheckedBackground = '#4b5563',
    thumbOnPosition = '22px',
    thumbOffPosition = '2px',
  } = options;

  element.setAttribute('aria-checked', String(checked));
  (element as HTMLElement).style.background = checked ? checkedBackground : uncheckedBackground;

  if (thumbSelector) {
    const thumb = element.querySelector(thumbSelector) as HTMLElement;
    if (thumb) {
      thumb.style.left = checked ? thumbOnPosition : thumbOffPosition;
    }
  }
}

/**
 * Update slider/progress value.
 */
export function updateSliderValue(
  element: Element,
  value: number,
  options: {
    min?: number;
    max?: number;
    rangeSelector?: string;
    thumbSelector?: string;
    valueDisplaySelector?: string;
  } = {}
): void {
  const {
    min = 0,
    max = 100,
    rangeSelector,
    thumbSelector,
    valueDisplaySelector,
  } = options;

  const percentage = ((value - min) / (max - min)) * 100;

  element.setAttribute('aria-valuenow', String(value));
  (element as HTMLElement).dataset.value = String(value);

  if (rangeSelector) {
    const range = element.querySelector(rangeSelector) as HTMLElement;
    if (range) range.style.width = `${percentage}%`;
  }

  if (thumbSelector) {
    const thumb = element.querySelector(thumbSelector) as HTMLElement;
    if (thumb) thumb.style.left = `${percentage}%`;
  }

  if (valueDisplaySelector) {
    const display = element.querySelector(valueDisplaySelector);
    if (display) display.textContent = String(value);
  }
}

// =============================================================================
// Hydration State Management
// =============================================================================

/**
 * Mark element as hydrated to prevent double hydration.
 */
export function markHydrated(element: Element): void {
  (element as HTMLElement).dataset.hydrated = 'true';
}

/**
 * Check if element is already hydrated.
 */
export function isHydrated(element: Element): boolean {
  return (element as HTMLElement).dataset.hydrated === 'true';
}

// =============================================================================
// Dialog/Modal Helpers
// =============================================================================

/**
 * Open a dialog element.
 */
export function openDialog(
  dialog: Element,
  overlay?: Element | null,
  content?: Element | null
): void {
  (dialog as HTMLElement).dataset.state = 'open';
  if (overlay) (overlay as HTMLElement).style.display = 'block';
  if (content) (content as HTMLElement).style.display = 'block';
  document.body.style.overflow = 'hidden';
}

/**
 * Close a dialog element.
 */
export function closeDialog(
  dialog: Element,
  overlay?: Element | null,
  content?: Element | null
): void {
  (dialog as HTMLElement).dataset.state = 'closed';
  if (overlay) (overlay as HTMLElement).style.display = 'none';
  if (content) (content as HTMLElement).style.display = 'none';
  document.body.style.overflow = '';
}

/**
 * Setup escape key handler for dialog.
 *
 * @returns Cleanup function
 */
export function setupEscapeHandler(
  dialog: Element,
  onClose: () => void
): CleanupFn {
  const handler = (e: KeyboardEvent) => {
    if (e.key === 'Escape' && (dialog as HTMLElement).dataset.state === 'open') {
      onClose();
    }
  };
  document.addEventListener('keydown', handler);
  return () => document.removeEventListener('keydown', handler);
}

// =============================================================================
// Utilities
// =============================================================================

/** Convert kebab-case to camelCase */
function toCamelCase(str: string): string {
  return str.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

/**
 * Query element with type safety.
 */
export function $(element: Element, selector: string): HTMLElement | null {
  return element.querySelector(selector);
}

/**
 * Query all elements with type safety.
 */
export function $$(element: Element, selector: string): HTMLElement[] {
  return Array.from(element.querySelectorAll(selector));
}
