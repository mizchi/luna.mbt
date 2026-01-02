/**
 * Sol-compatible hydration wrappers
 *
 * These exports can be used with luna:wc-url for SSR hydration
 */

import { setupTabs } from '../tabs';
import { setupCard } from '../card';
import { setupAccordion } from '../accordion';
import { setupCheckbox } from '../checkbox';
import { setupSwitch } from '../switch';
import { setupDialog } from '../dialog';
import { setupSlider } from '../slider';
import { setupRadioGroup } from '../radio-group';
import { setupProgress } from '../progress';
import { setupCollapsible } from '../collapsible';
import { setupTooltip } from '../tooltip';
import { setupToggle } from '../toggle';
import { setupToggleGroup } from '../toggle-group';
import { setupSelect } from '../select';
import { setupPopover } from '../popover';
import { setupMenu } from '../menu';
import { setupAlertDialog } from '../alert-dialog';
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
export const hydrateCard = createHydrator(setupCard);
export const hydrateAccordion = createHydrator(setupAccordion);
export const hydrateCheckbox = createHydrator(setupCheckbox);
export const hydrateSwitch = createHydrator(setupSwitch);
export const hydrateDialog = createHydrator(setupDialog);
export const hydrateSlider = createHydrator(setupSlider);
export const hydrateRadioGroup = createHydrator(setupRadioGroup);
export const hydrateProgress = createHydrator(setupProgress);
export const hydrateCollapsible = createHydrator(setupCollapsible);
export const hydrateTooltip = createHydrator(setupTooltip);
export const hydrateToggle = createHydrator(setupToggle);
export const hydrateToggleGroup = createHydrator(setupToggleGroup);
export const hydrateSelect = createHydrator(setupSelect);
export const hydratePopover = createHydrator(setupPopover);
export const hydrateMenu = createHydrator(setupMenu);
export const hydrateAlertDialog = createHydrator(setupAlertDialog);

// Default exports for direct use with luna:wc-url
export { hydrateTabs as tabs };
export { hydrateCard as card };
export { hydrateAccordion as accordion };
export { hydrateCheckbox as checkbox };
export { hydrateSwitch as switch_ };
export { hydrateDialog as dialog };
export { hydrateSlider as slider };
export { hydrateRadioGroup as radioGroup };
export { hydrateProgress as progress };
export { hydrateCollapsible as collapsible };
export { hydrateTooltip as tooltip };
export { hydrateToggle as toggle };
export { hydrateToggleGroup as toggleGroup };
export { hydrateSelect as select };
export { hydratePopover as popover };
export { hydrateMenu as menu };
export { hydrateAlertDialog as alertDialog };
