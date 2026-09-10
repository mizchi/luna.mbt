# Luna CSS Utility Module

Atomic CSS generation and portable style composition for Luna.

## Composable styles

The `Style` API adds StyleX-inspired composition to the existing atomic CSS
utilities without depending on StyleX. It supports conditional styles, themes,
dynamic custom properties, static extraction, and server rendering. Style
construction and composition are pure MoonBit and work on JS, native, and Wasm.
Unlike the legacy string API, a `Style` retains property information until it is
resolved to attributes. Declare reusable styles outside render callbacks.

```moonbit
let base = @css.create([
  @css.rule(@css.Display, "flex"),
  @css.rule(@css.Color, "var(--text)"),
  @css.rule_on(@css.Hover, @css.Color, "green"),
  @css.rule_media("min-width:768px", @css.FontSize, "18px"),
  @css.rule_when("min-width:1024px", @css.Hover, @css.Color, "purple"),
  @css.rule(@css.Width, "var(--width)"),
])
let selected = @css.create([@css.rule(@css.Color, "blue")])
let light = @css.create_theme([("--text", "black")])
let dark = @css.create_theme([("--text", "white")])

// create_theme and with_vars raise StyleError for invalid custom-property names.
let resolved = @css.attrs([
  light,
  dark.when(is_dark),
  base.with_vars([("--width", width.to_string() + "px")]),
  selected.when(is_selected),
])
// resolved.class_name -> class attribute
// resolved.style      -> style attribute (CSS text, not escaped HTML)
```

`compose([base, override])` returns a reusable `Style`; `attrs([...])` composes
and resolves in one step. The last style wins for the same property, replacing
that property's entire group of hover/media conditions. In the example, selecting
blue also removes the green and purple hover styles. Within one `create`,
conditions coexist and the last declaration for an identical slot wins.
Pseudo-elements have separate property namespaces. `unset("color")` removes the
element's color and its conditions, and remains effective through nested
composition. `style.when(false)` contributes nothing.

### Typed property names

