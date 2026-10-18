# Void adapter

The `@luna_ui/luna/void` subpaths connect Luna's JavaScript build to
[Void](https://void.cloud/) Pages. Void owns routing, authentication, D1,
loaders, actions, validation, and head metadata. The adapter owns the HTML
document and explicitly registered client islands.

Tested with Void **1.1.11**, Vite **8.3.4**, and Node **24.21.0**. The adapter
uses Void's virtual renderer entry points; keep the exact Void peer version
until its integration contract has been tested against another release.
This feature is in the repository build and has not been published to npm yet.

Luna's prepack hook and `just build-void` build only the MoonBit modules imported
by the npm wrapper; they do not regenerate unrelated Sol/Astra examples.

The workspace keeps Sol's existing SQLite v12 build permission and leaves
Void's unused SQLite v13 dependency unbuilt. This uses pnpm 10.19+'s
[version-specific build permissions](https://pnpm.io/10.x/settings#onlybuiltdependencies).
Void's Cloudflare plugin also requires the example's Wrangler 4.151.0.

## Vite configuration

Add `void` to the application, and use a local build or tarball of this package
until a release containing these subpaths is published. Do not enable another
Void Pages adapter such as `@void/react/plugin` alongside `voidLuna()`; they
provide the same virtual modules. React and Solid can instead register islands
through the shared `mount()` contract below.

```ts
import { defineConfig } from "vite";
import { voidPlugin } from "void";
import { voidLuna } from "@luna_ui/luna/void";

export default defineConfig({
  plugins: [voidPlugin(), voidLuna({ islands: { counter: "./src/counter.luna.tsx" } })],
});
```

Paths in `islands` resolve from Vite's configured root. The adapter reads Void's
configured pages directory, including `sourceDir`; `pagesDir` can override it.
Only registered island modules enter the client manifest. Server page and
layout modules stay on the server.

## Loader and page

Keep the usual `.server.ts` backend, including `InferProps`:

```ts
// pages/index.server.ts
import { defineHandler, type InferProps } from "void";

export const loader = defineHandler(() => ({ initialCount: 2 }));
export type Props = InferProps<typeof loader>;
```

Render the host HTML with `html` and place the interactive boundary with
`island()`. The `.island.tsx` extension is recognized by Void's page scanner;
this server module returns an HTML fragment and does not run Luna DOM JSX.

```ts
// pages/index.island.tsx
import { definePage, html, island } from "@luna_ui/luna/void/server";
import type { Props } from "./index.server";

export default definePage<Props>(
  ({ initialCount }) => html`
    <h1>Counter</h1>
    ${island(
      "counter",
      { initialCount },
      {
        strategy: "visible",
        fallback: html`<button>Luna ${initialCount}</button>`,
      },
    )}
  `,
);
```

`html` escapes interpolated text and quoted attribute values, supports arrays
of fragments, and leaves `Html` fragments intact. It is not a JavaScript or CSS
escaper: interpolate values in text or quoted attributes, never in scripts,
styles, tag names, or attribute names. `raw()` is an explicit escape hatch for
trusted renderer output. Island props must be JSON serializable; functions,
undefined, symbols, bigint, and non-finite numbers fail rather than silently
changing the payload. Serialization escapes JSON for an HTML attribute.

Page functions may be asynchronous. Their second argument is Void's
`PageObject`, which contains params, shared data, errors, URL, and head data.
Only the props explicitly passed to each `island()` are sent to its client.
Root, nested, and named layouts follow Void's generated layout tree. A layout
receives `{ ...page.props, children: Html }` and returns another HTML fragment.

```ts
// pages/layout.island.tsx
import { definePage, html, type Html } from "@luna_ui/luna/void/server";

export default definePage<{ children: Html }>(({ children }) => html`<main>${children}</main>`);
```

## Luna client module

```tsx
/** @jsxImportSource @luna_ui/luna */
// src/counter.luna.tsx
import { createSignal } from "@luna_ui/luna";
import { defineLunaIsland } from "@luna_ui/luna/void/client";

export default defineLunaIsland(({ initialCount }: { initialCount: number }) => {
  const [count, setCount] = createSignal(initialCount);
  return <button onClick={() => setCount((n) => n + 1)}>{() => `Luna ${count()}`}</button>;
});
```

The local JSX pragma keeps Luna separate from other JSX runtimes. Pass a
function child to track signal updates. `defineLunaIsland()` creates a Luna
root, renders the component, and returns its disposer. The adapter invokes
disposers when mounted island elements leave the document or the client entry
is disposed. A pending asynchronous mount is also disposed if it finishes
after removal.

The scheduling options are `load` (default), `idle`, `visible`, and
`media:(query)`. Void's scheduler imports each module at that time. Multiple
instances of the same island module get separate component roots and props.
Disposal prevents later mounts; Void's scheduler does not expose cancellation
handles for its pending observers/imports.

## Other renderers

Any registered module may default-export `Island<Props>`:

```ts
import { createElement } from "react";
import { hydrateRoot } from "react-dom/client";
import type { Island } from "@luna_ui/luna/void/client";
import Counter from "./Counter";

export default {
  mount(element, props) {
    const root = hydrateRoot(element, createElement(Counter, props));
    return () => root.unmount();
  },
} satisfies Island<{ initialCount: number }>;
```

`mount(element, props)` may return a cleanup function or a promise of one.
The host page provides that renderer's SSR markup with
`fallback: raw(renderToString(...))`. Solid hydration needs a matching
`renderId` on the server and client, and `generateHydrationScript()` in the
document. The [working example](../examples-void/) includes both renderers.

## Supported behavior and limits

- The adapter renders full documents. Links and native forms use full page
  navigation, including pages without the `.island` suffix. There is no Void
  SPA router, `Link`/`useForm` Context, or automatic client loader refresh.
  Standard actions and their JSON protocol remain in Void.
- Void 1.1.11 island actions return `{ success: true }` or 422 JSON errors.
  Its `withValidator({ body })` reads JSON. For a native form, parse fields
  with `c.req.parseBody()`, validate them, and return an explicit 303 redirect
  after a successful write (see the example's `addForm` action). Inline form
  validation needs an island form handler or a regular Page. The adapter does
  not rewrite action responses.
- Luna's current JS package provides a DOM renderer, not an SSR renderer or a
  DOM-reusing `hydrate()` export. Its fallback HTML is generated by the host
  page and **replaced** when Luna mounts. React/Solid islands can reuse their
  SSR DOM through their own hydration APIs.
- Server pages/layouts must return `Html`; a Luna DOM node cannot run on a
  Worker. Client-only pages (`ssr = false`) and deferred props fail explicitly.
  Native prerendering is delegated to Void and is not covered by this fixture.
- Page additions/removals trigger a full reload in development. Structural
  SPA HMR and import-attribute island discovery are not implemented. Islands
  are registered explicitly in the plugin options.

## Verification

From the repository root:

```sh
just test-void          # escaping, layouts, plugin root/manifest, cleanup races
just test-void-e2e      # build artifacts; Playwright against dev and build/preview
```

The E2E runner copies the sample and built npm artifacts into a temporary
directory, applies its own migrations, and deletes its DB/server afterward.
It tests email auth, D1 actions/loaders, validation, dangerous text escaping,
two independent delayed Luna islands, React/Solid hydration, and no-JS HTML.
It compares DOM object identities: React/Solid preserve their buttons; Luna
replaces its fallback buttons. No Cloudflare account or remote deployment is
required.

To edit the sample interactively after building the package:

```sh
just build-void
pnpm --filter @luna_ui/void-example exec void db migrate
pnpm --filter @luna_ui/void-example dev
```

The example requires a session before `/` can load. Create one through the
same-origin `/api/auth/sign-up/email` endpoint with `name`, `email`, and a
password of at least 12 characters. The example is a backend/renderer fixture
and does not include a signup screen.
