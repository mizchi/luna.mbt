/**
 * Shoelace Input Binding for Luna
 *
 * Provides a Luna-compatible API for sl-input.
 * Supports both CSR and SSR contexts.
 */

import type { Signal, InputType, Size } from './types.js';

export interface SlInputProps {
  type?: InputType;
  label?: string;
  placeholder?: string;
  value?: string;
  size?: Size;
  disabled?: boolean;
  readonly?: boolean;
  required?: boolean;
  clearable?: boolean;
  passwordToggle?: boolean;
  helpText?: string;
  minlength?: number;
  maxlength?: number;
  pattern?: string;
  onInput?: (e: Event) => void;
  onChange?: (e: Event) => void;
  onFocus?: (e: Event) => void;
  onBlur?: (e: Event) => void;
}

export interface SlInputReactiveProps extends SlInputProps {
  valueSignal?: Signal<string>;
  disabledSignal?: Signal<boolean>;
}

/**
 * Create sl-input element
 */
export function slInput(props: SlInputProps = {}): HTMLElement | string {
  const {
    type = 'text',
    label,
    placeholder,
    value,
    size,
    disabled,
    readonly,
    required,
    clearable,
    passwordToggle,
    helpText,
    minlength,
    maxlength,
    pattern,
    onInput,
    onChange,
    onFocus,
    onBlur,
  } = props;

  // For SSR: return HTML string
  if (typeof document === 'undefined') {
    return slInputSSR(props);
  }

  // For CSR: create DOM element
  const input = document.createElement('sl-input') as HTMLElement & { value: string };

  // Set attributes
  input.setAttribute('type', type);
  if (label) input.setAttribute('label', label);
  if (placeholder) input.setAttribute('placeholder', placeholder);
  if (value !== undefined) input.setAttribute('value', value);
  if (size) input.setAttribute('size', size);
  if (disabled) input.setAttribute('disabled', '');
  if (readonly) input.setAttribute('readonly', '');
  if (required) input.setAttribute('required', '');
  if (clearable) input.setAttribute('clearable', '');
  if (passwordToggle) input.setAttribute('password-toggle', '');
  if (helpText) input.setAttribute('help-text', helpText);
  if (minlength !== undefined) input.setAttribute('minlength', String(minlength));
  if (maxlength !== undefined) input.setAttribute('maxlength', String(maxlength));
  if (pattern) input.setAttribute('pattern', pattern);

  // Event handlers
  if (onInput) input.addEventListener('sl-input', onInput);
  if (onChange) input.addEventListener('sl-change', onChange);
  if (onFocus) input.addEventListener('sl-focus', onFocus);
  if (onBlur) input.addEventListener('sl-blur', onBlur);

  return input;
}

/**
 * SSR version - returns HTML string
 */
function slInputSSR(props: SlInputProps): string {
  const attrs: string[] = [];

  attrs.push(`type="${props.type || 'text'}"`);
  if (props.label) attrs.push(`label="${escapeHtml(props.label)}"`);
  if (props.placeholder) attrs.push(`placeholder="${escapeHtml(props.placeholder)}"`);
  if (props.value !== undefined) attrs.push(`value="${escapeHtml(props.value)}"`);
  if (props.size) attrs.push(`size="${props.size}"`);
  if (props.disabled) attrs.push('disabled');
  if (props.readonly) attrs.push('readonly');
  if (props.required) attrs.push('required');
  if (props.clearable) attrs.push('clearable');
  if (props.passwordToggle) attrs.push('password-toggle');
  if (props.helpText) attrs.push(`help-text="${escapeHtml(props.helpText)}"`);
  if (props.minlength !== undefined) attrs.push(`minlength="${props.minlength}"`);
  if (props.maxlength !== undefined) attrs.push(`maxlength="${props.maxlength}"`);
  if (props.pattern) attrs.push(`pattern="${escapeHtml(props.pattern)}"`);

  return `<sl-input ${attrs.join(' ')}></sl-input>`;
}

/**
 * Signal-aware input for Luna integration
 */
export function slInputReactive(props: SlInputReactiveProps = {}): HTMLElement {
  const {
    valueSignal,
    disabledSignal,
    onInput,
    ...staticProps
  } = props;

  const input = slInput({
    ...staticProps,
    value: valueSignal?.get() ?? staticProps.value,
    onInput: (e) => {
      const target = e.target as HTMLInputElement;
      if (valueSignal) valueSignal.set(target.value);
      if (onInput) onInput(e);
    }
  }) as HTMLElement & { value: string };

  // Subscribe to signals
  if (valueSignal) {
    valueSignal.subscribe(value => {
      if (input.value !== value) {
        input.value = value;
      }
    });
  }

  if (disabledSignal) {
    disabledSignal.subscribe(disabled => {
      if (disabled) input.setAttribute('disabled', '');
      else input.removeAttribute('disabled');
    });
  }

  return input;
}

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
