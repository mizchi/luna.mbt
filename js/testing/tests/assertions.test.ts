import { describe, it, expect, afterEach } from 'vitest';
import {
  render,
  cleanup,
  isChecked,
  isMixed,
  isPressed,
  isSelected,
  isExpanded,
  isDisabled,
  isHidden,
  hasFocus,
  getSliderValue,
  getSliderMin,
  getSliderMax,
  getRadioValue,
  getSelectedTabIndex,
  hasAccessibleName,
  hasRequiredAriaAttributes,
  isFocusable,
} from '../src';

describe('Assertions', () => {
  afterEach(() => {
    cleanup();
  });

  describe('isChecked', () => {
    it('returns true for aria-checked="true"', () => {
      render(`<div role="checkbox" aria-checked="true" id="cb"></div>`);
      const cb = document.getElementById('cb') as HTMLElement;
      expect(isChecked(cb)).toBe(true);
    });

    it('returns false for aria-checked="false"', () => {
      render(`<div role="checkbox" aria-checked="false" id="cb"></div>`);
      const cb = document.getElementById('cb') as HTMLElement;
      expect(isChecked(cb)).toBe(false);
    });

    it('returns true for checked input', () => {
      render(`<input type="checkbox" checked id="cb" />`);
      const cb = document.getElementById('cb') as HTMLInputElement;
      expect(isChecked(cb)).toBe(true);
    });
  });

  describe('isMixed', () => {
    it('returns true for aria-checked="mixed"', () => {
      render(`<div role="checkbox" aria-checked="mixed" id="cb"></div>`);
      const cb = document.getElementById('cb') as HTMLElement;
      expect(isMixed(cb)).toBe(true);
    });
  });

  describe('isPressed', () => {
    it('returns true for aria-pressed="true"', () => {
      render(`<button aria-pressed="true" id="btn">Toggle</button>`);
      const btn = document.getElementById('btn') as HTMLElement;
      expect(isPressed(btn)).toBe(true);
    });
  });

  describe('isSelected', () => {
    it('returns true for aria-selected="true"', () => {
      render(`<button role="tab" aria-selected="true" id="tab">Tab</button>`);
      const tab = document.getElementById('tab') as HTMLElement;
      expect(isSelected(tab)).toBe(true);
    });
  });

  describe('isExpanded', () => {
    it('returns true for aria-expanded="true"', () => {
      render(`<button aria-expanded="true" id="btn">Expand</button>`);
      const btn = document.getElementById('btn') as HTMLElement;
      expect(isExpanded(btn)).toBe(true);
    });
  });

  describe('isDisabled', () => {
    it('returns true for aria-disabled="true"', () => {
      render(`<div aria-disabled="true" id="el">Disabled</div>`);
      const el = document.getElementById('el') as HTMLElement;
      expect(isDisabled(el)).toBe(true);
    });

    it('returns true for disabled button', () => {
      render(`<button disabled id="btn">Disabled</button>`);
      const btn = document.getElementById('btn') as HTMLButtonElement;
      expect(isDisabled(btn)).toBe(true);
    });
  });

  describe('isHidden', () => {
    it('returns true for hidden attribute', () => {
      render(`<div hidden id="el">Hidden</div>`);
      const el = document.getElementById('el') as HTMLElement;
      expect(isHidden(el)).toBe(true);
    });

    it('returns true for aria-hidden="true"', () => {
      render(`<div aria-hidden="true" id="el">Hidden</div>`);
      const el = document.getElementById('el') as HTMLElement;
      expect(isHidden(el)).toBe(true);
    });
  });

  describe('hasFocus', () => {
    it('returns true when element has focus', () => {
      render(`<input id="input" />`);
      const input = document.getElementById('input') as HTMLElement;
      input.focus();
      expect(hasFocus(input)).toBe(true);
    });
  });

  describe('slider values', () => {
    it('getSliderValue returns aria-valuenow', () => {
      render(`<div role="slider" aria-valuenow="75" id="slider"></div>`);
      const slider = document.getElementById('slider') as HTMLElement;
      expect(getSliderValue(slider)).toBe(75);
    });

    it('getSliderMin returns aria-valuemin', () => {
      render(`<div role="slider" aria-valuemin="10" id="slider"></div>`);
      const slider = document.getElementById('slider') as HTMLElement;
      expect(getSliderMin(slider)).toBe(10);
    });

    it('getSliderMax returns aria-valuemax', () => {
      render(`<div role="slider" aria-valuemax="200" id="slider"></div>`);
      const slider = document.getElementById('slider') as HTMLElement;
      expect(getSliderMax(slider)).toBe(200);
    });
  });

  describe('getRadioValue', () => {
    it('returns selected radio value', () => {
      render(`
        <div id="group" role="radiogroup">
          <div role="radio" data-value="a" aria-checked="false"></div>
          <div role="radio" data-value="b" aria-checked="true"></div>
          <div role="radio" data-value="c" aria-checked="false"></div>
        </div>
      `);
      const group = document.getElementById('group') as HTMLElement;
      expect(getRadioValue(group)).toBe('b');
    });
  });

  describe('getSelectedTabIndex', () => {
    it('returns index of selected tab', () => {
      render(`
        <div id="tablist" role="tablist">
          <button role="tab" aria-selected="false">Tab 1</button>
          <button role="tab" aria-selected="true">Tab 2</button>
          <button role="tab" aria-selected="false">Tab 3</button>
        </div>
      `);
      const tablist = document.getElementById('tablist') as HTMLElement;
      expect(getSelectedTabIndex(tablist)).toBe(1);
    });
  });

  describe('hasAccessibleName', () => {
    it('returns true for aria-label', () => {
      render(`<button aria-label="Close" id="btn">X</button>`);
      const btn = document.getElementById('btn') as HTMLElement;
      expect(hasAccessibleName(btn)).toBe(true);
    });

    it('returns true for aria-labelledby', () => {
      render(`
        <span id="label">Label</span>
        <button aria-labelledby="label" id="btn"></button>
      `);
      const btn = document.getElementById('btn') as HTMLElement;
      expect(hasAccessibleName(btn)).toBe(true);
    });

    it('returns true for text content', () => {
      render(`<button id="btn">Click me</button>`);
      const btn = document.getElementById('btn') as HTMLElement;
      expect(hasAccessibleName(btn)).toBe(true);
    });
  });

  describe('hasRequiredAriaAttributes', () => {
    it('validates checkbox', () => {
      render(`<div role="checkbox" id="cb"></div>`);
      const cb = document.getElementById('cb') as HTMLElement;
      const result = hasRequiredAriaAttributes(cb);
      expect(result.valid).toBe(false);
      expect(result.missing).toContain('aria-checked');
    });

    it('validates complete checkbox', () => {
      render(`<div role="checkbox" aria-checked="false" id="cb"></div>`);
      const cb = document.getElementById('cb') as HTMLElement;
      const result = hasRequiredAriaAttributes(cb);
      expect(result.valid).toBe(true);
    });

    it('validates slider', () => {
      render(`<div role="slider" id="slider"></div>`);
      const slider = document.getElementById('slider') as HTMLElement;
      const result = hasRequiredAriaAttributes(slider);
      expect(result.valid).toBe(false);
      expect(result.missing).toContain('aria-valuenow');
      expect(result.missing).toContain('aria-valuemin');
      expect(result.missing).toContain('aria-valuemax');
    });
  });

  describe('isFocusable', () => {
    it('returns true for tabindex="0"', () => {
      render(`<div tabindex="0" id="el">Focusable</div>`);
      const el = document.getElementById('el') as HTMLElement;
      expect(isFocusable(el)).toBe(true);
    });

    it('returns false for tabindex="-1"', () => {
      render(`<div tabindex="-1" id="el">Not focusable</div>`);
      const el = document.getElementById('el') as HTMLElement;
      expect(isFocusable(el)).toBe(false);
    });

    it('returns true for enabled button', () => {
      render(`<button id="btn">Button</button>`);
      const btn = document.getElementById('btn') as HTMLElement;
      expect(isFocusable(btn)).toBe(true);
    });

    it('returns false for disabled button', () => {
      render(`<button disabled id="btn">Button</button>`);
      const btn = document.getElementById('btn') as HTMLElement;
      expect(isFocusable(btn)).toBe(false);
    });
  });
});
