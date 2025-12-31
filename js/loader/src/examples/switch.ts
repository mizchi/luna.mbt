/**
 * Switch component hydration example using @luna_ui/luna-loader/hydration
 *
 * This demonstrates how to use the hydration utilities for a toggle switch component.
 */
import {
  createHydrator,
  attachTriggers,
  updateCheckedState,
} from '../hydration';

/**
 * Switch hydration using createHydrator factory
 */
export const hydrate = createHydrator((element) => {
  attachTriggers(element, '[data-switch-toggle]', (trigger) => {
    const isChecked = trigger.getAttribute('aria-checked') === 'true';
    updateCheckedState(trigger, !isChecked, {
      thumbSelector: '[data-switch-thumb]',
    });
  });
});

export default hydrate;
