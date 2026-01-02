import { describe, it, expect, beforeEach } from 'vitest';
import { setupSlider, getValue, setValue } from '../src/slider';

describe('Slider', () => {
  let el: HTMLDivElement;
  let track: HTMLDivElement;
  let thumb: HTMLDivElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-slider', '');
    el.setAttribute('role', 'slider');
    el.setAttribute('data-value', '50');
    el.setAttribute('data-min', '0');
    el.setAttribute('data-max', '100');
    el.setAttribute('data-step', '1');
    el.setAttribute('aria-valuenow', '50');
    el.setAttribute('aria-valuemin', '0');
    el.setAttribute('aria-valuemax', '100');

    track = document.createElement('div');
    track.setAttribute('data-slider-track', '');

    const range = document.createElement('div');
    range.setAttribute('data-slider-range', '');
    track.appendChild(range);

    thumb = document.createElement('div');
    thumb.setAttribute('data-slider-thumb', '');
    thumb.setAttribute('tabindex', '0');

    el.appendChild(track);
    el.appendChild(thumb);
    document.body.appendChild(el);
  });

  it('should get current value', () => {
    expect(getValue(el)).toBe(50);
  });

  it('should set value programmatically', () => {
    setValue(el, 75);

    expect(getValue(el)).toBe(75);
    expect(el.getAttribute('aria-valuenow')).toBe('75');
    expect(el.getAttribute('data-value')).toBe('75');
    expect(el.style.getPropertyValue('--slider-percent')).toBe('75');
  });

  it('should clamp value to min/max', () => {
    setValue(el, 150);
    expect(getValue(el)).toBe(100);

    setValue(el, -10);
    expect(getValue(el)).toBe(0);
  });

  it('should snap to step', () => {
    el.setAttribute('data-step', '10');
    setValue(el, 47);
    expect(getValue(el)).toBe(50);

    setValue(el, 43);
    expect(getValue(el)).toBe(40);
  });

  it('should call onChange callback on keyboard input', () => {
    const values: number[] = [];
    const cleanup = setupSlider(el, {
      onChange: (value) => values.push(value),
    });

    // Simulate keyboard events on thumb
    thumb.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }));
    expect(values).toContain(51);

    cleanup();
  });

  it('should handle Home/End keys', () => {
    const cleanup = setupSlider(el);

    thumb.dispatchEvent(new KeyboardEvent('keydown', { key: 'Home', bubbles: true }));
    expect(getValue(el)).toBe(0);

    thumb.dispatchEvent(new KeyboardEvent('keydown', { key: 'End', bubbles: true }));
    expect(getValue(el)).toBe(100);

    cleanup();
  });
});
