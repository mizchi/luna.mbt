/**
 * Luna Native Button - Light DOM Implementation
 *
 * SSR-safe button component with zero CLS (Cumulative Layout Shift).
 * Uses standard <button> element with CSS styling for consistent rendering.
 */

/**
 * Create a Luna button element
 * @param {Object} props
 * @param {string} [props.variant] - 'default' | 'primary' | 'success' | 'warning' | 'danger'
 * @param {string} [props.size] - 'small' | 'medium' | 'large'
 * @param {boolean} [props.disabled]
 * @param {boolean} [props.loading]
 * @param {boolean} [props.outline]
 * @param {boolean} [props.pill]
 * @param {string} [props.href] - If provided, renders as <a> instead of <button>
 * @param {string} [props.target]
 * @param {Function} [props.onClick]
 * @param {string} [props.className]
 * @param {Array} children
 * @returns {HTMLElement|string} - DOM element (CSR) or HTML string (SSR)
 */
export function lunaButton(props = {}, children = []) {
  const {
    variant = 'default',
    size = 'medium',
    disabled,
    loading,
    outline,
    pill,
    href,
    target,
    onClick,
    className,
    ...rest
  } = props;

  // For SSR: return HTML string
  if (typeof document === 'undefined') {
    return lunaButtonSSR(props, children);
  }

  // For CSR: create DOM element
  const isLink = !!href;
  const button = document.createElement(isLink ? 'a' : 'button');

  // Build class list
  const classes = ['luna-btn'];
  classes.push(`luna-btn--${variant}`);
  classes.push(`luna-btn--${size}`);
  if (outline) classes.push('luna-btn--outline');
  if (pill) classes.push('luna-btn--pill');
  if (loading) classes.push('luna-btn--loading');
  if (disabled) classes.push('luna-btn--disabled');
  if (className) classes.push(className);

  button.className = classes.join(' ');

  // Set attributes
  if (isLink) {
    button.href = href;
    if (target) button.target = target;
    if (disabled) {
      button.setAttribute('aria-disabled', 'true');
      button.tabIndex = -1;
    }
  } else {
    button.type = 'button';
    if (disabled) button.disabled = true;
  }

  // Loading spinner
  if (loading) {
    const spinner = document.createElement('span');
    spinner.className = 'luna-btn__spinner';
    spinner.setAttribute('aria-hidden', 'true');
    button.appendChild(spinner);
  }

  // Content wrapper
  const content = document.createElement('span');
  content.className = 'luna-btn__content';

  // Append children
  children.forEach(child => {
    if (typeof child === 'string') {
      content.appendChild(document.createTextNode(child));
    } else if (child instanceof Node) {
      content.appendChild(child);
    }
  });

  button.appendChild(content);

  // Event handlers
  if (onClick && !disabled) {
    button.addEventListener('click', (e) => {
      if (loading) {
        e.preventDefault();
        return;
      }
      onClick(e);
    });
  }

  return button;
}

/**
 * SSR version - returns HTML string
 */
function lunaButtonSSR(props, children) {
  const {
    variant = 'default',
    size = 'medium',
    disabled,
    loading,
    outline,
    pill,
    href,
    target,
    className,
  } = props;

  const isLink = !!href;
  const tag = isLink ? 'a' : 'button';

  // Build class list
  const classes = ['luna-btn'];
  classes.push(`luna-btn--${variant}`);
  classes.push(`luna-btn--${size}`);
  if (outline) classes.push('luna-btn--outline');
  if (pill) classes.push('luna-btn--pill');
  if (loading) classes.push('luna-btn--loading');
  if (disabled) classes.push('luna-btn--disabled');
  if (className) classes.push(className);

  const attrs = [`class="${classes.join(' ')}"`];

  if (isLink) {
    attrs.push(`href="${escapeHtml(href)}"`);
    if (target) attrs.push(`target="${escapeHtml(target)}"`);
    if (disabled) {
      attrs.push('aria-disabled="true"');
      attrs.push('tabindex="-1"');
    }
  } else {
    attrs.push('type="button"');
    if (disabled) attrs.push('disabled');
  }

  const spinnerHtml = loading
    ? '<span class="luna-btn__spinner" aria-hidden="true"></span>'
    : '';

  const childrenStr = children.map(c =>
    typeof c === 'string' ? escapeHtml(c) : c
  ).join('');

  return `<${tag} ${attrs.join(' ')}>${spinnerHtml}<span class="luna-btn__content">${childrenStr}</span></${tag}>`;
}

/**
 * Escape HTML special characters
 */
function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * Signal-aware button (for Luna integration)
 * @param {Object} props
 * @param {Signal} [props.disabledSignal] - Signal for disabled state
 * @param {Signal} [props.loadingSignal] - Signal for loading state
 * @param {Signal} [props.textSignal] - Signal for button text
 */
export function lunaButtonReactive(props = {}, children = []) {
  const {
    disabledSignal,
    loadingSignal,
    textSignal,
    ...staticProps
  } = props;

  const button = lunaButton(staticProps, children);

  // Subscribe to signals
  if (disabledSignal) {
    disabledSignal.subscribe(disabled => {
      if (button.tagName === 'BUTTON') {
        button.disabled = disabled;
      } else {
        if (disabled) {
          button.setAttribute('aria-disabled', 'true');
          button.tabIndex = -1;
        } else {
          button.removeAttribute('aria-disabled');
          button.tabIndex = 0;
        }
      }
      button.classList.toggle('luna-btn--disabled', disabled);
    });
  }

  if (loadingSignal) {
    loadingSignal.subscribe(loading => {
      button.classList.toggle('luna-btn--loading', loading);

      // Add/remove spinner
      let spinner = button.querySelector('.luna-btn__spinner');
      if (loading && !spinner) {
        spinner = document.createElement('span');
        spinner.className = 'luna-btn__spinner';
        spinner.setAttribute('aria-hidden', 'true');
        button.insertBefore(spinner, button.firstChild);
      } else if (!loading && spinner) {
        spinner.remove();
      }
    });
  }

  if (textSignal) {
    textSignal.subscribe(text => {
      const content = button.querySelector('.luna-btn__content');
      if (content) content.textContent = text;
    });
  }

  return button;
}

// Export for use in HTML
if (typeof window !== 'undefined') {
  window.lunaButton = lunaButton;
  window.lunaButtonReactive = lunaButtonReactive;
}
