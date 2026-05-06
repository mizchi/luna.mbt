// Styled Tabs Demo - APG Tabs Pattern
// Switches active tab and panel on click

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const tabs = el.querySelectorAll('.tabs__tab');
  const panels = el.querySelectorAll('.tabs__panel');

  const selectTab = (index) => {
    tabs.forEach((tab, i) => {
      const isActive = i === index;
      tab.setAttribute('data-state', isActive ? 'active' : 'inactive');
      tab.setAttribute('aria-selected', isActive ? 'true' : 'false');
      tab.setAttribute('tabindex', isActive ? '0' : '-1');
    });

    panels.forEach((panel, i) => {
      if (i === index) {
        panel.style.display = '';
        panel.removeAttribute('hidden');
      } else {
        panel.style.display = 'none';
        panel.setAttribute('hidden', '');
      }
    });
  };

  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => {
      selectTab(index);
      tab.focus();
    });

    tab.addEventListener('keydown', (e) => {
      const tabList = Array.from(tabs);
      const currentIndex = tabList.indexOf(tab);
      let newIndex = currentIndex;

      switch (e.key) {
        case 'ArrowLeft':
          e.preventDefault();
          newIndex = currentIndex === 0 ? tabList.length - 1 : currentIndex - 1;
          break;
        case 'ArrowRight':
          e.preventDefault();
          newIndex = currentIndex === tabList.length - 1 ? 0 : currentIndex + 1;
          break;
        case 'Home':
          e.preventDefault();
          newIndex = 0;
          break;
        case 'End':
          e.preventDefault();
          newIndex = tabList.length - 1;
          break;
        default:
          return;
      }

      selectTab(newIndex);
      tabList[newIndex].focus();
    });
  });

  return () => {
    tabs.forEach(tab => {
      tab.replaceWith(tab.cloneNode(true));
    });
  };
});

export default hydrate;
