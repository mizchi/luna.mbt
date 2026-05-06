// Styled Switch Demo - APG Switch Pattern
// Toggles data-state and aria-checked on click
//
// SSR HTML:
//   <styled-switch-demo luna:trigger="visible">
//     <button class="switch" role="switch" aria-checked="false" data-state="off">
//       <span class="switch__track"><span class="switch__thumb"></span></span>
//       <span class="switch__label">Label</span>
//     </button>
//   </styled-switch-demo>

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const switches = el.querySelectorAll('.switch:not([data-disabled])');

  const toggle = (btn) => {
    const isOn = btn.getAttribute('data-state') === 'on';
    const newState = isOn ? 'off' : 'on';
    btn.setAttribute('data-state', newState);
    btn.setAttribute('aria-checked', newState === 'on' ? 'true' : 'false');
  };

  switches.forEach(btn => {
    btn.addEventListener('click', () => toggle(btn));
    btn.addEventListener('keydown', (e) => {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        toggle(btn);
      }
    });
  });

  return () => {
    switches.forEach(btn => {
      btn.replaceWith(btn.cloneNode(true));
    });
  };
});

export default hydrate;
