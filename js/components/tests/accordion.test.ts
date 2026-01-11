import { describe, it, expect, beforeEach } from 'vitest';
import { setupAccordion, getItemOpen, setItemOpen, getOpenIds } from '../src/accordion';

describe('Accordion', () => {
  let el: HTMLDivElement;
  let item1: HTMLDivElement;
  let item2: HTMLDivElement;
  let trigger1: HTMLButtonElement;
  let trigger2: HTMLButtonElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-accordion', '');

    // Item 1
    item1 = document.createElement('div');
    item1.setAttribute('data-accordion-item', '');
    item1.setAttribute('data-item-id', 'item1');
    item1.setAttribute('data-state', 'closed');

    trigger1 = document.createElement('button');
    trigger1.setAttribute('data-accordion-trigger', '');
    trigger1.setAttribute('aria-expanded', 'false');
    item1.appendChild(trigger1);

    const content1 = document.createElement('div');
    content1.setAttribute('data-accordion-content', '');
    item1.appendChild(content1);

    // Item 2
    item2 = document.createElement('div');
    item2.setAttribute('data-accordion-item', '');
    item2.setAttribute('data-item-id', 'item2');
    item2.setAttribute('data-state', 'closed');

    trigger2 = document.createElement('button');
    trigger2.setAttribute('data-accordion-trigger', '');
    trigger2.setAttribute('aria-expanded', 'false');
    item2.appendChild(trigger2);

    const content2 = document.createElement('div');
    content2.setAttribute('data-accordion-content', '');
    item2.appendChild(content2);

    el.appendChild(item1);
    el.appendChild(item2);
    document.body.appendChild(el);
  });

  it('should initialize all items as closed', () => {
    expect(getItemOpen(item1)).toBe(false);
    expect(getItemOpen(item2)).toBe(false);
    expect(getOpenIds(el)).toEqual([]);
  });

  it('should open item on trigger click', () => {
    const cleanup = setupAccordion(el);

    trigger1.click();
    expect(getItemOpen(item1)).toBe(true);
    expect(trigger1.getAttribute('aria-expanded')).toBe('true');

    cleanup();
  });

  it('should close other items in single mode (default)', () => {
    const cleanup = setupAccordion(el);

    trigger1.click();
    expect(getOpenIds(el)).toEqual(['item1']);

    trigger2.click();
    expect(getOpenIds(el)).toEqual(['item2']);
    expect(getItemOpen(item1)).toBe(false);

    cleanup();
  });

  it('should allow multiple items open in multiple mode', () => {
    const cleanup = setupAccordion(el, { multiple: true });

    trigger1.click();
    trigger2.click();

    expect(getOpenIds(el)).toEqual(['item1', 'item2']);

    cleanup();
  });

  it('should initialize with defaultOpen items', () => {
    const cleanup = setupAccordion(el, { defaultOpen: ['item1'] });

    expect(getItemOpen(item1)).toBe(true);
    expect(getItemOpen(item2)).toBe(false);

    cleanup();
  });

  it('should call onChange callback', () => {
    const calls: string[][] = [];
    const cleanup = setupAccordion(el, {
      onChange: (ids) => calls.push([...ids]),
    });

    trigger1.click();
    trigger2.click();

    expect(calls).toEqual([['item1'], ['item2']]);
    cleanup();
  });

  it('should set item open programmatically', () => {
    setItemOpen(item1, true);
    expect(getItemOpen(item1)).toBe(true);

    setItemOpen(item1, false);
    expect(getItemOpen(item1)).toBe(false);
  });
});
