// Radio Demo - Radio button group
// SSR-compatible: adopts existing DOM
// CSS handles visual changes via :checked pseudo-class
//
// SSR HTML Convention:
//   <radio-demo luna:trigger="visible">
//     <div role="radiogroup">
//       <label>
//         <input type="radio" name="group" value="opt1" checked>
//         <span data-radio-indicator></span>
//         Option 1
//       </label>
//     </div>
//   </radio-demo>
//
// Required CSS:
//   input[type="radio"]:checked + [data-radio-indicator] { display: block; }
//   input[type="radio"]:not(:checked) + [data-radio-indicator] { display: none; }

export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;
  // Native radio buttons handle state automatically
  // CSS handles indicator visibility via :checked pseudo-class
  element.dataset.hydrated = 'true';
}

export default hydrate;
