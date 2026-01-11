import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query, queryAll } from '../core/dom';
import { onActivate, onArrowNav } from '../core/keyboard';

export interface AccordionOptions {
  /**
   * Allow multiple items to be open at once
   */
  multiple?: boolean;

  /**
   * IDs of initially open items
   */
  defaultOpen?: string[];

  /**
   * Callback when open items change
   */
  onChange?: (openIds: string[]) => void;
}

/**
 * Setup accordion behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-accordion>
 *   <div data-accordion-item data-item-id="item1">
 *     <button data-accordion-trigger aria-expanded="false">
 *       Item 1
 *     </button>
 *     <div data-accordion-content>
 *       Content 1
 *     </div>
 *   </div>
 *   <!-- more items -->
 * </div>
 * ```
 */
export function setupAccordion(el: Element, options: AccordionOptions = {}): CleanupFn {
  const { multiple = false, defaultOpen = [], onChange } = options;

  // Initialize default open items
  for (const id of defaultOpen) {
    const item = query(el, `[data-item-id="${id}"]`);
    if (item) setItemOpen(item, true);
  }

  const handleTriggerClick = (e: Event) => {
    const trigger = (e.target as Element).closest('[data-accordion-trigger]');
    if (!trigger) return;

    const item = trigger.closest('[data-accordion-item]');
    if (!item) return;

    const isOpen = getItemOpen(item);

    if (!multiple && !isOpen) {
      // Close all other items
      const items = queryAll(el, '[data-accordion-item]');
      for (const other of items) {
        if (other !== item) setItemOpen(other, false);
      }
    }

    setItemOpen(item, !isOpen);
    notifyChange();
  };

  const notifyChange = () => {
    if (!onChange) return;
    const openIds = getOpenIds(el);
    onChange(openIds);
  };

  const cleanups: CleanupFn[] = [];

  // Click handler
  cleanups.push(on(el as HTMLElement, 'click', handleTriggerClick));

  // Keyboard activation for triggers
  const triggers = queryAll(el, '[data-accordion-trigger]');
  for (const trigger of triggers) {
    cleanups.push(onActivate(trigger, (e) => {
      handleTriggerClick(e);
    }));
  }

  // Arrow key navigation between triggers
  cleanups.push(onArrowNav(el, '[data-accordion-trigger]', {
    orientation: 'vertical',
    loop: true
  }));

  return combine(...cleanups);
}

/**
 * Check if an accordion item is open
 */
export function getItemOpen(item: Element): boolean {
  const trigger = query(item, '[data-accordion-trigger]');
  if (trigger) {
    const expanded = attr(trigger, 'aria-expanded');
    if (expanded === 'true') return true;
  }
  const state = attr(item, 'data-state');
  return state === 'open';
}

/**
 * Set accordion item open state
 */
export function setItemOpen(item: Element, open: boolean): void {
  attr(item, 'data-state', open ? 'open' : 'closed');

  const trigger = query(item, '[data-accordion-trigger]');
  if (trigger) {
    attr(trigger, 'aria-expanded', open ? 'true' : 'false');
  }

  const content = query(item, '[data-accordion-content]');
  if (content) {
    attr(content, 'data-state', open ? 'open' : 'closed');
    // For accessibility: hide content when closed
    attr(content, 'aria-hidden', open ? 'false' : 'true');
  }
}

/**
 * Get IDs of all open items
 */
export function getOpenIds(accordion: Element): string[] {
  const ids: string[] = [];
  const items = queryAll(accordion, '[data-accordion-item]');
  for (const item of items) {
    if (getItemOpen(item)) {
      const id = attr(item, 'data-item-id');
      if (id) ids.push(id);
    }
  }
  return ids;
}
