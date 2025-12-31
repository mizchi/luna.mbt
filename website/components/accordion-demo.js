// Accordion Demo - Expandable sections
// SSR-compatible: adopts existing DOM, adds event handlers
//
// SSR HTML Convention:
//   <accordion-demo luna:trigger="visible">
//     <div data-accordion-item="id" data-state="open|closed">
//       <button data-accordion-trigger>
//         Title <span data-chevron>▼</span>
//       </button>
//       <div data-accordion-content>Content</div>
//     </div>
//   </accordion-demo>

export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  // Read initial open states from SSR
  const openItems = new Set();
  element.querySelectorAll('[data-accordion-item][data-state="open"]').forEach(item => {
    openItems.add(item.dataset.accordionItem);
  });

  // Enable transitions after hydration (prevent initial flash)
  requestAnimationFrame(() => {
    element.querySelectorAll('[data-accordion-content]').forEach(el => {
      el.style.transition = 'max-height 0.3s ease';
    });
    element.querySelectorAll('[data-chevron]').forEach(el => {
      el.style.transition = 'transform 0.2s ease';
    });
  });

  // Toggle handler
  const toggle = (itemId) => {
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

  // Attach handlers via event delegation
  element.querySelectorAll('[data-accordion-trigger]').forEach(trigger => {
    const item = trigger.closest('[data-accordion-item]');
    if (item) {
      trigger.onclick = () => toggle(item.dataset.accordionItem);
    }
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
