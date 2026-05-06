// Styled Accordion Demo - APG Accordion Pattern
// Toggles panel expansion on header click

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const items = el.querySelectorAll('.accordion__item');
  const headers = el.querySelectorAll('.accordion__header');

  const expandItem = (index) => {
    items.forEach((item, i) => {
      const header = item.querySelector('.accordion__header');
      const panel = item.querySelector('.accordion__panel');
      const isOpen = i === index;

      item.setAttribute('data-state', isOpen ? 'open' : 'closed');
      header.setAttribute('data-state', isOpen ? 'open' : 'closed');
      header.setAttribute('aria-expanded', isOpen ? 'true' : 'false');
      panel.setAttribute('data-state', isOpen ? 'open' : 'closed');

      if (isOpen) {
        panel.removeAttribute('hidden');
      } else {
        panel.setAttribute('hidden', '');
      }
    });
  };

  headers.forEach((header, index) => {
    header.addEventListener('click', () => {
      const item = header.closest('.accordion__item');
      const isOpen = item.getAttribute('data-state') === 'open';
      expandItem(isOpen ? -1 : index);
    });

    header.addEventListener('keydown', (e) => {
      const headerList = Array.from(headers);
      const currentIndex = headerList.indexOf(header);

      switch (e.key) {
        case 'ArrowDown':
          e.preventDefault();
          const nextIndex = Math.min(currentIndex + 1, headerList.length - 1);
          headerList[nextIndex].focus();
          break;
        case 'ArrowUp':
          e.preventDefault();
          const prevIndex = Math.max(currentIndex - 1, 0);
          headerList[prevIndex].focus();
          break;
        case 'Home':
          e.preventDefault();
          headerList[0].focus();
          break;
        case 'End':
          e.preventDefault();
          headerList[headerList.length - 1].focus();
          break;
      }
    });
  });

  return () => {
    headers.forEach(header => {
      header.replaceWith(header.cloneNode(true));
    });
  };
});

export default hydrate;
