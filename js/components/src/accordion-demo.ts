// Accordion Demo Component
// Hydration wrapper for accordion demo in documentation
// This is bundled as a standalone entry for islands

import { setupAccordion, query } from './index';

/**
 * Setup accordion demo hydration
 * Finds the accordion element inside the custom element and sets up behavior
 */
export function setup(el: Element): (() => void) | void {
  const accordion = query(el, '[data-accordion]');
  if (!accordion) return;

  return setupAccordion(accordion, {
    multiple: false
  });
}

export default setup;
