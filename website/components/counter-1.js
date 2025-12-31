// my-counter Web Component
// SSR-compatible: adopts existing DOM, adds event handlers only

export function hydrate(element, _state, name) {
  // Get initial count from SSR state or attribute
  const valueEl = element.querySelector('[data-counter-value]');
  let count = parseInt(valueEl?.textContent || element.getAttribute('initial') || '0', 10);

  // Update display
  const updateValue = () => {
    if (valueEl) {
      valueEl.textContent = count;
    }
  };

  // Attach event handlers to existing buttons (SSR-rendered)
  const decBtn = element.querySelector('[data-counter-dec]');
  const incBtn = element.querySelector('[data-counter-inc]');

  if (decBtn) {
    decBtn.onmouseover = () => decBtn.style.opacity = '0.8';
    decBtn.onmouseout = () => decBtn.style.opacity = '1';
    decBtn.onclick = () => { count--; updateValue(); };
  }

  if (incBtn) {
    incBtn.onmouseover = () => incBtn.style.opacity = '0.8';
    incBtn.onmouseout = () => incBtn.style.opacity = '1';
    incBtn.onclick = () => { count++; updateValue(); };
  }

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
