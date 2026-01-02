import type { CleanupFn } from '../core/types';
import { attr } from '../core/dom';

export interface ProgressOptions {
  /**
   * Callback when value changes
   */
  onChange?: (value: number) => void;
}

/**
 * Setup progress bar behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-progress role="progressbar"
 *      aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"
 *      data-value="50" data-max="100"
 *      style="--progress-percent: 50;">
 *   <div data-progress-indicator
 *        style="width: calc(var(--progress-percent) * 1%);"></div>
 * </div>
 * ```
 */
export function setupProgress(_el: Element, _options: ProgressOptions = {}): CleanupFn {
  // Progress is primarily CSS-driven, no JS behavior needed
  // This setup function exists for consistency and future enhancements
  return () => {};
}

/**
 * Get current progress value
 */
export function getValue(progress: Element): number {
  return parseFloat(attr(progress, 'aria-valuenow') ?? attr(progress, 'data-value') ?? '0');
}

/**
 * Get max value
 */
export function getMax(progress: Element): number {
  return parseFloat(attr(progress, 'aria-valuemax') ?? attr(progress, 'data-max') ?? '100');
}

/**
 * Set progress value
 */
export function setValue(progress: Element, value: number): void {
  const max = getMax(progress);
  const clamped = Math.max(0, Math.min(max, value));
  const percent = (clamped / max) * 100;

  attr(progress, 'data-value', String(clamped));
  attr(progress, 'aria-valuenow', String(clamped));
  (progress as HTMLElement).style.setProperty('--progress-percent', String(percent));
}

/**
 * Set indeterminate state
 */
export function setIndeterminate(progress: Element, indeterminate: boolean): void {
  if (indeterminate) {
    progress.removeAttribute('aria-valuenow');
    attr(progress, 'data-state', 'indeterminate');
  } else {
    attr(progress, 'data-state', 'determinate');
  }
}
