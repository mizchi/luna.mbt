import { describe, it, expect, beforeEach } from 'vitest';
import { setupMenu, isOpen, setOpen } from '../src/menu';

describe('Menu', () => {
  let el: HTMLDivElement;
  let trigger: HTMLButtonElement;
  let content: HTMLDivElement;
  let item1: HTMLButtonElement;
  let item2: HTMLButtonElement;
  let item3: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-menu', '');

    trigger = document.createElement('button');
    trigger.setAttribute('data-menu-trigger', '');
    trigger.setAttribute('aria-haspopup', 'menu');
    trigger.setAttribute('aria-expanded', 'false');
    trigger.textContent = 'Menu';

    content = document.createElement('div');
    content.setAttribute('data-menu-content', '');
    content.setAttribute('role', 'menu');
    content.setAttribute('aria-hidden', 'true');

    item1 = document.createElement('button');
    item1.setAttribute('data-menu-item', '');
    item1.setAttribute('data-value', 'edit');
    item1.setAttribute('role', 'menuitem');
    item1.textContent = 'Edit';

    item2 = document.createElement('button');
    item2.setAttribute('data-menu-item', '');
    item2.setAttribute('data-value', 'delete');
    item2.setAttribute('role', 'menuitem');
    item2.textContent = 'Delete';

    item3 = document.createElement('button');
    item3.setAttribute('data-menu-item', '');
    item3.setAttribute('data-value', 'settings');
    item3.setAttribute('role', 'menuitem');
    item3.textContent = 'Settings';

    content.appendChild(item1);
    content.appendChild(item2);
    content.appendChild(item3);
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
    const cleanup = setupMenu(el);

    trigger.click();
    expect(isOpen(el)).toBe(true);

    trigger.click();
    expect(isOpen(el)).toBe(false);

    cleanup();
  });

  it('should select item on click', () => {
    const selections: string[] = [];
    const cleanup = setupMenu(el, {
      onSelect: (value) => selections.push(value),
    });

    trigger.click();
    item2.click();

    expect(isOpen(el)).toBe(false);
    expect(selections).toEqual(['delete']);

    cleanup();
  });

  it('should close on Escape', () => {
    const cleanup = setupMenu(el);

    trigger.click();
    expect(isOpen(el)).toBe(true);

    el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    expect(isOpen(el)).toBe(false);

    cleanup();
  });

  it('should call onOpenChange callback', () => {
    const states: boolean[] = [];
    const cleanup = setupMenu(el, {
      onOpenChange: (open) => states.push(open),
    });

    trigger.click();
    trigger.click();

    expect(states).toEqual([true, false]);

    cleanup();
  });

  it('should update ARIA attributes', () => {
    const cleanup = setupMenu(el);

    trigger.click();
    expect(trigger.getAttribute('aria-expanded')).toBe('true');
    expect(content.getAttribute('aria-hidden')).toBe('false');
    expect(content.getAttribute('data-state')).toBe('open');

    cleanup();
  });

  it('should focus first item on open', () => {
    const cleanup = setupMenu(el);

    trigger.click();
    expect(item1.getAttribute('data-focused')).toBe('true');

    cleanup();
  });
});
