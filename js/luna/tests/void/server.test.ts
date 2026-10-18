import { describe, expect, it } from "vitest";
import type { PageObject } from "void/pages-protocol";
import { createPageRenderer, definePage, html, island, raw } from "../../src/void/server";

const page: PageObject = {
  component: "index",
  props: { count: 2 },
  params: {},
  shared: {},
  url: "/",
  errors: null,
  head: { title: "Counter <two>", htmlAttrs: { lang: "ja" }, bodyAttrs: { class: "app" } },
};
const assets = {
  css: '<link href="/app.css" rel="stylesheet">',
  preloads: "",
  body: '<script src="/app.js"></script>',
};

describe("Void server HTML", () => {
  it("escapes text and JSON props while preserving explicit HTML fragments", () => {
    const payload = '\"><script>alert("x")</script>&';
    const fragment = html`<p>${payload}</p>
      ${[html`<b>safe</b>`, null, false]}`;
    expect(String(fragment).replace(/>\s+</g, "><")).toBe(
      "<p>&quot;&gt;&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;&amp;</p><b>safe</b>",
    );
    const markup = String(
      island("counter", { payload }, { strategy: "visible", fallback: fragment }),
    );
    document.body.innerHTML = markup;
    const element = document.querySelector("[data-island]")!;
    expect(element.getAttribute("data-hydrate")).toBe("visible");
    expect(JSON.parse(element.getAttribute("data-props")!)).toEqual({ payload });
    expect(document.querySelector("script")).toBeNull();
    expect(element.querySelector("b")?.textContent).toBe("safe");
    expect(element.firstChild).toBe(element.querySelector("p"));
  });

  it("rejects props that cannot survive JSON serialization", () => {
    expect(() => island("counter", { value: undefined })).toThrow(/JSON/);
    expect(() => island("counter", { value: Number.NaN })).toThrow(/JSON/);
    expect(() => island('counter" onclick="x', {})).toThrow(/island/i);
    expect(() => island("counter", {}, { strategy: "later" as "load" })).toThrow(/strategy/i);
  });

  it("awaits pages and wraps nested layouts inside a complete document", async () => {
    const render = createPageRenderer(
      {
        index: async () => ({
          default: definePage<{ count: number }>(
            async ({ count }) => html`<button>${count}</button>`,
          ),
        }),
        inner: async () => ({
          default: definePage<{ children: unknown }>(
            ({ children }) => html`<main>${children}</main>`,
          ),
        }),
        outer: async () => ({
          default: definePage<{ children: unknown }>(
            ({ children }) => html`<article>${children}</article>`,
          ),
        }),
      },
      { index: ["outer", "inner"] },
    );
    const document = await render(page, assets);
    expect(document).toContain('<html lang="ja">');
    expect(document).toContain('<body class="app">');
    expect(document).toContain("<title>Counter &lt;two&gt;</title>");
    expect(document).toContain("<article><main><button>2</button></main></article>");
    expect(document).toContain(assets.css);
    expect(document).toContain(assets.body);
    expect(document).not.toContain('"shared"');
  });

  it("fails clearly for missing pages and unsupported deferred props", async () => {
    const render = createPageRenderer({ index: async () => ({ default: () => raw("ok") }) });
    await expect(render({ ...page, component: "missing" }, assets)).rejects.toThrow(/missing/);
    await expect(render({ ...page, deferred: ["late"] }, assets)).rejects.toThrow(/deferred/i);
    const invalid = createPageRenderer({ index: async () => ({ default: () => "unescaped" }) });
    await expect(invalid(page, assets)).rejects.toThrow(/html/i);
  });
});
