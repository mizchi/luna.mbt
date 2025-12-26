/**
 * Web Component definition helpers
 */

import { Signal, effect } from './signal.js';

// Supported attribute types
export type AttrType = 'string' | 'int' | 'float' | 'bool';

export interface AttrDef {
  name: string;
  type: AttrType;
  default?: string | number | boolean;
}

export interface ComponentDef<P extends object> {
  tag: string;
  attributes: AttrDef[];
  styles?: string;
  shadow?: 'open' | 'closed' | 'none';
  setup: (ctx: Context<P>) => void | (() => void);
  template?: (props: P) => string;
}

export interface Context<P> {
  element: HTMLElement;
  shadow: ShadowRoot | HTMLElement;
  props: SignalProps<P>;

  // DOM binding helpers
  bind(selector: string, getter: () => string): () => void;
  bindAttr(selector: string, attr: string, signal: Signal<unknown>): () => void;
  on(selector: string, event: string, handler: (e: Event) => void): () => void;
  onCleanup(fn: () => void): void;
}

// Convert props object to signals
export type SignalProps<T> = {
  [K in keyof T]: Signal<T[K]>;
};

/**
 * Parse attribute value based on type
 */
function parseAttr(value: string | null, def: AttrDef): unknown {
  if (value === null) {
    if (def.type === 'bool') return false;
    return def.default ?? (def.type === 'string' ? '' : 0);
  }

  switch (def.type) {
    case 'string':
      return value;
    case 'int':
      return parseInt(value, 10) || (def.default ?? 0);
    case 'float':
      return parseFloat(value) || (def.default ?? 0);
    case 'bool':
      return true; // Presence = true
  }
}

/**
 * Define a Web Component
 */
export function defineComponent<P extends object>(
  def: ComponentDef<P>
): typeof HTMLElement {
  const { tag, attributes, styles, shadow = 'open', setup, template } = def;

  // Create stylesheet once
  let sheet: CSSStyleSheet | null = null;
  if (styles && shadow !== 'none') {
    sheet = new CSSStyleSheet();
    sheet.replaceSync(styles);
  }

  class Component extends HTMLElement {
    static observedAttributes = attributes.map(a => a.name);

    #props: SignalProps<P>;
    #dispose: (() => void) | null = null;
    #cleanups: (() => void)[] = [];
    #connected = false;

    constructor() {
      super();
      // Initialize props as signals with defaults
      const props: Record<string, Signal<unknown>> = {};
      for (const attr of attributes) {
        const defaultVal = parseAttr(null, attr);
        props[attr.name] = new Signal(defaultVal);
      }
      this.#props = props as SignalProps<P>;
    }

    connectedCallback() {
      this.#connected = true;
      this.#syncAttributes();

      // Setup shadow DOM
      let root: ShadowRoot | HTMLElement;
      if (shadow === 'none') {
        root = this;
      } else if (this.shadowRoot) {
        // Declarative Shadow DOM (SSR)
        root = this.shadowRoot;
        if (sheet) {
          root.adoptedStyleSheets = [sheet];
        }
      } else {
        // Create shadow root
        root = this.attachShadow({ mode: shadow });
        if (sheet) {
          root.adoptedStyleSheets = [sheet];
        }
        // Render template if provided and not SSR
        if (template) {
          const props = this.#getPropsSnapshot();
          root.innerHTML = template(props);
        }
      }

      // Create context
      const ctx: Context<P> = {
        element: this,
        shadow: root,
        props: this.#props,

        bind: (selector, getter) => {
          const el = root.querySelector(selector);
          if (!el) return () => {};

          // Auto-tracking effect
          return effect(() => {
            el.textContent = getter();
          });
        },

        bindAttr: (selector, attr, signal) => {
          const el = root.querySelector(selector);
          if (!el) return () => {};

          return signal.subscribe(() => {
            const val = signal.get();
            if (typeof val === 'boolean') {
              if (val) {
                el.setAttribute(attr, '');
              } else {
                el.removeAttribute(attr);
              }
            } else {
              el.setAttribute(attr, String(val));
            }
          });
        },

        on: (selector, event, handler) => {
          const el = root.querySelector(selector);
          if (!el) return () => {};

          el.addEventListener(event, handler);
          return () => el.removeEventListener(event, handler);
        },

        onCleanup: (fn) => {
          this.#cleanups.push(fn);
        },
      };

      // Run setup
      const result = setup(ctx);
      if (typeof result === 'function') {
        this.#dispose = result;
      }
    }

    disconnectedCallback() {
      this.#connected = false;
      this.#dispose?.();
      this.#dispose = null;
      for (const cleanup of this.#cleanups) {
        cleanup();
      }
      this.#cleanups = [];
    }

    attributeChangedCallback(name: string, _oldVal: string | null, newVal: string | null) {
      if (!this.#connected) return;

      const attrDef = attributes.find(a => a.name === name);
      if (!attrDef) return;

      const signal = this.#props[name as keyof P];
      if (signal) {
        (signal as Signal<unknown>).set(parseAttr(newVal, attrDef));
      }
    }

    #syncAttributes() {
      for (const attr of attributes) {
        const value = attr.type === 'bool'
          ? this.hasAttribute(attr.name)
            ? ''
            : null
          : this.getAttribute(attr.name);
        const signal = this.#props[attr.name as keyof P];
        if (signal) {
          (signal as Signal<unknown>).set(parseAttr(value, attr));
        }
      }
    }

    #getPropsSnapshot(): P {
      const snapshot: Record<string, unknown> = {};
      for (const key in this.#props) {
        snapshot[key] = this.#props[key].get();
      }
      return snapshot as P;
    }
  }

  return Component;
}

/**
 * Register a component with customElements
 */
export function register<P extends object>(
  def: ComponentDef<P>
): void {
  const Component = defineComponent(def);
  if (!customElements.get(def.tag)) {
    customElements.define(def.tag, Component);
  }
}
