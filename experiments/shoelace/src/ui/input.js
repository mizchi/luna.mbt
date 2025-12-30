/**
 * Luna Native Input - Light DOM Implementation
 *
 * SSR-safe input component with zero CLS.
 * Uses standard <input> element with CSS styling.
 */

/**
 * Create a Luna input element
 * @param {Object} props
 * @param {string} [props.type] - 'text' | 'email' | 'password' | 'number' | 'tel' | 'url' | 'search' | 'date'
 * @param {string} [props.label]
 * @param {string} [props.placeholder]
 * @param {string} [props.value]
 * @param {string} [props.size] - 'small' | 'medium' | 'large'
 * @param {boolean} [props.disabled]
 * @param {boolean} [props.readonly]
 * @param {boolean} [props.required]
 * @param {string} [props.helpText]
 * @param {string} [props.errorText]
 * @param {number} [props.minlength]
 * @param {number} [props.maxlength]
 * @param {string} [props.pattern]
 * @param {Function} [props.onInput]
 * @param {Function} [props.onChange]
 * @param {Function} [props.onFocus]
 * @param {Function} [props.onBlur]
 * @param {string} [props.className]
 * @returns {HTMLElement|string} - DOM element (CSR) or HTML string (SSR)
 */
export function lunaInput(props = {}) {
  const {
    type = 'text',
    label,
    placeholder,
    value = '',
    size = 'medium',
    disabled,
    readonly,
    required,
    helpText,
    errorText,
    minlength,
    maxlength,
    pattern,
    onInput,
    onChange,
    onFocus,
    onBlur,
    className,
    ...rest
  } = props;

  // For SSR: return HTML string
  if (typeof document === 'undefined') {
    return lunaInputSSR(props);
  }

  // Generate unique ID for label association
  const inputId = `luna-input-${Math.random().toString(36).substr(2, 9)}`;

  // Create wrapper
  const wrapper = document.createElement('div');
  const classes = ['luna-input'];
  classes.push(`luna-input--${size}`);
  if (disabled) classes.push('luna-input--disabled');
  if (errorText) classes.push('luna-input--error');
  if (className) classes.push(className);
  wrapper.className = classes.join(' ');

  // Label
  if (label) {
    const labelEl = document.createElement('label');
    labelEl.className = 'luna-input__label';
    labelEl.htmlFor = inputId;
    labelEl.textContent = label;
    if (required) {
      const asterisk = document.createElement('span');
      asterisk.className = 'luna-input__required';
      asterisk.textContent = ' *';
      asterisk.setAttribute('aria-hidden', 'true');
      labelEl.appendChild(asterisk);
    }
    wrapper.appendChild(labelEl);
  }

  // Input container (for potential icons/clear button)
  const inputContainer = document.createElement('div');
  inputContainer.className = 'luna-input__container';

  // Input element
  const input = document.createElement('input');
  input.id = inputId;
  input.className = 'luna-input__control';
  input.type = type;
  if (placeholder) input.placeholder = placeholder;
  if (value) input.value = value;
  if (disabled) input.disabled = true;
  if (readonly) input.readOnly = true;
  if (required) input.required = true;
  if (minlength !== undefined) input.minLength = minlength;
  if (maxlength !== undefined) input.maxLength = maxlength;
  if (pattern) input.pattern = pattern;

  // ARIA
  if (helpText || errorText) {
    const helpId = `${inputId}-help`;
    input.setAttribute('aria-describedby', helpId);
  }
  if (errorText) {
    input.setAttribute('aria-invalid', 'true');
  }

  // Event handlers
  if (onInput) input.addEventListener('input', onInput);
  if (onChange) input.addEventListener('change', onChange);
  if (onFocus) input.addEventListener('focus', onFocus);
  if (onBlur) input.addEventListener('blur', onBlur);

  inputContainer.appendChild(input);
  wrapper.appendChild(inputContainer);

  // Help/Error text
  if (helpText || errorText) {
    const helpEl = document.createElement('div');
    helpEl.id = `${inputId}-help`;
    helpEl.className = errorText ? 'luna-input__error' : 'luna-input__help';
    helpEl.textContent = errorText || helpText;
    wrapper.appendChild(helpEl);
  }

  // Store input reference for easy access
  wrapper._input = input;

  // Proxy common properties
  Object.defineProperty(wrapper, 'value', {
    get: () => input.value,
    set: (v) => { input.value = v; }
  });

  return wrapper;
}

