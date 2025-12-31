/**
 * Accordion component hydration example using @luna_ui/luna-loader/hydration
 *
 * This demonstrates how to use the hydration utilities for an accordion component.
 */
import {
  createHydrator,
  readOpenStates,
  enableMultipleTransitions,
  updateOpenState,
  delegate,
} from '../hydration';

/**
 * Accordion hydration using createHydrator factory
 */
export const hydrate = createHydrator((element) => {
  // Read initial open states from SSR-rendered DOM
  const openItems = readOpenStates(element, 'data-accordion-item');

  // Enable transitions after hydration (prevents initial animation flash)
  enableMultipleTransitions(element, [
    { selector: '[data-accordion-content]', property: 'max-height' },
    { selector: '[data-chevron]', property: 'transform', duration: '0.2s' },
  ]);

  // Toggle handler
  const toggleItem = (itemId: string) => {
    const item = element.querySelector(`[data-accordion-item="${itemId}"]`);
    if (!item) return;

    const isOpen = openItems.has(itemId);

    if (isOpen) {
      openItems.delete(itemId);
    } else {
      openItems.add(itemId);
    }

    updateOpenState(item, !isOpen, {
      contentSelector: '[data-accordion-content]',
      chevronSelector: '[data-chevron]',
    });
  };

  // Event delegation for triggers
  delegate(element, 'click', '[data-accordion-trigger]', (_event, trigger) => {
    const item = trigger.closest('[data-accordion-item]');
    if (item) {
      const itemId = (item as HTMLElement).dataset.accordionItem;
      if (itemId) toggleItem(itemId);
    }
  });
});

export default hydrate;
