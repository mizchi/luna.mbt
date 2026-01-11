/**
 * Query utilities for finding elements in rendered Luna components
 * Inspired by @testing-library but focused on APG patterns
 */

export type QueryOptions = {
  container?: Element;
};

/**
 * Get the default container (document.body or provided container)
 */
function getContainer(options?: QueryOptions): Element {
  return options?.container ?? document.body;
}

// =============================================================================
// By Role queries (primary method for accessible components)
// =============================================================================

/**
 * Find element by ARIA role
 */
export function getByRole(
  role: string,
  options?: QueryOptions & { name?: string; pressed?: boolean; checked?: boolean | 'mixed'; selected?: boolean; expanded?: boolean }
): HTMLElement {
  const el = queryByRole(role, options);
  if (!el) {
    throw new Error(`Unable to find element with role="${role}"${options?.name ? ` and accessible name "${options.name}"` : ''}`);
  }
  return el;
}

export function queryByRole(
  role: string,
  options?: QueryOptions & { name?: string; pressed?: boolean; checked?: boolean | 'mixed'; selected?: boolean; expanded?: boolean }
): HTMLElement | null {
  const container = getContainer(options);
  const elements = container.querySelectorAll(`[role="${role}"]`);

  for (const el of elements) {
    if (options?.name !== undefined) {
      const name = getAccessibleName(el as HTMLElement);
      if (name !== options.name) continue;
    }
    if (options?.pressed !== undefined) {
      const pressed = el.getAttribute('aria-pressed');
      if ((pressed === 'true') !== options.pressed) continue;
    }
    if (options?.checked !== undefined) {
      const checked = el.getAttribute('aria-checked');
      if (options.checked === 'mixed') {
        if (checked !== 'mixed') continue;
      } else {
        if ((checked === 'true') !== options.checked) continue;
      }
    }
    if (options?.selected !== undefined) {
      const selected = el.getAttribute('aria-selected');
      if ((selected === 'true') !== options.selected) continue;
    }
    if (options?.expanded !== undefined) {
      const expanded = el.getAttribute('aria-expanded');
      if ((expanded === 'true') !== options.expanded) continue;
    }
    return el as HTMLElement;
  }
  return null;
}

export function getAllByRole(
  role: string,
  options?: QueryOptions
): HTMLElement[] {
  const container = getContainer(options);
  return Array.from(container.querySelectorAll(`[role="${role}"]`)) as HTMLElement[];
}

// =============================================================================
// By Text queries
// =============================================================================

/**
 * Find element by text content
 */
export function getByText(
  text: string | RegExp,
  options?: QueryOptions
): HTMLElement {
  const el = queryByText(text, options);
  if (!el) {
    throw new Error(`Unable to find element with text: ${text}`);
  }
  return el;
}

export function queryByText(
  text: string | RegExp,
  options?: QueryOptions
): HTMLElement | null {
  const container = getContainer(options);
  const walker = document.createTreeWalker(
    container,
    NodeFilter.SHOW_TEXT,
    null
  );

  let node: Text | null;
  while ((node = walker.nextNode() as Text | null)) {
    const content = node.textContent?.trim() ?? '';
    const matches = typeof text === 'string'
      ? content === text || content.includes(text)
      : text.test(content);

    if (matches && node.parentElement) {
      return node.parentElement;
    }
  }
  return null;
}

export function getAllByText(
  text: string | RegExp,
  options?: QueryOptions
): HTMLElement[] {
  const container = getContainer(options);
  const results: HTMLElement[] = [];
  const walker = document.createTreeWalker(
    container,
    NodeFilter.SHOW_TEXT,
    null
  );

  let node: Text | null;
  while ((node = walker.nextNode() as Text | null)) {
    const content = node.textContent?.trim() ?? '';
    const matches = typeof text === 'string'
      ? content === text || content.includes(text)
      : text.test(content);

    if (matches && node.parentElement) {
      results.push(node.parentElement);
    }
  }
  return results;
}

// =============================================================================
// By Label queries (for form elements)
// =============================================================================

/**
 * Find element by its label text
 */
export function getByLabelText(
  text: string | RegExp,
  options?: QueryOptions
): HTMLElement {
  const el = queryByLabelText(text, options);
  if (!el) {
    throw new Error(`Unable to find element with label: ${text}`);
  }
  return el;
}

