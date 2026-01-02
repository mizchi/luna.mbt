import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr } from '../core/dom';
import { onActivate } from '../core/keyboard';

export interface ToggleOptions {
  /**
   * Callback when pressed state changes
   */
  onChange?: (pressed: boolean) => void;
}

/**
 * Setup toggle button behavior
 *
 * Expected DOM structure:
 * ```html
 * <button data-toggle aria-pressed="false">
 *   Bold
 * </button>
 * ```
 */
export function setupToggle(el: Element, options: ToggleOptions = {}): CleanupFn {
  const { onChange } = options;

  const toggle = () => {
    const current = isPressed(el);
    setPressed(el, !current);
    onChange?.(!current);
  };

  return combine(
    on(el as HTMLElement, 'click', toggle),
    onActivate(el, toggle)
  );
}

/**
 * Check if toggle is pressed
 */
export function isPressed(toggle: Element): boolean {
  return attr(toggle, 'aria-pressed') === 'true' || attr(toggle, 'data-state') === 'on';
}

/**
 * Set pressed state
 */
export function setPressed(toggle: Element, pressed: boolean): void {
  attr(toggle, 'aria-pressed', pressed ? 'true' : 'false');
  attr(toggle, 'data-state', pressed ? 'on' : 'off');
}
