// MoonBit emits JavaScript without declarations. Keep the interop types here.
// @ts-ignore TypeScript 6 requires declarations; TypeScript 7 infers this generated JS.
import * as api from "../../../../_build/js/release/build/mizchi/luna/js/api/api.js";

export type Attr = {
  _0: string;
  _1: { $tag: 0 | 1 | 2; _0: unknown };
};

// Export individual bindings so server-only and client-only code can be removed.
export const ssrText = api.ssrText as (value: string) => unknown;
export const ssrTextDyn = api.ssrTextDyn as (getter: () => string) => unknown;
export const ssrFragment = api.ssrFragment as (children: unknown[]) => unknown;
export const ssrElement = api.ssrElement as (
  tag: string,
  attrs: Attr[],
  children: unknown[],
) => unknown;
export const ssrRender = api.ssrRender as (node: unknown) => string;
export const ssrHydrate = api.ssrHydrate as unknown as (
  container: Element,
  node: unknown,
) => {
  _0: string;
  _1: () => void;
};
