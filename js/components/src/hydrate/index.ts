/**
 * Sol-compatible hydration wrappers
 *
 * These exports can be used with luna:wc-url for SSR hydration
 * Matches src/components APG patterns
 */

import { setupTabs } from '../tabs';
import { setupAccordion } from '../accordion';
import { setupCheckbox } from '../checkbox';
import { setupSwitch } from '../switch';
import { setupDialog } from '../dialog';
import { setupSlider } from '../slider';
import { setupRadio } from '../radio';
import { setupTooltip } from '../tooltip';
import type { CleanupFn } from '../core/types';

type HydrateFn = (el: Element, state?: unknown, id?: string) => CleanupFn | void;

/**
 * Create a hydrate function from a setup function
 */
function createHydrator<T>(
  setup: (el: Element, options?: T) => CleanupFn
): HydrateFn {
  return (el: Element, state?: unknown) => {
    return setup(el, state as T);
  };
}

// Export hydrate functions for each component
export const hydrateTabs = createHydrator(setupTabs);
export const hydrateAccordion = createHydrator(setupAccordion);
export const hydrateCheckbox = createHydrator(setupCheckbox);
export const hydrateSwitch = createHydrator(setupSwitch);
export const hydrateDialog = createHydrator(setupDialog);
export const hydrateSlider = createHydrator(setupSlider);
export const hydrateRadio = createHydrator(setupRadio);
export const hydrateTooltip = createHydrator(setupTooltip);

// Default exports for direct use with luna:wc-url
export { hydrateTabs as tabs };
export { hydrateAccordion as accordion };
export { hydrateCheckbox as checkbox };
export { hydrateSwitch as switch_ };
export { hydrateDialog as dialog };
export { hydrateSlider as slider };
export { hydrateRadio as radio };
export { hydrateTooltip as tooltip };
