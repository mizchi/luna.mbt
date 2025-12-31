/**
 * Accordion component hydration example using @luna_ui/luna-loader/hydration
 *
 * Demonstrates attribute-only hydration pattern.
 * CSS handles all visual changes via [data-state] selector.
 */
import { createHydrator, onClick, toggle, closest } from '../hydration';

/**
 * Accordion hydration using createHydrator factory
 *
 * @example
 * ```html
 * <accordion-demo luna:trigger="visible">
 *   <div data-accordion-item="item-1" data-state="open">
 *     <button data-accordion-trigger>
 *       Title <span data-chevron>▼</span>
 *     </button>
 *     <div data-accordion-content>Content</div>
 *   </div>
 * </accordion-demo>
 * ```
 *
 * Required CSS:
 * ```css
 * [data-state="open"] [data-accordion-content] { max-height: 200px; }
 * [data-state="closed"] [data-accordion-content] { max-height: 0; }
 * [data-state="open"] [data-chevron] { transform: rotate(180deg); }
 * [data-state="closed"] [data-chevron] { transform: rotate(0deg); }
 * [data-accordion-content] { transition: max-height 0.3s ease; overflow: hidden; }
 * [data-chevron] { transition: transform 0.2s ease; }
 * ```
 */
export const hydrate = createHydrator((element) => {
  const cleanup = onClick(element, '[data-accordion-trigger]', (_event, target) => {
    const item = closest(target, '[data-accordion-item]');
    if (item) {
      toggle(item, 'data-state', ['open', 'closed']);
    }
  });

  return cleanup;
});

export default hydrate;
