// Styled Radio Demo - APG Radio Group Pattern
// Handles radio selection with keyboard navigation

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const radios = el.querySelectorAll('.radio:not([data-disabled])');

  const selectRadio = (index) => {
    radios.forEach((radio, i) => {
      const isSelected = i === index;
      if (isSelected) {
        radio.setAttribute('data-selected', '');
        radio.setAttribute('aria-checked', 'true');
        radio.setAttribute('tabindex', '0');
      } else {
        radio.setAttribute('data-selected', 'false');
        radio.setAttribute('aria-checked', 'false');
        radio.setAttribute('tabindex', '-1');
      }
    });
  };

  radios.forEach((radio, index) => {
    radio.addEventListener('click', () => {
      selectRadio(index);
      radio.focus();
    });

    radio.addEventListener('keydown', (e) => {
      const radioList = Array.from(radios);
      const currentIndex = radioList.indexOf(radio);
      let newIndex = currentIndex;

      switch (e.key) {
        case 'ArrowDown':
        case 'ArrowRight':
          e.preventDefault();
          newIndex = currentIndex === radioList.length - 1 ? 0 : currentIndex + 1;
          break;
        case 'ArrowUp':
        case 'ArrowLeft':
          e.preventDefault();
          newIndex = currentIndex === 0 ? radioList.length - 1 : currentIndex - 1;
          break;
        case 'Home':
          e.preventDefault();
          newIndex = 0;
          break;
        case 'End':
          e.preventDefault();
          newIndex = radioList.length - 1;
          break;
        case ' ':
          e.preventDefault();
          selectRadio(currentIndex);
          return;
        default:
          return;
      }

      selectRadio(newIndex);
      radioList[newIndex].focus();
    });
  });

  return () => {
    radios.forEach(radio => {
      radio.replaceWith(radio.cloneNode(true));
    });
  };
});

export default hydrate;
