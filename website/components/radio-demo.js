// Radio Demo - Radio button group
// SSR-compatible: adopts existing DOM, adds event handlers
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

export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  // Update indicator visibility based on checked state
  const updateIndicators = (name) => {
    element.querySelectorAll(`input[name="${name}"]`).forEach(input => {
      const indicator = input.parentElement?.querySelector('[data-radio-indicator]');
      if (indicator) {
        indicator.style.display = input.checked ? 'block' : 'none';
      }
    });
  };

  // Attach handlers
  element.querySelectorAll('input[type="radio"]').forEach(input => {
    if (!input.disabled) {
      input.onchange = () => updateIndicators(input.name);
    }
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
