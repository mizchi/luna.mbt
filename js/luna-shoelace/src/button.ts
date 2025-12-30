/**
 * Shoelace Button Binding for Luna
 *
 * Provides a Luna-compatible API for sl-button.
 * Supports both CSR and SSR contexts.
 */

import type { Signal, ButtonVariant, Size } from './types.js';

export interface SlButtonProps {
  variant?: ButtonVariant;
  size?: Size;
  disabled?: boolean;
  loading?: boolean;
  outline?: boolean;
  pill?: boolean;
  circle?: boolean;
  href?: string;
  target?: string;
  onClick?: (e: Event) => void;
}

export interface SlButtonReactiveProps extends SlButtonProps {
  disabledSignal?: Signal<boolean>;
  loadingSignal?: Signal<boolean>;
  textSignal?: Signal<string>;
}

/**
 * Create sl-button element
 */
export function slButton(props: SlButtonProps = {}, children: (string | Node)[] = []): HTMLElement | string {
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
  } = props;

  // For SSR: return HTML string
  if (typeof document === 'undefined') {
    return slButtonSSR(props, children as string[]);
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
function slButtonSSR(props: SlButtonProps, children: string[]): string {
  const attrs: string[] = [];

  if (props.variant) attrs.push(`variant="${props.variant}"`);
  if (props.size) attrs.push(`size="${props.size}"`);
  if (props.disabled) attrs.push('disabled');
  if (props.loading) attrs.push('loading');
  if (props.outline) attrs.push('outline');
  if (props.pill) attrs.push('pill');
  if (props.circle) attrs.push('circle');
  if (props.href) attrs.push(`href="${escapeHtml(props.href)}"`);
  if (props.target) attrs.push(`target="${escapeHtml(props.target)}"`);

  const attrsStr = attrs.length ? ' ' + attrs.join(' ') : '';
  const childrenStr = children.map(c => typeof c === 'string' ? escapeHtml(c) : c).join('');

  return `<sl-button${attrsStr}>${childrenStr}</sl-button>`;
}

/**
 * Signal-aware button for Luna integration
 */
export function slButtonReactive(props: SlButtonReactiveProps = {}, children: (string | Node)[] = []): HTMLElement {
  const {
    disabledSignal,
    loadingSignal,
    textSignal,
    ...staticProps
  } = props;

  const button = slButton(staticProps, children) as HTMLElement;

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

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