export function queryByLabelText(
  text: string | RegExp,
  options?: QueryOptions
): HTMLElement | null {
  const container = getContainer(options);

  // Check aria-label
  const byAriaLabel = container.querySelectorAll('[aria-label]');
  for (const el of byAriaLabel) {
    const label = el.getAttribute('aria-label') ?? '';
    const matches = typeof text === 'string' ? label === text : text.test(label);
    if (matches) return el as HTMLElement;
  }

  // Check aria-labelledby
  const byAriaLabelledby = container.querySelectorAll('[aria-labelledby]');
  for (const el of byAriaLabelledby) {
    const labelId = el.getAttribute('aria-labelledby');
    if (labelId) {
      const labelEl = document.getElementById(labelId);
      const labelText = labelEl?.textContent?.trim() ?? '';
      const matches = typeof text === 'string' ? labelText === text : text.test(labelText);
      if (matches) return el as HTMLElement;
    }
  }

  // Check <label> elements
  const labels = container.querySelectorAll('label');
  for (const label of labels) {
    const labelText = label.textContent?.trim() ?? '';
    const matches = typeof text === 'string' ? labelText === text : text.test(labelText);
    if (matches) {
      const forId = label.getAttribute('for');
      if (forId) {
        const target = document.getElementById(forId);
        if (target) return target as HTMLElement;
      }
      // Check nested input
      const nested = label.querySelector('input, select, textarea');
      if (nested) return nested as HTMLElement;
    }
  }

  return null;
}

// =============================================================================
// By TestId queries (fallback)
// =============================================================================

/**
 * Find element by data-testid attribute
 */
export function getByTestId(
  testId: string,
  options?: QueryOptions
): HTMLElement {
  const el = queryByTestId(testId, options);
  if (!el) {
    throw new Error(`Unable to find element with data-testid="${testId}"`);
  }
  return el;
}

export function queryByTestId(
  testId: string,
  options?: QueryOptions
): HTMLElement | null {
  const container = getContainer(options);
  return container.querySelector(`[data-testid="${testId}"]`) as HTMLElement | null;
}

// =============================================================================
// APG-specific queries
// =============================================================================

/**
 * Find tab by name
 */
export function getTab(name: string, options?: QueryOptions): HTMLElement {
  return getByRole('tab', { ...options, name });
}

/**
 * Find tabpanel by label
 */
export function getTabPanel(labelledBy: string, options?: QueryOptions): HTMLElement {
  const container = getContainer(options);
  const panel = container.querySelector(`[role="tabpanel"][aria-labelledby="${labelledBy}"]`);
  if (!panel) {
    throw new Error(`Unable to find tabpanel labelled by "${labelledBy}"`);
  }
  return panel as HTMLElement;
}

/**
 * Find checkbox by label
 */
export function getCheckbox(label: string, options?: QueryOptions): HTMLElement {
  return getByRole('checkbox', { ...options, name: label });
}

/**
 * Find switch by label
 */
export function getSwitch(label: string, options?: QueryOptions): HTMLElement {
  return getByRole('switch', { ...options, name: label });
}

/**
 * Find button by text
 */
export function getButton(text: string, options?: QueryOptions): HTMLElement {
  return getByRole('button', { ...options, name: text });
}

/**
 * Find slider by label
 */
export function getSlider(label: string, options?: QueryOptions): HTMLElement {
  return getByRole('slider', { ...options, name: label });
}

/**
 * Find radio by value within a radiogroup
 */
export function getRadio(value: string, options?: QueryOptions): HTMLElement {
  const container = getContainer(options);
  const radio = container.querySelector(`[role="radio"][data-value="${value}"]`);
  if (!radio) {
    throw new Error(`Unable to find radio with value="${value}"`);
  }
  return radio as HTMLElement;
}

/**
 * Find dialog by label
 */
export function getDialog(label: string, options?: QueryOptions): HTMLElement {
  return getByRole('dialog', { ...options, name: label });
}

// =============================================================================
// Utilities
// =============================================================================

/**
 * Get the accessible name of an element
 */
export function getAccessibleName(el: HTMLElement): string {
  // Check aria-label
  const ariaLabel = el.getAttribute('aria-label');
  if (ariaLabel) return ariaLabel;

  // Check aria-labelledby
  const labelledby = el.getAttribute('aria-labelledby');
  if (labelledby) {
    const labels = labelledby.split(' ').map(id => document.getElementById(id)?.textContent?.trim() ?? '');
    return labels.join(' ');
  }

  // Fallback to text content
  return el.textContent?.trim() ?? '';
}

/**
 * Check if element is visible (not hidden)
 */
export function isVisible(el: HTMLElement): boolean {
  if (el.hidden) return false;
  if (el.getAttribute('aria-hidden') === 'true') return false;
  const style = getComputedStyle(el);
  if (style.display === 'none') return false;
  if (style.visibility === 'hidden') return false;
  return true;
}

/**
 * Wait for element to appear
 */
export async function waitFor<T>(
  callback: () => T,
  options?: { timeout?: number; interval?: number }
): Promise<T> {
  const { timeout = 1000, interval = 50 } = options ?? {};
  const start = Date.now();

  while (Date.now() - start < timeout) {
    try {
      const result = callback();
      if (result) return result;
    } catch {
      // Continue waiting
    }
    await new Promise(resolve => setTimeout(resolve, interval));
  }

  // Final attempt
  return callback();
}
