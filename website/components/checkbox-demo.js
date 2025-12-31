// Checkbox Demo - Interactive checkboxes
// SSR-compatible: adopts existing DOM, adds event handlers only
export function hydrate(element, state, name) {
  // Toggle checkbox state
  const toggleCheckbox = (btn) => {
    const currentState = btn.dataset.state;
    const indicator = btn.querySelector('[data-checkbox-indicator]');

    let newState;
    if (currentState === 'checked') {
      newState = 'unchecked';
    } else if (currentState === 'unchecked') {
      newState = 'checked';
    } else {
      // indeterminate -> checked
      newState = 'checked';
    }

    btn.dataset.state = newState;
    btn.setAttribute('aria-checked', newState === 'checked' ? 'true' : newState === 'indeterminate' ? 'mixed' : 'false');

    // Update visual state
    if (newState === 'checked') {
      btn.style.background = 'var(--primary-color, #6366f1)';
      btn.style.borderColor = 'var(--primary-color, #6366f1)';
      if (indicator) indicator.style.display = 'flex';
    } else {
      btn.style.background = 'transparent';
      btn.style.borderColor = 'var(--border-color, #4b5563)';
      if (indicator) indicator.style.display = 'none';
    }
  };

  // Attach event handlers to existing checkboxes (SSR-rendered)
  element.querySelectorAll('[data-checkbox]').forEach(btn => {
    if (!btn.hasAttribute('data-disabled')) {
      btn.onclick = () => toggleCheckbox(btn);
    }
  });

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
