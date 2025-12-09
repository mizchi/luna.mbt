# Target Support

## Supported Targets

This package **only supports the `js` target** (JavaScript/Browser).

```json
{
  "supported-targets": ["js"]
}
```

## Why JS-only?

This UI library depends on browser-specific APIs:
- **DOM API** (`@dom`) - For rendering to actual DOM nodes
- **JSON API** (`@json`) - For state serialization
- **Browser Events** (`@event`) - For event handling

These APIs are not available in other targets (wasm, wasm-gc, native).

## Running Tests

Use the `js` target specifically:

```bash
# ✅ Correct - test with js target
moon test --target js --package mizchi/js/_experimental/ui

# ❌ Wrong - will fail on wasm targets
moon test --target all --package mizchi/js/_experimental/ui
```

## Multi-Target Support (Future)

To support multiple targets in the future, we would need:

### Option 1: Backend Abstraction
- Create trait-based abstractions for DOM, Events, etc.
- Implement JS backend (`hooks_serialization_js.mbt` ✅ already done)
- Implement WASM backend (`hooks_serialization_wasm.mbt`)
- Implement Native backend (`hooks_serialization_native.mbt`)

### Option 2: Virtual DOM Only
- Keep core VNode types backend-agnostic (✅ already done in `vdom.mbt`)
- Renderers are backend-specific:
  - `renderer_dom.mbt` - JS/Browser only
  - `renderer_canvas.mbt` - Could work on WASM
  - `renderer_terminal.mbt` - Native only

## Current Architecture

```
Backend-Agnostic:
├── vdom.mbt          ✅ VNode[H] generic over handler type
├── hooks.mbt         ✅ Core hooks (no serialization)
├── element.mbt       ⚠️  Returns JSVNode (JS-specific)
└── props_builder.mbt ⚠️  Returns JSProps (JS-specific)

JS-Specific:
├── vdom_js.mbt                ❌ JSVNode = VNode[JSHandler]
├── hooks_serialization_js.mbt ❌ JSON serialization
├── renderer_dom.mbt           ❌ DOM rendering
├── renderer_ssr.mbt           ❌ Server-side rendering
└── reconcile.mbt              ❌ Uses @dom.Node directly
```

## Testing Strategy

Since this package is JS-only, all tests are written for the JS target:

```bash
# Run all tests
moon test --target js --package mizchi/js/_experimental/ui

# Or test the entire project (will only test supported targets per package)
moon test --target js
```

**Note**: `moon test --target all` at the project level will attempt to build all packages for all targets. Since this package is marked as `"supported-targets": ["js"]`, it should automatically skip wasm/native targets. However, if you see failures, it's likely from other packages in the project that have wasm support issues.

## Workaround for Project-Wide Testing

If you want to test the entire project with `moon test --target all`, ensure all packages have correct `supported-targets` specified:

```bash
# This should work if all packages have correct supported-targets
moon test --target all

# If it fails, test targets separately:
moon test --target js
moon test --target wasm  # Will skip JS-only packages
```
