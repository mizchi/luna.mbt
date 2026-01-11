import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  render,
  cleanup,
  getByRole,
  click,
  dblClick,
  keyDown,
  keyUp,
  keyPress,
  type,
  pressEnter,
  pressSpace,
  pressEscape,
  pressArrowUp,
  pressArrowDown,
  pressArrowLeft,
  pressArrowRight,
  focus,
  blur,
  change,
  clear,
  user,
} from '../src';

describe('Events', () => {
  afterEach(() => {
    cleanup();
  });

  describe('click', () => {
    it('triggers click event', () => {
      const onClick = vi.fn();
      render(`<button id="btn">Click me</button>`);
      const btn = document.getElementById('btn')!;
      btn.addEventListener('click', onClick);

      click(btn);
      expect(onClick).toHaveBeenCalledTimes(1);
    });
  });

  describe('dblClick', () => {
    it('triggers dblclick event', () => {
      const onDblClick = vi.fn();
      render(`<button id="btn">Double click</button>`);
      const btn = document.getElementById('btn')!;
      btn.addEventListener('dblclick', onDblClick);

      dblClick(btn);
      expect(onDblClick).toHaveBeenCalledTimes(1);
    });
  });

  describe('keyboard events', () => {
    it('keyDown triggers keydown event', () => {
      const onKeyDown = vi.fn();
      render(`<input id="input" />`);
      const input = document.getElementById('input')!;
      input.addEventListener('keydown', onKeyDown);

      keyDown(input, 'Enter');
      expect(onKeyDown).toHaveBeenCalledTimes(1);
      expect(onKeyDown.mock.calls[0][0].key).toBe('Enter');
    });

    it('keyUp triggers keyup event', () => {
      const onKeyUp = vi.fn();
      render(`<input id="input" />`);
      const input = document.getElementById('input')!;
      input.addEventListener('keyup', onKeyUp);

      keyUp(input, 'a');
      expect(onKeyUp).toHaveBeenCalledTimes(1);
    });

    it('keyPress triggers both keydown and keyup', () => {
      const onKeyDown = vi.fn();
      const onKeyUp = vi.fn();
      render(`<input id="input" />`);
      const input = document.getElementById('input')!;
      input.addEventListener('keydown', onKeyDown);
      input.addEventListener('keyup', onKeyUp);

      keyPress(input, 'x');
      expect(onKeyDown).toHaveBeenCalledTimes(1);
      expect(onKeyUp).toHaveBeenCalledTimes(1);
    });

    it('supports modifier keys', () => {
      const onKeyDown = vi.fn();
      render(`<input id="input" />`);
      const input = document.getElementById('input')!;
      input.addEventListener('keydown', onKeyDown);

      keyDown(input, { key: 's', ctrlKey: true });
      const event = onKeyDown.mock.calls[0][0];
      expect(event.key).toBe('s');
      expect(event.ctrlKey).toBe(true);
    });
  });

  describe('key shortcuts', () => {
    it('pressEnter triggers Enter key', () => {
      const onKeyDown = vi.fn();
      render(`<button id="btn">OK</button>`);
      const btn = document.getElementById('btn')!;
      btn.addEventListener('keydown', onKeyDown);

      pressEnter(btn);
      expect(onKeyDown.mock.calls[0][0].key).toBe('Enter');
    });

    it('pressSpace triggers Space key', () => {
      const onKeyDown = vi.fn();
      render(`<button id="btn">OK</button>`);
      const btn = document.getElementById('btn')!;
      btn.addEventListener('keydown', onKeyDown);

      pressSpace(btn);
      expect(onKeyDown.mock.calls[0][0].key).toBe(' ');
    });

    it('pressEscape triggers Escape key', () => {
      const onKeyDown = vi.fn();
      render(`<div id="dialog">Dialog</div>`);
      const dialog = document.getElementById('dialog')!;
      dialog.addEventListener('keydown', onKeyDown);

      pressEscape(dialog);
      expect(onKeyDown.mock.calls[0][0].key).toBe('Escape');
    });

    it('arrow keys work correctly', () => {
      const onKeyDown = vi.fn();
      render(`<div id="el" tabindex="0">Element</div>`);
      const el = document.getElementById('el')!;
      el.addEventListener('keydown', onKeyDown);

      pressArrowUp(el);
      expect(onKeyDown.mock.calls[0][0].key).toBe('ArrowUp');

      pressArrowDown(el);
      expect(onKeyDown.mock.calls[1][0].key).toBe('ArrowDown');

      pressArrowLeft(el);
      expect(onKeyDown.mock.calls[2][0].key).toBe('ArrowLeft');

      pressArrowRight(el);
      expect(onKeyDown.mock.calls[3][0].key).toBe('ArrowRight');
    });
  });

  describe('type', () => {
    it('types into input element', () => {
      render(`<input id="input" />`);
      const input = document.getElementById('input') as HTMLInputElement;

      type(input, 'hello');
      expect(input.value).toBe('hello');
    });
  });

  describe('focus/blur', () => {
    it('focus focuses element', () => {
      render(`<input id="input" />`);
      const input = document.getElementById('input')!;

      focus(input);
      expect(document.activeElement).toBe(input);
    });

    it('blur blurs element', () => {
      render(`<input id="input" />`);
      const input = document.getElementById('input')!;
      input.focus();

      blur(input);
      expect(document.activeElement).not.toBe(input);
    });
  });

  describe('form events', () => {
    it('change updates value and triggers event', () => {
      const onChange = vi.fn();
      render(`<input id="input" />`);
      const input = document.getElementById('input') as HTMLInputElement;
      input.addEventListener('change', onChange);

      change(input, 'new value');
      expect(input.value).toBe('new value');
      expect(onChange).toHaveBeenCalledTimes(1);
    });

    it('clear empties input', () => {
      render(`<input id="input" value="existing" />`);
      const input = document.getElementById('input') as HTMLInputElement;

      clear(input);
      expect(input.value).toBe('');
    });
  });

  describe('user helper', () => {
    it('provides unified interface', () => {
      render(`<button id="btn">Click</button>`);
      const btn = document.getElementById('btn')!;
      const onClick = vi.fn();
      btn.addEventListener('click', onClick);

      user.click(btn);
      expect(onClick).toHaveBeenCalled();
    });

    it('keyboard shortcuts are accessible', () => {
      const onKeyDown = vi.fn();
      render(`<input id="input" />`);
      const input = document.getElementById('input')!;
      input.addEventListener('keydown', onKeyDown);

      user.keyboard.enter(input);
      expect(onKeyDown.mock.calls[0][0].key).toBe('Enter');
    });
  });
});
