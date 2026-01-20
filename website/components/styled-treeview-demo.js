// Styled Tree View Demo - APG Tree View Pattern
// Hierarchical list with expand/collapse and keyboard navigation

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const getVisibleRows = () => {
    return Array.from(el.querySelectorAll('.treeview__row')).filter(row => {
      let parent = row.closest('.treeview__group');
      while (parent) {
        const parentItem = parent.closest('.treeview__item');
        if (parentItem && parentItem.getAttribute('data-expanded') === 'false') {
          return false;
        }
        parent = parentItem?.parentElement?.closest('.treeview__group');
      }
      return true;
    });
  };

  const toggleExpand = (item) => {
    const hasChildren = item.querySelector('.treeview__group');
    if (!hasChildren) return;

    const isExpanded = item.getAttribute('data-expanded') === 'true';
    item.setAttribute('data-expanded', isExpanded ? 'false' : 'true');
    item.setAttribute('aria-expanded', isExpanded ? 'false' : 'true');

    const icon = item.querySelector(':scope > .treeview__row .treeview__icon');
    if (icon) {
      icon.textContent = isExpanded ? '▶' : '▼';
    }
  };

  const selectItem = (row) => {
    el.querySelectorAll('.treeview__row').forEach(r => {
      r.setAttribute('data-selected', 'false');
      r.setAttribute('tabindex', '-1');
    });
    row.setAttribute('data-selected', 'true');
    row.setAttribute('tabindex', '0');
    row.focus();
  };

  el.querySelectorAll('.treeview__row').forEach(row => {
    row.addEventListener('click', () => {
      const item = row.closest('.treeview__item');
      selectItem(row);
      toggleExpand(item);
    });

    row.addEventListener('keydown', (e) => {
      const item = row.closest('.treeview__item');
      const visibleRows = getVisibleRows();
      const currentIndex = visibleRows.indexOf(row);

      switch (e.key) {
        case 'ArrowDown':
          e.preventDefault();
          if (currentIndex < visibleRows.length - 1) {
            selectItem(visibleRows[currentIndex + 1]);
          }
          break;
        case 'ArrowUp':
          e.preventDefault();
          if (currentIndex > 0) {
            selectItem(visibleRows[currentIndex - 1]);
          }
          break;
        case 'ArrowRight':
          e.preventDefault();
          if (item.getAttribute('data-expanded') === 'false') {
            toggleExpand(item);
          } else {
            const firstChild = item.querySelector('.treeview__group > .treeview__item > .treeview__row');
            if (firstChild) selectItem(firstChild);
          }
          break;
        case 'ArrowLeft':
          e.preventDefault();
          if (item.getAttribute('data-expanded') === 'true') {
            toggleExpand(item);
          } else {
            const parentItem = item.parentElement?.closest('.treeview__item');
            if (parentItem) {
              const parentRow = parentItem.querySelector(':scope > .treeview__row');
              if (parentRow) selectItem(parentRow);
            }
          }
          break;
        case 'Home':
          e.preventDefault();
          selectItem(visibleRows[0]);
          break;
        case 'End':
          e.preventDefault();
          selectItem(visibleRows[visibleRows.length - 1]);
          break;
        case 'Enter':
        case ' ':
          e.preventDefault();
          toggleExpand(item);
          break;
      }
    });
  });

  return () => {
    el.querySelectorAll('.treeview__row').forEach(row => {
      row.replaceWith(row.cloneNode(true));
    });
  };
});

export default hydrate;
