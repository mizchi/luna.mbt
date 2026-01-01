// Accordion hydration script
export function hydrate(el, state, id) {
  const items = el.querySelectorAll('[data-accordion-item]');

  items.forEach(item => {
    const trigger = item.querySelector('[data-accordion-trigger]');
    if (!trigger) return;

    trigger.addEventListener('click', () => {
      const currentState = item.getAttribute('data-state');
      const newState = currentState === 'open' ? 'closed' : 'open';
      item.setAttribute('data-state', newState);
    });
  });

  console.log(`[luna] Accordion hydrated: ${id}`);
}
