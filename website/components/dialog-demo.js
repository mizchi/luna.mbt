// Dialog Demo - Modal dialog with overlay
// SSR-compatible: adopts existing DOM, adds event handlers
//
// SSR HTML Convention:
//   <dialog-demo luna:trigger="visible">
//     <div data-dialog data-state="closed">
//       <button data-dialog-trigger>Open</button>
//       <div data-dialog-overlay style="display:none"></div>
//       <div data-dialog-content style="display:none">
//         <button data-dialog-close>×</button>
//         Content...
//       </div>
//     </div>
//   </dialog-demo>

export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  const dialog = element.querySelector('[data-dialog]');
  const overlay = element.querySelector('[data-dialog-overlay]');
  const content = element.querySelector('[data-dialog-content]');

  if (!dialog) return;

  const open = () => {
    dialog.dataset.state = 'open';
    if (overlay) overlay.style.display = 'block';
    if (content) content.style.display = 'block';
    document.body.style.overflow = 'hidden';
  };

  const close = () => {
    dialog.dataset.state = 'closed';
    if (overlay) overlay.style.display = 'none';
    if (content) content.style.display = 'none';
    document.body.style.overflow = '';
  };

  // Trigger button
  element.querySelectorAll('[data-dialog-trigger]').forEach(btn => {
    btn.onclick = open;
  });

  // Close buttons
  element.querySelectorAll('[data-dialog-close]').forEach(btn => {
    btn.onclick = close;
  });

  // Click overlay to close
  if (overlay) overlay.onclick = close;

  // Prevent content clicks from closing
  if (content) content.onclick = (e) => e.stopPropagation();

  // Escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && dialog.dataset.state === 'open') close();
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
