/**
 * Dialog component hydration example using @luna_ui/luna-loader/hydration
 *
 * Demonstrates attribute-only hydration pattern.
 * CSS handles all visual changes via [data-state] selector.
 */
import { createHydrator, onClick, onKey, setState, getState, $, combine } from '../hydration';

/**
 * Dialog hydration using createHydrator factory
 *
 * @example
 * ```html
 * <dialog-demo luna:trigger="visible">
 *   <div data-dialog data-state="closed">
 *     <button data-dialog-trigger>Open</button>
 *     <div data-dialog-overlay></div>
 *     <div data-dialog-content>
 *       <button data-dialog-close>×</button>
 *       Content...
 *     </div>
 *   </div>
 * </dialog-demo>
 * ```
 *
 * Required CSS:
 * ```css
 * [data-dialog][data-state="closed"] [data-dialog-overlay],
 * [data-dialog][data-state="closed"] [data-dialog-content] { display: none; }
 * [data-dialog][data-state="open"] [data-dialog-overlay],
 * [data-dialog][data-state="open"] [data-dialog-content] { display: block; }
 * body:has([data-dialog][data-state="open"]) { overflow: hidden; }
 * ```
 */
export const hydrate = createHydrator((element) => {
  const dialog = $(element, '[data-dialog]');
  if (!dialog) return () => {};

  const open = () => setState(dialog, 'open');
  const close = () => setState(dialog, 'closed');

  // Trigger buttons
  const cleanup1 = onClick(element, '[data-dialog-trigger]', () => open());

  // Close buttons
  const cleanup2 = onClick(element, '[data-dialog-close]', () => close());

  // Click overlay to close
  const overlay = $(element, '[data-dialog-overlay]');
  if (overlay) {
    overlay.onclick = close;
  }

  // Prevent content clicks from closing
  const content = $(element, '[data-dialog-content]');
  if (content) {
    content.onclick = (e) => e.stopPropagation();
  }

  // Escape key
  const cleanup3 = onKey(document, 'Escape', () => close(), {
    condition: () => getState(dialog) === 'open',
  });

  return combine(cleanup1, cleanup2, cleanup3);
});

export default hydrate;
