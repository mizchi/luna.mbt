/**
 * Shoelace Button Binding for Luna
 *
 * This module provides a Luna-compatible API for sl-button.
 * Can be used in both CSR and SSR contexts.
 */

/**
 * Create sl-button element
 * @param {Object} props
 * @param {string} [props.variant] - 'default' | 'primary' | 'success' | 'neutral' | 'warning' | 'danger'
 * @param {string} [props.size] - 'small' | 'medium' | 'large'
 * @param {boolean} [props.disabled]
 * @param {boolean} [props.loading]
 * @param {boolean} [props.outline]
 * @param {boolean} [props.pill]
 * @param {boolean} [props.circle]
 * @param {string} [props.href]
 * @param {string} [props.target]
 * @param {Function} [props.onClick]
 * @param {Array} children
 * @returns {HTMLElement|string} - DOM element (CSR) or HTML string (SSR)
 */
export function slButton(props = {}, children = []) {
  const {
    variant,
    size,
    disabled,
    loading,
    outline,
    pill,
    circle,
    href,
    target,
    onClick,
    ...rest
  } = props;

  // For SSR: return HTML string
  if (typeof document === 'undefined') {
    return slButtonSSR(props, children);
  }

  // For CSR: create DOM element
  const button = document.createElement('sl-button');

  // Set attributes
  if (variant) button.setAttribute('variant', variant);
  if (size) button.setAttribute('size', size);
  if (disabled) button.setAttribute('disabled', '');
  if (loading) button.setAttribute('loading', '');
  if (outline) button.setAttribute('outline', '');
  if (pill) button.setAttribute('pill', '');
  if (circle) button.setAttribute('circle', '');
  if (href) button.setAttribute('href', href);
  if (target) button.setAttribute('target', target);

  // Event handlers
  if (onClick) {
    button.addEventListener('click', onClick);
  }

  // Append children
  children.forEach(child => {
    if (typeof child === 'string') {
      button.appendChild(document.createTextNode(child));
    } else if (child instanceof Node) {
      button.appendChild(child);
    }
  });

  return button;
}

/**
 * SSR version - returns HTML string
 */
function slButtonSSR(props, children) {
  const attrs = [];

  if (props.variant) attrs.push(`variant="${props.variant}"`);
  if (props.size) attrs.push(`size="${props.size}"`);
  if (props.disabled) attrs.push('disabled');
  if (props.loading) attrs.push('loading');
  if (props.outline) attrs.push('outline');
  if (props.pill) attrs.push('pill');
  if (props.circle) attrs.push('circle');
  if (props.href) attrs.push(`href="${props.href}"`);
  if (props.target) attrs.push(`target="${props.target}"`);

  const attrsStr = attrs.length ? ' ' + attrs.join(' ') : '';
  const childrenStr = children.join('');

  return `<sl-button${attrsStr}>${childrenStr}</sl-button>`;
}

/**
 * Signal-aware button (for Luna integration)
 * @param {Object} props
 * @param {Signal} [props.disabledSignal] - Signal for disabled state
 * @param {Signal} [props.loadingSignal] - Signal for loading state
 * @param {Signal} [props.textSignal] - Signal for button text
 */
export function slButtonReactive(props = {}, children = []) {
  const {
    disabledSignal,
    loadingSignal,
    textSignal,
    ...staticProps
  } = props;

  const button = slButton(staticProps, children);

  // Subscribe to signals
  if (disabledSignal) {
    disabledSignal.subscribe(disabled => {
      if (disabled) button.setAttribute('disabled', '');
      else button.removeAttribute('disabled');
    });
  }

  if (loadingSignal) {
    loadingSignal.subscribe(loading => {
      if (loading) button.setAttribute('loading', '');
      else button.removeAttribute('loading');
    });
  }

  if (textSignal) {
    textSignal.subscribe(text => {
      button.textContent = text;
    });
  }

  return button;
}

// Export for use in HTML
if (typeof window !== 'undefined') {
  window.slButton = slButton;
  window.slButtonReactive = slButtonReactive;
}
