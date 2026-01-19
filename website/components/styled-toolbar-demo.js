// Styled Toolbar Demo - APG Toolbar Pattern
// Button toolbar with keyboard navigation

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const items = el.querySelectorAll('.toolbar__item:not([data-disabled])');

  const toggleItem = (item) => {
    const isPressed = item.getAttribute('aria-pressed') === 'true';
    item.setAttribute('aria-pressed', isPressed ? 'false' : 'true');
    if (isPressed) {
      item.removeAttribute('data-pressed');
    } else {
      item.setAttribute('data-pressed', '');
    }
  };

  items.forEach((item, index) => {
    item.addEventListener('click', () => toggleItem(item));

    item.addEventListener('keydown', (e) => {
      const itemList = Array.from(items);
      const currentIndex = itemList.indexOf(item);
      let newIndex = currentIndex;

      switch (e.key) {
        case 'ArrowLeft':
          e.preventDefault();
          newIndex = Math.max(0, currentIndex - 1);
          break;
        case 'ArrowRight':
          e.preventDefault();
          newIndex = Math.min(itemList.length - 1, currentIndex + 1);
          break;
        case 'Home':
          e.preventDefault();
          newIndex = 0;
          break;
        case 'End':
          e.preventDefault();
          newIndex = itemList.length - 1;
          break;
        default:
          return;
      }

      itemList[newIndex].focus();
    });
  });

  return () => {
    items.forEach(item => {
      item.replaceWith(item.cloneNode(true));
    });
  };
});

export default hydrate;
