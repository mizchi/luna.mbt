/**
 * Switch component hydration example using @luna_ui/luna-loader/hydration
 *
 * Demonstrates attribute-only hydration pattern.
 * CSS handles all visual changes via [aria-checked] selector.
 */
import { createHydrator, onClick, toggleChecked, combine } from '../hydration';

/**
 * Switch hydration using createHydrator factory
 *
 * @example
 * ```html
 * <switch-demo luna:trigger="visible">
 *   <button data-switch-toggle aria-checked="true">
 *     <span data-switch-thumb></span>
 *   </button>
 * </switch-demo>
 * ```
 *
 * Required CSS:
 * ```css
 * [data-switch-toggle][aria-checked="true"] { background: var(--primary); }
 * [data-switch-toggle][aria-checked="false"] { background: var(--muted); }
 * [aria-checked="true"] [data-switch-thumb] { transform: translateX(20px); }
 * [aria-checked="false"] [data-switch-thumb] { transform: translateX(0); }
 * ```
 */
export const hydrate = createHydrator((element) => {
  const cleanup = onClick(element, '[data-switch-toggle]', (_event, target) => {
    toggleChecked(target);
  });

  return cleanup;
});

export default hydrate;
