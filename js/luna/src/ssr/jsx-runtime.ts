import type { JSX as DomJSX } from "../jsx-runtime";
import { element, fragment, text, textDyn, type VNode } from "./node";
import type { Attr } from "./bridge";

const booleanAttrs = new Set([
  "disabled",
  "checked",
  "selected",
  "multiple",
  "readonly",
  "required",
  "hidden",
  "autofocus",
  "open",
  "controls",
  "loop",
  "muted",
  "autoplay",
]);

function attributeValue(name: string, value: unknown): string {
  if (value == null || (value === false && booleanAttrs.has(name.toLowerCase())))
    return "__remove__";
  if (value === true && booleanAttrs.has(name.toLowerCase())) return "";
  if (name === "style" && typeof value === "object") {
    return Object.entries(value)
      .map(([key, item]) => `${key.replace(/[A-Z]/g, (char) => `-${char.toLowerCase()}`)}: ${item}`)
      .join("; ");
  }
  return String(value);
}

function attributes(props: Record<string, unknown>): Attr[] {
  const attrs: Attr[] = [];
  for (const [key, value] of Object.entries(props)) {
    if (key === "children" || key === "key") continue;
    if (!/^[^\s"'<>/=]+$/.test(key)) throw new TypeError(`Invalid JSX attribute: ${key}`);
    if (key === "dangerouslySetInnerHTML")
      throw new TypeError("SSR JSX does not support dangerouslySetInnerHTML");
    if (key.startsWith("__") || key.toLowerCase() === "sol:hk")
      throw new TypeError(`Reserved SSR JSX attribute: ${key}`);
    let name = key === "className" ? "class" : key === "htmlFor" ? "for" : key;
    let attr: Attr["_1"];
    if (key === "ref" || /^on/i.test(key)) {
      if (value == null) continue;
      if (typeof value !== "function") throw new TypeError(`${key} must be a function`);
      name = key === "ref" ? "__ref" : key.slice(2).toLowerCase();
      attr = { $tag: 2, _0: value };
    } else if (typeof value === "function") {
      attr = { $tag: 1, _0: () => attributeValue(name, value()) };
    } else {
      attr = { $tag: 0, _0: attributeValue(name, value) };
    }
    attrs.push({ _0: name, _1: attr });
  }
  return attrs;
}

function children(value: unknown): VNode[] {
  if (value == null || typeof value === "boolean") return [];
  if (Array.isArray(value)) return value.flatMap(children);
  if (typeof value === "string" || typeof value === "number") return [text(String(value))];
  if (typeof value === "function") return [textDyn(() => String(value()))];
  return [value as VNode];
}

/** DOM-independent JSX, shared by the server renderer and client hydrator. */
export function jsx<P extends object>(
  type: string | ((props: P) => VNode),
  props: P | null,
): VNode {
  if (typeof type === "function") return type((props ?? {}) as P);
  if (!/^[a-z][a-z\d:.-]*$/i.test(type)) throw new TypeError(`Invalid JSX tag: ${type}`);
  const values = props ?? {};
  return element(type, attributes(values), children((values as Record<string, unknown>).children));
}

export const jsxs = jsx;
export const jsxDEV = jsx;

export function Fragment(props: { children?: unknown }): VNode {
  return fragment(children(props.children));
}

export namespace JSX {
  export type Element = VNode;
  export type IntrinsicElements = {
    [Tag in keyof DomJSX.IntrinsicElements]: DomJSX.IntrinsicElements[Tag] & {
      dangerouslySetInnerHTML?: never;
      "sol:hk"?: never;
      [internal: `__${string}`]: never;
    };
  };
  export interface ElementChildrenAttribute {
    children: {};
  }
}
