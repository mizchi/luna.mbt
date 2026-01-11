import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query, queryAll } from '../core/dom';

export interface RadioOptions {
  /**
   * Callback when selection changes
   */
  onChange?: (value: string) => void;

  /**
   * Orientation for keyboard navigation (default: vertical)
   */
  orientation?: 'horizontal' | 'vertical';
}

/**
 * Setup radio group behavior
 *
 * Expected DOM structure (with native inputs):
 * ```html
 * <div role="radiogroup" data-radio-group>
 *   <label data-radio-item data-value="option1">
 *     <input type="radio" name="group" value="option1" />
 *     <span data-radio-indicator></span>
 *     Option 1
 *   </label>
 *   <label data-radio-item data-value="option2">
 *     <input type="radio" name="group" value="option2" />
 *     <span data-radio-indicator></span>
 *     Option 2
 *   </label>
 * </div>
 * ```
 *
 * Or with custom elements (no native inputs):
 * ```html
 * <div role="radiogroup" data-radio-group>
 *   <div role="radio" data-radio-item data-value="option1"
 *        aria-checked="true" tabindex="0">
 *     <span data-radio-indicator></span>
 *     Option 1
 *   </div>
 *   <div role="radio" data-radio-item data-value="option2"
 *        aria-checked="false" tabindex="-1">
 *     <span data-radio-indicator></span>
 *     Option 2
 *   </div>
 * </div>
 * ```
 */
export function setupRadio(el: Element, options: RadioOptions = {}): CleanupFn {
  const { onChange, orientation = 'vertical' } = options;

  const items = queryAll(el, '[data-radio-item]');
  const hasNativeInputs = query(el, 'input[type="radio"]') !== null;

  // Update visual indicators based on selection
  const updateIndicators = () => {
    for (const item of items) {
      const indicator = query(item, '[data-radio-indicator]');
      if (!indicator) continue;

      const isChecked = hasNativeInputs
        ? (query<HTMLInputElement>(item, 'input[type="radio"]')?.checked ?? false)
        : attr(item, 'aria-checked') === 'true';

      (indicator as HTMLElement).style.display = isChecked ? 'block' : 'none';
      attr(item, 'data-state', isChecked ? 'checked' : 'unchecked');
    }
  };

  // Select an item by value
  const selectValue = (value: string) => {
    for (const item of items) {
      const itemValue = attr(item, 'data-value');
      const isSelected = itemValue === value;

      if (hasNativeInputs) {
        const input = query<HTMLInputElement>(item, 'input[type="radio"]');
        if (input) input.checked = isSelected;
      } else {
        attr(item, 'aria-checked', isSelected ? 'true' : 'false');
        attr(item, 'tabindex', isSelected ? '0' : '-1');
      }
    }
    updateIndicators();
    onChange?.(value);
  };

  // Get focusable items (inputs for native, items for custom)
  const getFocusableItems = (): HTMLElement[] => {
    if (hasNativeInputs) {
      return items.map(item => query<HTMLElement>(item, 'input[type="radio"]')!).filter(Boolean);
    }
    return items as HTMLElement[];
  };

  // Keyboard navigation
  const handleKeydown = (e: KeyboardEvent) => {
    const focusable = getFocusableItems();
    const current = document.activeElement as HTMLElement;
    const idx = focusable.indexOf(current);
    if (idx === -1) return;

    const isVertical = orientation === 'vertical';
    const isHorizontal = orientation === 'horizontal';
    let next = idx;

    if ((e.key === 'ArrowDown' && isVertical) || (e.key === 'ArrowRight' && isHorizontal)) {
      e.preventDefault();
      next = (idx + 1) % focusable.length;
    } else if ((e.key === 'ArrowUp' && isVertical) || (e.key === 'ArrowLeft' && isHorizontal)) {
      e.preventDefault();
      next = (idx - 1 + focusable.length) % focusable.length;
    } else if (e.key === ' ' && !hasNativeInputs) {
      // Space selects for custom elements (native inputs handle this automatically)
      e.preventDefault();
      const item = items[idx];
      const value = attr(item, 'data-value');
      if (value) selectValue(value);
      return;
    } else {
      return;
    }

    // Focus and select the next item
    focusable[next].focus();
    const nextItem = items[next];
    const value = attr(nextItem, 'data-value');
    if (value) selectValue(value);
  };

  const cleanups: CleanupFn[] = [];

  // Listen for changes on native inputs
  if (hasNativeInputs) {
    cleanups.push(on(el as HTMLElement, 'change', (e) => {
      const input = e.target as HTMLInputElement;
      if (input.type === 'radio' && input.checked) {
        updateIndicators();
        onChange?.(input.value);
      }
    }));
  }

  // Click handler for custom elements
  if (!hasNativeInputs) {
    cleanups.push(on(el as HTMLElement, 'click', (e) => {
      const item = (e.target as Element).closest('[data-radio-item]');
      if (!item) return;
      const value = attr(item, 'data-value');
      if (value) {
        selectValue(value);
        (item as HTMLElement).focus();
      }
    }));
  }

  // Keyboard navigation
  cleanups.push(on(el as HTMLElement, 'keydown', handleKeydown));

  // Initialize indicators
  updateIndicators();

  return combine(...cleanups);
}

/**
 * Get currently selected value
 */
export function getValue(group: Element): string | null {
  const hasNativeInputs = query(group, 'input[type="radio"]') !== null;

  if (hasNativeInputs) {
    const checked = query<HTMLInputElement>(group, 'input[type="radio"]:checked');
    return checked?.value ?? null;
  }

  const checked = query(group, '[data-radio-item][aria-checked="true"]');
  return checked ? attr(checked, 'data-value') : null;
}

/**
 * Set selected value programmatically
 */
export function setValue(group: Element, value: string): void {
  const items = queryAll(group, '[data-radio-item]');
  const hasNativeInputs = query(group, 'input[type="radio"]') !== null;

  for (const item of items) {
    const itemValue = attr(item, 'data-value');
    const isSelected = itemValue === value;

    if (hasNativeInputs) {
      const input = query<HTMLInputElement>(item, 'input[type="radio"]');
      if (input) input.checked = isSelected;
    } else {
      attr(item, 'aria-checked', isSelected ? 'true' : 'false');
      attr(item, 'tabindex', isSelected ? '0' : '-1');
    }

    // Update indicator
    const indicator = query(item, '[data-radio-indicator]');
    if (indicator) {
      (indicator as HTMLElement).style.display = isSelected ? 'block' : 'none';
    }
    attr(item, 'data-state', isSelected ? 'checked' : 'unchecked');
  }
}
