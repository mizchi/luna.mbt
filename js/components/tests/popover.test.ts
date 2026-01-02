import { describe, it, expect, beforeEach } from 'vitest';
import { setupPopover, isOpen, setOpen } from '../src/popover';

describe('Popover', () => {
  let el: HTMLDivElement;
  let trigger: HTMLButtonElement;
  let content: HTMLDivElement;
  let closeBtn: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-popover', '');

    trigger = document.createElement('button');
    trigger.setAttribute('data-popover-trigger', '');
    trigger.setAttribute('aria-haspopup', 'dialog');
    trigger.setAttribute('aria-expanded', 'false');
    trigger.textContent = 'Open Popover';

    content = document.createElement('div');
    content.setAttribute('data-popover-content', '');
    content.setAttribute('role', 'dialog');
    content.setAttribute('aria-hidden', 'true');

    closeBtn = document.createElement('button');
    closeBtn.setAttribute('data-popover-close', '');
    closeBtn.textContent = 'Close';
    content.appendChild(closeBtn);

    el.appendChild(trigger);
    el.appendChild(content);
    document.body.appendChild(el);
  });

  it('should check open state', () => {
    expect(isOpen(el)).toBe(false);

    setOpen(el, true);
    expect(isOpen(el)).toBe(true);

    setOpen(el, false);
    expect(isOpen(el)).toBe(false);
  });

  it('should toggle on trigger click', () => {
    const cleanup = setupPopover(el);

    trigger.click();
    expect(isOpen(el)).toBe(true);

    trigger.click();
    expect(isOpen(el)).toBe(false);

    cleanup();
  });

  it('should close on close button click', () => {
    const cleanup = setupPopover(el);

    trigger.click();
    expect(isOpen(el)).toBe(true);

    closeBtn.click();
    expect(isOpen(el)).toBe(false);

    cleanup();
  });

  it('should close on Escape', () => {
    const cleanup = setupPopover(el);

    trigger.click();
    expect(isOpen(el)).toBe(true);

    el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    expect(isOpen(el)).toBe(false);

    cleanup();
  });

  it('should call onOpenChange callback', () => {
    const states: boolean[] = [];
    const cleanup = setupPopover(el, {
      onOpenChange: (open) => states.push(open),
    });

    trigger.click();
    trigger.click();

    expect(states).toEqual([true, false]);

    cleanup();
  });

  it('should update ARIA attributes', () => {
    const cleanup = setupPopover(el);

    trigger.click();
    expect(trigger.getAttribute('aria-expanded')).toBe('true');
    expect(content.getAttribute('aria-hidden')).toBe('false');
    expect(content.getAttribute('data-state')).toBe('open');

    trigger.click();
    expect(trigger.getAttribute('aria-expanded')).toBe('false');
    expect(content.getAttribute('aria-hidden')).toBe('true');
    expect(content.getAttribute('data-state')).toBe('closed');

    cleanup();
  });
});