/**
 * SSR version - returns HTML string
 */
function lunaInputSSR(props) {
  const {
    type = 'text',
    label,
    placeholder,
    value = '',
    size = 'medium',
    disabled,
    readonly,
    required,
    helpText,
    errorText,
    minlength,
    maxlength,
    pattern,
    className,
  } = props;

  const inputId = `luna-input-${Math.random().toString(36).substr(2, 9)}`;

  const classes = ['luna-input', `luna-input--${size}`];
  if (disabled) classes.push('luna-input--disabled');
  if (errorText) classes.push('luna-input--error');
  if (className) classes.push(className);

  const inputAttrs = [`type="${type}"`, `id="${inputId}"`, 'class="luna-input__control"'];
  if (placeholder) inputAttrs.push(`placeholder="${escapeHtml(placeholder)}"`);
  if (value) inputAttrs.push(`value="${escapeHtml(value)}"`);
  if (disabled) inputAttrs.push('disabled');
  if (readonly) inputAttrs.push('readonly');
  if (required) inputAttrs.push('required');
  if (minlength !== undefined) inputAttrs.push(`minlength="${minlength}"`);
  if (maxlength !== undefined) inputAttrs.push(`maxlength="${maxlength}"`);
  if (pattern) inputAttrs.push(`pattern="${escapeHtml(pattern)}"`);
  if (helpText || errorText) inputAttrs.push(`aria-describedby="${inputId}-help"`);
  if (errorText) inputAttrs.push('aria-invalid="true"');

  let html = `<div class="${classes.join(' ')}">`;

  if (label) {
    const requiredMark = required ? '<span class="luna-input__required" aria-hidden="true"> *</span>' : '';
    html += `<label class="luna-input__label" for="${inputId}">${escapeHtml(label)}${requiredMark}</label>`;
  }

  html += `<div class="luna-input__container"><input ${inputAttrs.join(' ')}></div>`;

  if (helpText || errorText) {
    const helpClass = errorText ? 'luna-input__error' : 'luna-input__help';
    html += `<div id="${inputId}-help" class="${helpClass}">${escapeHtml(errorText || helpText)}</div>`;
  }

  html += '</div>';

  return html;
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
 * @param {Signal} [props.errorSignal] - Signal for error text
 */
export function lunaInputReactive(props = {}) {
  const {
    valueSignal,
    disabledSignal,
    errorSignal,
    onInput,
    ...staticProps
  } = props;

  const wrapper = lunaInput({
    ...staticProps,
    value: valueSignal?.get?.() ?? staticProps.value,
    onInput: (e) => {
      if (valueSignal) valueSignal.set(e.target.value);
      if (onInput) onInput(e);
    }
  });

  const input = wrapper._input;

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
      input.disabled = disabled;
      wrapper.classList.toggle('luna-input--disabled', disabled);
    });
  }

  if (errorSignal) {
    errorSignal.subscribe?.(error => {
      const helpEl = wrapper.querySelector('.luna-input__help, .luna-input__error');
      if (error) {
        wrapper.classList.add('luna-input--error');
        input.setAttribute('aria-invalid', 'true');
        if (helpEl) {
          helpEl.className = 'luna-input__error';
          helpEl.textContent = error;
        }
      } else {
        wrapper.classList.remove('luna-input--error');
        input.removeAttribute('aria-invalid');
        if (helpEl && staticProps.helpText) {
          helpEl.className = 'luna-input__help';
          helpEl.textContent = staticProps.helpText;
        }
      }
    });
  }

  return wrapper;
}

// Export for use in HTML
if (typeof window !== 'undefined') {
  window.lunaInput = lunaInput;
  window.lunaInputReactive = lunaInputReactive;
}
