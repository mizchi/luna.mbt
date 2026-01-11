import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr } from '../core/dom';
import { onActivate } from '../core/keyboard';

export interface SwitchOptions {
  /**
   * Callback when switch state changes
   */
  onChange?: (checked: boolean) => void;
}

/**
 * Setup switch behavior on an element
 *
 * Expected DOM structure:
 * ```html
 * <button data-switch role="switch" aria-checked="false">
 *   <span data-switch-thumb></span>
 *   Enable feature
 * </button>
 * ```
 */
export function setupSwitch(el: Element, options: SwitchOptions = {}): CleanupFn {
  const { onChange } = options;

  const toggle = () => {
    const current = isChecked(el);
    const next = !current;
    setChecked(el, next);
    onChange?.(next);
  };

  return combine(
    on(el as HTMLElement, 'click', toggle),
    onActivate(el, toggle)
  );
}

/**
 * Check if switch is on
 */
export function isChecked(el: Element): boolean {
  const ariaChecked = attr(el, 'aria-checked');
  if (ariaChecked === 'true') return true;
  if (ariaChecked === 'false') return false;

  // Fallback to data-state
  const dataState = attr(el, 'data-state');
  return dataState === 'checked' || dataState === 'on';
}

/**
 * Set switch state
 */
export function setChecked(el: Element, checked: boolean): void {
  attr(el, 'aria-checked', checked ? 'true' : 'false');
  attr(el, 'data-state', checked ? 'checked' : 'unchecked');
}
