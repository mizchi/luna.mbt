import { describe, it, expect, beforeEach } from 'vitest';
import { setupDialog, isOpen, setOpen, openDialog, closeDialog } from '../src/dialog';

describe('Dialog', () => {
  let el: HTMLDivElement;
  let overlay: HTMLDivElement;
  let content: HTMLDivElement;
  let closeBtn: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-dialog', '');
    el.setAttribute('role', 'dialog');
    el.setAttribute('aria-modal', 'true');
    el.setAttribute('aria-hidden', 'true');

    overlay = document.createElement('div');
    overlay.setAttribute('data-dialog-overlay', '');

    content = document.createElement('div');
    content.setAttribute('data-dialog-content', '');

    closeBtn = document.createElement('button');
    closeBtn.setAttribute('data-dialog-close', '');
    closeBtn.textContent = 'Close';
    content.appendChild(closeBtn);

    el.appendChild(overlay);
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

  it('should update aria-hidden on open/close', () => {
    setOpen(el, true);
    expect(el.getAttribute('aria-hidden')).toBe('false');
    expect(el.getAttribute('data-state')).toBe('open');

    setOpen(el, false);
    expect(el.getAttribute('aria-hidden')).toBe('true');
    expect(el.getAttribute('data-state')).toBe('closed');
  });

  it('should close on close button click', () => {
    const closeCalls: number[] = [];
    const cleanup = setupDialog(el, {
      onClose: () => closeCalls.push(1),
    });

    openDialog(el);
    expect(isOpen(el)).toBe(true);

    closeBtn.click();
    expect(isOpen(el)).toBe(false);
    expect(closeCalls).toHaveLength(1);

    cleanup();
  });

  it('should close on overlay click', () => {
    const cleanup = setupDialog(el, { closeOnOverlay: true });

    openDialog(el);
    expect(isOpen(el)).toBe(true);

    overlay.click();
    expect(isOpen(el)).toBe(false);

    cleanup();
  });

  it('should not close on overlay click when disabled', () => {
    const cleanup = setupDialog(el, { closeOnOverlay: false });

    openDialog(el);
    overlay.click();
    expect(isOpen(el)).toBe(true);

    cleanup();
  });

  it('should close on Escape key', () => {
    const cleanup = setupDialog(el, { closeOnEscape: true });

    openDialog(el);
    expect(isOpen(el)).toBe(true);

    el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    expect(isOpen(el)).toBe(false);

    cleanup();
  });
});
