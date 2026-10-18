// Sidebar Disclosure - Enhanced keyboard navigation
// SSR-compatible: adopts existing DOM, adds event handlers
// Syncs aria-expanded with details open state
//
// SSR HTML Convention:
//   <aside class="sidebar" luna:wc-url="/components/sidebar-disclosure.js" luna:trigger="load">
//     <details class="sidebar-collapse">
//       <summary aria-expanded="true|false" aria-controls="id" aria-labelledby="id">
//         ...
//       </summary>
//       <div class="sidebar-items" id="content-id" role="region">
//         ...
//       </div>
//     </details>
//   </aside>

/**
 * Hydrate sidebar disclosure elements
 * @param {HTMLElement} element - The sidebar element
 */
export function hydrate(element) {
  const disclosures = element.querySelectorAll('details.sidebar-collapse');

  disclosures.forEach(details => {
    const summary = details.querySelector('summary');
    if (!summary) return;

    // Sync aria-expanded with details open state
    const syncAriaExpanded = () => {
      summary.setAttribute('aria-expanded', details.open ? 'true' : 'false');
    };

    // Listen for toggle event (fires when open state changes)
    details.addEventListener('toggle', syncAriaExpanded);

    // Enhanced keyboard handling
    summary.addEventListener('keydown', (e) => {
      // Enter and Space are handled natively by details/summary
      // But we add Home/End for first/last disclosure navigation
      if (e.key === 'Home' || e.key === 'End') {
        e.preventDefault();
        const allSummaries = Array.from(
          element.querySelectorAll('details.sidebar-collapse > summary')
        );
        if (allSummaries.length === 0) return;

        const targetSummary = e.key === 'Home'
          ? allSummaries[0]
          : allSummaries[allSummaries.length - 1];
        targetSummary.focus();
      }

      // Arrow keys for moving between sibling disclosures
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        const allSummaries = Array.from(
          element.querySelectorAll('details.sidebar-collapse > summary')
        );
        const currentIndex = allSummaries.indexOf(summary);
        if (currentIndex === -1) return;

        let nextIndex;
        if (e.key === 'ArrowDown') {
          nextIndex = currentIndex + 1;
          if (nextIndex >= allSummaries.length) nextIndex = 0;
        } else {
          nextIndex = currentIndex - 1;
          if (nextIndex < 0) nextIndex = allSummaries.length - 1;
        }

        e.preventDefault();
        allSummaries[nextIndex].focus();
      }
    });

    // Initial sync
    syncAriaExpanded();
  });

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
