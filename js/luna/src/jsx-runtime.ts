// JSX Runtime for @mizchi/luna
// Usage: Configure tsconfig.json with:
//   "jsx": "react-jsx",
//   "jsxImportSource": "@mizchi/luna"

import { text, textDyn, createElement } from "./index";

// Types for reactive attributes (can be static value or accessor function)
type MaybeAccessor<T> = T | (() => T);

// Common HTML attributes with reactive support
interface HTMLAttributes {
  // Core attributes
  id?: MaybeAccessor<string>;
  className?: MaybeAccessor<string>;
  class?: MaybeAccessor<string>;
  style?: MaybeAccessor<string | Record<string, string | number>>;
  title?: MaybeAccessor<string>;
  tabIndex?: MaybeAccessor<number>;
  hidden?: MaybeAccessor<boolean>;

  // Form attributes
  type?: MaybeAccessor<string>;
  name?: MaybeAccessor<string>;
  value?: MaybeAccessor<string | number>;
  placeholder?: MaybeAccessor<string>;
  disabled?: MaybeAccessor<boolean>;
  checked?: MaybeAccessor<boolean>;
  readonly?: MaybeAccessor<boolean>;
  required?: MaybeAccessor<boolean>;
  min?: MaybeAccessor<string | number>;
  max?: MaybeAccessor<string | number>;
  step?: MaybeAccessor<string | number>;
  pattern?: MaybeAccessor<string>;

  // Link/Media attributes
  href?: MaybeAccessor<string>;
  src?: MaybeAccessor<string>;
  alt?: MaybeAccessor<string>;
  target?: MaybeAccessor<string>;
  rel?: MaybeAccessor<string>;

  // ARIA attributes
  role?: MaybeAccessor<string>;
  "aria-label"?: MaybeAccessor<string>;
  "aria-hidden"?: MaybeAccessor<boolean | "true" | "false">;
  "aria-expanded"?: MaybeAccessor<boolean | "true" | "false">;
  "aria-selected"?: MaybeAccessor<boolean | "true" | "false">;
  "aria-disabled"?: MaybeAccessor<boolean | "true" | "false">;

  // Data attributes
  [key: `data-${string}`]: MaybeAccessor<string | number | boolean>;

  // Event handlers
  onClick?: (e: MouseEvent) => void;
  onInput?: (e: Event) => void;
  onChange?: (e: Event) => void;
  onSubmit?: (e: Event) => void;
  onKeyDown?: (e: KeyboardEvent) => void;
  onKeyUp?: (e: KeyboardEvent) => void;
  onKeyPress?: (e: KeyboardEvent) => void;
  onFocus?: (e: FocusEvent) => void;
  onBlur?: (e: FocusEvent) => void;
  onMouseEnter?: (e: MouseEvent) => void;
  onMouseLeave?: (e: MouseEvent) => void;
  onMouseDown?: (e: MouseEvent) => void;
  onMouseUp?: (e: MouseEvent) => void;
  onMouseMove?: (e: MouseEvent) => void;
  onTouchStart?: (e: TouchEvent) => void;
  onTouchEnd?: (e: TouchEvent) => void;
  onTouchMove?: (e: TouchEvent) => void;
  onScroll?: (e: Event) => void;
  onLoad?: (e: Event) => void;
  onError?: (e: Event) => void;

  // Ref callback
  ref?: (el: HTMLElement) => void;

  // Children
  children?: JSX.Element | JSX.Element[] | string | number | (() => string | number);

  // Allow any other attribute
  [key: string]: unknown;
}

// Internal types for MoonBit interop
interface Attr {
  _0: string;
  _1: AttrValue;
}

interface AttrValue {
  $tag: 0 | 1 | 2;
  _0: unknown;
}

// Convert style object to CSS string
function styleToString(style: unknown): string {
  if (typeof style === "string") return style;
  if (typeof style !== "object" || style === null) return "";
  return Object.entries(style)
    .map(([key, value]) => {
      // Convert camelCase to kebab-case
      const cssKey = key.replace(/([A-Z])/g, "-$1").toLowerCase();
      return `${cssKey}: ${value}`;
    })
    .join("; ");
}

