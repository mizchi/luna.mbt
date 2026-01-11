import { describe, it, expect, beforeEach } from 'vitest';
import { setupCheckbox, getState, setState } from '../src/checkbox';

describe('Checkbox', () => {
  let el: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('button');
    el.setAttribute('data-checkbox', '');
    el.setAttribute('role', 'checkbox');
    el.setAttribute('aria-checked', 'false');
    document.body.appendChild(el);
  });

  it('should initialize with unchecked state', () => {
    expect(getState(el)).toBe('unchecked');
  });

  it('should toggle state on click', () => {
    const cleanup = setupCheckbox(el);

    el.click();
    expect(getState(el)).toBe('checked');
    expect(el.getAttribute('aria-checked')).toBe('true');

    el.click();
    expect(getState(el)).toBe('unchecked');
    expect(el.getAttribute('aria-checked')).toBe('false');

    cleanup();
  });

  it('should call onChange callback', () => {
    const states: string[] = [];
    const cleanup = setupCheckbox(el, {
      onChange: (state) => states.push(state),
    });

    el.click();
    el.click();

    expect(states).toEqual(['checked', 'unchecked']);
    cleanup();
  });

  it('should set state programmatically', () => {
    setState(el, 'checked');
    expect(getState(el)).toBe('checked');
    expect(el.getAttribute('aria-checked')).toBe('true');
    expect(el.getAttribute('data-state')).toBe('checked');

    setState(el, 'indeterminate');
    expect(getState(el)).toBe('indeterminate');
    expect(el.getAttribute('aria-checked')).toBe('mixed');
  });
});
