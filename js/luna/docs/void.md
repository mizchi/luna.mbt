# Void adapter

The `@luna_ui/luna/void` subpaths connect Luna's JavaScript build to
[Void](https://void.cloud/) Pages. Void owns routing, authentication, D1,
loaders, actions, validation, and head metadata. The adapter owns the HTML
document and explicitly registered client islands.

Tested with Void **1.1.11**, Vite **8.3.4**, and Node **24.21.0**. The adapter
uses Void's virtual renderer entry points; keep the exact Void peer version
until its integration contract has been tested against another release.
The SSR JSX additions described below are available in the repository build.

Luna's prepack hook and `just build-void` build only the MoonBit modules imported
by the npm wrapper; they do not regenerate unrelated Sol/Astra examples.

The workspace keeps Sol's existing SQLite v12 build permission and leaves
Void's unused SQLite v13 dependency unbuilt. This uses pnpm 10.19+'s
[version-specific build permissions](https://pnpm.io/10.x/settings#onlybuiltdependencies).
Void's Cloudflare plugin also requires the example's Wrangler 4.151.0.

## Vite configuration

Add `void` to the application, and use a local build or tarball of this package
until a release containing the SSR subpaths is published. Do not enable another
Void Pages adapter such as `@void/react/plugin` alongside `voidLuna()`; they
provide the same virtual modules. React and Solid can instead register islands
through the shared `mount()` contract below.

```ts
import { defineConfig } from "vite";
import { voidPlugin } from "void";
import { voidLuna } from "@luna_ui/luna/void";

export default defineConfig({
  plugins: [voidPlugin(), voidLuna({ islands: { counter: "./src/luna.island.tsx" } })],
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

Render the host HTML with `html` and place a Luna component with `lunaIsland()`.
It renders the component with hydration markers and sends the same props to
its registered client module. The `.island.tsx` extension is recognized by
Void's page scanner; the host page returns an HTML fragment.

```ts
// pages/index.island.tsx
import { definePage, html, lunaIsland } from "@luna_ui/luna/void/server";
import Counter from "../src/counter.luna";
import type { Props } from "./index.server";

export default definePage<Props>(
  ({ initialCount }) => html`
    <h1>Counter</h1>
    ${lunaIsland(
      "counter",
      Counter,
      { initialCount },
      { strategy: "visible" },
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
/** @jsxImportSource @luna_ui/luna/ssr */
// src/counter.luna.tsx
import { createSignal } from "@luna_ui/luna";

export default function Counter({ initialCount }: { initialCount: number }) {
  const [count, setCount] = createSignal(initialCount);
  return <button onClick={() => setCount((n) => n + 1)}>{() => `Luna ${count()}`}</button>;
}
```

Register the client boundary separately so the server can import the component
without importing the island scheduler:

```ts
// src/luna.island.tsx
import { defineLunaIsland } from "@luna_ui/luna/void/hydrate";
import Counter from "./counter.luna";

export default defineLunaIsland(Counter);
```

The `@luna_ui/luna/ssr` JSX runtime produces VNodes that work on both the server
and client. Pass a function child to track signal updates. `defineLunaIsland()`
hydrates these VNodes into the existing DOM and returns its disposer. Buttons,
inputs, and text nodes are retained, including values entered in uncontrolled
inputs before hydration. Each island has its own hydration scope, so repeated
instances can activate in either order.

`lunaIsland()` disposes the server render's reactive root. `onMount()` is skipped
during SSR. Reported structural or marker mismatches throw instead of silently
replacing the DOM. Use the same component and initial props on both sides.

The adapter invokes
disposers when mounted island elements leave the document or the client entry
is disposed. A pending asynchronous mount is also disposed if it finishes
after removal.

The scheduling options are `load` (default), `idle`, `visible`, and
`media:(query)`. Void's scheduler imports each module at that time. Multiple
instances of the same island module get separate component roots and props.
Disposal prevents later mounts; Void's scheduler does not expose cancellation
handles for its pending observers/imports.

For manual scheduling, import `initLunaIslands()` from
`@luna_ui/luna/void/scheduler`. This entry loads no Luna rendering runtime;
the plugin uses it automatically so deferred islands also defer their runtime.

Outside Void, the same JSX can use `renderToString(() => <Counter ... />)` and
`hydrate(element, () => <Counter ... />)` from `@luna_ui/luna/ssr`. `hydrate()`
returns a disposer for effects and event listeners. The original
`@luna_ui/luna` JSX runtime remains available for DOM-only components;
use `defineLunaIsland()` from `@luna_ui/luna/void/client` to render those
components by replacing their fallback. The DOM and hydrate helpers have
separate entries so each island loads only the renderer it uses.

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

## Island forms

Import `useIslandForm` from `@luna_ui/luna/void/form` inside a Luna component.
This follows Void's island form API and needs no SPA router or React/Solid
runtime. The separate entry keeps forms out of islands that do not use them.

```tsx
/** @jsxImportSource @luna_ui/luna/ssr */
import { createSignal } from "@luna_ui/luna";
import { useIslandForm } from "@luna_ui/luna/void/form";

export default function NoteForm() {
  const form = useIslandForm({ title: "" });
  const [failure, setFailure] = createSignal("");
  return (
    <form onSubmit={async (event: Event) => {
      event.preventDefault();
      setFailure("");
      try {
        await form.post("/?add");
      } catch (error) {
        setFailure(error instanceof Error ? error.message : "Submission failed");
      }
    }}>
      <input
        aria-label="Title"
        ref={(input) => form.setData("title", (input as HTMLInputElement).value)}
        value={() => form.data.title}
        onInput={(event: Event) => form.setData("title", (event.target as HTMLInputElement).value)}
      />
      <p role="alert">{() => form.errors.title ?? form.error?.message ?? failure()}</p>
      <button disabled={() => form.pending}>Save</button>
    </form>
  );
}
```

Register and render this component with `defineLunaIsland()` and `lunaIsland()`
as above. Read reactive properties inside JSX accessors, such as
`disabled={() => form.pending}`. The input ref copies any draft entered before
a delayed island hydrates into form state before its value accessor runs.

| API | Behavior |
| --- | --- |
| `data`, `setData(field, value)` | Read values and update a field, with types inferred from defaults |
| `errors`, `error` | Field errors from a 422 response, or an expected action error |
| `pending`, `hasChanges` | Request in progress, or changes from the last successful submission/defaults |
| `wasSuccessful`, `recentlySuccessful` | Success state; the latter resets after two seconds |
| `post(url)`, `put(url)`, `patch(url)`, `delete(url)` | Submit JSON to a Void island action |
| `reset(...fields)` | Restore all or selected fields to the last successful submission/defaults |
| `clearErrors(...fields)`, `clearError()` | Clear field errors or the action error |

Failed submissions keep form data. Authentication, server, and network failures
reject the submission promise; catch them in the event handler. Successful
actions reload the page to refresh its loader; same-origin redirects navigate
to the response URL. Mutation URLs and redirect destinations must use the
current HTTP(S) origin, without URL credentials. Relative URLs resolve against
the current page URL. Requests use `mode: "same-origin"`, so a redirect cannot
forward the form body to another origin. Duplicate submissions share the
in-flight request. Disposing
the component aborts its request, clears the success timer, and prevents late
responses from navigating.

The helper is safe to create during SSR. It currently submits JSON values;
file uploads and generated action-URL/body inference are not included. Field
names and values are inferred from `defaults`, and URL arguments are strings.
For a no-JS fallback, add a native `method`, `action`, and input `name`, with a
server action that parses form fields and redirects after success. The
[note form example](../examples-void/src/note-form.luna.tsx) includes this setup.

## Supported behavior and limits

- The adapter renders full documents. Links and native forms use full page
  navigation, including pages without the `.island` suffix. There is no Void
  SPA router, `Link`/`useForm` Context, or automatic client loader refresh.
  Standard actions and their JSON protocol remain in Void.
- Void 1.1.11 island actions return `{ success: true }` or 422 JSON errors.
  Its `withValidator({ body })` reads JSON. For a native form, parse fields
  with `c.req.parseBody()`, validate them, and return an explicit 303 redirect
  after a successful write (see the example's `addForm` action). Inline form
  validation uses the island form helper above or a regular Page. The adapter
  does not rewrite action responses.
- SSR JSX supports elements, fragments, function components, reactive text and
  attributes, events, and callback refs. DOM-only nodes and control-flow/portal
  helpers from `@luna_ui/luna` cannot be mixed into an SSR VNode tree.
  `dangerouslySetInnerHTML` is not supported by this JSX runtime. Attributes
  starting with `__` and the `sol:hk` hydration key are reserved for the
  renderer; the public JSX runtime rejects them. The JSX types also reject
  raw HTML and canonical internal attribute names. Use a text child or accessor
  to display untrusted strings.
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
just test-void-types    # built package JSX contract and form source types
just test-void-e2e      # build artifacts; Playwright against dev and build/preview
```

The E2E runner copies the sample and built npm artifacts into a temporary
directory, applies its own migrations, and deletes its DB/server afterward.
It tests email auth, D1 actions/loaders, validation, dangerous text escaping,
two independent delayed Luna islands, React/Solid hydration, and no-JS HTML.
It also tests a delayed Luna form against D1: preserving a pre-hydration draft,
retaining invalid input, showing pending state, and reloading after a write.
Real browser checks cover a same-origin 303 and block external 307/308 redirects
before any request reaches a separate loopback origin that permits CORS.
It compares DOM object identities: React, Solid, and Luna preserve their
buttons, and Luna retains its input nodes and values entered before activation.
No Cloudflare account or remote deployment is required.

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
