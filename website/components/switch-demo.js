// Switch Demo - Toggle switches
// SSR-compatible: adopts existing DOM, adds event handlers
//
// SSR HTML Convention:
//   <switch-demo luna:trigger="visible">
//     <button data-switch-toggle aria-checked="true/false">
//       <span data-switch-thumb></span>
//     </button>
//   </switch-demo>

export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  // Toggle switch state
  const toggle = (btn) => {
    const checked = btn.getAttribute('aria-checked') !== 'true';
    btn.setAttribute('aria-checked', checked);
    btn.style.background = checked ? 'var(--primary-color, #6366f1)' : '#4b5563';

    const thumb = btn.querySelector('[data-switch-thumb]');
    if (thumb) thumb.style.left = checked ? '22px' : '2px';
  };

  // Attach handlers
  element.querySelectorAll('[data-switch-toggle]').forEach(btn => {
    btn.onclick = () => toggle(btn);
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
