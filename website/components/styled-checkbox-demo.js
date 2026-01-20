// Styled Checkbox Demo - APG Checkbox Pattern
// Toggles data-checked and aria-checked on click
//
// SSR HTML:
//   <styled-checkbox-demo luna:trigger="visible">
//     <div class="checkbox" data-checked="false">
//       <input type="checkbox" class="checkbox__input" aria-checked="false">
//       <span class="checkbox__control">...</span>
//       <span class="checkbox__label">Label</span>
//     </div>
//   </styled-checkbox-demo>

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const checkboxes = el.querySelectorAll('.checkbox:not([data-disabled])');

  const toggle = (wrapper) => {
    const isChecked = wrapper.getAttribute('data-checked') === 'true';
    const newChecked = !isChecked;

    // Clear indeterminate on toggle
    wrapper.removeAttribute('data-indeterminate');

    wrapper.setAttribute('data-checked', newChecked ? 'true' : 'false');

    const input = wrapper.querySelector('.checkbox__input');
    if (input) {
      input.checked = newChecked;
      input.setAttribute('aria-checked', newChecked ? 'true' : 'false');
      input.indeterminate = false;
    }
  };

  checkboxes.forEach(wrapper => {
    wrapper.addEventListener('click', (e) => {
      e.preventDefault();
      toggle(wrapper);
    });

    const input = wrapper.querySelector('.checkbox__input');
    if (input) {
      input.addEventListener('keydown', (e) => {
        if (e.key === ' ') {
          e.preventDefault();
          toggle(wrapper);
        }
      });
    }
  });

  return () => {
    checkboxes.forEach(wrapper => {
      wrapper.replaceWith(wrapper.cloneNode(true));
    });
  };
});

export default hydrate;
