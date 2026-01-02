import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, queryAll } from '../core/dom';
import { onArrowNav } from '../core/keyboard';

export interface ToggleGroupOptions {
  /**
   * Allow multiple items to be selected
   */
  multiple?: boolean;

  /**
   * Callback when selection changes
   */
  onChange?: (values: string[]) => void;

  /**
   * Orientation for keyboard navigation
   */
  orientation?: 'horizontal' | 'vertical';
}

/**
 * Setup toggle group behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-toggle-group role="group">
 *   <button data-toggle-item data-value="bold" aria-pressed="false">B</button>
 *   <button data-toggle-item data-value="italic" aria-pressed="false">I</button>
 *   <button data-toggle-item data-value="underline" aria-pressed="false">U</button>
 * </div>
 * ```
 */
export function setupToggleGroup(el: Element, options: ToggleGroupOptions = {}): CleanupFn {
  const { multiple = false, onChange, orientation = 'horizontal' } = options;

  const items = queryAll(el, '[data-toggle-item]');

  const handleClick = (e: Event) => {
    const item = (e.target as Element).closest('[data-toggle-item]');
    if (!item) return;

    const value = attr(item, 'data-value');
    if (!value) return;

    const isCurrentlyPressed = attr(item, 'aria-pressed') === 'true';

    if (multiple) {
      // Toggle individual item
      attr(item, 'aria-pressed', isCurrentlyPressed ? 'false' : 'true');
      attr(item, 'data-state', isCurrentlyPressed ? 'off' : 'on');
    } else {
      // Single selection - deselect others
      for (const other of items) {
        const shouldBePressed = other === item && !isCurrentlyPressed;
        attr(other, 'aria-pressed', shouldBePressed ? 'true' : 'false');
        attr(other, 'data-state', shouldBePressed ? 'on' : 'off');
      }
    }

    onChange?.(getValues(el));
  };

  const cleanups: CleanupFn[] = [];

  cleanups.push(on(el as HTMLElement, 'click', handleClick));
  cleanups.push(onArrowNav(el, '[data-toggle-item]', { orientation, loop: true }));

  return combine(...cleanups);
}

/**
 * Get currently selected values
 */
export function getValues(group: Element): string[] {
  const values: string[] = [];
  const items = queryAll(group, '[data-toggle-item]');
  for (const item of items) {
    if (attr(item, 'aria-pressed') === 'true') {
      const value = attr(item, 'data-value');
      if (value) values.push(value);
    }
  }
  return values;
}

/**
 * Set selected values
 */
export function setValues(group: Element, values: string[]): void {
  const items = queryAll(group, '[data-toggle-item]');
  for (const item of items) {
    const value = attr(item, 'data-value');
    const shouldBePressed = value ? values.includes(value) : false;
    attr(item, 'aria-pressed', shouldBePressed ? 'true' : 'false');
    attr(item, 'data-state', shouldBePressed ? 'on' : 'off');
  }
}
