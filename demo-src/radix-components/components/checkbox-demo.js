// Checkbox hydration script
export function hydrate(el, state, id) {
  const checkbox = el.querySelector('[data-checkbox]');
  if (!checkbox) return;

  checkbox.addEventListener('click', () => {
    const checked = checkbox.getAttribute('aria-checked') === 'true';
    const newChecked = !checked;
    checkbox.setAttribute('aria-checked', newChecked.toString());
    checkbox.setAttribute('data-state', newChecked ? 'checked' : 'unchecked');
  });

  console.log(`[luna] Checkbox hydrated: ${id}`);
}
