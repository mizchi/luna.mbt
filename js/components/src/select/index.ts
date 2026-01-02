import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query, queryAll } from '../core/dom';
import { onEscape } from '../core/keyboard';

export interface SelectOptions {
  /**
   * Callback when selection changes
   */
  onChange?: (value: string) => void;

  /**
   * Callback when open state changes
   */
  onOpenChange?: (open: boolean) => void;
}

/**
 * Setup select/dropdown behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-select>
 *   <button data-select-trigger aria-haspopup="listbox" aria-expanded="false">
 *     <span data-select-value>Select an option</span>
 *   </button>
 *   <div data-select-content role="listbox" aria-hidden="true">
 *     <div data-select-item data-value="option1" role="option">Option 1</div>
 *     <div data-select-item data-value="option2" role="option">Option 2</div>
 *     <div data-select-item data-value="option3" role="option">Option 3</div>
 *   </div>
 * </div>
 * ```
 */
export function setupSelect(el: Element, options: SelectOptions = {}): CleanupFn {
  const { onChange, onOpenChange } = options;

  const trigger = query(el, '[data-select-trigger]');
  const content = query(el, '[data-select-content]');
  const valueDisplay = query(el, '[data-select-value]');

  if (!trigger || !content) return () => {};

  let focusedIndex = -1;

  const items = () => queryAll(el, '[data-select-item]:not([data-disabled])');

  const open = () => {
    setOpen(el, true);
    onOpenChange?.(true);

    // Focus first selected item or first item
    const allItems = items();
    const selectedIdx = allItems.findIndex(item => attr(item, 'data-state') === 'selected');
    focusedIndex = selectedIdx >= 0 ? selectedIdx : 0;
    updateFocusedItem(el, focusedIndex);
  };

  const close = () => {
    setOpen(el, false);
    onOpenChange?.(false);
    focusedIndex = -1;
    (trigger as HTMLElement).focus();
  };

  const selectItem = (item: Element) => {
    const value = attr(item, 'data-value');
    if (!value) return;

    // Update all items
    for (const i of items()) {
      const isSelected = i === item;
      attr(i, 'data-state', isSelected ? 'selected' : '');
      attr(i, 'aria-selected', isSelected ? 'true' : 'false');
    }

    // Update display
    if (valueDisplay) {
      valueDisplay.textContent = item.textContent ?? value;
    }

    attr(el, 'data-value', value);
    onChange?.(value);
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
    const item = (e.target as Element).closest('[data-select-item]');
    if (item && !attr(item, 'data-disabled')) {
      selectItem(item);
    }
  };

  const handleKeydown = (e: KeyboardEvent) => {
    if (!isOpen(el)) {
      if (e.key === 'ArrowDown' || e.key === 'ArrowUp' || e.key === 'Enter' || e.key === ' ') {
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

  // Close on outside click
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
 * Check if select is open
 */
export function isOpen(select: Element): boolean {
  const trigger = query(select, '[data-select-trigger]');
  return trigger ? attr(trigger, 'aria-expanded') === 'true' : false;
}

/**
 * Set open state
 */
export function setOpen(select: Element, open: boolean): void {
  const trigger = query(select, '[data-select-trigger]');
  const content = query(select, '[data-select-content]');

  if (trigger) {
    attr(trigger, 'aria-expanded', open ? 'true' : 'false');
  }
  if (content) {
    attr(content, 'aria-hidden', open ? 'false' : 'true');
    attr(content, 'data-state', open ? 'open' : 'closed');
  }
  attr(select, 'data-state', open ? 'open' : 'closed');
}

/**
 * Update focused item visual state
 */
function updateFocusedItem(select: Element, index: number): void {
  const allItems = queryAll(select, '[data-select-item]');
  for (let i = 0; i < allItems.length; i++) {
    attr(allItems[i], 'data-focused', i === index ? 'true' : 'false');
  }
}

/**
 * Get current value
 */
export function getValue(select: Element): string | null {
  return attr(select, 'data-value');
}

/**
 * Set value programmatically
 */
export function setValue(select: Element, value: string): void {
  const items = queryAll(select, '[data-select-item]');
  const valueDisplay = query(select, '[data-select-value]');

  for (const item of items) {
    const itemValue = attr(item, 'data-value');
    const isSelected = itemValue === value;
    attr(item, 'data-state', isSelected ? 'selected' : '');
    attr(item, 'aria-selected', isSelected ? 'true' : 'false');

    if (isSelected && valueDisplay) {
      valueDisplay.textContent = item.textContent ?? value;
    }
  }

  attr(select, 'data-value', value);
}
