import { describe, it, expect, beforeEach } from 'vitest';
import { getValue, setValue, getMax, setIndeterminate } from '../src/progress';

describe('Progress', () => {
  let el: HTMLDivElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-progress', '');
    el.setAttribute('role', 'progressbar');
    el.setAttribute('aria-valuenow', '50');
    el.setAttribute('aria-valuemin', '0');
    el.setAttribute('aria-valuemax', '100');
    el.setAttribute('data-value', '50');
    el.setAttribute('data-max', '100');
    document.body.appendChild(el);
  });

  it('should get current value', () => {
    expect(getValue(el)).toBe(50);
  });

  it('should get max value', () => {
    expect(getMax(el)).toBe(100);
  });

  it('should set value', () => {
    setValue(el, 75);

    expect(getValue(el)).toBe(75);
    expect(el.getAttribute('aria-valuenow')).toBe('75');
    expect(el.getAttribute('data-value')).toBe('75');
    expect(el.style.getPropertyValue('--progress-percent')).toBe('75');
  });

  it('should clamp value to min/max', () => {
    setValue(el, 150);
    expect(getValue(el)).toBe(100);

    setValue(el, -10);
    expect(getValue(el)).toBe(0);
  });

  it('should set indeterminate state', () => {
    setIndeterminate(el, true);
    expect(el.getAttribute('data-state')).toBe('indeterminate');
    expect(el.hasAttribute('aria-valuenow')).toBe(false);

    setIndeterminate(el, false);
    expect(el.getAttribute('data-state')).toBe('determinate');
  });
});
