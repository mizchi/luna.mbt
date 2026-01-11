import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query } from '../core/dom';

export interface SliderOptions {
  /**
   * Callback when value changes
   */
  onChange?: (value: number) => void;

  /**
   * Callback when drag starts
   */
  onDragStart?: () => void;

  /**
   * Callback when drag ends
   */
  onDragEnd?: () => void;
}

/**
 * Setup slider behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-slider data-value="50" data-min="0" data-max="100" data-step="1"
 *      role="slider" aria-valuenow="50" aria-valuemin="0" aria-valuemax="100"
 *      style="--slider-percent: 50;">
 *   <div data-slider-track>
 *     <div data-slider-range></div>
 *   </div>
 *   <div data-slider-thumb tabindex="0"></div>
 * </div>
 * ```
 *
 * CSS should use:
 * - `--slider-percent` for thumb/range positioning
 * - `[data-slider-range] { width: calc(var(--slider-percent) * 1%); }`
 * - `[data-slider-thumb] { left: calc(var(--slider-percent) * 1%); }`
 */
export function setupSlider(el: Element, options: SliderOptions = {}): CleanupFn {
  const { onChange, onDragStart, onDragEnd } = options;

  const slider = el as HTMLElement;
  const thumb = query<HTMLElement>(el, '[data-slider-thumb]');
  const track = query<HTMLElement>(el, '[data-slider-track]');

  if (!thumb || !track) return () => {};

  // Read initial values from attributes
  const getConfig = () => ({
    min: parseFloat(attr(slider, 'data-min') ?? '0'),
    max: parseFloat(attr(slider, 'data-max') ?? '100'),
    step: parseFloat(attr(slider, 'data-step') ?? '1'),
  });

  const getValue = (): number => {
    return parseFloat(attr(slider, 'data-value') ?? attr(slider, 'aria-valuenow') ?? '0');
  };

  const setValue = (value: number): void => {
    const { min, max, step } = getConfig();

    // Clamp and snap to step
    let newValue = Math.max(min, Math.min(max, value));
    newValue = Math.round((newValue - min) / step) * step + min;
    newValue = Math.max(min, Math.min(max, newValue)); // Re-clamp after step

    const percent = ((newValue - min) / (max - min)) * 100;

    // Update attributes
    attr(slider, 'data-value', String(newValue));
    attr(slider, 'aria-valuenow', String(newValue));
    slider.style.setProperty('--slider-percent', String(percent));

    // Update value display if exists
    const parent = slider.parentElement;
    if (parent) {
      const valueDisplay = query(parent, '[data-slider-value]');
      if (valueDisplay) {
        valueDisplay.textContent = String(newValue);
      }
    }

    onChange?.(newValue);
  };

  // Calculate value from position
  const getValueFromPosition = (clientX: number): number => {
    const rect = track.getBoundingClientRect();
    const { min, max } = getConfig();
    const percent = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
    return min + percent * (max - min);
  };

  // Drag handling
  let isDragging = false;

  const startDrag = (e: MouseEvent | TouchEvent) => {
    e.preventDefault();
    isDragging = true;
    slider.setAttribute('data-dragging', 'true');
    thumb.focus();
    onDragStart?.();

    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    setValue(getValueFromPosition(clientX));
  };

  const moveDrag = (e: MouseEvent | TouchEvent) => {
    if (!isDragging) return;
    e.preventDefault();
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    setValue(getValueFromPosition(clientX));
  };

  const endDrag = () => {
    if (!isDragging) return;
    isDragging = false;
    slider.removeAttribute('data-dragging');
    onDragEnd?.();
  };

  // Keyboard handling
  const handleKeydown = (e: KeyboardEvent) => {
    const { min, max, step } = getConfig();
    const current = getValue();
    let newValue = current;

    switch (e.key) {
      case 'ArrowRight':
      case 'ArrowUp':
        e.preventDefault();
        newValue = current + step;
        break;
      case 'ArrowLeft':
      case 'ArrowDown':
        e.preventDefault();
        newValue = current - step;
        break;
      case 'Home':
        e.preventDefault();
        newValue = min;
        break;
      case 'End':
        e.preventDefault();
        newValue = max;
        break;
      case 'PageUp':
        e.preventDefault();
        newValue = current + step * 10;
        break;
      case 'PageDown':
        e.preventDefault();
        newValue = current - step * 10;
        break;
      default:
        return;
    }

    setValue(newValue);
  };

  const cleanups: CleanupFn[] = [];

  // Mouse events
  cleanups.push(on(thumb, 'mousedown', startDrag));
  cleanups.push(on(track, 'mousedown', startDrag));
  cleanups.push(on(document, 'mousemove', moveDrag));
  cleanups.push(on(document, 'mouseup', endDrag));

  // Touch events
  cleanups.push(on(thumb, 'touchstart', startDrag, { passive: false }));
  cleanups.push(on(track, 'touchstart', startDrag, { passive: false }));
  cleanups.push(on(document, 'touchmove', moveDrag, { passive: false }));
  cleanups.push(on(document, 'touchend', endDrag));

  // Keyboard events
  cleanups.push(on(thumb, 'keydown', handleKeydown));

  return combine(...cleanups);
}

/**
 * Get current slider value
 */
export function getValue(slider: Element): number {
  return parseFloat(attr(slider, 'data-value') ?? attr(slider, 'aria-valuenow') ?? '0');
}

/**
 * Set slider value programmatically
 */
export function setValue(slider: Element, value: number): void {
  const min = parseFloat(attr(slider, 'data-min') ?? '0');
  const max = parseFloat(attr(slider, 'data-max') ?? '100');
  const step = parseFloat(attr(slider, 'data-step') ?? '1');

  let newValue = Math.max(min, Math.min(max, value));
  newValue = Math.round((newValue - min) / step) * step + min;
  newValue = Math.max(min, Math.min(max, newValue));

  const percent = ((newValue - min) / (max - min)) * 100;

  attr(slider, 'data-value', String(newValue));
  attr(slider, 'aria-valuenow', String(newValue));
  (slider as HTMLElement).style.setProperty('--slider-percent', String(percent));
}
