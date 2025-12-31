// Accordion Demo - Expandable sections
// SSR-compatible: adopts existing DOM, adds event handlers
// CSS handles visual changes via [data-state] selector
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
//
// Required CSS:
//   [data-state="open"] [data-accordion-content] { max-height: 200px; }
//   [data-state="closed"] [data-accordion-content] { max-height: 0; }
//   [data-state="open"] [data-chevron] { transform: rotate(180deg); }
//   [data-state="closed"] [data-chevron] { transform: rotate(0deg); }
//   [data-accordion-content] { transition: max-height 0.3s ease; }
//   [data-chevron] { transition: transform 0.2s ease; }

import { createHydrator, toggle } from '../../../js/luna/src/hydration/index.ts';

export const hydrate = createHydrator((el) => {
  return toggle(el, '[data-accordion-trigger]', {
    target: '[data-accordion-item]',
    states: ['open', 'closed']
  });
});

export default hydrate;