// Convert JSX props to createElement attrs format
function convertProps(props: Record<string, unknown> | null | undefined): Attr[] {
  if (!props) return [];
  const attrs: Attr[] = [];
  for (const [key, value] of Object.entries(props)) {
    if (key === "children") continue;

    // Map JSX prop names to DOM attribute format
    let attrName = key;
    let attrValue: AttrValue;

    // Handle className -> class
    if (key === "className") {
      attrName = "class";
    }

    // Handle style object -> CSS string
    if (key === "style") {
      const cssString = styleToString(value);
      attrValue = { $tag: 0, _0: cssString }; // AttrValue.Static
      attrs.push({ _0: attrName, _1: attrValue });
      continue;
    }

    // Handle event handlers (onClick -> click for addEventListener)
    if (key.startsWith("on") && typeof value === "function") {
      // Remove "on" prefix and lowercase first char: onClick -> click
      attrName = key.slice(2).toLowerCase();
      attrValue = { $tag: 2, _0: value }; // AttrValue.Handler
      attrs.push({ _0: attrName, _1: attrValue });
      continue;
    }

    // Handle dynamic values (functions)
    if (typeof value === "function") {
      attrValue = { $tag: 1, _0: value }; // AttrValue.Dynamic
    } else {
      attrValue = { $tag: 0, _0: String(value) }; // AttrValue.Static
    }

    attrs.push({ _0: attrName, _1: attrValue });
  }
  return attrs;
}

type Child = string | number | JSX.Element | (() => unknown) | Child[];

