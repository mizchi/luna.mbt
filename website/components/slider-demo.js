// Slider Demo - Draggable range slider
// SSR-compatible: adopts existing DOM, adds drag handlers
// Uses CSS custom property --slider-percent for dynamic positioning
//
// SSR HTML Convention:
//   <slider-demo luna:trigger="visible">
//     <div data-slider data-value="50" data-min="0" data-max="100" aria-valuenow="50">
//       <div data-slider-track>
//         <div data-slider-range></div>
//       </div>
//       <div data-slider-thumb tabindex="0"></div>
//     </div>
//     <span data-slider-value>50</span>
//   </slider-demo>
//
// Required CSS:
//   [data-slider-range] { width: calc(var(--slider-percent, 50) * 1%); }
//   [data-slider-thumb] { left: calc(var(--slider-percent, 50) * 1%); }

import { createHydrator, drag } from '../../../js/luna/src/hydration/index.ts';

export const hydrate = createHydrator((el) => {
  // Get slider config from data attributes
  const slider = el.querySelector('[data-slider]');
  if (!slider) return;

  const min = parseInt(slider.dataset.min || '0', 10);
  const max = parseInt(slider.dataset.max || '100', 10);
  const step = parseInt(slider.dataset.step || '1', 10);

  return drag(el, '[data-slider]', {
    track: '[data-slider-track]',
    display: '[data-slider-value]',
    min,
    max,
    step,
  });
});

export default hydrate;
