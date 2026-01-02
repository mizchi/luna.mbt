import { describe, it, expect, beforeEach } from 'vitest';
import { setupToggle, isPressed, setPressed } from '../src/toggle';

describe('Toggle', () => {
  let el: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('button');
    el.setAttribute('data-toggle', '');
    el.setAttribute('aria-pressed', 'false');
    document.body.appendChild(el);
  });

  it('should initialize as not pressed', () => {
    expect(isPressed(el)).toBe(false);
  });

  it('should toggle on click', () => {
    const cleanup = setupToggle(el);

    el.click();
    expect(isPressed(el)).toBe(true);
    expect(el.getAttribute('aria-pressed')).toBe('true');
    expect(el.getAttribute('data-state')).toBe('on');

    el.click();
    expect(isPressed(el)).toBe(false);
    expect(el.getAttribute('aria-pressed')).toBe('false');
    expect(el.getAttribute('data-state')).toBe('off');

    cleanup();
  });

  it('should call onChange callback', () => {
    const values: boolean[] = [];
    const cleanup = setupToggle(el, {
      onChange: (pressed) => values.push(pressed),
    });

    el.click();
    el.click();

    expect(values).toEqual([true, false]);
    cleanup();
  });

  it('should set pressed programmatically', () => {
    setPressed(el, true);
    expect(isPressed(el)).toBe(true);

    setPressed(el, false);
    expect(isPressed(el)).toBe(false);
  });
});
