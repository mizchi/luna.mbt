import type { CleanupFn, CheckboxState } from '../core/types';
import { combine } from '../core/types';
import { on, attr } from '../core/dom';
import { onActivate } from '../core/keyboard';

export interface CheckboxOptions {
  /**
   * Callback when checkbox state changes
   */
  onChange?: (state: CheckboxState) => void;
}

/**
 * Setup checkbox behavior on an element
 *
 * Expected DOM structure:
 * ```html
 * <button data-checkbox aria-checked="false" role="checkbox">
 *   Check me
 * </button>
 * ```
 *
 * Or with data-state:
 * ```html
 * <button data-checkbox data-state="unchecked" role="checkbox">
 *   Check me
 * </button>
 * ```
 */
export function setupCheckbox(el: Element, options: CheckboxOptions = {}): CleanupFn {
  const { onChange } = options;

  const toggle = () => {
    const current = getState(el);
    const next = current === 'checked' ? 'unchecked' : 'checked';
    setState(el, next);
    onChange?.(next);
  };

  return combine(
    on(el as HTMLElement, 'click', toggle),
    onActivate(el, toggle)
  );
}

/**
 * Get current checkbox state
 */
export function getState(el: Element): CheckboxState {
  // Check aria-checked first
  const ariaChecked = attr(el, 'aria-checked');
  if (ariaChecked === 'true') return 'checked';
  if (ariaChecked === 'mixed') return 'indeterminate';
  if (ariaChecked === 'false') return 'unchecked';

  // Fallback to data-state
  const dataState = attr(el, 'data-state');
  if (dataState === 'checked') return 'checked';
  if (dataState === 'indeterminate') return 'indeterminate';

  return 'unchecked';
}

/**
 * Set checkbox state
 */
export function setState(el: Element, state: CheckboxState): void {
  // Update aria-checked
  const ariaValue = state === 'checked' ? 'true' : state === 'indeterminate' ? 'mixed' : 'false';
  attr(el, 'aria-checked', ariaValue);

  // Update data-state
  attr(el, 'data-state', state);
}

export type { CheckboxState };
