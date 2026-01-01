// Switch Demo - Toggle switches
// SSR-compatible: adopts existing DOM, adds event handlers
// CSS handles visual changes via [aria-checked] selector
//
// SSR HTML Convention:
//   <switch-demo luna:trigger="visible">
//     <button data-switch-toggle aria-checked="true|false">
//       <span data-switch-thumb></span>
//     </button>
//   </switch-demo>
//
// Required CSS:
//   [data-switch-toggle][aria-checked="true"] { background: var(--primary); }
//   [data-switch-toggle][aria-checked="false"] { background: var(--muted); }
//   [aria-checked="true"] [data-switch-thumb] { transform: translateX(20px); }
//   [aria-checked="false"] [data-switch-thumb] { transform: translateX(0); }

import { createHydrator, toggle } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  return toggle(el, '[data-switch-toggle]', {
    attribute: 'aria-checked',
    states: ['true', 'false']
  });
});

export default hydrate;
