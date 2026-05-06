// Styled Disclosure Demo - APG Disclosure Pattern
// Toggles content visibility

import { createHydrator } from '@luna/hydration';

export const hydrate = createHydrator((el) => {
  const disclosures = el.querySelectorAll('.disclosure');

  disclosures.forEach(disclosure => {
    const trigger = disclosure.querySelector('.disclosure__trigger');
    const panel = disclosure.querySelector('.disclosure__panel');

    const toggle = () => {
      const isOpen = disclosure.getAttribute('data-state') === 'open';
      const newState = isOpen ? 'closed' : 'open';

      disclosure.setAttribute('data-state', newState);
      trigger.setAttribute('data-state', newState);
      trigger.setAttribute('aria-expanded', newState === 'open' ? 'true' : 'false');
      panel.setAttribute('data-state', newState);
    };

    trigger.addEventListener('click', toggle);
  });

  return () => {
    disclosures.forEach(disclosure => {
      const trigger = disclosure.querySelector('.disclosure__trigger');
      trigger.replaceWith(trigger.cloneNode(true));
    });
  };
});

export default hydrate;
