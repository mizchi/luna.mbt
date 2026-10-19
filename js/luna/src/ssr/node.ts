import * as bridge from "./bridge";

const node = Symbol("LunaVNode");

/** An SSR-capable Luna VNode, distinct from the DOM renderer's LunaNode. */
export interface VNode {
  readonly [node]: unknown;
}

export function isVNode(value: unknown): value is VNode {
  return typeof value === "object" && value !== null && node in value;
}

export function unwrap(value: VNode): unknown {
  if (!isVNode(value))
    throw new TypeError("Use @luna_ui/luna/ssr JSX for server-rendered components");
  return value[node];
}

export function text(value: string): VNode {
  return { [node]: bridge.ssrText(value) };
}

export function textDyn(getter: () => string): VNode {
  return { [node]: bridge.ssrTextDyn(getter) };
}

export function fragment(children: VNode[]): VNode {
  return { [node]: bridge.ssrFragment(children.map(unwrap)) };
}

export function element(
  tag: string,
  attrs: Parameters<typeof bridge.ssrElement>[1],
  children: VNode[],
): VNode {
  return { [node]: bridge.ssrElement(tag, attrs, children.map(unwrap)) };
}
