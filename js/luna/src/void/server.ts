import { renderBodyAttrs, renderHeadToString, renderHtmlAttrs } from "void/pages-head";
import type { RenderAssetTags } from "void/handler";
import type { PageObject } from "void/pages-protocol";
import { assertIslandId, assertStrategy, type IslandStrategy } from "./contracts";

/** Trusted markup. Use html for interpolation; raw is an explicit escape hatch. */
export class Html {
  constructor(readonly value: string) {}
  toString(): string {
    return this.value;
  }
}

function escape(value: unknown): string {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function interpolate(value: unknown): string {
  if (value == null || value === false) return "";
  if (value instanceof Html) return value.value;
  if (Array.isArray(value)) return value.map(interpolate).join("");
  return escape(value);
}

/** Values must appear in HTML text or quoted attributes, never JS/CSS/tag names. */
export function html(strings: TemplateStringsArray, ...values: unknown[]): Html {
  return new Html(
    strings.reduce(
      (result, part, index) =>
        result + part + (index < values.length ? interpolate(values[index]) : ""),
      "",
    ),
  );
}

/** Only pass markup from a trusted renderer, never user input. */
export function raw(markup: string): Html {
  return new Html(markup);
}

export function island<P extends object>(
  id: string,
  props: P,
  options: { strategy?: IslandStrategy; fallback?: Html } = {},
): Html {
  assertIslandId(id);
  const strategy = options.strategy ?? "load";
  assertStrategy(strategy);
  const json = JSON.stringify(props, (_key, value: unknown) => {
    if (
      ["undefined", "function", "symbol", "bigint"].includes(typeof value) ||
      (typeof value === "number" && !Number.isFinite(value))
    ) {
      throw new TypeError("Island props must be JSON serializable");
    }
    return value;
  });
  // Keep the renderer's fragment exact: whitespace text nodes inside this
  // boundary can make hydrateRoot reject otherwise matching SSR markup.
  return new Html(
    `<section data-island="${escape(id)}" data-hydrate="${escape(strategy)}" data-props="${escape(json)}">` +
      (options.fallback?.value ?? "") +
      "</section>",
  );
}

export type Page<P extends object = Record<string, unknown>> = (
  props: P,
  page: PageObject,
) => Html | Promise<Html>;

export function definePage<P extends object>(page: Page<P>): Page<P> {
  return page;
}

export type PageModules = Record<string, () => Promise<{ default: unknown }>>;

export function createPageRenderer(modules: PageModules, layouts: Record<string, string[]> = {}) {
  async function render(id: string, props: object, page: PageObject): Promise<Html> {
    if (!Object.hasOwn(modules, id)) throw new Error(`Missing Void page: ${id}`);
    const component = (await modules[id]()).default;
    if (typeof component !== "function")
      throw new TypeError(`Void page ${id} must export a function`);
    const result: unknown = await (component as Page)(props as Record<string, unknown>, page);
    if (!(result instanceof Html))
      throw new TypeError(`Void page ${id} must return html or raw markup`);
    return result;
  }

  return async (page: PageObject, assets: RenderAssetTags): Promise<string> => {
    if (page.deferred?.length)
      throw new Error("The Luna Void adapter does not support deferred props");
    let body = await render(page.component, page.props, page);
    for (const id of [...(layouts[page.component] ?? [])].reverse()) {
      body = await render(id, { ...page.props, children: body }, page);
    }
    const head = page.head ?? {};
    return `<!doctype html><html${renderHtmlAttrs(head)}><head>${renderHeadToString(head)}${assets.css}${assets.preloads}</head><body${renderBodyAttrs(head)}>${body}${assets.body}</body></html>`;
  };
}

export type { IslandStrategy } from "./contracts";