`Property` provides 530 unprefixed standard and experimental names from a pinned
[MDN CSS property catalog](https://github.com/mdn/data/blob/635d63e0c4b4a0a4216aa9ee1cbdaed0c5111065/css/properties.json)
(CC0-1.0), including logical properties and SVG properties. Names use PascalCase:
`@css.BackgroundColor`, `@css.MarginInlineStart`, `@css.StrokeWidth`.
An unknown constructor such as `@css.Colro` is a compile error.

`rule`, `rule_on`, `rule_media`, `rule_when`, and `unset` accept `Property` or
`String` through `PropertyName`. Typed and string forms share composition groups,
class hashes, and CSS output. Use strings for custom properties, vendor prefixes,
or names outside the catalog: `rule("--brand", "red")`. String property names
are not validated. The legacy registry API still takes strings.

Values remain CSS strings: `rule(@css.Display, "flex")`. Value grammar and
property/value compatibility are not checked yet; the enum does not imply
browser support. `@css.Property::Color` is also accepted. Within the CSS package,
use `Property::Color` where a generic argument cannot infer its type.

The checked-in `properties.json` is the single source for the MoonBit enum and
the JavaScript extraction map. Run `just generate-css-properties` after editing
it. Generation is offline; `just test-css` checks that generated files are current.

### Typed pseudo selectors

`Pseudo` covers 64 common pseudo-classes and pseudo-elements, following the
[MDN pseudo-class](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/Pseudo-classes)
and [pseudo-element](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Selectors/Pseudo-elements)
references. Both `rule_on` and `rule_when` accept it through `PseudoSelector`:

```moonbit
let interactions = @css.create([
  @css.rule_on(@css.Hover, @css.Color, "blue"),
  @css.rule_on(@css.FocusVisible, @css.Outline, "2px solid blue"),
  @css.rule_on(@css.Disabled, @css.Opacity, "0.5"),
  @css.rule_on(@css.NthChild("2n"), @css.BackgroundColor, "#eee"),
  @css.rule_on(@css.Not(":disabled"), @css.Cursor, "pointer"),
  @css.rule_on(@css.Before, @css.Content, "\"hello\""),
])
```

`@css.Pseudo::Hover` is the fully qualified form. Functional constructors such as
`NthChild`, `Not`, `Is`, `Where`, `Has`, `Lang`, and `Part` take one CSS string.
Constructor names and argument types are checked; argument grammar, browser
support, and valid selector combinations are not. Compound selectors remain
available as strings, e.g. `rule_on(":hover:not(:disabled)", Color, "blue")`.
Typed and string forms produce the same CSS and compose in the same groups.

Static extraction supports literal constructors and literal functional arguments,
including `@css.NthChild("2n")`. Computed arguments produce diagnostics in strict
mode. Run `just generate-css-pseudos` after editing the shared selector catalog in
`scripts/generate-css-pseudos.mjs`.

Themes use explicit CSS custom-property names, not generated token identifiers.
Apply their classes to an ancestor or shadow host for inheritance. `with_vars`
binds runtime values to custom properties on the current element; it does not
generate CSS or change class names. Values use CSS units explicitly. These two
APIs accept ASCII custom-property names matching `--[a-zA-Z0-9_-]+` and reject
ordinary properties. Inline variables follow normal CSS precedence over theme
classes.

## SSR and Shadow DOM

```moonbit
// Collect every possible variant, including variants initially inactive.
let sheet = @css.stylesheet([base, selected, light, dark])
let content = @core.h("button", [
  ("class", @core.attr_static(resolved.class_name)),
  ("style", @core.attr_static(resolved.style)),
], [@core.text("Hello")])
let island = @core.wc_island(
  "styled-button", "/button.js", sheet, "{}", [content],
)
let html = @render.render_to_string(island).html
```

`stylesheet` deduplicates rules and produces deterministic CSS independently of
the global registries and collection order. Supply it to the existing Island
`styles` argument to put CSS inside the declarative shadow root. For light DOM,
serve the extracted CSS as a stylesheet or place it in the document head.
Document-level selectors do not style elements inside a shadow root.

Compute the stylesheet before streaming begins. Reuse the same definitions and
initial state on the client. Keep the stylesheet outside the content container
passed to the low-level `hydrate` API. The executable fixture under
`luna/src/tests/css_styles` demonstrates this boundary and reactive attributes.
Do not use `reset_all` or request-global CSS collection for this API. New styles
are collected by `stylesheet`, not by the legacy `generate_full_css` registry.

## Static extraction and supported scope

Both `luna css extract` / `lunaCss()` and the standalone `extract.js` recognize
literal `rule`, `rule_on`, `rule_media`, `rule_when`, and `create_theme` calls.
Property arguments can also be literal enum constructors such as `@css.Color`
or `@css.Property::Color`; aliases in `@alias.Color` are accepted. Variables and
computed property expressions require runtime `stylesheet` collection and are
rejected by strict static extraction.
The scanner skips comments and string contents and decodes quoted literals.
Nonliteral declarations generate warnings; `--strict` rejects them. Dynamic
values should use a literal `var(--name)` rule with `with_vars`. Literal calls
inside conditionally used definitions are still extracted. Extraction collects
CSS but does not rewrite MoonBit source or eliminate the composition runtime.

### Static compilation before debug and release builds

`luna css compile` adds one static preprocessing path for both debug and release
builds. There is no runtime/optimized mode switch. Type-check the original source
with MoonBit, then compile a staged copy:

```sh
moon -C app check --target js
luna css compile app --output-dir build/app
moon -C build/app build --target js           # debug
moon -C build/app build --target js --release # release
```

From this repository, `just compile-css app build/app` runs the source CLI.

The MoonBit package `mizchi/luna/cmd/css` also exposes `compile`, `extract`,
and `watch`. Its compiler is bundled in the Mooncake and requires Node.js 24+:

```sh
moon run --target js luna/src/cmd/css -- compile app --output-dir build/app
moon run --target js luna/src/cmd/css -- watch --root web
```

Use the package's filesystem path with `moon run`; the tested Moon CLI does
not resolve bare package names. See the [CLI documentation](../../cmd/css/README.md)
for invocation details and Vite requirements.
Stage a standalone module or a complete workspace so relative dependencies and
build assets retain their layout. Dependency resolution follows MoonBit's normal
workflow in the output directory; build/cache directories are not copied.
Run preprocessing before both server and client builds. For Vite, use
`lunaCssCompile()` below to run this step and MoonBit compilation automatically.

The compiler folds qualified, nested literal `create`/`compose` expressions,
including typed properties, pseudo selectors, themes, and unset tombstones:

- Static `attrs([...])` becomes a `StyleAttrs` record containing class strings.
- Static `stylesheet([...])` becomes a CSS string literal.
- Static style definitions become normalized rules with precomputed class names.
  Rule constructors, enum conversion, normalization, and hashing can then be
  removed by MoonBit's dead-code elimination when no other calls need them.
- Dynamic composition, `when`, and `with_vars` keep their normal semantics.
  Runtime attribute resolution reuses the precomputed class names without hashing.

The output directory contains generated MoonBit sources and a deduplicated,
deterministically ordered `luna.css`. The CSS includes inactive literal variants.
For Shadow DOM, continue passing `stylesheet` output to the Island `styles`
argument; document-level `luna.css` does not cross a shadow boundary. Pseudo-class
matching itself runs in the browser's CSS engine, including without JavaScript.

Output must be outside the input tree. Reusing an output directory created by
this compiler updates changed files, removes stale generated files, and preserves
unchanged timestamps and MoonBit build caches. Unmanaged output directories are
rejected. Diagnostics are checked before updating the previous successful output.
Debug source locations refer to the staged sources.

This is a literal-expression preprocessor, not a general MoonBit evaluator.
It resolves the CSS import alias from `moon.pkg` or `moon.pkg.json`, but does not
inline user functions, trace local variables, execute callbacks, or resolve styles
across packages. It compiles literal children inside otherwise dynamic expressions.
Dynamic declaration names, values, selector arguments, and theme definitions are
errors; express runtime values using literal `var(--name)` plus `with_vars`.
Legacy registry APIs and test files are copied unchanged. The `precompiled_*`
functions are compiler output contracts and should not be handwritten.

The JavaScript API is `compileStyles(source, { cssAlias? })` for one source and
`compileStyleDirectory(input, { outputDir, cssPackage? })` for staging. Both are
exported from `@luna_ui/luna/css`. Use the compiler and MoonBit CSS package from
the same version. Run `just bench-css-compile` to measure 1,000 files / 6,000
declarations, reporting preprocessing time separately from MoonBit compilation.

### Vite watch integration

```ts
// vite.config.ts — paths are relative to the Vite root
import { defineConfig } from "vite";
import { lunaCssCompile } from "@luna_ui/luna/vite-plugin";

export default defineConfig({
  plugins: [
    lunaCssCompile({ input: "moon", outputDir: ".luna/moon" }),
  ],
});
```

The `moon` directory in this example is a complete MoonBit module/workspace,
separate from the frontend entry files. Import generated CSS and JS using names
that work in both development and production:

```ts
// main.ts
import "virtual:luna-compiled.css";
import { hydrate } from "virtual:luna-compiled/app/app.js";
```

The JS suffix is relative to MoonBit's `_build/js/{debug|release}/build/` directory.
For example, `app/app.js` is the ESM output for a package named `app`. Configure
that package's JS exports and ESM format in `moon.pkg`. SSR imports use the same
resolver. For islands, continue passing their stylesheet to the shadow root;
the imported virtual stylesheet applies to light DOM.

The plugin performs initial preprocessing before Vite scans imports, then runs
`moon build --target js` in the generated directory (`--release` for production).
Source changes, additions, deletions, manifests, and copied assets are watched.
Events are debounced (30ms by default) and builds are serialized. An edit arriving
during a build schedules another pass; only the newest successful build reloads
the browser. Input caches and generated output never trigger preprocessing loops.
Client and SSR module caches are invalidated together. Updates use full page
reloads, so component state is reset.

Static compiler or MoonBit errors appear in Vite's overlay. Development watching
continues, including after an initial source error, and the next successful edit
recovers. A production build fails on errors. `vite build --watch` also recompiles
sources. Shutdown detaches watchers, clears pending timers, and cancels the default
MoonBit child process.

Options:

| Option | Meaning |
| --- | --- |
| `input`, `outputDir` | Required source and compiler-owned output directories |
| `cssPackage` | CSS import path; defaults to `mizchi/luna/x/css` |
| `debounceMs` | Filesystem event debounce; defaults to `30` |
| `build(context)` | Optional async replacement for the default MoonBit build; receives `inputDir`, `outputDir`, `command`, `signal`, and the preprocessing result |
| `build: false` | Preprocess only, for integrations that already compile generated MoonBit |

Custom build callbacks should honor `signal` on shutdown and resolve only after
all server/client artifacts are ready. No runtime/optimized mode switch is needed.
The older `lunaCss()` plugin remains the extraction-only API for legacy projects;
`lunaCssCompile()` supplies its own virtual CSS module and does not inject a CSS
runtime. The lifecycle follows Vite's [plugin API](https://vite.dev/guide/api-plugin).

Normal, pseudo, and media rules use the same hashes in MoonBit and both
extractors. Existing media classes and the standalone extractor previously used
counters; rebuild server, client, and CSS artifacts together when upgrading.
The legacy `css`, `styles`, and `combine` signatures remain available; `combine`
continues to concatenate strings and does not resolve conflicts.

This is a focused port, not full StyleX compatibility:

- Property values remain CSS strings, not a complete typed CSS value schema.
- Composition resolves exact properties. Shorthand/longhand overlap (including
  logical versus physical properties) follows CSS; prefer explicit longhands.
- Common pseudo-class ordering is explicit. Simple min/max width/height queries
  in the same unit (`px`, `em`, `rem`) sort numerically, ascending for min and
  descending for max. Other conditions have deterministic lexical ordering;
  compound/range-query implication is not analyzed.
- There is no `defineVars` token code generation, keyframes API, marker-based
  descendant selectors, automatic route manifest, or automatic CSS tree shaking.

Run `just test-css` for portable unit tests, extractor parity, SSR and streaming
checks, and Playwright tests for no-JS rendering and hydration.

Design references: [StyleX composition](https://stylexjs.com/docs/learn/thinking-in-stylex/)
and [conditional/dynamic styles](https://stylexjs.com/docs/learn/styling-ui/defining-styles/).

## Legacy string API

Luna CSS provides two mechanisms:

1. **MoonBit Runtime** (`@css`): Generates class names at SSR time
2. **Static Extraction** (`luna css extract`): Extracts CSS from `.mbt` files at build time

Both produce **identical class names** using DJB2 hash, ensuring consistency.

## How It Works

```
┌─────────────────────────────────────────────────────────────────┐
│                        Build Time                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  .mbt files ──→ luna css extract ──→ CSS file                   │
│     │                                    │                       │
│     │  @css.css("display", "flex")       │  ._z5et{display:flex} │
│     │           ↓                        │                       │
│     │       "_z5et"                      │                       │
│     │                                    │                       │
└─────┴────────────────────────────────────┴───────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        Runtime (Browser)                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  HTML: <div class="_z5et">              CSS: ._z5et{display:flex}│
│                                                                  │
│  No CSS generation code in client bundle!                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Class Name Generation

All class names are generated using DJB2 hash for determinism:

```
css("display", "flex")     → hash("display:flex")     → "_z5et"
css("display", "none")     → hash("display:none")     → "_3pgqo"
hover("color", "#fff")     → hash(":hover:color:#fff") → "_abc12"
```

**Key Properties:**
- Same declaration always produces the same class name
- Works identically in MoonBit runtime and static extraction
- `_` prefix prevents conflicts with external CSS

## Usage

### 1. MoonBit API (`@css` module)

```moonbit
// Single property
let flex_class = @css.css("display", "flex")  // "_z5et"

// Multiple properties
let card = @css.styles([
  ("display", "flex"),
  ("padding", "1rem"),
])  // "_z5et _8ktnx"

// Pseudo-classes
let hover_bg = @css.hover("background", "#2563eb")

// Media queries
let responsive = @css.at_md("padding", "2rem")

// Use in elements
div(class=flex_class, [...])
```

### 2. Vite Plugin (Recommended)

```typescript
// vite.config.ts
import { lunaCss } from "@luna_ui/luna/vite-plugin";

export default defineConfig({
  plugins: [
    lunaCss({
      src: ["src"],       // Source directories with .mbt files
      verbose: true,
    }),
  ],
});
```

```typescript
// main.ts - Import CSS like Tailwind
import "virtual:luna.css";
```

This extracts CSS from all `.mbt` files and injects it via Vite's CSS pipeline.

### 3. CLI Commands

```bash
# Extract all CSS from directory
luna css extract src -o dist/styles.css

# With pretty output
luna css extract src --pretty

# Split by directory (for code splitting)
luna css extract src --split-dir --output-dir dist/css

# Inject into HTML
luna css inject index.html --src src
```

## Vite Plugin Options

```typescript
interface LunaCssPluginOptions {
  // Source directories (relative or absolute paths)
  src?: string | string[];

  // Enable directory-based CSS splitting
  split?: boolean;

  // Minimum usages for shared CSS (default: 3)
  sharedThreshold?: number;

  // Enable console logging
  verbose?: boolean;
}
```

### Virtual Modules

| Module | Description |
|--------|-------------|
| `virtual:luna.css` | All extracted CSS (use this for production) |
| `virtual:luna-shared.css` | Shared CSS only (split mode) |
| `virtual:luna-chunk/{dir}.css` | Per-directory CSS (split mode) |

> **Note**: For dev runtime, use `@luna_ui/luna/css/runtime` npm package instead of virtual modules.

### Split Mode Example

```typescript
// vite.config.ts
lunaCss({
  src: ["src"],
  split: true,
  sharedThreshold: 3,  // CSS used 3+ times → shared
})

// main.ts
import "virtual:luna-shared.css";        // Common CSS
import "virtual:luna-chunk/todomvc.css"; // Page-specific CSS
```

## CLI Reference

### extract

Extract CSS from `.mbt` files.

```bash
luna css extract <dir> [options]

Options:
  -o, --output <file>     Output file (default: stdout)
  --output-dir <dir>      Output directory (for split mode)
  --split                 Split by file
  --split-dir             Split by directory
  --shared-threshold <n>  Min usages for shared CSS (default: 3)
  --pretty                Pretty print output
  --json                  Output as JSON with class mapping
  --strict                Exit with error on warnings
  -v, --verbose           Show details
```

### inject

Inject CSS into HTML file.

```bash
luna css inject <html> --src <dir> [options]

Options:
  --src <dir>           Source directory (required)
  -o, --output <file>   Output file (default: in-place)
  -m, --mode <mode>     inline | external | auto (default: inline)
  -t, --threshold <n>   Size threshold for auto mode (default: 4096)
  --css-file <name>     External CSS filename (default: luna.css)
```

### minify

Minify CSS file.

```bash
luna css minify <file> -o <output>
```

## Development Mode

For development, use the CSS runtime for instant feedback:

```typescript
// Only in development!
import { css, hover } from "@luna_ui/luna/css/runtime";

// Generates CSS dynamically with console warnings
const cls = css("display", "flex");
// Console: [luna-css] Generated at runtime: ._z5et{display:flex}
//          → Run 'luna css extract' to pre-generate
```

## Best Practices

### 1. Use String Literals

Static extraction only works with string literals:

```moonbit
// ✓ Good - extractable at build time
@css.css("display", "flex")

// ✗ Bad - cannot be extracted
let prop = "display"
@css.css(prop, "flex")  // Works at runtime, but CSS won't be in extracted file
```

When non-literal arguments are used:
- Static extraction (`luna css extract`) cannot detect them
- MoonBit runtime still generates the class name correctly
- But the CSS rule won't exist in the pre-extracted CSS file
- Result: The element will have the class but no matching CSS rule

### 2. Keep CSS in SSR Code

For zero runtime overhead, use CSS in SSR-only components:

```moonbit
// ✓ Good - SSR component (server-side only)
fn my_component() -> @dom.static.ServerNode {
  div(class=@css.css("display", "flex"), [...])
}

// ✗ Avoid - Island component (runs in browser)
fn my_island() -> @luna.Node[Unit] {
  // This includes @css module in client bundle!
  div(class=@css.css("display", "flex"), [...])
}

// ✓ Better for Islands - use pre-computed class string
fn my_island() -> @luna.Node[Unit] {
  div(class="_z5et", [...])  // Just the class name, no @css import
}
```

**Why?** `@dom.static.ServerNode` components only run on the server (SSR). `@luna.Node` components (Islands) run in the browser, so importing `@css` would include CSS generation code in the client bundle.

### 3. Pre-extract for Production

Always extract CSS at build time:

```bash
# Build script
luna css extract src -o dist/styles.css
```

## API Reference

### Base Styles

| Function | Returns | Example |
|----------|---------|---------|
| `css(prop, val)` | Class name | `css("display", "flex")` → `"_z5et"` |
| `styles(pairs)` | Space-separated | `styles([...])` → `"_z5et _abc"` |
| `combine(classes)` | Joined | `combine([a, b])` → `"_z5et _abc"` |

### Pseudo-classes

| Function | Selector |
|----------|----------|
| `on(pseudo, prop, val)` | Custom |
| `hover(prop, val)` | `:hover` |
| `focus(prop, val)` | `:focus` |
| `active(prop, val)` | `:active` |

### Media Queries

| Function | Condition |
|----------|-----------|
| `media(cond, prop, val)` | Custom |
| `at_sm(prop, val)` | `min-width: 640px` |
| `at_md(prop, val)` | `min-width: 768px` |
| `at_lg(prop, val)` | `min-width: 1024px` |
| `at_xl(prop, val)` | `min-width: 1280px` |
| `dark(prop, val)` | `prefers-color-scheme: dark` |

### Generation (SSR only)

| Function | Description |
|----------|-------------|
| `generate_css()` | Base styles only (`css()`, `styles()`) |
| `generate_full_css()` | All styles (base + pseudo + media queries) |
| `reset_all()` | Clear all registries (for testing) |

Example output difference:
```css
/* generate_css() */
._z5et{display:flex}

/* generate_full_css() - includes pseudo and media */
._z5et{display:flex}
._1i41w:hover{border-color:#DB7676}
@media(min-width:768px){._abc{padding:2rem}}
```

## Static Analyzer (`analyzer/`)

MoonBit AST-based static analyzer for detecting CSS class co-occurrences.

### Usage

```bash
# Analyze MoonBit source files
luna css analyze-mbt src/luna --verbose
```

### Output

```json
{
  "cooccurrences": [
    {
      "classes": ["display:flex", "gap:8px"],
      "file": "src/components/card.mbt",
      "line": 42,
      "isStatic": true
    }
  ],
  "warnings": [
    {
      "kind": "dynamic_conditional",
      "file": "src/components/button.mbt",
      "line": 15,
      "message": "Conditional expression in class array"
    }
  ]
}
```

### Warning Types

| Kind | Description |
|------|-------------|
| `dynamic_conditional` | `if`/`match` in `class_=` array |
| `untraceable_variable` | Variable not traceable to `css()`/`styles()` |
| `dynamic_function_call` | Unknown function call result |
| `dynamic_array_construction` | Spread operator in array |

### Design Notes

- Uses `moonbitlang/parser` for MoonBit AST traversal
- Tracks `let x = css(...)` bindings across function scope
- API boundary: `analyze_file_json(source, file) -> String` (JSON)
- **Future**: May be extracted to a separate repository to minimize dependencies
