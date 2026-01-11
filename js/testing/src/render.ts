/**
 * Render utilities for testing Luna components
 */

export type RenderResult = {
  container: HTMLElement;
  baseElement: HTMLElement;
  unmount: () => void;
  rerender: (html: string) => void;
};

// Track all rendered containers for cleanup
const renderedContainers: HTMLElement[] = [];

/**
 * Render HTML string to a container for testing
 */
export function render(html: string): RenderResult {
  const container = document.createElement('div');
  container.setAttribute('data-testid', 'test-container');
  container.innerHTML = html;
  document.body.appendChild(container);
  renderedContainers.push(container);

  return {
    container,
    baseElement: document.body,
    unmount: () => {
      container.remove();
      const idx = renderedContainers.indexOf(container);
      if (idx !== -1) renderedContainers.splice(idx, 1);
    },
    rerender: (newHtml: string) => {
      container.innerHTML = newHtml;
    },
  };
}

/**
 * Render from a template element
 */
export function renderTemplate(template: HTMLTemplateElement): RenderResult {
  const container = document.createElement('div');
  container.appendChild(template.content.cloneNode(true));
  document.body.appendChild(container);

  return {
    container,
    baseElement: document.body,
    unmount: () => {
      container.remove();
    },
    rerender: () => {
      container.innerHTML = '';
      container.appendChild(template.content.cloneNode(true));
    },
  };
}

/**
 * Create a test container with cleanup
 */
export function createContainer(): { container: HTMLElement; cleanup: () => void } {
  const container = document.createElement('div');
  container.setAttribute('data-testid', 'test-container');
  document.body.appendChild(container);

  return {
    container,
    cleanup: () => {
      container.remove();
    },
  };
}

/**
 * Clean up all test containers
 */
export function cleanup(): void {
  // Remove tracked containers
  while (renderedContainers.length > 0) {
    const container = renderedContainers.pop();
    container?.remove();
  }
  // Also clean up any orphaned containers
  const containers = document.querySelectorAll('[data-testid="test-container"]');
  containers.forEach(container => container.remove());
}

// =============================================================================
// APG Component HTML builders
// =============================================================================

/**
 * Build checkbox HTML
 */
export function buildCheckbox(options: {
  label: string;
  checked?: boolean;
  disabled?: boolean;
}): string {
  const { label, checked = false, disabled = false } = options;
  const ariaChecked = checked ? 'true' : 'false';
  const tabindex = disabled ? '-1' : '0';
  return `
    <div role="checkbox"
         aria-checked="${ariaChecked}"
         aria-label="${label}"
         tabindex="${tabindex}"
         ${disabled ? 'aria-disabled="true"' : ''}>
      ${label}
    </div>
  `.trim();
}

/**
 * Build switch HTML
 */
export function buildSwitch(options: {
  label: string;
  checked?: boolean;
  disabled?: boolean;
}): string {
  const { label, checked = false, disabled = false } = options;
  const ariaChecked = checked ? 'true' : 'false';
  return `
    <button role="switch"
            aria-checked="${ariaChecked}"
            aria-label="${label}"
            ${disabled ? 'disabled' : ''}>
      ${label}
    </button>
  `.trim();
}

/**
 * Build button HTML
 */
export function buildButton(options: {
  text: string;
  disabled?: boolean;
  pressed?: boolean;
}): string {
  const { text, disabled = false, pressed } = options;
  const pressedAttr = pressed !== undefined ? `aria-pressed="${pressed}"` : '';
  return `
    <button role="button"
            ${pressedAttr}
            ${disabled ? 'disabled' : ''}>
      ${text}
    </button>
  `.trim();
}

/**
 * Build tabs HTML
 */
export function buildTabs(options: {
  tabs: { id: string; label: string; content: string }[];
  selectedIndex?: number;
}): string {
  const { tabs, selectedIndex = 0 } = options;

  const tablist = tabs.map((tab, i) => {
    const selected = i === selectedIndex;
    return `
      <button role="tab"
              id="tab-${tab.id}"
              aria-selected="${selected}"
              aria-controls="panel-${tab.id}"
              tabindex="${selected ? '0' : '-1'}">
        ${tab.label}
      </button>
    `.trim();
  }).join('\n');

  const panels = tabs.map((tab, i) => {
    const selected = i === selectedIndex;
    return `
      <div role="tabpanel"
           id="panel-${tab.id}"
           aria-labelledby="tab-${tab.id}"
           ${selected ? '' : 'hidden'}>
        ${tab.content}
      </div>
    `.trim();
  }).join('\n');

  return `
    <div role="tablist">
      ${tablist}
    </div>
    ${panels}
  `.trim();
}

/**
 * Build accordion HTML
 */
export function buildAccordion(options: {
  items: { id: string; header: string; content: string }[];
  expandedIndex?: number;
}): string {
  const { items, expandedIndex = -1 } = options;

  return items.map((item, i) => {
    const expanded = i === expandedIndex;
    return `
      <div data-accordion-item>
        <h3>
          <button aria-expanded="${expanded}"
                  aria-controls="panel-${item.id}"
                  id="header-${item.id}">
            ${item.header}
          </button>
        </h3>
        <div id="panel-${item.id}"
             role="region"
             aria-labelledby="header-${item.id}"
             ${expanded ? '' : 'hidden'}>
          ${item.content}
        </div>
      </div>
    `.trim();
  }).join('\n');
}

/**
 * Build slider HTML
 */
export function buildSlider(options: {
  label: string;
  value?: number;
  min?: number;
  max?: number;
}): string {
  const { label, value = 50, min = 0, max = 100 } = options;
  return `
    <div role="slider"
         aria-label="${label}"
         aria-valuenow="${value}"
         aria-valuemin="${min}"
         aria-valuemax="${max}"
         tabindex="0">
      ${value}
    </div>
  `.trim();
}

/**
 * Build radio group HTML
 */
export function buildRadioGroup(options: {
  label: string;
  options: { value: string; label: string }[];
  selectedValue?: string;
}): string {
  const { label, options: radioOptions, selectedValue } = options;

  const radios = radioOptions.map(opt => {
    const selected = opt.value === selectedValue;
    return `
      <div role="radio"
           data-value="${opt.value}"
           aria-checked="${selected}"
           tabindex="${selected ? '0' : '-1'}">
        ${opt.label}
      </div>
    `.trim();
  }).join('\n');

  return `
    <div role="radiogroup" aria-label="${label}">
      ${radios}
    </div>
  `.trim();
}

/**
 * Build dialog HTML
 */
export function buildDialog(options: {
  label: string;
  content: string;
  open?: boolean;
}): string {
  const { label, content, open = false } = options;
  return `
    <div role="dialog"
         aria-label="${label}"
         aria-modal="true"
         ${open ? '' : 'hidden'}>
      ${content}
    </div>
  `.trim();
}
