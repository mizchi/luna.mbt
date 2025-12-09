// JSX Runtime for @mizchi/ui
// Usage: Configure tsconfig.json with:
//   "jsx": "react-jsx",
//   "jsxImportSource": "@mizchi/ui"

import {
  div, span, p, button, a, input, textarea, form, label,
  h1, h2, h3, ul, ol, li, img, br, hr,
  text,
  className, classNameDyn, id, type, placeholder, value, valueDyn,
  href, src, alt, disabled, disabledDyn,
  onClick, onInput, onChange, onSubmit, onKeyDown, onKeyUp,
  onFocus, onBlur, onMouseEnter, onMouseLeave,
  style, styleDyn, attr, attrDyn,
} from "./dom.js";

// Element factory map
const elements = {
  div, span, p, button, a, input, textarea, form, label,
  h1, h2, h3, ul, ol, li, img, br, hr,
};

// Attribute converters
const attrConverters = {
  className: (v) => typeof v === "function" ? classNameDyn(v) : className(v),
  class: (v) => typeof v === "function" ? classNameDyn(v) : className(v),
  id: (v) => id(v),
  type: (v) => type(v),
  placeholder: (v) => placeholder(v),
  value: (v) => typeof v === "function" ? valueDyn(v) : value(v),
  href: (v) => href(v),
  src: (v) => src(v),
  alt: (v) => alt(v),
  disabled: (v) => typeof v === "function" ? disabledDyn(v) : disabled(v),
  onClick: (v) => onClick(v),
  onInput: (v) => onInput(v),
  onChange: (v) => onChange(v),
  onSubmit: (v) => onSubmit(v),
  onKeyDown: (v) => onKeyDown(v),
  onKeyUp: (v) => onKeyUp(v),
  onFocus: (v) => onFocus(v),
  onBlur: (v) => onBlur(v),
  onMouseEnter: (v) => onMouseEnter(v),
  onMouseLeave: (v) => onMouseLeave(v),
  style: (v) => typeof v === "function" ? styleDyn(v) : style(Object.entries(v)),
};

function convertAttrs(props) {
  if (!props) return [];
  const attrs = [];
  for (const [key, value] of Object.entries(props)) {
    if (key === "children") continue;
    const converter = attrConverters[key];
    if (converter) {
      attrs.push(converter(value));
    } else {
      // Generic attribute
      if (typeof value === "function") {
        attrs.push(attrDyn(key, value));
      } else {
        attrs.push(attr(key, String(value)));
      }
    }
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
    return child;
  }).filter(Boolean);
}

// JSX factory function
export function jsx(type, props) {
  const { children, ...rest } = props || {};
  const attrs = convertAttrs(rest);
  const childNodes = convertChildren(children);

  if (typeof type === "string") {
    const factory = elements[type];
    if (factory) {
      // input, img, br, hr don't take children
      if (type === "input" || type === "img") {
        return factory(attrs);
      }
      if (type === "br" || type === "hr") {
        return factory();
      }
      return factory(attrs, childNodes);
    }
    throw new Error(`Unknown element: ${type}`);
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
