// Switch hydration script
export function hydrate(el, state, id) {
  const toggle = el.querySelector('[data-switch-toggle]');
  if (!toggle) return;

  toggle.addEventListener('click', () => {
    const checked = toggle.getAttribute('aria-checked') === 'true';
    toggle.setAttribute('aria-checked', (!checked).toString());
  });

  console.log(`[luna] Switch hydrated: ${id}`);
}
