// Dialog Demo - Modal dialog with overlay
// SSR-compatible: adopts existing DOM, adds event handlers
export function hydrate(element, state, name) {
  const dialog = element.querySelector('[data-dialog]');
  const trigger = element.querySelector('[data-dialog-trigger]');
  const overlay = element.querySelector('[data-dialog-overlay]');
  const closeBtn = element.querySelector('[data-dialog-close]');
  const content = element.querySelector('[data-dialog-content]');

  if (!dialog || !trigger) return;

  const openDialog = () => {
    dialog.dataset.state = 'open';
    if (overlay) overlay.style.display = 'block';
    if (content) content.style.display = 'block';
    document.body.style.overflow = 'hidden';
  };

  const closeDialog = () => {
    dialog.dataset.state = 'closed';
    if (overlay) overlay.style.display = 'none';
    if (content) content.style.display = 'none';
    document.body.style.overflow = '';
  };

  trigger.onclick = openDialog;
  if (overlay) overlay.onclick = closeDialog;
  if (closeBtn) closeBtn.onclick = closeDialog;

  // Close on Escape
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && dialog.dataset.state === 'open') {
      closeDialog();
    }
  });

  // Prevent clicks inside content from closing
  if (content) {
    content.onclick = (e) => e.stopPropagation();
  }

  element.dataset.hydrated = 'true';
}

export default hydrate;
