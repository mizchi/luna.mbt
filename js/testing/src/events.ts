/**
 * Event simulation utilities for testing Luna components
 */

// =============================================================================
// Click events
// =============================================================================

/**
 * Simulate a click event on an element
 */
export function click(el: HTMLElement): void {
  el.click();
}

/**
 * Simulate a double click event
 */
export function dblClick(el: HTMLElement): void {
  el.dispatchEvent(new MouseEvent('dblclick', { bubbles: true, cancelable: true }));
}

// =============================================================================
// Keyboard events
// =============================================================================

export type KeyOptions = {
  key: string;
  code?: string;
  ctrlKey?: boolean;
  shiftKey?: boolean;
  altKey?: boolean;
  metaKey?: boolean;
};

/**
 * Simulate a keydown event
 */
export function keyDown(el: HTMLElement, options: KeyOptions | string): void {
  const opts = typeof options === 'string' ? { key: options } : options;
  el.dispatchEvent(new KeyboardEvent('keydown', {
    key: opts.key,
    code: opts.code ?? opts.key,
    ctrlKey: opts.ctrlKey ?? false,
    shiftKey: opts.shiftKey ?? false,
    altKey: opts.altKey ?? false,
    metaKey: opts.metaKey ?? false,
    bubbles: true,
    cancelable: true,
  }));
}

/**
 * Simulate a keyup event
 */
export function keyUp(el: HTMLElement, options: KeyOptions | string): void {
  const opts = typeof options === 'string' ? { key: options } : options;
  el.dispatchEvent(new KeyboardEvent('keyup', {
    key: opts.key,
    code: opts.code ?? opts.key,
    ctrlKey: opts.ctrlKey ?? false,
    shiftKey: opts.shiftKey ?? false,
    altKey: opts.altKey ?? false,
    metaKey: opts.metaKey ?? false,
    bubbles: true,
    cancelable: true,
  }));
}

/**
 * Simulate a keypress (keydown + keyup)
 */
export function keyPress(el: HTMLElement, options: KeyOptions | string): void {
  keyDown(el, options);
  keyUp(el, options);
}

/**
 * Type a string character by character
 */
export function type(el: HTMLElement, text: string): void {
  if (el instanceof HTMLInputElement || el instanceof HTMLTextAreaElement) {
    el.focus();
    for (const char of text) {
      keyDown(el, char);
      el.value += char;
      el.dispatchEvent(new Event('input', { bubbles: true }));
      keyUp(el, char);
    }
  } else {
    for (const char of text) {
      keyPress(el, char);
    }
  }
}

// =============================================================================
// Common key sequences
// =============================================================================

/**
 * Press Enter key
 */
export function pressEnter(el: HTMLElement): void {
  keyPress(el, 'Enter');
}

/**
 * Press Space key
 */
export function pressSpace(el: HTMLElement): void {
  keyPress(el, ' ');
}

/**
 * Press Escape key
 */
export function pressEscape(el: HTMLElement): void {
  keyPress(el, 'Escape');
}

/**
 * Press Tab key
 */
export function pressTab(el: HTMLElement, options?: { shiftKey?: boolean }): void {
  keyPress(el, { key: 'Tab', shiftKey: options?.shiftKey });
}

/**
 * Press Arrow keys
 */
export function pressArrowUp(el: HTMLElement): void {
  keyPress(el, 'ArrowUp');
}

export function pressArrowDown(el: HTMLElement): void {
  keyPress(el, 'ArrowDown');
}

export function pressArrowLeft(el: HTMLElement): void {
  keyPress(el, 'ArrowLeft');
}

export function pressArrowRight(el: HTMLElement): void {
  keyPress(el, 'ArrowRight');
}

/**
 * Press Home/End keys
 */
export function pressHome(el: HTMLElement): void {
  keyPress(el, 'Home');
}

export function pressEnd(el: HTMLElement): void {
  keyPress(el, 'End');
}

/**
 * Press PageUp/PageDown keys
 */
export function pressPageUp(el: HTMLElement): void {
  keyPress(el, 'PageUp');
}

export function pressPageDown(el: HTMLElement): void {
  keyPress(el, 'PageDown');
}

// =============================================================================
// Focus events
// =============================================================================

/**
 * Focus an element
 */
export function focus(el: HTMLElement): void {
  el.focus();
}

/**
 * Blur an element
 */
export function blur(el: HTMLElement): void {
  el.blur();
}

// =============================================================================
// Form events
// =============================================================================

/**
 * Change value of an input
 */
export function change(el: HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement, value: string): void {
  el.value = value;
  el.dispatchEvent(new Event('change', { bubbles: true }));
  el.dispatchEvent(new Event('input', { bubbles: true }));
}

/**
 * Clear input value
 */
export function clear(el: HTMLInputElement | HTMLTextAreaElement): void {
  el.value = '';
  el.dispatchEvent(new Event('input', { bubbles: true }));
}

/**
 * Select option in a select element
 */
export function selectOption(el: HTMLSelectElement, value: string): void {
  el.value = value;
  el.dispatchEvent(new Event('change', { bubbles: true }));
}

// =============================================================================
// User event helper (combines common patterns)
// =============================================================================

export const user = {
  click,
  dblClick,
  type,
  clear,
  selectOption,
  keyboard: {
    press: keyPress,
    down: keyDown,
    up: keyUp,
    enter: pressEnter,
    space: pressSpace,
    escape: pressEscape,
    tab: pressTab,
    arrowUp: pressArrowUp,
    arrowDown: pressArrowDown,
    arrowLeft: pressArrowLeft,
    arrowRight: pressArrowRight,
    home: pressHome,
    end: pressEnd,
    pageUp: pressPageUp,
    pageDown: pressPageDown,
  },
  focus,
  blur,
};
