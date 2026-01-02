import { describe, it, expect, beforeEach } from 'vitest';
import { setupAlertDialog, isOpen, setOpen, openAlertDialog, closeAlertDialog } from '../src/alert-dialog';

describe('AlertDialog', () => {
  let el: HTMLDivElement;
  let overlay: HTMLDivElement;
  let content: HTMLDivElement;
  let confirmBtn: HTMLButtonElement;
  let cancelBtn: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-alert-dialog', '');
    el.setAttribute('role', 'alertdialog');
    el.setAttribute('aria-modal', 'true');
    el.setAttribute('aria-hidden', 'true');

    overlay = document.createElement('div');
    overlay.setAttribute('data-alert-dialog-overlay', '');

    content = document.createElement('div');
    content.setAttribute('data-alert-dialog-content', '');

    const title = document.createElement('h2');
    title.setAttribute('data-alert-dialog-title', '');
    title.textContent = 'Are you sure?';

    const description = document.createElement('p');
    description.setAttribute('data-alert-dialog-description', '');
    description.textContent = 'This action cannot be undone.';

    const actions = document.createElement('div');
    actions.setAttribute('data-alert-dialog-actions', '');

    cancelBtn = document.createElement('button');
    cancelBtn.setAttribute('data-alert-dialog-cancel', '');
    cancelBtn.textContent = 'Cancel';

    confirmBtn = document.createElement('button');
    confirmBtn.setAttribute('data-alert-dialog-confirm', '');
    confirmBtn.textContent = 'Confirm';

    actions.appendChild(cancelBtn);
    actions.appendChild(confirmBtn);
    content.appendChild(title);
    content.appendChild(description);
    content.appendChild(actions);
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

  it('should call onConfirm and close on confirm button click', () => {
    const confirmCalls: number[] = [];
    const closeCalls: number[] = [];
    const cleanup = setupAlertDialog(el, {
      onConfirm: () => confirmCalls.push(1),
      onClose: () => closeCalls.push(1),
    });

    openAlertDialog(el);
    expect(isOpen(el)).toBe(true);

    confirmBtn.click();
    expect(isOpen(el)).toBe(false);
    expect(confirmCalls).toHaveLength(1);
    expect(closeCalls).toHaveLength(1);

    cleanup();
  });

  it('should call onCancel and close on cancel button click', () => {
    const cancelCalls: number[] = [];
    const closeCalls: number[] = [];
    const cleanup = setupAlertDialog(el, {
      onCancel: () => cancelCalls.push(1),
      onClose: () => closeCalls.push(1),
    });

    openAlertDialog(el);
    cancelBtn.click();

    expect(isOpen(el)).toBe(false);
    expect(cancelCalls).toHaveLength(1);
    expect(closeCalls).toHaveLength(1);

    cleanup();
  });

  it('should call onCancel on Escape key', () => {
    const cancelCalls: number[] = [];
    const cleanup = setupAlertDialog(el, {
      onCancel: () => cancelCalls.push(1),
    });

    openAlertDialog(el);
    expect(isOpen(el)).toBe(true);

    el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    expect(isOpen(el)).toBe(false);
    expect(cancelCalls).toHaveLength(1);

    cleanup();
  });

  it('should NOT close on overlay click (unlike regular dialog)', () => {
    const cleanup = setupAlertDialog(el);

    openAlertDialog(el);
    expect(isOpen(el)).toBe(true);

    // Alert dialogs should not close on overlay click
    overlay.click();
    expect(isOpen(el)).toBe(true);

    cleanup();
  });

  it('should open/close programmatically', () => {
    const cleanup = setupAlertDialog(el);

    expect(isOpen(el)).toBe(false);

    openAlertDialog(el);
    expect(isOpen(el)).toBe(true);

    closeAlertDialog(el);
    expect(isOpen(el)).toBe(false);

    cleanup();
  });
});
