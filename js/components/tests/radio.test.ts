import { describe, it, expect, beforeEach } from 'vitest';
import { setupRadio, getValue, setValue } from '../src/radio-group';

describe('RadioGroup', () => {
  let el: HTMLDivElement;
  let item1: HTMLDivElement;
  let item2: HTMLDivElement;
  let item3: HTMLDivElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('role', 'radiogroup');
    el.setAttribute('data-radio-group', '');

    // Custom elements (no native inputs)
    item1 = document.createElement('div');
    item1.setAttribute('role', 'radio');
    item1.setAttribute('data-radio-item', '');
    item1.setAttribute('data-value', 'option1');
    item1.setAttribute('aria-checked', 'true');
    item1.setAttribute('tabindex', '0');
    const indicator1 = document.createElement('span');
    indicator1.setAttribute('data-radio-indicator', '');
    indicator1.style.display = 'block';
    item1.appendChild(indicator1);

    item2 = document.createElement('div');
    item2.setAttribute('role', 'radio');
    item2.setAttribute('data-radio-item', '');
    item2.setAttribute('data-value', 'option2');
    item2.setAttribute('aria-checked', 'false');
    item2.setAttribute('tabindex', '-1');
    const indicator2 = document.createElement('span');
    indicator2.setAttribute('data-radio-indicator', '');
    indicator2.style.display = 'none';
    item2.appendChild(indicator2);

    item3 = document.createElement('div');
    item3.setAttribute('role', 'radio');
    item3.setAttribute('data-radio-item', '');
    item3.setAttribute('data-value', 'option3');
    item3.setAttribute('aria-checked', 'false');
    item3.setAttribute('tabindex', '-1');
    const indicator3 = document.createElement('span');
    indicator3.setAttribute('data-radio-indicator', '');
    indicator3.style.display = 'none';
    item3.appendChild(indicator3);

    el.appendChild(item1);
    el.appendChild(item2);
    el.appendChild(item3);
    document.body.appendChild(el);
  });

  it('should get current value', () => {
    expect(getValue(el)).toBe('option1');
  });

  it('should select item on click', () => {
    const cleanup = setupRadio(el);

    item2.click();
    expect(getValue(el)).toBe('option2');
    expect(item2.getAttribute('aria-checked')).toBe('true');
    expect(item1.getAttribute('aria-checked')).toBe('false');

    cleanup();
  });

  it('should call onChange callback', () => {
    const values: string[] = [];
    const cleanup = setupRadio(el, {
      onChange: (value) => values.push(value),
    });

    item2.click();
    item3.click();

    expect(values).toEqual(['option2', 'option3']);
    cleanup();
  });

  it('should set value programmatically', () => {
    setValue(el, 'option3');

    expect(getValue(el)).toBe('option3');
    expect(item3.getAttribute('aria-checked')).toBe('true');
    expect(item1.getAttribute('aria-checked')).toBe('false');
    expect(item2.getAttribute('aria-checked')).toBe('false');
  });

  it('should update indicators', () => {
    const cleanup = setupRadio(el);

    item2.click();

    const indicator1 = item1.querySelector('[data-radio-indicator]') as HTMLElement;
    const indicator2 = item2.querySelector('[data-radio-indicator]') as HTMLElement;

    expect(indicator1.style.display).toBe('none');
    expect(indicator2.style.display).toBe('block');

    cleanup();
  });
});
