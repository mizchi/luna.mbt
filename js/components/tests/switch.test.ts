import { describe, it, expect, beforeEach } from 'vitest';
import { setupSwitch, isChecked, setChecked } from '../src/switch';

describe('Switch', () => {
  let el: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('button');
    el.setAttribute('data-switch', '');
    el.setAttribute('role', 'switch');
    el.setAttribute('aria-checked', 'false');
    document.body.appendChild(el);
  });

  it('should initialize as unchecked', () => {
    expect(isChecked(el)).toBe(false);
  });

  it('should toggle on click', () => {
    const cleanup = setupSwitch(el);

    el.click();
    expect(isChecked(el)).toBe(true);
    expect(el.getAttribute('aria-checked')).toBe('true');

    el.click();
    expect(isChecked(el)).toBe(false);

    cleanup();
  });

  it('should call onChange callback', () => {
    const values: boolean[] = [];
    const cleanup = setupSwitch(el, {
      onChange: (checked) => values.push(checked),
    });

    el.click();
    el.click();

    expect(values).toEqual([true, false]);
    cleanup();
  });

  it('should set checked programmatically', () => {
    setChecked(el, true);
    expect(isChecked(el)).toBe(true);

    setChecked(el, false);
    expect(isChecked(el)).toBe(false);
  });
});
