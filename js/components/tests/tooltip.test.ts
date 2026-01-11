import { describe, it, expect, beforeEach, vi } from 'vitest';
import { setupTooltip, isVisible, setVisible } from '../src/tooltip';

describe('Tooltip', () => {
  let el: HTMLDivElement;
  let trigger: HTMLButtonElement;
  let content: HTMLDivElement;

  beforeEach(() => {
    vi.useFakeTimers();

    el = document.createElement('div');
    el.setAttribute('data-tooltip', '');

    trigger = document.createElement('button');
    trigger.setAttribute('data-tooltip-trigger', '');
    trigger.textContent = 'Hover me';

    content = document.createElement('div');
    content.setAttribute('data-tooltip-content', '');
    content.setAttribute('role', 'tooltip');
    content.setAttribute('aria-hidden', 'true');
    content.textContent = 'Tooltip text';

    el.appendChild(trigger);
    el.appendChild(content);
    document.body.appendChild(el);
  });

  it('should check visibility state', () => {
    expect(isVisible(el)).toBe(false);

    setVisible(el, true);
    expect(isVisible(el)).toBe(true);

    setVisible(el, false);
    expect(isVisible(el)).toBe(false);
  });

  it('should update aria-hidden on visibility change', () => {
    setVisible(el, true);
    expect(content.getAttribute('aria-hidden')).toBe('false');
    expect(content.getAttribute('data-state')).toBe('open');

    setVisible(el, false);
    expect(content.getAttribute('aria-hidden')).toBe('true');
    expect(content.getAttribute('data-state')).toBe('closed');
  });

  it('should show on mouseenter after delay', () => {
    const cleanup = setupTooltip(el, { showDelay: 300 });

    trigger.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
    expect(isVisible(el)).toBe(false);

    vi.advanceTimersByTime(300);
    expect(isVisible(el)).toBe(true);

    cleanup();
  });

  it('should hide on mouseleave after delay', () => {
    const cleanup = setupTooltip(el, { showDelay: 0, hideDelay: 100 });

    trigger.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
    vi.advanceTimersByTime(0);
    expect(isVisible(el)).toBe(true);

    trigger.dispatchEvent(new MouseEvent('mouseleave', { bubbles: true }));
    expect(isVisible(el)).toBe(true); // Still visible during delay

    vi.advanceTimersByTime(100);
    expect(isVisible(el)).toBe(false);

    cleanup();
  });

  it('should show on focus', () => {
    const cleanup = setupTooltip(el, { showDelay: 0 });

    trigger.dispatchEvent(new FocusEvent('focus', { bubbles: true }));
    vi.advanceTimersByTime(0);
    expect(isVisible(el)).toBe(true);

    cleanup();
  });

  it('should hide on blur', () => {
    const cleanup = setupTooltip(el, { showDelay: 0, hideDelay: 0 });

    trigger.dispatchEvent(new FocusEvent('focus', { bubbles: true }));
    vi.advanceTimersByTime(0);
    expect(isVisible(el)).toBe(true);

    trigger.dispatchEvent(new FocusEvent('blur', { bubbles: true }));
    vi.advanceTimersByTime(0);
    expect(isVisible(el)).toBe(false);

    cleanup();
  });

  it('should call onChange callback', () => {
    const changes: boolean[] = [];
    const cleanup = setupTooltip(el, {
      showDelay: 0,
      hideDelay: 0,
      onChange: (visible) => changes.push(visible),
    });

    trigger.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
    vi.advanceTimersByTime(0);

    trigger.dispatchEvent(new MouseEvent('mouseleave', { bubbles: true }));
    vi.advanceTimersByTime(0);

    expect(changes).toEqual([true, false]);

    cleanup();
  });

  it('should hide immediately on Escape', () => {
    const cleanup = setupTooltip(el, { showDelay: 0, hideDelay: 1000 });

    trigger.dispatchEvent(new MouseEvent('mouseenter', { bubbles: true }));
    vi.advanceTimersByTime(0);
    expect(isVisible(el)).toBe(true);

    trigger.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    expect(isVisible(el)).toBe(false); // Immediately, no delay

    cleanup();
  });
});
