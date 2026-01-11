import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import {
  render,
  cleanup,
  getByRole,
  queryByRole,
  getAllByRole,
  getByText,
  getByLabelText,
  getByTestId,
  getCheckbox,
  getSwitch,
  getButton,
  getSlider,
  getTab,
  getRadio,
  getDialog,
  getAccessibleName,
  isVisible,
} from '../src';

describe('Queries', () => {
  afterEach(() => {
    cleanup();
  });

  describe('getByRole', () => {
    it('finds element by role', () => {
      const { container } = render(`<button role="button">Click me</button>`);
      const button = getByRole('button', { container });
      expect(button).toBeTruthy();
      expect(button.textContent).toBe('Click me');
    });

    it('filters by accessible name', () => {
      const { container } = render(`
        <button role="button" aria-label="Save">Save</button>
        <button role="button" aria-label="Cancel">Cancel</button>
      `);
      const saveBtn = getByRole('button', { container, name: 'Save' });
      expect(saveBtn.getAttribute('aria-label')).toBe('Save');
    });

    it('filters by pressed state', () => {
      const { container } = render(`
        <button role="button" aria-pressed="true">Pressed</button>
        <button role="button" aria-pressed="false">Not Pressed</button>
      `);
      const pressed = getByRole('button', { container, pressed: true });
      expect(pressed.textContent).toBe('Pressed');
    });

    it('filters by checked state', () => {
      const { container } = render(`
        <div role="checkbox" aria-checked="true" aria-label="Checked"></div>
        <div role="checkbox" aria-checked="false" aria-label="Unchecked"></div>
      `);
      const checked = getByRole('checkbox', { container, checked: true });
      expect(checked.getAttribute('aria-label')).toBe('Checked');
    });

    it('throws when not found', () => {
      const { container } = render(`<div>No button here</div>`);
      expect(() => getByRole('button', { container })).toThrow();
    });
  });

  describe('queryByRole', () => {
    it('returns null when not found', () => {
      const { container } = render(`<div>No button here</div>`);
      expect(queryByRole('button', { container })).toBeNull();
    });
  });

  describe('getAllByRole', () => {
    it('finds all elements with role', () => {
      const { container } = render(`
        <button role="button">One</button>
        <button role="button">Two</button>
        <button role="button">Three</button>
      `);
      const buttons = getAllByRole('button', { container });
      expect(buttons.length).toBe(3);
    });
  });

  describe('getByText', () => {
    it('finds element by exact text', () => {
      const { container } = render(`<span>Hello World</span>`);
      const el = getByText('Hello World', { container });
      expect(el.textContent).toBe('Hello World');
    });

    it('finds element by regex', () => {
      const { container } = render(`<span>Hello World 123</span>`);
      const el = getByText(/World \d+/, { container });
      expect(el).toBeTruthy();
    });
  });

  describe('getByLabelText', () => {
    it('finds by aria-label', () => {
      const { container } = render(`<input aria-label="Username" />`);
      const input = getByLabelText('Username', { container });
      expect(input.getAttribute('aria-label')).toBe('Username');
    });
  });

  describe('getByTestId', () => {
    it('finds by data-testid', () => {
      const { container } = render(`<div data-testid="my-element">Content</div>`);
      const el = getByTestId('my-element', { container });
      expect(el.textContent).toBe('Content');
    });
  });

  describe('APG-specific queries', () => {
    it('getCheckbox finds checkbox by label', () => {
      const { container } = render(`<div role="checkbox" aria-label="Accept terms" aria-checked="false"></div>`);
      const checkbox = getCheckbox('Accept terms', { container });
      expect(checkbox.getAttribute('role')).toBe('checkbox');
    });

    it('getSwitch finds switch by label', () => {
      const { container } = render(`<button role="switch" aria-label="Dark mode" aria-checked="false"></button>`);
      const sw = getSwitch('Dark mode', { container });
      expect(sw.getAttribute('role')).toBe('switch');
    });

    it('getButton finds button by text', () => {
      const { container } = render(`<button role="button">Submit</button>`);
      const btn = getButton('Submit', { container });
      expect(btn.textContent).toBe('Submit');
    });

    it('getSlider finds slider by label', () => {
      const { container } = render(`<div role="slider" aria-label="Volume" aria-valuenow="50"></div>`);
      const slider = getSlider('Volume', { container });
      expect(slider.getAttribute('role')).toBe('slider');
    });

    it('getTab finds tab by name', () => {
      const { container } = render(`<button role="tab" aria-label="Settings">Settings</button>`);
      const tab = getTab('Settings', { container });
      expect(tab.getAttribute('role')).toBe('tab');
    });

    it('getRadio finds radio by value', () => {
      const { container } = render(`
        <div role="radiogroup">
          <div role="radio" data-value="option1" aria-checked="true">Option 1</div>
          <div role="radio" data-value="option2" aria-checked="false">Option 2</div>
        </div>
      `);
      const radio = getRadio('option2', { container });
      expect(radio.textContent).toBe('Option 2');
    });

    it('getDialog finds dialog by label', () => {
      const { container } = render(`<div role="dialog" aria-label="Confirm">Are you sure?</div>`);
      const dialog = getDialog('Confirm', { container });
      expect(dialog.textContent).toBe('Are you sure?');
    });
  });

  describe('getAccessibleName', () => {
    it('gets aria-label', () => {
      const { container } = render(`<button role="button" aria-label="Close">X</button>`);
      const btn = getByRole('button', { container });
      expect(getAccessibleName(btn)).toBe('Close');
    });

    it('gets aria-labelledby', () => {
      const { container } = render(`
        <span id="label-test">My Label</span>
        <button role="button" aria-labelledby="label-test">Content</button>
      `);
      const btn = getByRole('button', { container });
      expect(getAccessibleName(btn)).toBe('My Label');
    });

    it('falls back to text content', () => {
      const { container } = render(`<button role="button">Click me</button>`);
      const btn = getByRole('button', { container });
      expect(getAccessibleName(btn)).toBe('Click me');
    });
  });

  describe('isVisible', () => {
    it('returns true for visible elements', () => {
      const { container } = render(`<div>Visible</div>`);
      const el = getByText('Visible', { container });
      expect(isVisible(el)).toBe(true);
    });

    it('returns false for hidden elements', () => {
      const { container } = render(`<div hidden>Hidden</div>`);
      const el = container.querySelector('[hidden]') as HTMLElement;
      expect(isVisible(el)).toBe(false);
    });

    it('returns false for aria-hidden elements', () => {
      const { container } = render(`<div aria-hidden="true">Hidden</div>`);
      const el = container.querySelector('[aria-hidden]') as HTMLElement;
      expect(isVisible(el)).toBe(false);
    });
  });
});
