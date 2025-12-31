// Checkbox Demo - Interactive checkboxes
// SSR-compatible: adopts existing DOM, adds event handlers
// CSS handles visual changes via [data-state] and [aria-checked] selectors
//
// SSR HTML Convention:
//   <checkbox-demo luna:trigger="visible">
//     <button data-checkbox data-state="checked|unchecked" aria-checked="true|false">
//       <span data-checkbox-indicator>✓</span>
//     </button>
//   </checkbox-demo>
//
// Required CSS:
//   [data-checkbox][data-state="checked"] { background: var(--primary); border-color: var(--primary); }
//   [data-checkbox][data-state="unchecked"] { background: transparent; border-color: var(--border); }
//   [data-state="checked"] [data-checkbox-indicator] { display: flex; }
//   [data-state="unchecked"] [data-checkbox-indicator] { display: none; }

import { createHydrator, toggle } from '../../../js/luna/src/hydration/index.ts';

export const hydrate = createHydrator((el) => {
  // Toggle data-state and aria-checked together
  return toggle(el, '[data-checkbox]:not([data-disabled])', {
    states: ['checked', 'unchecked'],
    onChange: (state, target) => {
      target.setAttribute('aria-checked', state === 'checked' ? 'true' : 'false');
    }
  });
});

export default hydrate;
