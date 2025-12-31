// Checkbox Demo - Interactive checkboxes
// SSR-compatible: adopts existing DOM, adds event handlers
//
// SSR HTML Convention:
//   <checkbox-demo luna:trigger="visible">
//     <button data-checkbox data-state="checked|unchecked" aria-checked="true|false">
//       <span data-checkbox-indicator>✓</span>
//     </button>
//   </checkbox-demo>

export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  // Toggle checkbox
  const toggle = (btn) => {
    const checked = btn.dataset.state !== 'checked';
    btn.dataset.state = checked ? 'checked' : 'unchecked';
    btn.setAttribute('aria-checked', checked);

    btn.style.background = checked ? 'var(--primary-color, #6366f1)' : 'transparent';
    btn.style.borderColor = checked ? 'var(--primary-color, #6366f1)' : 'var(--border-color, #4b5563)';

    const indicator = btn.querySelector('[data-checkbox-indicator]');
    if (indicator) indicator.style.display = checked ? 'flex' : 'none';
  };

  // Attach handlers (skip disabled)
  element.querySelectorAll('[data-checkbox]:not([data-disabled])').forEach(btn => {
    btn.onclick = () => toggle(btn);
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
