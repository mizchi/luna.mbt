// Dialog Demo - Modal dialog with overlay
// SSR-compatible: adopts existing DOM, adds event handlers
// CSS handles visual changes via [data-state] selector
//
// SSR HTML Convention:
//   <dialog-demo luna:trigger="visible">
//     <div data-dialog data-state="closed">
//       <button data-dialog-trigger>Open</button>
//       <div data-dialog-overlay></div>
//       <div data-dialog-content>
//         <button data-dialog-close>×</button>
//         Content...
//       </div>
//     </div>
//   </dialog-demo>
//
// Required CSS:
//   [data-dialog][data-state="closed"] [data-dialog-overlay],
//   [data-dialog][data-state="closed"] [data-dialog-content] { display: none; }
//   [data-dialog][data-state="open"] [data-dialog-overlay],
//   [data-dialog][data-state="open"] [data-dialog-content] { display: block; }
//   body:has([data-dialog][data-state="open"]) { overflow: hidden; }

import { createHydrator, onClick, onEscape } from '../../../js/luna/src/hydration/index.ts';

export const hydrate = createHydrator((el) => {
  const dialog = el.querySelector('[data-dialog]');
  if (!dialog) return;

  const open = () => { dialog.dataset.state = 'open'; };
  const close = () => { dialog.dataset.state = 'closed'; };

  const cleanups = [
    // Open triggers
    onClick(el, '[data-dialog-trigger]', open),

    // Close triggers
    onClick(el, '[data-dialog-close]', close),

    // Click overlay to close
    onClick(el, '[data-dialog-overlay]', close),

    // Escape key
    onEscape(() => {
      if (dialog.dataset.state === 'open') close();
    })
  ];

  // Prevent content clicks from closing
  const content = el.querySelector('[data-dialog-content]');
  if (content) {
    content.addEventListener('click', (e) => e.stopPropagation());
  }

  return () => cleanups.forEach(fn => fn());
});

export default hydrate;
