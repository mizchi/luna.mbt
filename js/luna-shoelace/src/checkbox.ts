/**
 * Shoelace Checkbox Binding for Luna
 *
 * Provides a Luna-compatible API for sl-checkbox.
 * Supports both CSR and SSR contexts.
 */

import type { Signal, Size } from './types.js';

export interface SlCheckboxProps {
  checked?: boolean;
  indeterminate?: boolean;
  disabled?: boolean;
  required?: boolean;
  size?: Size;
  helpText?: string;
  onChange?: (e: Event) => void;
}

export interface SlCheckboxReactiveProps extends SlCheckboxProps {
  checkedSignal?: Signal<boolean>;
  disabledSignal?: Signal<boolean>;
}

/**
 * Create sl-checkbox element
 */
export function slCheckbox(props: SlCheckboxProps = {}, children: (string | Node)[] = []): HTMLElement | string {
  const {
    checked,
    indeterminate,
    disabled,
    required,
    size,
    helpText,
    onChange,
  } = props;

  // For SSR: return HTML string
  if (typeof document === 'undefined') {
    return slCheckboxSSR(props, children as string[]);
  }

  // For CSR: create DOM element
  const checkbox = document.createElement('sl-checkbox') as HTMLElement & { checked: boolean; indeterminate: boolean };

  // Set attributes
  if (checked) checkbox.setAttribute('checked', '');
  if (indeterminate) checkbox.setAttribute('indeterminate', '');
  if (disabled) checkbox.setAttribute('disabled', '');
  if (required) checkbox.setAttribute('required', '');
  if (size) checkbox.setAttribute('size', size);
  if (helpText) checkbox.setAttribute('help-text', helpText);

  // Event handlers
  if (onChange) {
    checkbox.addEventListener('sl-change', onChange);
  }

  // Append children (label text)
  children.forEach(child => {
    if (typeof child === 'string') {
      checkbox.appendChild(document.createTextNode(child));
    } else if (child instanceof Node) {
      checkbox.appendChild(child);
    }
  });

  return checkbox;
}

/**
 * SSR version - returns HTML string
 */
function slCheckboxSSR(props: SlCheckboxProps, children: string[]): string {
  const attrs: string[] = [];

  if (props.checked) attrs.push('checked');
  if (props.indeterminate) attrs.push('indeterminate');
  if (props.disabled) attrs.push('disabled');
  if (props.required) attrs.push('required');
  if (props.size) attrs.push(`size="${props.size}"`);
  if (props.helpText) attrs.push(`help-text="${escapeHtml(props.helpText)}"`);

  const attrsStr = attrs.length ? ' ' + attrs.join(' ') : '';
  const childrenStr = children.map(c => typeof c === 'string' ? escapeHtml(c) : c).join('');

  return `<sl-checkbox${attrsStr}>${childrenStr}</sl-checkbox>`;
}

/**
 * Signal-aware checkbox for Luna integration
 */
export function slCheckboxReactive(props: SlCheckboxReactiveProps = {}, children: (string | Node)[] = []): HTMLElement {
  const {
    checkedSignal,
    disabledSignal,
    onChange,
    ...staticProps
  } = props;

  const checkbox = slCheckbox({
    ...staticProps,
    checked: checkedSignal?.get() ?? staticProps.checked,
    onChange: (e) => {
      const target = e.target as HTMLInputElement;
      if (checkedSignal) checkedSignal.set(target.checked);
      if (onChange) onChange(e);
    }
  }, children) as HTMLElement & { checked: boolean };

  // Subscribe to signals
  if (checkedSignal) {
    checkedSignal.subscribe(checked => {
      if (checkbox.checked !== checked) {
        checkbox.checked = checked;
      }
    });
  }

  if (disabledSignal) {
    disabledSignal.subscribe(disabled => {
      if (disabled) checkbox.setAttribute('disabled', '');
      else checkbox.removeAttribute('disabled');
    });
  }

  return checkbox;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
