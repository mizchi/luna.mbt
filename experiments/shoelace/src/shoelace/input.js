/**
 * Shoelace Input Binding for Luna
 *
 * This module provides a Luna-compatible API for sl-input.
 * Can be used in both CSR and SSR contexts.
 */

/**
 * Create sl-input element
 * @param {Object} props
 * @param {string} [props.type] - 'text' | 'email' | 'password' | 'number' | 'tel' | 'url' | 'search' | 'date'
 * @param {string} [props.label]
 * @param {string} [props.placeholder]
 * @param {string} [props.value]
 * @param {string} [props.size] - 'small' | 'medium' | 'large'
 * @param {boolean} [props.disabled]
 * @param {boolean} [props.readonly]
 * @param {boolean} [props.required]
 * @param {boolean} [props.clearable]
 * @param {boolean} [props.passwordToggle]
 * @param {string} [props.helpText]
 * @param {number} [props.minlength]
 * @param {number} [props.maxlength]
 * @param {string} [props.pattern]
 * @param {Function} [props.onInput]
 * @param {Function} [props.onChange]
 * @param {Function} [props.onFocus]
 * @param {Function} [props.onBlur]
 * @returns {HTMLElement|string} - DOM element (CSR) or HTML string (SSR)
 */
export function slInput(props = {}) {
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
    ...rest
  } = props;

  // For SSR: return HTML string
  if (typeof document === 'undefined') {
    return slInputSSR(props);
  }

  // For CSR: create DOM element
  const input = document.createElement('sl-input');

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
  if (minlength !== undefined) input.setAttribute('minlength', minlength);
  if (maxlength !== undefined) input.setAttribute('maxlength', maxlength);
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
function slInputSSR(props) {
  const attrs = [];

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

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

/**
 * Signal-aware input (for Luna integration)
 * @param {Object} props
 * @param {Signal} [props.valueSignal] - Two-way binding signal
 * @param {Signal} [props.disabledSignal] - Signal for disabled state
 */
export function slInputReactive(props = {}) {
  const {
    valueSignal,
    disabledSignal,
    onInput,
    ...staticProps
  } = props;

  const input = slInput({
    ...staticProps,
    value: valueSignal?.get?.() ?? staticProps.value,
    onInput: (e) => {
      if (valueSignal) valueSignal.set(e.target.value);
      if (onInput) onInput(e);
    }
  });

  // Subscribe to signals
  if (valueSignal) {
    valueSignal.subscribe?.(value => {
      if (input.value !== value) {
        input.value = value;
      }
    });
  }

  if (disabledSignal) {
    disabledSignal.subscribe?.(disabled => {
      if (disabled) input.setAttribute('disabled', '');
      else input.removeAttribute('disabled');
    });
  }

  return input;
}

// Export for use in HTML
if (typeof window !== 'undefined') {
  window.slInput = slInput;
  window.slInputReactive = slInputReactive;
}
