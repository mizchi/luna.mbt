import { createElement } from "react";
import { renderToString as renderReact } from "react-dom/server";
import { createComponent } from "solid-js";
import { renderToString as renderSolid, generateHydrationScript } from "solid-js/web";
import { definePage, html, island, raw } from "@luna_ui/luna/void/server";
import { ReactCounter } from "../src/react-counter";
import { SolidCounter } from "../src/counter.solid";
import type { Props } from "./index.server";

export default definePage<Props>(({ name, initialCount, titles }, page) => {
  const props = { initialCount };
  return html`
    ${raw(generateHydrationScript())}
    <h1>Luna + Void</h1>
    <p>Hello ${name}</p>
    <ul>
      ${titles.map((title) => html`<li>${title}</li>`)}
    </ul>
    <form method="post" action="/?addForm">
      <label>Title<input name="title" required /></label><button>Save</button>
    </form>
    ${page.errors ? html`<p role="alert">${Object.values(page.errors).join(", ")}</p>` : null}
    ${island("react", props, { fallback: raw(renderReact(createElement(ReactCounter, props))) })}
    ${island("solid", props, { fallback: raw(renderSolid(() => createComponent(SolidCounter, props), { renderId: "void-solid" })) })}
    <div style="height:1200px" aria-hidden="true"></div>
    ${island("luna", props, { strategy: "visible", fallback: html`<button data-counter="luna">Luna ${initialCount}</button>` })}
    <div style="height:1200px" aria-hidden="true"></div>
    ${island("luna", props, { strategy: "visible", fallback: html`<button data-counter="luna">Luna ${initialCount}</button>` })}
    <script>
      window.__ssrNodes = Array.from(document.querySelectorAll("[data-counter]"));
    </script>
  `;
});
