// Styled Spinbutton Demo - APG Spinbutton Pattern
// Numeric input with increment/decrement buttons

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const spinbuttons = el.querySelectorAll('.spinbutton:not([data-disabled])');

  spinbuttons.forEach(spinbutton => {
    const input = spinbutton.querySelector('.spinbutton__input');
    const decBtn = spinbutton.querySelector('.spinbutton__decrement');
    const incBtn = spinbutton.querySelector('.spinbutton__increment');

    const min = parseFloat(input.getAttribute('aria-valuemin')) || 0;
    const max = parseFloat(input.getAttribute('aria-valuemax')) || 100;
    const step = 1;
    const largeStep = 10;

    const getValue = () => parseFloat(input.getAttribute('aria-valuenow')) || 0;

    const setValue = (value) => {
      const clamped = Math.max(min, Math.min(max, value));
      input.setAttribute('aria-valuenow', clamped);
      input.textContent = clamped;
    };

    decBtn.addEventListener('click', () => setValue(getValue() - step));
    incBtn.addEventListener('click', () => setValue(getValue() + step));

    input.addEventListener('keydown', (e) => {
      switch (e.key) {
        case 'ArrowUp':
          e.preventDefault();
          setValue(getValue() + step);
          break;
        case 'ArrowDown':
          e.preventDefault();
          setValue(getValue() - step);
          break;
        case 'PageUp':
          e.preventDefault();
          setValue(getValue() + largeStep);
          break;
        case 'PageDown':
          e.preventDefault();
          setValue(getValue() - largeStep);
          break;
        case 'Home':
          e.preventDefault();
          setValue(min);
          break;
        case 'End':
          e.preventDefault();
          setValue(max);
          break;
      }
    });
  });

  return () => {
    spinbuttons.forEach(spinbutton => {
      spinbutton.replaceWith(spinbutton.cloneNode(true));
    });
  };
});

export default hydrate;