function convertChildren(children: unknown): unknown[] {
  if (!children) return [];
  let childArray: unknown[];
  if (!Array.isArray(children)) {
    childArray = [children];
  } else {
    childArray = children;
  }
  return childArray.flat().map((child) => {
    if (typeof child === "string") {
      return text(child);
    }
    if (typeof child === "number") {
      return text(String(child));
    }
    // Handle functions:
    // - No args (length === 0): signal accessor -> textDyn
    // - With args (length > 0): render function -> pass through
    if (typeof child === "function") {
      if (child.length === 0) {
        return textDyn(() => String(child()));
      }
      // Render function, pass through as-is
      return child;
    }
    return child;
  }).filter(Boolean);
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type Component = (props: any) => JSX.Element;

// JSX factory function
export function jsx(type: string | Component, props: Record<string, unknown> | null): JSX.Element {
  const { children, ...rest } = props || {};
  const attrs = convertProps(rest);
  const childNodes = convertChildren(children);

  if (typeof type === "string") {
    return createElement(type, attrs, childNodes) as JSX.Element;
  }

  // Function component
  if (typeof type === "function") {
    return type({ ...rest, children });
  }

  throw new Error(`Invalid JSX type: ${type}`);
}

// jsxs is the same as jsx for our implementation
export const jsxs = jsx;

// Fragment just returns children as-is (flattened)
export function Fragment({ children }: { children?: unknown }): unknown[] {
  return convertChildren(children);
}

// Export jsxDEV for development mode
export const jsxDEV = jsx;

// JSX namespace for TypeScript
export namespace JSX {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  export type Element = any;
  export interface IntrinsicElements {
    // All HTML elements use HTMLAttributes with reactive support
    a: HTMLAttributes;
    abbr: HTMLAttributes;
    address: HTMLAttributes;
    area: HTMLAttributes;
    article: HTMLAttributes;
    aside: HTMLAttributes;
    audio: HTMLAttributes;
    b: HTMLAttributes;
    base: HTMLAttributes;
    bdi: HTMLAttributes;
    bdo: HTMLAttributes;
    blockquote: HTMLAttributes;
    body: HTMLAttributes;
    br: HTMLAttributes;
    button: HTMLAttributes;
    canvas: HTMLAttributes;
    caption: HTMLAttributes;
    cite: HTMLAttributes;
    code: HTMLAttributes;
    col: HTMLAttributes;
    colgroup: HTMLAttributes;
    data: HTMLAttributes;
    datalist: HTMLAttributes;
    dd: HTMLAttributes;
    del: HTMLAttributes;
    details: HTMLAttributes;
    dfn: HTMLAttributes;
    dialog: HTMLAttributes;
    div: HTMLAttributes;
    dl: HTMLAttributes;
    dt: HTMLAttributes;
    em: HTMLAttributes;
    embed: HTMLAttributes;
    fieldset: HTMLAttributes;
    figcaption: HTMLAttributes;
    figure: HTMLAttributes;
    footer: HTMLAttributes;
    form: HTMLAttributes;
    h1: HTMLAttributes;
    h2: HTMLAttributes;
    h3: HTMLAttributes;
    h4: HTMLAttributes;
    h5: HTMLAttributes;
    h6: HTMLAttributes;
    head: HTMLAttributes;
    header: HTMLAttributes;
    hgroup: HTMLAttributes;
    hr: HTMLAttributes;
    html: HTMLAttributes;
    i: HTMLAttributes;
    iframe: HTMLAttributes;
    img: HTMLAttributes;
    input: HTMLAttributes;
    ins: HTMLAttributes;
    kbd: HTMLAttributes;
    label: HTMLAttributes;
    legend: HTMLAttributes;
    li: HTMLAttributes;
    link: HTMLAttributes;
    main: HTMLAttributes;
    map: HTMLAttributes;
    mark: HTMLAttributes;
    menu: HTMLAttributes;
    meta: HTMLAttributes;
    meter: HTMLAttributes;
    nav: HTMLAttributes;
    noscript: HTMLAttributes;
    object: HTMLAttributes;
    ol: HTMLAttributes;
    optgroup: HTMLAttributes;
    option: HTMLAttributes;
    output: HTMLAttributes;
    p: HTMLAttributes;
    picture: HTMLAttributes;
    pre: HTMLAttributes;
    progress: HTMLAttributes;
    q: HTMLAttributes;
    rp: HTMLAttributes;
    rt: HTMLAttributes;
    ruby: HTMLAttributes;
    s: HTMLAttributes;
    samp: HTMLAttributes;
    script: HTMLAttributes;
    search: HTMLAttributes;
    section: HTMLAttributes;
    select: HTMLAttributes;
    slot: HTMLAttributes;
    small: HTMLAttributes;
    source: HTMLAttributes;
    span: HTMLAttributes;
    strong: HTMLAttributes;
    style: HTMLAttributes;
    sub: HTMLAttributes;
    summary: HTMLAttributes;
    sup: HTMLAttributes;
    table: HTMLAttributes;
    tbody: HTMLAttributes;
    td: HTMLAttributes;
    template: HTMLAttributes;
    textarea: HTMLAttributes;
    tfoot: HTMLAttributes;
    th: HTMLAttributes;
    thead: HTMLAttributes;
    time: HTMLAttributes;
    title: HTMLAttributes;
    tr: HTMLAttributes;
    track: HTMLAttributes;
    u: HTMLAttributes;
    ul: HTMLAttributes;
    var: HTMLAttributes;
    video: HTMLAttributes;
    wbr: HTMLAttributes;
    // SVG elements
    svg: HTMLAttributes;
    path: HTMLAttributes;
    circle: HTMLAttributes;
    rect: HTMLAttributes;
    line: HTMLAttributes;
    polyline: HTMLAttributes;
    polygon: HTMLAttributes;
    ellipse: HTMLAttributes;
    g: HTMLAttributes;
    text: HTMLAttributes;
    tspan: HTMLAttributes;
    defs: HTMLAttributes;
    use: HTMLAttributes;
    image: HTMLAttributes;
    // Allow any custom element
    [key: string]: HTMLAttributes;
  }
  export interface ElementChildrenAttribute {
    children: {};
  }
}
