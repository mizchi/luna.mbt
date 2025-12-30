/**
 * Shoelace Switch Binding for Luna
 *
 * Provides a Luna-compatible API for sl-switch.
 * Supports both CSR and SSR contexts.
 */

import type { Signal, Size } from './types.js';

export interface SlSwitchProps {
  checked?: boolean;
  disabled?: boolean;
  required?: boolean;
  size?: Size;
  helpText?: string;
  onChange?: (e: Event) => void;
}

export interface SlSwitchReactiveProps extends SlSwitchProps {
  checkedSignal?: Signal<boolean>;
  disabledSignal?: Signal<boolean>;
}

/**
 * Create sl-switch element
 */
export function slSwitch(props: SlSwitchProps = {}, children: (string | Node)[] = []): HTMLElement | string {
  const {
    checked,
    disabled,
    required,
    size,
    helpText,
    onChange,
  } = props;

  // For SSR: return HTML string
  if (typeof document === 'undefined') {
    return slSwitchSSR(props, children as string[]);
  }

  // For CSR: create DOM element
  const switchEl = document.createElement('sl-switch') as HTMLElement & { checked: boolean };

  // Set attributes
  if (checked) switchEl.setAttribute('checked', '');
  if (disabled) switchEl.setAttribute('disabled', '');
  if (required) switchEl.setAttribute('required', '');
  if (size) switchEl.setAttribute('size', size);
  if (helpText) switchEl.setAttribute('help-text', helpText);

  // Event handlers
  if (onChange) {
    switchEl.addEventListener('sl-change', onChange);
  }

  // Append children (label text)
  children.forEach(child => {
    if (typeof child === 'string') {
      switchEl.appendChild(document.createTextNode(child));
    } else if (child instanceof Node) {
      switchEl.appendChild(child);
    }
  });

  return switchEl;
}

/**
 * SSR version - returns HTML string
 */
function slSwitchSSR(props: SlSwitchProps, children: string[]): string {
  const attrs: string[] = [];

  if (props.checked) attrs.push('checked');
  if (props.disabled) attrs.push('disabled');
  if (props.required) attrs.push('required');
  if (props.size) attrs.push(`size="${props.size}"`);
  if (props.helpText) attrs.push(`help-text="${escapeHtml(props.helpText)}"`);

  const attrsStr = attrs.length ? ' ' + attrs.join(' ') : '';
  const childrenStr = children.map(c => typeof c === 'string' ? escapeHtml(c) : c).join('');

  return `<sl-switch${attrsStr}>${childrenStr}</sl-switch>`;
}

/**
 * Signal-aware switch for Luna integration
 */
export function slSwitchReactive(props: SlSwitchReactiveProps = {}, children: (string | Node)[] = []): HTMLElement {
  const {
    checkedSignal,
    disabledSignal,
    onChange,
    ...staticProps
  } = props;

  const switchEl = slSwitch({
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
      if (switchEl.checked !== checked) {
        switchEl.checked = checked;
      }
    });
  }

  if (disabledSignal) {
    disabledSignal.subscribe(disabled => {
      if (disabled) switchEl.setAttribute('disabled', '');
      else switchEl.removeAttribute('disabled');
    });
  }

  return switchEl;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
