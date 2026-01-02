import { describe, it, expect, beforeEach } from 'vitest';
import { setupSelect, isOpen, setOpen, getValue, setValue } from '../src/select';

describe('Select', () => {
  let el: HTMLDivElement;
  let trigger: HTMLButtonElement;
  let content: HTMLDivElement;
  let valueDisplay: HTMLSpanElement;
  let item1: HTMLDivElement;
  let item2: HTMLDivElement;
  let item3: HTMLDivElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-select', '');

    trigger = document.createElement('button');
    trigger.setAttribute('data-select-trigger', '');
    trigger.setAttribute('aria-haspopup', 'listbox');
    trigger.setAttribute('aria-expanded', 'false');

    valueDisplay = document.createElement('span');
    valueDisplay.setAttribute('data-select-value', '');
    valueDisplay.textContent = 'Select an option';
    trigger.appendChild(valueDisplay);

    content = document.createElement('div');
    content.setAttribute('data-select-content', '');
    content.setAttribute('role', 'listbox');
    content.setAttribute('aria-hidden', 'true');

    item1 = document.createElement('div');
    item1.setAttribute('data-select-item', '');
    item1.setAttribute('data-value', 'option1');
    item1.setAttribute('role', 'option');
    item1.textContent = 'Option 1';

    item2 = document.createElement('div');
    item2.setAttribute('data-select-item', '');
    item2.setAttribute('data-value', 'option2');
    item2.setAttribute('role', 'option');
    item2.textContent = 'Option 2';

    item3 = document.createElement('div');
    item3.setAttribute('data-select-item', '');
    item3.setAttribute('data-value', 'option3');
    item3.setAttribute('role', 'option');
    item3.textContent = 'Option 3';

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
    const cleanup = setupSelect(el);

    trigger.click();
    expect(isOpen(el)).toBe(true);

    trigger.click();
    expect(isOpen(el)).toBe(false);

    cleanup();
  });

  it('should select item on click', () => {
    const values: string[] = [];
    const cleanup = setupSelect(el, {
      onChange: (value) => values.push(value),
    });

    trigger.click(); // Open
    item2.click();

    expect(getValue(el)).toBe('option2');
    expect(isOpen(el)).toBe(false);
    expect(values).toEqual(['option2']);

    cleanup();
  });

  it('should update value display on selection', () => {
    const cleanup = setupSelect(el);

    trigger.click();
    item2.click();

    expect(valueDisplay.textContent).toBe('Option 2');

    cleanup();
  });

  it('should set value programmatically', () => {
    setValue(el, 'option3');

    expect(getValue(el)).toBe('option3');
    expect(item3.getAttribute('data-state')).toBe('selected');
    expect(item3.getAttribute('aria-selected')).toBe('true');
    expect(valueDisplay.textContent).toBe('Option 3');
  });

  it('should close on Escape', () => {
    const cleanup = setupSelect(el);

    trigger.click();
    expect(isOpen(el)).toBe(true);

    el.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    expect(isOpen(el)).toBe(false);

    cleanup();
  });

  it('should call onOpenChange callback', () => {
    const states: boolean[] = [];
    const cleanup = setupSelect(el, {
      onOpenChange: (open) => states.push(open),
    });

    trigger.click();
    trigger.click();

    expect(states).toEqual([true, false]);

    cleanup();
  });
});
