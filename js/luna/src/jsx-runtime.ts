// @ts-nocheck
// JSX Runtime for @mizchi/luna
// Usage: Configure tsconfig.json with:
//   "jsx": "react-jsx",
//   "jsxImportSource": "@mizchi/luna"

import { text, textDyn, createElement } from "./index";

// Convert style object to CSS string
function styleToString(style) {
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
function convertProps(props) {
  if (!props) return [];
  const attrs = [];
  for (const [key, value] of Object.entries(props)) {
    if (key === "children") continue;

    // Map JSX prop names to DOM attribute format
    let attrName = key;
    let attrValue;

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

function convertChildren(children) {
  if (!children) return [];
  if (!Array.isArray(children)) {
    children = [children];
  }
  return children.flat().map((child) => {
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

// JSX factory function
export function jsx(type, props) {
  const { children, ...rest } = props || {};
  const attrs = convertProps(rest);
  const childNodes = convertChildren(children);

  if (typeof type === "string") {
    return createElement(type, attrs, childNodes);
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
export function Fragment({ children }) {
  return convertChildren(children);
}

// Export jsxDEV for development mode
export const jsxDEV = jsx;

// JSX namespace for TypeScript
export namespace JSX {
  export type Element = any;
  export interface IntrinsicElements {
    // HTML elements
    a: any;
    abbr: any;
    address: any;
    area: any;
    article: any;
    aside: any;
    audio: any;
    b: any;
    base: any;
    bdi: any;
    bdo: any;
    blockquote: any;
    body: any;
    br: any;
    button: any;
    canvas: any;
    caption: any;
    cite: any;
    code: any;
    col: any;
    colgroup: any;
    data: any;
    datalist: any;
    dd: any;
    del: any;
    details: any;
    dfn: any;
    dialog: any;
    div: any;
    dl: any;
    dt: any;
    em: any;
    embed: any;
    fieldset: any;
    figcaption: any;
    figure: any;
    footer: any;
    form: any;
    h1: any;
    h2: any;
    h3: any;
    h4: any;
    h5: any;
    h6: any;
    head: any;
    header: any;
    hgroup: any;
    hr: any;
    html: any;
    i: any;
    iframe: any;
    img: any;
    input: any;
    ins: any;
    kbd: any;
    label: any;
    legend: any;
    li: any;
    link: any;
    main: any;
    map: any;
    mark: any;
    menu: any;
    meta: any;
    meter: any;
    nav: any;
    noscript: any;
    object: any;
    ol: any;
    optgroup: any;
    option: any;
    output: any;
    p: any;
    picture: any;
    pre: any;
    progress: any;
    q: any;
    rp: any;
    rt: any;
    ruby: any;
    s: any;
    samp: any;
    script: any;
    search: any;
    section: any;
    select: any;
    slot: any;
    small: any;
    source: any;
    span: any;
    strong: any;
    style: any;
    sub: any;
    summary: any;
    sup: any;
    table: any;
    tbody: any;
    td: any;
    template: any;
    textarea: any;
    tfoot: any;
    th: any;
    thead: any;
    time: any;
    title: any;
    tr: any;
    track: any;
    u: any;
    ul: any;
    var: any;
    video: any;
    wbr: any;
    // SVG elements
    svg: any;
    path: any;
    circle: any;
    rect: any;
    line: any;
    polyline: any;
    polygon: any;
    ellipse: any;
    g: any;
    text: any;
    tspan: any;
    defs: any;
    use: any;
    image: any;
    // Allow any custom element
    [key: string]: any;
  }
  export interface ElementChildrenAttribute {
    children: {};
  }
}
