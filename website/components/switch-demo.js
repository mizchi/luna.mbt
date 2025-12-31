// Switch Demo - Toggle switches with labels
// SSR-compatible: adopts existing DOM, adds event handlers only
export function hydrate(element, state, name) {
  // Toggle switch state
  const toggleSwitch = (btn) => {
    const isChecked = btn.getAttribute('aria-checked') === 'true';
    const newChecked = !isChecked;
    const thumb = btn.querySelector('[data-switch-thumb]');

    btn.setAttribute('aria-checked', newChecked);
    btn.style.background = newChecked ? 'var(--primary-color, #6366f1)' : '#4b5563';
    if (thumb) {
      thumb.style.left = newChecked ? '22px' : '2px';
    }
  };

  // Attach event handlers to existing switches (SSR-rendered)
  element.querySelectorAll('[data-switch-toggle]').forEach(btn => {
    btn.onclick = () => toggleSwitch(btn);
  });

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
