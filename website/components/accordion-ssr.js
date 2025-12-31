// Accordion SSR Demo - Progressive Enhancement
// This component adopts existing SSR HTML and adds interactivity
// The DOM structure is already rendered server-side, we just attach event handlers

export function hydrate(element, state, name) {
  // Read initial state from SSR data attributes or state prop
  const openItems = new Set(state?.open || ['item-1']);

  // Find all accordion items (already rendered by SSR)
  const items = element.querySelectorAll('[data-accordion-item]');

  // Attach event handlers to existing DOM - no innerHTML replacement!
  function attachHandlers() {
    items.forEach(item => {
      const trigger = item.querySelector('[data-accordion-trigger]');
      const content = item.querySelector('[data-accordion-content]');
      const itemId = item.dataset.accordionItem;

      if (!trigger || !content) return;

      // Update visual state based on current openItems
      const isOpen = openItems.has(itemId);
      item.dataset.state = isOpen ? 'open' : 'closed';
      content.style.maxHeight = isOpen ? content.scrollHeight + 'px' : '0';
      content.style.overflow = 'hidden';
      content.style.transition = 'max-height 0.3s ease';

      // Find arrow and rotate
      const arrow = trigger.querySelector('[data-arrow]');
      if (arrow) {
        arrow.style.transform = `rotate(${isOpen ? '180deg' : '0deg'})`;
        arrow.style.transition = 'transform 0.2s';
      }

      // Attach click handler
      trigger.onclick = () => {
        if (openItems.has(itemId)) {
          openItems.delete(itemId);
        } else {
          openItems.add(itemId);
        }

        // Update this item's state
        const nowOpen = openItems.has(itemId);
        item.dataset.state = nowOpen ? 'open' : 'closed';
        content.style.maxHeight = nowOpen ? content.scrollHeight + 'px' : '0';
        if (arrow) {
          arrow.style.transform = `rotate(${nowOpen ? '180deg' : '0deg'})`;
        }
      };
    });
  }

  attachHandlers();

  // Mark as hydrated for debugging
  element.dataset.hydrated = 'true';
}

export default hydrate;
