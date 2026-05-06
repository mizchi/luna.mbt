// Accordion Demo Component
// Hydration for accordion demo using APG pattern

import { createHydrator } from '@luna/hydration';

/**
 * Set accordion item open state
 * @param {Element} item
 * @param {boolean} open
 */
function setItemOpen(item, open) {
  const state = open ? 'open' : 'closed';
  item.setAttribute('data-state', state);

  const trigger = item.querySelector('[data-accordion-trigger]');
  if (trigger) {
    trigger.setAttribute('aria-expanded', open ? 'true' : 'false');
    trigger.setAttribute('data-state', state);
  }

  const content = item.querySelector('[data-accordion-content]');
  if (content) {
    content.setAttribute('data-state', state);
    content.setAttribute('aria-hidden', open ? 'false' : 'true');
    if (open) {
      content.removeAttribute('hidden');
    } else {
      content.setAttribute('hidden', '');
    }
  }
}

export const hydrate = createHydrator((el) => {
  const accordion = el.querySelector('[data-accordion]');
  if (!accordion) return;

  const handleClick = (e) => {
    const trigger = e.target.closest('[data-accordion-trigger]');
    if (!trigger) return;

    const item = trigger.closest('[data-accordion-item]');
    if (!item) return;

    const isOpen = trigger.getAttribute('aria-expanded') === 'true';

    // Close all other items (single mode)
    if (!isOpen) {
      const items = accordion.querySelectorAll('[data-accordion-item]');
      items.forEach(other => {
        if (other !== item) setItemOpen(other, false);
      });
    }

    setItemOpen(item, !isOpen);
  };

  const handleKeydown = (e) => {
    const trigger = e.target.closest('[data-accordion-trigger]');
    if (!trigger) return;

    const triggers = [...accordion.querySelectorAll('[data-accordion-trigger]')];
    const currentIndex = triggers.indexOf(trigger);

    let nextIndex = -1;
    switch (e.key) {
      case 'ArrowDown':
        nextIndex = (currentIndex + 1) % triggers.length;
        break;
      case 'ArrowUp':
        nextIndex = (currentIndex - 1 + triggers.length) % triggers.length;
        break;
      case 'Home':
        nextIndex = 0;
        break;
      case 'End':
        nextIndex = triggers.length - 1;
        break;
      default:
        return;
    }

    e.preventDefault();
    triggers[nextIndex]?.focus();
  };

  accordion.addEventListener('click', handleClick);
  accordion.addEventListener('keydown', handleKeydown);

  return () => {
    accordion.removeEventListener('click', handleClick);
    accordion.removeEventListener('keydown', handleKeydown);
  };
});

export default hydrate;
