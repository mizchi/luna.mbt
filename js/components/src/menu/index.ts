import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query, queryAll } from '../core/dom';
import { onEscape } from '../core/keyboard';

export interface MenuOptions {
  /**
   * Callback when selection is made
   */
  onSelect?: (value: string) => void;

  /**
   * Callback when open state changes
   */
  onOpenChange?: (open: boolean) => void;
}

/**
 * Setup dropdown menu behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-menu>
 *   <button data-menu-trigger aria-haspopup="menu" aria-expanded="false">
 *     Menu
 *   </button>
 *   <div data-menu-content role="menu" aria-hidden="true">
 *     <button data-menu-item data-value="edit" role="menuitem">Edit</button>
 *     <button data-menu-item data-value="delete" role="menuitem">Delete</button>
 *     <div data-menu-separator role="separator"></div>
 *     <button data-menu-item data-value="settings" role="menuitem">Settings</button>
 *   </div>
 * </div>
 * ```
 */
export function setupMenu(el: Element, options: MenuOptions = {}): CleanupFn {
  const { onSelect, onOpenChange } = options;

  const trigger = query(el, '[data-menu-trigger]');
  const content = query(el, '[data-menu-content]');

  if (!trigger || !content) return () => {};

  let focusedIndex = -1;

  const items = () => queryAll(el, '[data-menu-item]:not([data-disabled])');

  const open = () => {
    setOpen(el, true);
    onOpenChange?.(true);
    focusedIndex = 0;
    updateFocusedItem(el, focusedIndex);
  };

  const close = () => {
    setOpen(el, false);
    onOpenChange?.(false);
    focusedIndex = -1;
    clearFocus(el);
    (trigger as HTMLElement).focus();
  };

  const selectItem = (item: Element) => {
    const value = attr(item, 'data-value');
    if (value) {
      onSelect?.(value);
    }
    close();
  };

  const handleTriggerClick = () => {
    if (isOpen(el)) {
      close();
    } else {
      open();
    }
  };

  const handleItemClick = (e: Event) => {
    const item = (e.target as Element).closest('[data-menu-item]');
    if (item && !attr(item, 'data-disabled')) {
      selectItem(item);
    }
  };

  const handleKeydown = (e: KeyboardEvent) => {
    if (!isOpen(el)) {
      if (e.key === 'ArrowDown' || e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        open();
      }
      return;
    }

    const allItems = items();
    if (allItems.length === 0) return;

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        focusedIndex = (focusedIndex + 1) % allItems.length;
        updateFocusedItem(el, focusedIndex);
        break;
      case 'ArrowUp':
        e.preventDefault();
        focusedIndex = (focusedIndex - 1 + allItems.length) % allItems.length;
        updateFocusedItem(el, focusedIndex);
        break;
      case 'Home':
        e.preventDefault();
        focusedIndex = 0;
        updateFocusedItem(el, focusedIndex);
        break;
      case 'End':
        e.preventDefault();
        focusedIndex = allItems.length - 1;
        updateFocusedItem(el, focusedIndex);
        break;
      case 'Enter':
      case ' ':
        e.preventDefault();
        if (focusedIndex >= 0 && focusedIndex < allItems.length) {
          selectItem(allItems[focusedIndex]);
        }
        break;
      case 'Tab':
        close();
        break;
    }
  };

  const handleOutsideClick = (e: Event) => {
    if (isOpen(el) && !el.contains(e.target as Node)) {
      close();
    }
  };

  const cleanups: CleanupFn[] = [];

  cleanups.push(on(trigger as HTMLElement, 'click', handleTriggerClick));
  cleanups.push(on(content as HTMLElement, 'click', handleItemClick));
  cleanups.push(on(el as HTMLElement, 'keydown', handleKeydown));
  cleanups.push(onEscape(el, close));
  cleanups.push(on(document, 'click', handleOutsideClick));

  return combine(...cleanups);
}

/**
 * Check if menu is open
 */
export function isOpen(menu: Element): boolean {
  const trigger = query(menu, '[data-menu-trigger]');
  return trigger ? attr(trigger, 'aria-expanded') === 'true' : false;
}

/**
 * Set open state
 */
export function setOpen(menu: Element, open: boolean): void {
  const trigger = query(menu, '[data-menu-trigger]');
  const content = query(menu, '[data-menu-content]');

  if (trigger) {
    attr(trigger, 'aria-expanded', open ? 'true' : 'false');
  }
  if (content) {
    attr(content, 'aria-hidden', open ? 'false' : 'true');
    attr(content, 'data-state', open ? 'open' : 'closed');
  }
  attr(menu, 'data-state', open ? 'open' : 'closed');
}

function updateFocusedItem(menu: Element, index: number): void {
  const allItems = queryAll(menu, '[data-menu-item]');
  for (let i = 0; i < allItems.length; i++) {
    attr(allItems[i], 'data-focused', i === index ? 'true' : 'false');
  }
}

function clearFocus(menu: Element): void {
  const allItems = queryAll(menu, '[data-menu-item]');
  for (const item of allItems) {
    attr(item, 'data-focused', 'false');
  }
}
