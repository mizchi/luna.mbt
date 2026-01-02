import { describe, it, expect, beforeEach } from 'vitest';
import { setupTabs, selectTab, getSelectedTab } from '../src/tabs';

describe('Tabs', () => {
  let el: HTMLDivElement;
  let tablist: HTMLDivElement;
  let tab1: HTMLButtonElement;
  let tab2: HTMLButtonElement;
  let panel1: HTMLDivElement;
  let panel2: HTMLDivElement;

  beforeEach(() => {
    el = document.createElement('div');
    el.setAttribute('data-tabs', '');

    tablist = document.createElement('div');
    tablist.setAttribute('data-tablist', '');
    tablist.setAttribute('role', 'tablist');

    tab1 = document.createElement('button');
    tab1.setAttribute('data-tab', '');
    tab1.setAttribute('data-tab-id', 'tab1');
    tab1.setAttribute('role', 'tab');
    tab1.setAttribute('aria-selected', 'true');

    tab2 = document.createElement('button');
    tab2.setAttribute('data-tab', '');
    tab2.setAttribute('data-tab-id', 'tab2');
    tab2.setAttribute('role', 'tab');
    tab2.setAttribute('aria-selected', 'false');

    tablist.appendChild(tab1);
    tablist.appendChild(tab2);

    panel1 = document.createElement('div');
    panel1.setAttribute('data-tabpanel', '');
    panel1.setAttribute('data-panel-id', 'tab1');
    panel1.setAttribute('role', 'tabpanel');

    panel2 = document.createElement('div');
    panel2.setAttribute('data-tabpanel', '');
    panel2.setAttribute('data-panel-id', 'tab2');
    panel2.setAttribute('role', 'tabpanel');
    panel2.setAttribute('hidden', '');

    el.appendChild(tablist);
    el.appendChild(panel1);
    el.appendChild(panel2);
    document.body.appendChild(el);
  });

  it('should get selected tab', () => {
    expect(getSelectedTab(el)).toBe('tab1');
  });

  it('should select tab on click', () => {
    const cleanup = setupTabs(el);

    tab2.click();
    expect(getSelectedTab(el)).toBe('tab2');
    expect(tab2.getAttribute('aria-selected')).toBe('true');
    expect(tab1.getAttribute('aria-selected')).toBe('false');
    expect(panel2.hasAttribute('hidden')).toBe(false);
    expect(panel1.hasAttribute('hidden')).toBe(true);

    cleanup();
  });

  it('should call onChange callback', () => {
    const tabs: string[] = [];
    const cleanup = setupTabs(el, {
      onChange: (id) => tabs.push(id),
    });

    tab2.click();
    tab1.click();

    expect(tabs).toEqual(['tab2', 'tab1']);
    cleanup();
  });

  it('should initialize with defaultTab', () => {
    const cleanup = setupTabs(el, { defaultTab: 'tab2' });

    expect(getSelectedTab(el)).toBe('tab2');
    cleanup();
  });

  it('should select tab programmatically', () => {
    selectTab(el, 'tab2');

    expect(getSelectedTab(el)).toBe('tab2');
    expect(tab2.getAttribute('aria-selected')).toBe('true');
    expect(panel2.hasAttribute('hidden')).toBe(false);
  });
});
