/**
 * drag - Horizontal drag helper for sliders/range inputs
 *
 * Handles mouse and touch drag interactions.
 * Updates CSS custom property for visual positioning.
 */

export interface DragOptions {
  /**
   * Selector for the track element (defines drag bounds).
   * Required for calculating position.
   */
  track: string;

  /**
   * CSS custom property to update with percentage (0-100).
   * @default '--slider-percent'
   */
  cssProperty?: string;

  /**
   * Attribute to update with the calculated value.
   * @default 'data-value'
   */
  attribute?: string;

  /**
   * Minimum value.
   * @default 0
   */
  min?: number;

  /**
   * Maximum value.
   * @default 100
   */
  max?: number;

  /**
   * Step increment (for keyboard navigation).
   * @default 1
   */
  step?: number;

  /**
   * Selector for value display element.
   * If provided, its textContent will be updated.
   */
  display?: string;

  /**
   * Callback when value changes.
   */
  onChange?: (value: number, percent: number, element: Element) => void;
}

/**
 * Set up drag behavior for slider-like components
 *
 * @example
 * ```ts
 * // Basic slider
 * drag(el, '[data-slider]', {
 *   track: '[data-slider-track]',
 *   display: '[data-slider-value]'
 * });
 *
 * // Custom range
 * drag(el, '[data-range]', {
 *   track: '[data-range-track]',
 *   min: -50,
 *   max: 50,
 *   cssProperty: '--range-position',
 *   onChange: (value) => console.log('Value:', value)
 * });
 * ```
 */
export function drag(
  root: Element,
  selector: string,
  options: DragOptions
): () => void {
  const {
    track: trackSelector,
    cssProperty = '--slider-percent',
    attribute = 'data-value',
    min = 0,
    max = 100,
    step = 1,
    display: displaySelector,
    onChange,
  } = options;

  const cleanups: Array<() => void> = [];

  root.querySelectorAll(selector).forEach((slider) => {
    const track = slider.querySelector(trackSelector);
    const thumb = slider.querySelector('[data-slider-thumb]');
    const display = displaySelector ? root.querySelector(displaySelector) : null;

    if (!track) return;

    // Get initial value from attribute
    let value = parseInt(slider.getAttribute(attribute) || '50', 10);

    const update = (val: number) => {
      // Clamp value
      value = Math.max(min, Math.min(max, val));
      const pct = ((value - min) / (max - min)) * 100;

      // Update attribute
      slider.setAttribute(attribute, String(value));

      // Update aria
      slider.setAttribute('aria-valuenow', String(value));

      // Update CSS custom property
      (slider as HTMLElement).style.setProperty(cssProperty, String(pct));

      // Update display
      if (display) {
        display.textContent = String(value);
      }

      onChange?.(value, pct, slider);
    };

    // Set initial CSS property
    const initialPct = ((value - min) / (max - min)) * 100;
    (slider as HTMLElement).style.setProperty(cssProperty, String(initialPct));

    // Calculate value from position
    const calcValue = (clientX: number): number => {
      const rect = track.getBoundingClientRect();
      const pct = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
      return Math.round(min + pct * (max - min));
    };

    // Drag handlers
    const handleDrag = (e: MouseEvent | TouchEvent) => {
      const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
      update(calcValue(clientX));
    };

    const handleStart = (e: MouseEvent | TouchEvent) => {
      e.preventDefault();
      handleDrag(e);

      const handleMove = (e: MouseEvent | TouchEvent) => handleDrag(e);
      const handleEnd = () => {
        document.removeEventListener('mousemove', handleMove);
        document.removeEventListener('mouseup', handleEnd);
        document.removeEventListener('touchmove', handleMove as EventListener);
        document.removeEventListener('touchend', handleEnd);
      };

      document.addEventListener('mousemove', handleMove);
      document.addEventListener('mouseup', handleEnd);
      document.addEventListener('touchmove', handleMove as EventListener);
      document.addEventListener('touchend', handleEnd);
    };

    // Attach to track
    track.addEventListener('mousedown', handleStart as EventListener);
    track.addEventListener('touchstart', handleStart as EventListener);

    // Attach to thumb if exists
    if (thumb) {
      thumb.addEventListener('mousedown', handleStart as EventListener);
      thumb.addEventListener('touchstart', handleStart as EventListener);
    }

    // Keyboard navigation
    const handleKeydown = (e: KeyboardEvent) => {
      switch (e.key) {
        case 'ArrowRight':
        case 'ArrowUp':
          update(value + step);
          e.preventDefault();
          break;
        case 'ArrowLeft':
        case 'ArrowDown':
          update(value - step);
          e.preventDefault();
          break;
        case 'Home':
          update(min);
          e.preventDefault();
          break;
        case 'End':
          update(max);
          e.preventDefault();
          break;
      }
    };

    if (thumb) {
      thumb.addEventListener('keydown', handleKeydown as EventListener);
    }

    // Cleanup
    cleanups.push(() => {
      track.removeEventListener('mousedown', handleStart as EventListener);
      track.removeEventListener('touchstart', handleStart as EventListener);
      if (thumb) {
        thumb.removeEventListener('mousedown', handleStart as EventListener);
        thumb.removeEventListener('touchstart', handleStart as EventListener);
        thumb.removeEventListener('keydown', handleKeydown as EventListener);
      }
    });
  });

  return () => cleanups.forEach((fn) => fn());
}
