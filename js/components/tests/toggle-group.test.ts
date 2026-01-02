import { describe, it, expect, beforeEach } from 'vitest';
import { setupToggleGroup, getValues, setValues } from '../src/toggle-group';

describe('ToggleGroup', () => {
  let el: HTMLDivElement;
  let item1: HTMLButtonElement;
  let item2: HTMLButtonElement;
  let item3: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-toggle-group', '');
    el.setAttribute('role', 'group');

    item1 = document.createElement('button');
    item1.setAttribute('data-toggle-item', '');
    item1.setAttribute('data-value', 'bold');
    item1.setAttribute('aria-pressed', 'false');

    item2 = document.createElement('button');
    item2.setAttribute('data-toggle-item', '');
    item2.setAttribute('data-value', 'italic');
    item2.setAttribute('aria-pressed', 'false');

    item3 = document.createElement('button');
    item3.setAttribute('data-toggle-item', '');
    item3.setAttribute('data-value', 'underline');
    item3.setAttribute('aria-pressed', 'false');

    el.appendChild(item1);
    el.appendChild(item2);
    el.appendChild(item3);
    document.body.appendChild(el);
  });

  it('should initialize with no selection', () => {
    expect(getValues(el)).toEqual([]);
  });

  it('should select single item in single mode (default)', () => {
    const cleanup = setupToggleGroup(el);

    item1.click();
    expect(getValues(el)).toEqual(['bold']);

    item2.click();
    expect(getValues(el)).toEqual(['italic']);
    expect(item1.getAttribute('aria-pressed')).toBe('false');

    cleanup();
  });

  it('should allow multiple selection in multiple mode', () => {
    const cleanup = setupToggleGroup(el, { multiple: true });

    item1.click();
    item2.click();

    expect(getValues(el)).toEqual(['bold', 'italic']);

    cleanup();
  });

  it('should toggle item off in multiple mode', () => {
    const cleanup = setupToggleGroup(el, { multiple: true });

    item1.click();
    item1.click();

    expect(getValues(el)).toEqual([]);

    cleanup();
  });

  it('should call onChange callback', () => {
    const calls: string[][] = [];
    const cleanup = setupToggleGroup(el, {
      onChange: (values) => calls.push([...values]),
    });

    item1.click();
    item2.click();

    expect(calls).toEqual([['bold'], ['italic']]);
    cleanup();
  });

  it('should set values programmatically', () => {
    setValues(el, ['bold', 'underline']);

    expect(getValues(el)).toEqual(['bold', 'underline']);
    expect(item1.getAttribute('aria-pressed')).toBe('true');
    expect(item2.getAttribute('aria-pressed')).toBe('false');
    expect(item3.getAttribute('aria-pressed')).toBe('true');
  });
});
