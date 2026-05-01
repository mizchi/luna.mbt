// Styled Table Demo - Sortable table with row selection
// Handles column sorting and row selection
//
// SSR HTML:
//   <styled-table-demo luna:trigger="visible">
//     <div class="table">
//       <table class="table__table">
//         <thead class="table__header">
//           <tr>
//             <th class="table__th table__th--sortable" aria-sort="none" data-col="name">
//               Name <span class="table__sort-icon"></span>
//             </th>
//           </tr>
//         </thead>
//         <tbody class="table__body">
//           <tr class="table__row" data-row-id="1" data-selected="false">
//             <td class="table__cell">Value</td>
//           </tr>
//         </tbody>
//       </table>
//     </div>
//   </styled-table-demo>

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const table = el.querySelector('.table__table');
  if (!table) return () => {};

  const headers = el.querySelectorAll('.table__th--sortable');
  const tbody = el.querySelector('.table__body');
  const rows = el.querySelectorAll('.table__row');

  let currentSortCol = null;
  let sortDirection = 'none'; // 'none', 'ascending', 'descending'

  const sortTable = (colName, colIndex) => {
    // Cycle through: none -> ascending -> descending -> none
    if (currentSortCol === colName) {
      if (sortDirection === 'none') sortDirection = 'ascending';
      else if (sortDirection === 'ascending') sortDirection = 'descending';
      else sortDirection = 'none';
    } else {
      currentSortCol = colName;
      sortDirection = 'ascending';
    }

    // Update aria-sort on all headers
    headers.forEach(th => {
      const col = th.getAttribute('data-col');
      const icon = th.querySelector('.table__sort-icon');
      if (col === colName) {
        th.setAttribute('aria-sort', sortDirection);
        if (icon) {
          icon.textContent = sortDirection === 'ascending' ? ' \u25B2' :
                            sortDirection === 'descending' ? ' \u25BC' : '';
          icon.setAttribute('aria-hidden', sortDirection === 'none' ? 'true' : 'false');
        }
      } else {
        th.setAttribute('aria-sort', 'none');
        if (icon) {
          icon.textContent = '';
          icon.setAttribute('aria-hidden', 'true');
        }
      }
    });

    // Sort rows
    if (sortDirection !== 'none' && tbody) {
      const rowsArray = Array.from(tbody.querySelectorAll('.table__row'));
      rowsArray.sort((a, b) => {
        const aVal = a.querySelectorAll('.table__cell')[colIndex]?.textContent || '';
        const bVal = b.querySelectorAll('.table__cell')[colIndex]?.textContent || '';
        const cmp = aVal.localeCompare(bVal);
        return sortDirection === 'ascending' ? cmp : -cmp;
      });
      rowsArray.forEach(row => tbody.appendChild(row));
    }
  };

  // Header click handlers
  headers.forEach((th, index) => {
    const colName = th.getAttribute('data-col');
    th.addEventListener('click', () => sortTable(colName, index));
    th.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        sortTable(colName, index);
      }
    });
    th.setAttribute('tabindex', '0');
  });

  // Row selection
  let selectedRow = null;
  rows.forEach(row => {
    row.addEventListener('click', () => {
      if (selectedRow) {
        selectedRow.setAttribute('data-selected', 'false');
      }
      row.setAttribute('data-selected', 'true');
      selectedRow = row;
    });
  });

  return () => {
    headers.forEach(th => {
      th.replaceWith(th.cloneNode(true));
    });
    rows.forEach(row => {
      row.replaceWith(row.cloneNode(true));
    });
  };
});

export default hydrate;
