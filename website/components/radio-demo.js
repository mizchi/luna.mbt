// Radio Demo - Radio button group
// SSR-compatible: adopts existing DOM, adds event handlers only
export function hydrate(element, state, name) {
  // Handle radio selection
  const selectRadio = (input) => {
    const groupName = input.name;

    // Update all radios in the same group
    element.querySelectorAll(`input[name="${groupName}"]`).forEach(radio => {
      const indicator = radio.parentElement.querySelector('[data-radio-indicator]');
      if (radio === input) {
        radio.checked = true;
        if (indicator) indicator.style.display = 'block';
      } else {
        radio.checked = false;
        if (indicator) indicator.style.display = 'none';
      }
    });
  };

  // Attach event handlers to existing radios (SSR-rendered)
  element.querySelectorAll('input[type="radio"]').forEach(input => {
    if (!input.disabled) {
      input.onchange = () => selectRadio(input);
    }
  });

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
