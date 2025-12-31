// Accordion Demo - Expandable sections
// SSR-compatible: adopts existing DOM, adds event handlers only
export function hydrate(element, state, name) {
  // Track open items based on SSR state
  const openItems = new Set();
  element.querySelectorAll('[data-accordion-item][data-state="open"]').forEach(item => {
    openItems.add(item.dataset.accordionItem);
  });

  // Toggle item state
  const toggleItem = (itemId) => {
    const item = element.querySelector(`[data-accordion-item="${itemId}"]`);
    if (!item) return;

    const isOpen = openItems.has(itemId);
    const content = item.querySelector('[data-accordion-content]');
    const chevron = item.querySelector('[data-chevron]');

    if (isOpen) {
      openItems.delete(itemId);
      item.dataset.state = 'closed';
      if (content) content.style.maxHeight = '0';
      if (chevron) chevron.style.transform = 'rotate(0deg)';
    } else {
      openItems.add(itemId);
      item.dataset.state = 'open';
      if (content) content.style.maxHeight = '200px';
      if (chevron) chevron.style.transform = 'rotate(180deg)';
    }
  };

  // Attach event handlers to existing triggers (SSR-rendered)
  element.querySelectorAll('[data-accordion-trigger]').forEach(trigger => {
    const item = trigger.closest('[data-accordion-item]');
    if (item) {
      trigger.onclick = () => toggleItem(item.dataset.accordionItem);
    }
  });

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
