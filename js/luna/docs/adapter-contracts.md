# Sol and Void adapter contracts

Both adapters share the reactive form state in `src/form/state.ts` and the renderer-free island lifetime in `js/loader/src/runtime/islands.ts`. Protocol decoding and navigation remain in their respective adapters. Shared runtime sources are bundled into each published package; consumers do not need another runtime dependency.

| Concern           | Void                                           | Sol                                                       |
| ----------------- | ---------------------------------------------- | --------------------------------------------------------- |
| Form helper       | `useIslandForm` from `@luna_ui/luna/void/form` | `useActionForm` from `@luna_ui/luna/sol/form`             |
| Successful action | Refresh the document                           | Invalidate the fragment cache and refresh the current URL |
| Redirect          | Document navigation                            | Sol fragment navigation                                   |
| Page data         | Void page data                                 | HTML fragments, including title and head assets           |
| Validation        | HTTP 422 with `fieldErrors`                    | HTTP 422 from `ActionResult::validation_errors`           |

## Form state and transport

Each helper creates signals in the island's reactive root. Form values, the submitted baseline, field errors, pending state and success flags belong to that root. A concurrent submission returns the existing promise. Validation and HTTP errors retain input. A successful write updates the baseline to the submitted values, preserving edits made while the request was pending. Disposing the root aborts the request, clears the success timer and ignores late results.

The internal transport result is a discriminated union: `success`, `redirect`, `validation`, or `error`. Network failures, cancellation and decoding failures reject the submission promise. Sol exposes those rejection kinds through `SolActionError.kind`; Void retains its existing error and boundary behavior. Callers should catch rejected submissions in their event handler.

Both browser transports resolve URLs against `location.href`, reject non-HTTP(S), foreign-origin and credential-bearing URLs, and fetch with `mode: "same-origin"` and `credentials: "same-origin"`. HTTP redirects are inspected before decoding the body. This also prevents a document `<base>` from changing the request destination.

Sol's existing MoonBit `TypedActionKey` / `TypedActionResponse` APIs remain compatible. JSON parsing failures now reach `DecodeError`. Cancellation and network failures use the existing `NetworkError` variant; field validation uses `Error(422, ...)`. The FFI uses string discriminators and plain data; it no longer constructs compiler-private enum tags. `ActionOptions.timeout` and `signal` both cancel requests.

Sol's action registry registers POST routes. Use `.post()` for those endpoints; other methods require matching server routes. JSON forms do not support file uploads. Generated URL/request-type inference for the JavaScript form helpers is separate work; the existing MoonBit typed invokers still provide it.

## Navigation port

Forms depend on this contract rather than a router implementation:

```ts
interface NavigationPort {
  navigate(url: string): void | Promise<void>;
  refresh(): void | Promise<void>;
}
```

`sol-nav` installs the default Sol port as `window.__LUNA_NAVIGATION__`. Refresh clears its fragment cache and replaces the current history entry. New fragments dispose the outgoing islands before replacement and scan the new DOM afterward, including cache revalidation. Void's adapter uses document navigation and reload.

A Sol island can inject a port when integrating another router:

```ts
import { useActionForm } from "@luna_ui/luna/sol/form";

// Inside an island's reactive root:
const form = useActionForm(
  { title: "" },
  {
    navigate: (url) => router.navigate(url),
    refresh: () => router.refresh(),
  },
);
```

This boundary preserves Sol streaming, ISR and typed actions. It does not translate Sol HTML fragments into Void page-data JSON.

## Island lifetime

The common renderer contract is `mount(element, props) => void | Dispose | Promise<void | Dispose>`. Sol's loaders adapt their existing `hydrate(element, state, id)` exports to this contract, so existing synchronous exports continue to work.

- Mounts are deduplicated per element, rather than per component ID.
- DOM removal, explicit unload and navigation run the returned disposer once.
- A mount that finishes after removal or replacement disposes its result immediately.
- Pending imports check that their element still owns the mount before executing the renderer.
- Failed mounts can be retried by scanning again.

`createHydrator` returns the setup cleanup and clears its hydration marker when disposed. Sol generates a reactive root around component construction and rendering, returning its disposer to both the Luna and WC loaders. Manual hydration triggers and the existing module-origin allowlist remain available.

Run `just test-adapter-contracts`, `just test-void-e2e`, and `just -f sol/justfile test-sol-app-hydration` to verify these boundaries.
