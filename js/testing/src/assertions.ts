/**
 * Assertion utilities for testing Luna components
 * These are designed to work with vitest/jest expect
 */

// =============================================================================
// State assertions
// =============================================================================

/**
 * Check if element is checked (checkbox, switch, radio)
 */
export function isChecked(el: HTMLElement): boolean {
  const ariaChecked = el.getAttribute('aria-checked');
  if (ariaChecked === 'true') return true;
  if (el instanceof HTMLInputElement) return el.checked;
  return false;
}

/**
 * Check if element is in indeterminate/mixed state
 */
export function isMixed(el: HTMLElement): boolean {
  return el.getAttribute('aria-checked') === 'mixed';
}

/**
 * Check if element is pressed (toggle button)
 */
export function isPressed(el: HTMLElement): boolean {
  return el.getAttribute('aria-pressed') === 'true';
}

/**
 * Check if element is selected (tab, option)
 */
export function isSelected(el: HTMLElement): boolean {
  return el.getAttribute('aria-selected') === 'true';
}

/**
 * Check if element is expanded (accordion, disclosure)
 */
export function isExpanded(el: HTMLElement): boolean {
  return el.getAttribute('aria-expanded') === 'true';
}

/**
 * Check if element is disabled
 */
export function isDisabled(el: HTMLElement): boolean {
  if (el.getAttribute('aria-disabled') === 'true') return true;
  if (el instanceof HTMLButtonElement || el instanceof HTMLInputElement) {
    return el.disabled;
  }
  return false;
}

/**
 * Check if element is hidden
 */
export function isHidden(el: HTMLElement): boolean {
  if (el.hidden) return true;
  if (el.getAttribute('aria-hidden') === 'true') return true;
  return false;
}

/**
 * Check if element has focus
 */
export function hasFocus(el: HTMLElement): boolean {
  return document.activeElement === el;
}

// =============================================================================
// Value assertions
// =============================================================================

/**
 * Get slider value
 */
export function getSliderValue(el: HTMLElement): number {
  const value = el.getAttribute('aria-valuenow');
  return value ? parseFloat(value) : 0;
}

/**
 * Get slider min value
 */
export function getSliderMin(el: HTMLElement): number {
  const value = el.getAttribute('aria-valuemin');
  return value ? parseFloat(value) : 0;
}

/**
 * Get slider max value
 */
export function getSliderMax(el: HTMLElement): number {
  const value = el.getAttribute('aria-valuemax');
  return value ? parseFloat(value) : 100;
}

/**
 * Get radio group selected value
 */
export function getRadioValue(container: HTMLElement): string | null {
  const selected = container.querySelector('[role="radio"][aria-checked="true"]');
  return selected?.getAttribute('data-value') ?? null;
}

/**
 * Get selected tab index
 */
export function getSelectedTabIndex(tablist: HTMLElement): number {
  const tabs = tablist.querySelectorAll('[role="tab"]');
  for (let i = 0; i < tabs.length; i++) {
    if (tabs[i].getAttribute('aria-selected') === 'true') {
      return i;
    }
  }
  return -1;
}

// =============================================================================
// Accessibility assertions
// =============================================================================

/**
 * Check if element has accessible name
 */
export function hasAccessibleName(el: HTMLElement): boolean {
  if (el.getAttribute('aria-label')) return true;
  if (el.getAttribute('aria-labelledby')) return true;
  if (el.textContent?.trim()) return true;
  return false;
}

/**
 * Get accessible name of element
 */
export function getAccessibleName(el: HTMLElement): string {
  const ariaLabel = el.getAttribute('aria-label');
  if (ariaLabel) return ariaLabel;

  const labelledby = el.getAttribute('aria-labelledby');
  if (labelledby) {
    const labels = labelledby.split(' ')
      .map(id => document.getElementById(id)?.textContent?.trim() ?? '')
      .filter(Boolean);
    return labels.join(' ');
  }

  return el.textContent?.trim() ?? '';
}

/**
 * Check if element has required ARIA attributes for its role
 */
export function hasRequiredAriaAttributes(el: HTMLElement): { valid: boolean; missing: string[] } {
  const role = el.getAttribute('role');
  const missing: string[] = [];

  switch (role) {
    case 'checkbox':
    case 'switch':
      if (!el.getAttribute('aria-checked')) missing.push('aria-checked');
      break;
    case 'slider':
      if (!el.getAttribute('aria-valuenow')) missing.push('aria-valuenow');
      if (!el.getAttribute('aria-valuemin')) missing.push('aria-valuemin');
      if (!el.getAttribute('aria-valuemax')) missing.push('aria-valuemax');
      break;
    case 'tab':
      if (!el.getAttribute('aria-selected')) missing.push('aria-selected');
      if (!el.getAttribute('aria-controls')) missing.push('aria-controls');
      break;
    case 'tabpanel':
      if (!el.getAttribute('aria-labelledby')) missing.push('aria-labelledby');
      break;
    case 'dialog':
      if (!el.getAttribute('aria-label') && !el.getAttribute('aria-labelledby')) {
        missing.push('aria-label or aria-labelledby');
      }
      break;
    case 'radio':
      if (!el.getAttribute('aria-checked')) missing.push('aria-checked');
      break;
    case 'meter':
      if (!el.getAttribute('aria-valuenow')) missing.push('aria-valuenow');
      break;
  }

  return { valid: missing.length === 0, missing };
}

/**
 * Check keyboard focusability
 */
export function isFocusable(el: HTMLElement): boolean {
  const tabindex = el.getAttribute('tabindex');
  if (tabindex === '-1') return false;
  if (tabindex !== null && parseInt(tabindex) >= 0) return true;

  // Natively focusable elements
  const tagName = el.tagName.toLowerCase();
  if (['button', 'input', 'select', 'textarea', 'a'].includes(tagName)) {
    return !isDisabled(el);
  }

  return false;
}

// =============================================================================
// Custom matchers (for extending expect)
// =============================================================================

export const customMatchers = {
  toBeChecked(received: HTMLElement) {
    const pass = isChecked(received);
    return {
      pass,
      message: () => pass
        ? `Expected element not to be checked`
        : `Expected element to be checked`,
    };
  },

  toBePressed(received: HTMLElement) {
    const pass = isPressed(received);
    return {
      pass,
      message: () => pass
        ? `Expected element not to be pressed`
        : `Expected element to be pressed`,
    };
  },

  toBeSelected(received: HTMLElement) {
    const pass = isSelected(received);
    return {
      pass,
      message: () => pass
        ? `Expected element not to be selected`
        : `Expected element to be selected`,
    };
  },

  toBeExpanded(received: HTMLElement) {
    const pass = isExpanded(received);
    return {
      pass,
      message: () => pass
        ? `Expected element not to be expanded`
        : `Expected element to be expanded`,
    };
  },

  toHaveFocus(received: HTMLElement) {
    const pass = hasFocus(received);
    return {
      pass,
      message: () => pass
        ? `Expected element not to have focus`
        : `Expected element to have focus`,
    };
  },

  toBeAccessible(received: HTMLElement) {
    const result = hasRequiredAriaAttributes(received);
    return {
      pass: result.valid,
      message: () => result.valid
        ? `Expected element not to be accessible`
        : `Expected element to be accessible, missing: ${result.missing.join(', ')}`,
    };
  },
};
