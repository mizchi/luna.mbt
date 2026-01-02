import { describe, it, expect, beforeEach } from 'vitest';
import { setupCollapsible, isOpen, setOpen, toggle } from '../src/collapsible';

describe('Collapsible', () => {
  let el: HTMLDivElement;
  let trigger: HTMLButtonElement;
  let content: HTMLDivElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-collapsible', '');
    el.setAttribute('data-state', 'closed');

    trigger = document.createElement('button');
    trigger.setAttribute('data-collapsible-trigger', '');
    trigger.setAttribute('aria-expanded', 'false');

    content = document.createElement('div');
    content.setAttribute('data-collapsible-content', '');
    content.setAttribute('aria-hidden', 'true');

    el.appendChild(trigger);
    el.appendChild(content);
    document.body.appendChild(el);
  });

  it('should initialize as closed', () => {
    expect(isOpen(el)).toBe(false);
  });

  it('should open on trigger click', () => {
    const cleanup = setupCollapsible(el);

    trigger.click();
    expect(isOpen(el)).toBe(true);
    expect(trigger.getAttribute('aria-expanded')).toBe('true');
    expect(content.getAttribute('aria-hidden')).toBe('false');

    cleanup();
  });

  it('should close when already open', () => {
    const cleanup = setupCollapsible(el);

    trigger.click(); // open
    trigger.click(); // close

    expect(isOpen(el)).toBe(false);
    cleanup();
  });

  it('should initialize as open with defaultOpen', () => {
    const cleanup = setupCollapsible(el, { defaultOpen: true });

    expect(isOpen(el)).toBe(true);
    cleanup();
  });

  it('should call onChange callback', () => {
    const states: boolean[] = [];
    const cleanup = setupCollapsible(el, {
      onChange: (open) => states.push(open),
    });

    trigger.click();
    trigger.click();

    expect(states).toEqual([true, false]);
    cleanup();
  });

  it('should set open programmatically', () => {
    setOpen(el, true);
    expect(isOpen(el)).toBe(true);

    setOpen(el, false);
    expect(isOpen(el)).toBe(false);
  });

  it('should toggle programmatically', () => {
    expect(toggle(el)).toBe(true);
    expect(isOpen(el)).toBe(true);

    expect(toggle(el)).toBe(false);
    expect(isOpen(el)).toBe(false);
  });
});
