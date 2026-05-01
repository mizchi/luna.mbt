# Astra Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract `mizchi/sol`'s `src/ssg/` into a standalone Mars middleware package `mizchi/astra`, hosted alongside `luna` and `sol` in a `moon.work`-based monorepo at `luna.mbt`.

**Architecture:** Three packages under one `moon.work`. `astra` exposes a `@mars.Handler`-shaped middleware plus an explicit `list_urls()` contract; `astra build` boots the middleware in-process and crawls every URL it claims. `sol` retains only the SSR / Island / file-routing framework and stops referencing SSG paths.

**Tech Stack:** MoonBit, `moon` build tool with `moon.work`, `mizchi/mars` (HTTP), `mizchi/markdown`, `mizchi/luna` (UI render), `mizchi/sol` (existing).

**Reference spec:** `docs/superpowers/specs/2026-05-01-astra-extraction-design.md`.

**Working repo for execution:** `~/ghq/github.com/mizchi/luna.mbt`. The current `sol.mbt` repo gets vendored under `luna.mbt/sol/` in Phase A.

---

## Phases

- **Phase A — Monorepo skeleton + empty astra package** (Tasks 1–4). Done when `moon.work` resolves `luna` + `sol` + `astra`, all three pass `moon check`, and a placeholder `astra` middleware is mountable on a Mars `Server`.
- **Phase B — Source migration + middleware wiring** (Tasks 5–11). Done when astra's middleware serves the existing `examples/sol_docs` content end-to-end, and `astra build` produces a static dump byte-equal to the previous `sol build` output for that fixture.
- **Phase C — sol cleanup, examples, docs, release** (Tasks 12–18). Done when `sol` builds with no `@ssg`/`@tree`/`@assets` imports, the docs/blog examples live under `astra/`, and the three READMEs describe the monorepo.

Each phase ends with a green build (`moon check && moon test`) and a commit.

---

# Phase A — Monorepo skeleton + empty astra

## Task 1: Initialize `moon.work` in `luna.mbt`

**Files:**
- Create: `~/ghq/github.com/mizchi/luna.mbt/moon.work`
- Modify: `~/ghq/github.com/mizchi/luna.mbt/.gitignore` (add `_build/` if missing)

- [ ] **Step 1: Inspect current luna layout**

Run:
```
ls ~/ghq/github.com/mizchi/luna.mbt
cat ~/ghq/github.com/mizchi/luna.mbt/moon.mod.json
```
Expected: `moon.mod.json` at repo root with `name: "mizchi/luna"` and `source: "src"`. There is no `moon.work` yet.

- [ ] **Step 2: Decide layout**

Two options for `moon.work`:
1. Keep luna at the repo root and add sol/astra as siblings: `members = [".", "./sol", "./astra"]`.
2. Nest luna under `./luna` and put sol/astra alongside: `members = ["./luna", "./sol", "./astra"]`.

Pick **option 1** to avoid moving every existing path under `luna.mbt/src/` (which would break every downstream consumer's git history view). The repo stays as `mizchi/luna` at root; sol and astra are added as siblings.

- [ ] **Step 3: Create `moon.work`**

Write `~/ghq/github.com/mizchi/luna.mbt/moon.work` with:
```
members = [
  ".",
  "./sol",
  "./astra",
]
```

- [ ] **Step 4: Verify the workspace resolves**

Run from `~/ghq/github.com/mizchi/luna.mbt`:
```
moon check
```
Expected: succeeds for the existing luna sources. Sol/astra members do not yet exist, so `moon` should warn but not fail. If `moon` fails on missing members, omit them from `moon.work` for now and re-add in Tasks 2 and 3.

- [ ] **Step 5: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add moon.work .gitignore
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "chore: introduce moon.work for monorepo (luna + sol + astra)"
```

## Task 2: Vendor `sol.mbt` under `luna.mbt/sol/`

**Files:**
- Create: `~/ghq/github.com/mizchi/luna.mbt/sol/` (entire tree from `~/ghq/github.com/mizchi/sol.mbt/`)

- [ ] **Step 1: Stage the move with git subtree to preserve history**

From `~/ghq/github.com/mizchi/luna.mbt`:
```
git remote add sol-origin ~/ghq/github.com/mizchi/sol.mbt
git fetch sol-origin
git subtree add --prefix=sol sol-origin main
```
Expected: a single merge commit pulls all `sol.mbt` history under `sol/`. If `git subtree` complains about uncommitted work, commit the `moon.work` first (Task 1 step 5).

- [ ] **Step 2: Confirm the layout**

Run:
```
ls ~/ghq/github.com/mizchi/luna.mbt/sol
cat ~/ghq/github.com/mizchi/luna.mbt/sol/moon.mod.json
```
Expected: full sol tree under `sol/`, `moon.mod.json` still says `"name": "mizchi/sol"`.

- [ ] **Step 3: Update `moon.mod.json` for in-workspace luna resolution**

Edit `~/ghq/github.com/mizchi/luna.mbt/sol/moon.mod.json` and remove the version pin for `mizchi/luna` so the workspace member is used:
```jsonc
"deps": {
  "moonbitlang/yacc": "0.7.12",
  // drop the pinned mizchi/luna line — moon.work resolves it
  "moonbitlang/async": "0.17.0",
  ...
}
```
moon.work auto-prefers workspace members for matching package names.

- [ ] **Step 4: Verify build**

```
cd ~/ghq/github.com/mizchi/luna.mbt
moon check
```
Expected: both `mizchi/luna` and `mizchi/sol` check cleanly. Resolve any version skew by bumping luna's `moon.mod.json` version locally (do not publish it).

- [ ] **Step 5: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "chore: vendor sol into monorepo under sol/"
```

## Task 3: Create empty `astra` package

**Files:**
- Create: `astra/moon.mod.json`
- Create: `astra/src/moon.pkg`
- Create: `astra/src/lib.mbt`
- Create: `astra/README.md`

- [ ] **Step 1: Author `astra/moon.mod.json`**

```jsonc
{
  "name": "mizchi/astra",
  "version": "0.1.0",
  "deps": {
    "mizchi/mars": "0.3.10",
    "mizchi/markdown": "0.4.7",
    "moonbitlang/async": "0.17.0",
    "moonbitlang/x": "0.4.41"
  },
  "readme": "README.md",
  "repository": "https://github.com/mizchi/luna.mbt",
  "license": "MIT",
  "keywords": ["astra", "ssg", "mars", "moonbit", "middleware"],
  "description": "Mountable Mars middleware for static site generation",
  "source": "src",
  "preferred-target": "js"
}
```

`mizchi/luna` is resolved through `moon.work`, so it does not appear in `deps`.

- [ ] **Step 2: Author `astra/src/moon.pkg`**

```
import {
  "mizchi/mars" @mars,
}

options(
  "supported-targets": "js",
)
```

- [ ] **Step 3: Author `astra/src/lib.mbt` placeholder**

```moonbit
// Astra: Mars middleware for static site generation.

///|
/// Placeholder middleware. Returns a 501 for every request until Phase B wires
/// the real document tree and render core.
pub fn placeholder() -> @mars.Handler {
  @mars.handler(fn(ctx) {
    ctx.text("astra: not implemented yet", status=501)
  })
}
```

- [ ] **Step 4: Author `astra/README.md`**

```markdown
# astra — Mars middleware for static site generation

Mountable Mars middleware. Renders Markdown / MDX documentation sites and
serves accompanying static assets. Pair with the `astra` CLI to dump a
fully static site (`astra build`).

See `docs/superpowers/specs/2026-05-01-astra-extraction-design.md` in this
monorepo for the design, and `astra/docs/` (added in Phase B) for usage.
```

- [ ] **Step 5: Verify**

```
cd ~/ghq/github.com/mizchi/luna.mbt
moon check
```
Expected: all three members compile. Astra has only the placeholder.

- [ ] **Step 6: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add astra
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "feat(astra): add empty package skeleton"
```

## Task 4: Add a `Testing::invoke` helper and smoke-test the placeholder

mars exposes `Context::text/json/html/not_found` for response writing but **no
public `test_request` helper** — `Context::new_js` is the only constructor.
Astra owns its in-process invocation helper because both this task and the
build crawler in Task 10 need it.

**Files:**
- Create: `astra/src/testing/moon.pkg`
- Create: `astra/src/testing/invoke.mbt`
- Create: `astra/tests/mount_test.mbt`
- Create: `astra/tests/moon.pkg`

- [ ] **Step 1: Author the in-process invoker**

`astra/src/testing/invoke.mbt`:
```moonbit
// Invoke a Mars Handler without a real HTTP server.
// Builds a Context from the request, runs the handler, returns the response
// captured on the context. JS-only (matches astra's preferred-target).

pub(all) struct InvokeResult {
  status : Int
  body : String
  headers : Map[String, String]
}

pub async fn invoke(
  handler : @mars.Handler,
  meth~ : @http.RequestMethod = Get,
  path~ : String,
) -> InvokeResult raise Error {
  let req = @http.Request::new(meth, path)
  let ctx = @mars.Context::new_js(req)
  handler.run(ctx)
  {
    status: ctx.response_status(),
    body: ctx.response_body_text(),
    headers: ctx.response_headers(),
  }
}
```

If `Context::response_status` / `response_body_text` / `response_headers` are
not yet exposed by mars at the pinned version, add accessor wrappers in
`astra/src/testing/invoke.mbt` that read the underlying private fields via
the JS interop already used in `mars/src/context_js.mbt`. Worst case, expose
them as public on a fork of mars and pin to that fork through `moon.work`'s
local override; document the override in `astra/README.md`.

`astra/src/testing/moon.pkg`:
```
import {
  "mizchi/mars" @mars,
  "mizchi/js/web/http" @http,
  "moonbitlang/async",
}
options("supported-targets": "js")
```

- [ ] **Step 2: Write the failing test**

`astra/tests/mount_test.mbt`:
```moonbit
test "placeholder middleware returns 501" {
  let res = @testing.invoke(@astra.placeholder(), path="/anything")
  inspect(res.status, content="501")
  inspect(res.body, content="astra: not implemented yet")
}
```

`astra/tests/moon.pkg`:
```
import {
  "mizchi/astra" @astra,
  "mizchi/astra/testing" @testing,
}
options("supported-targets": "js")
```

- [ ] **Step 3: Run the test, confirm pass**

```
cd ~/ghq/github.com/mizchi/luna.mbt
moon test --package mizchi/astra/tests
```
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add astra
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "test(astra): mount placeholder middleware on mars server"
```

**Phase A exit criterion:** `moon check` and `moon test` both pass at the workspace root. Astra exists as a real package, mountable but trivial. Sol still owns SSG. Phase B starts the migration.

---

# Phase B — Migrate SSG sources, wire middleware, build crawler

## Task 5: Move SSG types and config into astra

**Files:**
- Move: `sol/src/ssg/types.mbt` → `astra/src/types.mbt`
- Move: `sol/src/ssg/config.mbt` → `astra/src/config.mbt`
- Move: `sol/src/ssg/i18n.mbt` (and its tests) → `astra/src/i18n.mbt`
- Move: `sol/src/ssg/path_utils.mbt` → `astra/src/path_utils.mbt`
- Move: `sol/src/ssg/document_tree.mbt` → `astra/src/document_tree.mbt`
- Move: `sol/src/ssg/renderer_type.mbt` → `astra/src/renderer_type.mbt`
- Modify: `astra/src/moon.pkg` (add imports as needed)

- [ ] **Step 1: Verify the move list**

```
ls ~/ghq/github.com/mizchi/luna.mbt/sol/src/ssg | sort
```
Expected: matches the spec's table (`assets/ cache/ components/ docs/ generator/ mdx/ themes/ tree/`, plus the loose `*.mbt` files moved here in step 1).

- [ ] **Step 2: Move the type-and-config core only**

```
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/types.mbt astra/src/types.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/config.mbt astra/src/config.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/i18n.mbt astra/src/i18n.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/i18n_test.mbt astra/src/i18n_test.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/i18n_wbtest.mbt astra/src/i18n_wbtest.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/path_utils.mbt astra/src/path_utils.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/path_utils_test.mbt astra/src/path_utils_test.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/document_tree.mbt astra/src/document_tree.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/document_tree_wbtest.mbt astra/src/document_tree_wbtest.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/renderer_type.mbt astra/src/renderer_type.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/renderer_type_test.mbt astra/src/renderer_type_test.mbt
```

- [ ] **Step 3: Update `astra/src/moon.pkg`**

The moved files reference `@frontmatter` and `@markdown`. Replace the imports block in `astra/src/moon.pkg` with:
```
import {
  "moonbitlang/core/json",
  "mizchi/markdown" @markdown,
  "mizchi/markdown/frontmatter" @frontmatter,
  "mizchi/mars" @mars,
}

warnings = "-7-unused_field"

options(
  "supported-targets": "js",
)
```
If `mizchi/markdown` does not export a `frontmatter` subpackage at `0.4.7`, mirror the inner path used in sol — search with `grep -r "@frontmatter" sol/src/ssg/` and copy the canonical import line.

- [ ] **Step 4: Build and fix import paths**

```
cd ~/ghq/github.com/mizchi/luna.mbt
moon check
```
Fix every `unresolved import` reported in `astra/`. Common fixes:
- `@json_utils` lived in `mizchi/sol/internal/json_utils`; copy that file into `astra/src/internal/json_utils/` (preserve its license header) and import it locally.
- `@utils` similarly.

After each fix re-run `moon check` until astra compiles green and sol is *unchanged* (sol still has its previous SSG imports pointing at the now-missing files, so sol will be red — that is expected and gets resolved in Task 6).

- [ ] **Step 5: Commit (broken sol is OK; called out in the message)**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "refactor(astra): move SSG type/config/tree core out of sol

Sol does not build at this commit; restored in the next commit."
```

## Task 6: Re-export the moved core from sol as a thin shim

**Files:**
- Create: `sol/src/ssg/reexport.mbt`
- Modify: `sol/src/ssg/moon.pkg`

The CLI and runtime still import `@ssg.SsgConfig`, `@ssg.NavItem`, etc. To keep sol compiling during migration, sol's `ssg/` package becomes a thin re-export wrapper around `mizchi/astra`. This shim is deleted in Phase C.

- [ ] **Step 1: Edit `sol/src/ssg/moon.pkg`**

```
import {
  "moonbitlang/core/json",
  "mizchi/astra" @astra,
}

warnings = "-7-unused_field"

options(
  "supported-targets": "js",
)
```

- [ ] **Step 2: Author `sol/src/ssg/reexport.mbt`**

```moonbit
// Temporary re-export shim. Removed in Phase C once every sol caller
// imports mizchi/astra directly.

pub typealias @astra.SsgConfig as SsgConfig
pub typealias @astra.NavItem as NavItem
pub typealias @astra.SidebarConfig as SidebarConfig
pub typealias @astra.SidebarGroup as SidebarGroup
pub typealias @astra.SidebarItem as SidebarItem
pub typealias @astra.ThemeConfig as ThemeConfig
pub typealias @astra.HeaderConfig as HeaderConfig
pub typealias @astra.HeaderElement as HeaderElement
pub typealias @astra.FooterConfig as FooterConfig
pub typealias @astra.FooterElement as FooterElement
pub typealias @astra.FooterColumn as FooterColumn
pub typealias @astra.FooterLink as FooterLink
pub typealias @astra.NavigationConfig as NavigationConfig
pub typealias @astra.I18nConfig as I18nConfig
pub typealias @astra.LocaleConfig as LocaleConfig
pub typealias @astra.OgpConfig as OgpConfig
pub typealias @astra.CssUtilitiesConfig as CssUtilitiesConfig
pub typealias @astra.MetaFilesConfig as MetaFilesConfig
pub typealias @astra.IslandsConfig as IslandsConfig
pub typealias @astra.DeployTarget as DeployTarget
pub typealias @astra.PageMeta as PageMeta
pub typealias @astra.ContentType as ContentType
pub typealias @astra.RendererType as RendererType
pub typealias @astra.BuildContext as BuildContext
pub typealias @astra.SocialLink as SocialLink

pub fn parse_int_simple(s : String) -> Int = @astra.parse_int_simple
```

If MoonBit at the project's pinned version does not yet support `pub typealias`, replace with `pub type SsgConfig = @astra.SsgConfig` (legacy form). Verify with `moon version` and `grep typealias sol/src/**/*.mbt`.

- [ ] **Step 3: Build sol again**

```
cd ~/ghq/github.com/mizchi/luna.mbt
moon check --package mizchi/sol
```
Iterate until sol's CLI/runtime passes the type re-exports. If a particular type isn't yet ported (e.g. `parse_int_simple`), move it across in Task 5 and re-run.

- [ ] **Step 4: Run sol's existing tests as a regression check**

```
moon test --package mizchi/sol
```
Expected: parity with pre-migration. Any failure here means the re-export list missed a symbol — extend `reexport.mbt`.

- [ ] **Step 5: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "refactor(sol): shim ssg types via astra re-export"
```

## Task 7: Move remaining SSG submodules into astra

**Files (all moves, no logic edits):**
- `sol/src/ssg/tree/*` → `astra/src/tree/*`
- `sol/src/ssg/cache/*` → `astra/src/cache/*`
- `sol/src/ssg/components/*` → `astra/src/components/*`
- `sol/src/ssg/themes/*` → `astra/src/themes/*`
- `sol/src/ssg/mdx/*` → `astra/src/mdx/*`
- `sol/src/ssg/generator/*` → `astra/src/render/*` (rename only)
- `sol/src/ssg/assets/*` → `astra/src/assets/*`
- `sol/src/ssg/docs/*` → `astra/docs/*`

- [ ] **Step 1: Move each submodule with `git mv`**

For every directory in the list above:
```
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/ssg/<dir> astra/src/<dir>
```
Use `astra/src/render/` for what was `sol/src/ssg/generator/`. Rename `generator` to `render` to match the spec's render-core terminology.

- [ ] **Step 2: Update each moved `moon.pkg`'s import paths**

Inside every moved subpackage's `moon.pkg`, replace:
- `mizchi/sol/ssg` → `mizchi/astra`
- `mizchi/sol/ssg/<sub>` → `mizchi/astra/<sub>`
- `mizchi/sol/internal/json_utils` → `mizchi/astra/internal/json_utils`
- `mizchi/sol/internal/utils` → `mizchi/astra/internal/utils`
- `mizchi/sol/content/markdown` → `mizchi/markdown` (the public package)
- `mizchi/sol/content/frontmatter` → `mizchi/markdown/frontmatter`

Find them all:
```
grep -r "mizchi/sol/ssg\|mizchi/sol/internal\|mizchi/sol/content" astra/src
```
Edit until the grep returns zero hits.

- [ ] **Step 3: Move the internal helpers astra needs**

Repeat the pattern from Task 5 step 4 for `internal/json_utils`, `internal/utils`, and `content/{markdown,frontmatter}` shim files that astra calls but sol still needs. Move to `astra/src/internal/...`.

If sol still uses `mizchi/sol/internal/json_utils` elsewhere, copy (do not move) those files into astra so both packages have a self-contained copy. Mark sol's copy with a header comment that says the canonical owner is now astra; the duplicate is removed in Phase C.

- [ ] **Step 4: Build**

```
cd ~/ghq/github.com/mizchi/luna.mbt
moon check
```
Iterate. Astra's components / themes / render likely import each other; resolve in topological order: types → tree → render → components → themes → assets → mdx → cache.

- [ ] **Step 5: Run all tests**

```
moon test
```
Expected: every test that lived under `sol/src/ssg/` now lives in astra and passes there. Sol's test count drops by the moved tests; sol's remaining tests still pass via the re-export shim.

- [ ] **Step 6: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "refactor(astra): migrate SSG submodules (tree/cache/components/themes/mdx/render/assets)"
```

## Task 8: Implement `Middleware` type and `create()` entry

**Files:**
- Create: `astra/src/middleware/moon.pkg`
- Create: `astra/src/middleware/types.mbt`
- Create: `astra/src/middleware/middleware.mbt`
- Create: `astra/src/middleware/middleware_test.mbt`
- Modify: `astra/src/lib.mbt` (replace placeholder export)

- [ ] **Step 1: Write the failing test**

`astra/src/middleware/middleware_test.mbt`:
```moonbit
test "create returns a middleware whose handler responds to GET /" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.middleware(mw.handler())
  let res = @mars.test_request(app, @mars.Request::get("/"))
  inspect(res.status >= 200 && res.status < 600, content="true")
}

test "list_urls returns the document tree URLs" {
  let cfg = @astra.SsgConfig::default()
  let mw = @middleware.create(cfg, cwd=".")
  let urls = mw.list_urls()
  inspect(urls.length() >= 0, content="true")
}
```

- [ ] **Step 2: Run, confirm fail**

```
moon test --package mizchi/astra/middleware
```
Expected: FAIL — `@middleware.create` does not exist.

- [ ] **Step 3: Implement `Middleware` and `create`**

`astra/src/middleware/types.mbt`:
```moonbit
pub(all) struct Middleware {
  config : @astra.SsgConfig
  cwd : String
  doc_tree : @astra.DocumentTree
}

pub fn Middleware::handler(self : Middleware) -> @mars.Handler {
  @mars.handler(fn(ctx) { dispatch(self, ctx) })
}

pub fn Middleware::list_urls(self : Middleware) -> Array[String] {
  // Phase B-1: only emit page URLs; assets are added in Task 10.
  @astra.urls_from_tree(self.doc_tree)
}
```

`astra/src/middleware/middleware.mbt`:
```moonbit
pub fn create(config : @astra.SsgConfig, cwd~ : String = ".") -> Middleware {
  let tree = @astra.build_document_tree(config, cwd)
  { config, cwd, doc_tree: tree }
}

async fn dispatch(self : Middleware, ctx : @mars.Context) -> Unit raise Error {
  match ctx.meth() {
    Get | Head => () // fall through
    _ => {
      ctx.text("Method Not Allowed", status=405)
      return
    }
  }
  let path = normalize_path(ctx.path())
  match @astra.find_page(self.doc_tree, path) {
    Some(page) => {
      let html = @astra.render_page(self.config, self.cwd, page)
      ctx.html(html)
    }
    None => {
      ctx.text("Not Found", status=404)
    }
  }
}

fn normalize_path(p : String) -> String {
  if p.has_suffix("/") { p + "index" } else { p }
}
```

`astra/src/middleware/moon.pkg`:
```
import {
  "mizchi/mars" @mars,
  "mizchi/astra" @astra,
}
options("supported-targets": "js")
```

If `@astra.urls_from_tree`, `@astra.find_page`, or `@astra.render_page` do not yet exist with those exact names, add thin wrappers in `astra/src/lib.mbt` that delegate to the actual moved functions (e.g. those in `astra/src/render/page_generator.mbt` and `astra/src/tree/builder.mbt`). Use the names above so the rest of the plan stays consistent.

- [ ] **Step 4: Re-run tests, confirm pass**

```
moon test --package mizchi/astra/middleware
```
Expected: both tests pass.

- [ ] **Step 5: Replace the lib.mbt placeholder**

Edit `astra/src/lib.mbt`:
```moonbit
// astra public surface lives in submodules (`middleware`, `render`, `tree`).
// This file holds re-exports for ergonomic access.

pub typealias @middleware.Middleware as Middleware

pub fn create(config : SsgConfig, cwd~ : String = ".") -> Middleware = @middleware.create
```

(Drop the old `placeholder()` function; tests in Task 4 must be updated to call `create(SsgConfig::default()).handler()` instead. Re-run them.)

- [ ] **Step 6: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "feat(astra): mountable Middleware with handler() and list_urls()"
```

## Task 9: Wire asset serving inside the middleware

**Files:**
- Create: `astra/src/middleware/assets.mbt`
- Modify: `astra/src/middleware/middleware.mbt` (extend `dispatch`)

- [ ] **Step 1: Failing test**

Append to `astra/src/middleware/middleware_test.mbt`:
```moonbit
test "GET /sol-island.js returns the bundled island loader script" {
  let cfg = @astra.SsgConfig::default()
  let mw = create(cfg, cwd=".")
  let app = @mars.Server::new()
  app.middleware(mw.handler())
  let res = @mars.test_request(app, @mars.Request::get("/sol-island.js"))
  inspect(res.status, content="200")
  inspect(res.header("content-type"), content="Some(\"application/javascript; charset=utf-8\")")
}
```

- [ ] **Step 2: Confirm fail**

```
moon test --package mizchi/astra/middleware
```
Expected: 404 from current dispatch.

- [ ] **Step 3: Implement asset dispatch**

`astra/src/middleware/assets.mbt`:
```moonbit
fn try_serve_asset(self : Middleware, ctx : @mars.Context) -> Bool {
  let path = ctx.path()
  match @astra.lookup_asset(path) {
    Some(asset) => {
      ctx.bytes(asset.body, content_type=asset.content_type)
      true
    }
    None => false
  }
}
```

Add `try_serve_asset` to `dispatch` before `find_page`:
```moonbit
async fn dispatch(self : Middleware, ctx : @mars.Context) -> Unit raise Error {
  match ctx.meth() {
    Get | Head => ()
    _ => { ctx.text("Method Not Allowed", status=405); return }
  }
  if try_serve_asset(self, ctx) { return }
  // ...existing page dispatch...
}
```

`@astra.lookup_asset` lives in `astra/src/assets/`. If the moved assets module exposes a different signature (`lookup_script`, `find_asset`, ...), align by editing the assets module to expose `lookup_asset(path) -> Option[{ body, content_type }]` and updating the call site.

- [ ] **Step 4: Confirm pass**

```
moon test --package mizchi/astra/middleware
```
Expected: PASS.

- [ ] **Step 5: Extend `list_urls()`**

Update `Middleware::list_urls`:
```moonbit
pub fn Middleware::list_urls(self : Middleware) -> Array[String] {
  let xs = @astra.urls_from_tree(self.doc_tree)
  for asset_url in @astra.list_asset_urls() {
    xs.push(asset_url)
  }
  xs
}
```

Add a test asserting the asset URL is present in `list_urls()`.

- [ ] **Step 6: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "feat(astra): serve static assets through the middleware"
```

## Task 10: Build the static-dump CLI driver

**Files:**
- Create: `astra/src/cli/moon.pkg`
- Create: `astra/src/cli/build.mbt`
- Create: `astra/src/cli/build_test.mbt`
- Create: `astra/src/cli/main/moon.pkg`
- Create: `astra/src/cli/main/main.mbt`
- Create: `astra/tests/fixture/docs/index.md` (tiny fixture)

- [ ] **Step 1: Author the fixture**

`astra/tests/fixture/docs/index.md`:
```markdown
---
title: Hello Astra
---

# Hello Astra
This is a fixture file used by `astra build` integration tests.
```

- [ ] **Step 2: Failing test**

`astra/src/cli/build_test.mbt`:
```moonbit
test "build dumps every URL from list_urls() into output_dir" {
  let cfg = { ..@astra.SsgConfig::default(), docs_dir: "tests/fixture/docs", output_dir: "tests/fixture/.out" }
  let mw = @middleware.create(cfg, cwd=".")
  @cli.build_to_disk(mw, "tests/fixture/.out")
  let html = @fs.read_file_sync("tests/fixture/.out/index.html")
  inspect(html.contains("Hello Astra"), content="true")
}
```

- [ ] **Step 3: Confirm fail**

```
moon test --package mizchi/astra/cli
```
Expected: `build_to_disk` not defined.

- [ ] **Step 4: Implement `build_to_disk` using the Task 4 invoker**

`astra/src/cli/build.mbt`:
```moonbit
pub async fn build_to_disk(
  mw : @middleware.Middleware,
  output_dir : String,
) -> Unit raise Error {
  ensure_dir(output_dir)
  let handler = mw.handler()
  for url in mw.list_urls() {
    let res = @testing.invoke(handler, path=url)
    let target = @path.join2(output_dir, normalize_for_disk(url))
    ensure_parent_dir(target)
    @fs.write_file_sync(target, res.body)
  }
}

fn normalize_for_disk(url : String) -> String {
  if url.has_suffix("/") { url + "index.html" } else { url }
}
```

The `@testing.invoke` helper from Task 4 is the single in-process driver
shared by tests and the build crawler. If a captured response is binary
(asset bytes, not HTML), extend `InvokeResult` to expose `body_bytes : Bytes`
in addition to `body : String` and select the appropriate field per URL
(`url.has_suffix(".html")` or `.md` → text; everything else → bytes). Add a
unit test for an asset URL covering this branch.

- [ ] **Step 5: Author the CLI entry point**

`astra/src/cli/main/main.mbt`:
```moonbit
async fn main {
  let argv = @process.argv()
  let cmd = argv.get(2).or("help")
  match cmd {
    "build" => run_build(argv)
    "dev" => run_dev(argv)
    _ => print_help()
  }
}
```

Wire `run_build` to call `build_to_disk` after parsing `--out` and reading `astra.config.json` / `sol.config.json`. Wire `run_dev` to start a `mars` server and mount the middleware (see Task 11).

- [ ] **Step 6: Confirm pass**

```
moon test --package mizchi/astra/cli
```

- [ ] **Step 7: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "feat(astra): cli with build_to_disk crawler over list_urls"
```

## Task 11: Implement `astra dev` and parity-test against `examples/sol_docs`

**Files:**
- Modify: `astra/src/cli/main/main.mbt` (`run_dev`)
- Create: `astra/e2e/dev_smoke.spec.ts` (Playwright)

- [ ] **Step 1: Implement `run_dev`**

```moonbit
async fn run_dev(argv : Array[String]) -> Unit raise Error {
  let port = parse_port(argv).or(3000)
  let cfg = load_config_or_default()
  let mw = @middleware.create(cfg, cwd=@process.cwd())
  let app = @mars.Server::new()
  app.middleware(mw.handler())
  app.listen(port)
  println("astra dev: listening on http://localhost:\{port}")
}
```

- [ ] **Step 2: Manual sanity check (no automated test yet)**

```
cd ~/ghq/github.com/mizchi/luna.mbt/sol/examples/sol_docs
moon run mizchi/astra/cli/main -- dev --port 3000
curl -s http://localhost:3000/ | head -5
```
Expected: an HTML response containing the site title from `sol_docs/sol.config.json`.

- [ ] **Step 3: Add a Playwright smoke spec**

`astra/e2e/dev_smoke.spec.ts`:
```ts
import { test, expect } from "@playwright/test";
test("dev server serves the index page", async ({ page }) => {
  await page.goto("http://localhost:3000/");
  await expect(page).toHaveTitle(/.+/);
  await expect(page.locator("h1")).toBeVisible();
});
```
Wire `astra/playwright.config.ts` to start `astra dev` against the `sol_docs` fixture before the suite. Mirror `sol/playwright.config.ts` for setup conventions.

- [ ] **Step 4: Run e2e**

```
cd ~/ghq/github.com/mizchi/luna.mbt/astra
pnpm install
pnpm playwright test
```
Expected: green.

- [ ] **Step 5: Parity test against sol's existing build output**

Run sol's old SSG build against `examples/sol_docs` (still possible via the shim) and astra's new build, then diff:
```
cd ~/ghq/github.com/mizchi/luna.mbt/sol/examples/sol_docs
sol build --out /tmp/sol_dump
moon run mizchi/astra/cli/main -- build --out /tmp/astra_dump
diff -r /tmp/sol_dump /tmp/astra_dump
```
Expected: identical except for trivially differing whitespace / build timestamps. Document any intentional diff in `astra/docs/parity-notes.md`.

- [ ] **Step 6: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "feat(astra): dev server + parity check against sol_docs"
```

**Phase B exit criterion:** `astra dev` boots a working docs server against `examples/sol_docs`, `astra build` dumps a static tree byte-comparable to sol's old output (modulo intentional diffs), and `moon test` is green workspace-wide.

---

# Phase C — Sol cleanup, examples, docs, release

## Task 12: Migrate sol's CLI SSG callers to use astra directly

**Files:**
- Modify: `sol/src/cli/build.mbt`
- Modify: `sol/src/cli/dev.mbt`
- Modify: `sol/src/cli/generate_utils.mbt`
- Modify: `sol/src/cli/config_parser.mbt`
- Modify: `sol/src/cli/moon.pkg`
- Modify: `sol/src/cli/ssg.mbt` (likely deleted)

- [ ] **Step 1: Inventory the call sites**

```
grep -rn "@ssg\|@ssg_gen\|@ssg_routes\|@ssg_cache\|@tree\|@assets" sol/src/cli
```
Capture the list. Each line is either (a) a type reference now satisfied by astra, or (b) a function call that delegates to astra.

- [ ] **Step 2: Rewire imports in `sol/src/cli/moon.pkg`**

Replace:
```
"mizchi/sol/ssg" @ssg,
"mizchi/sol/ssg/generator" @ssg_gen,
"mizchi/sol/ssg/cache" @ssg_cache,
"mizchi/sol/ssg/tree" @tree,
"mizchi/sol/ssg/assets" @assets,
"mizchi/sol/routes" @ssg_routes,
```
with:
```
"mizchi/astra" @astra,
"mizchi/astra/render" @astra_render,
"mizchi/astra/cache" @astra_cache,
"mizchi/astra/tree" @astra_tree,
"mizchi/astra/assets" @astra_assets,
"mizchi/sol/routes" @ssg_routes,   // routes/ stays in sol (it's the SSR file-router)
```

- [ ] **Step 3: Rewrite `dev.mbt` to delete the SSG branch**

Remove:
- `has_ssg`, `find_ssg_config_file`, `parse_ssg_config`, `run_ssg_dev` calls
- `--mode ssg` parsing and the entire `if resolved_mode == "ssg"` block
- The hybrid-config warning text

The post-cleanup `sol dev` only runs the SSR app server. SSG users invoke `astra dev` instead.

- [ ] **Step 4: Rewrite `build.mbt` similarly**

Remove `is_ssg_only`, `Hybrid (app + ssg)` modes, `execute_ssg_build`, the static `SsgConfig::{ ... }` initializer at line 502, and the `if has_ssg_config(cwd)` block. `sol build` builds only the SSR app.

- [ ] **Step 5: Drop `generate_utils.mbt`'s SSG asset path lookup**

Delete the four-way fallback that searches for `src/ssg/assets/scripts/`. If `sol generate` still needs an island loader script, depend on `mizchi/astra/assets` to fetch it (`@astra_assets.island_loader_js()`), or move that helper into sol's own assets if it is sol-owned.

- [ ] **Step 6: Delete `sol/src/cli/ssg.mbt` if every symbol it exported is now unused**

```
grep -rn "<symbol>" sol/src
```
For each symbol exported from `ssg.mbt`, confirm zero remaining references and delete the file.

- [ ] **Step 7: Move `mdx_props_validator.mbt` and its wbtest into astra**

These live in `sol/src/cli/` but validate astra-owned MDX types
(`@ssg.JsxComponentEmbed`, `@ssg.MdxAttrValue`). Move them:
```
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/cli/mdx_props_validator.mbt astra/src/mdx/props_validator.mbt
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/src/cli/mdx_props_validator_wbtest.mbt astra/src/mdx/props_validator_wbtest.mbt
```
Update the `@ssg.*` references inside the moved files to `@astra.*` (or local
references inside the `mdx` subpackage). Verify with:
```
moon check --package mizchi/astra/mdx
moon test --package mizchi/astra/mdx
```

- [ ] **Step 8: Verify `sol/src/cli/templates.mbt` has no SSG-only paths**

```
grep -i "ssg" sol/src/cli/templates.mbt
```
Expected: zero matches. (As of writing this plan, `templates.mbt` already
has no SSG references — this is a confirmation step, not an edit step.)

- [ ] **Step 9: Build + test**

```
cd ~/ghq/github.com/mizchi/luna.mbt
moon check
moon test
```
Expected: green. Sol no longer imports anything under `mizchi/sol/ssg/*`.

- [ ] **Step 10: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "refactor(sol): cli no longer drives SSG; consumers use astra cli instead"
```

## Task 13: Clean up `sol/src/runtime_static_serving.mbt`

**Files:**
- Modify: `sol/src/runtime_static_serving.mbt`
- Modify: `sol/src/moon.pkg` (drop unused imports if any)

- [ ] **Step 1: Find SSG hardcoded paths**

```
grep -n "src/ssg" sol/src/runtime_static_serving.mbt
```
Expected: lines 211–214 (`.mooncakes/mizchi/sol/src/ssg/assets/scripts/`, `../../src/ssg/assets/scripts/`, etc.).

- [ ] **Step 2: Delete the SSG fallback**

Remove the entire fallback block that scans for `src/ssg/assets/scripts/`. The sol runtime is purely SSR; clients that need the island loader script should serve it via astra (or copy it into their static dir).

- [ ] **Step 3: Run sol's runtime tests**

```
moon test --package mizchi/sol
```
Expected: green. Any test that depended on the SSG fallback now relies on the real test fixtures under `sol/tests/`; if such a test fails, port the fixture into the test directory and remove the implicit dependency.

- [ ] **Step 4: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "refactor(sol): runtime no longer reaches into src/ssg/assets"
```

## Task 14: Delete `sol/src/ssg/` and the re-export shim

**Files:**
- Delete: `sol/src/ssg/` (entire directory)
- Modify: `sol/src/moon.pkg` (drop `@ssg` if still imported)

- [ ] **Step 1: Confirm no remaining callers**

```
grep -rn "mizchi/sol/ssg\|@ssg\b" sol/src
```
Expected: zero matches. If anything remains, return to Task 12 and rewire it.

- [ ] **Step 2: Delete the directory**

```
git -C ~/ghq/github.com/mizchi/luna.mbt rm -r sol/src/ssg
```

- [ ] **Step 3: Build**

```
cd ~/ghq/github.com/mizchi/luna.mbt
moon check
moon test
```
Expected: green.

- [ ] **Step 4: Trim `sol/moon.mod.json` deps**

```
grep -n "mizchi/markdown\|mizchi/jsonschema\|mizchi/process_pool\|mizchi/syntree" sol/src
```
For any dep with zero hits across `sol/src/`, remove it from
`sol/moon.mod.json`. Re-run `moon check --package mizchi/sol` to confirm it
still builds. Likely candidates after astra extraction: `mizchi/markdown`,
`mizchi/process_pool` (only used by SSG cache).

- [ ] **Step 5: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "chore(sol): drop src/ssg/ and unused deps — owned by mizchi/astra now"
```

## Task 15: Migrate documentation/blog examples to astra

**Files:**
- Move: `sol/examples/sol_docs/` → `astra/examples/sol_docs/`
- Move: `sol/examples/sol_blog/` → `astra/examples/sol_blog/`
- Modify: each example's `package.json`, `moon.mod.json`, and any path references to point at `mizchi/astra` instead of `mizchi/sol`

- [ ] **Step 1: Move with `git mv`**

```
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/examples/sol_docs astra/examples/sol_docs
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/examples/sol_blog astra/examples/sol_blog
```

- [ ] **Step 2: Update each example's `moon.mod.json` deps**

In `astra/examples/sol_docs/moon.mod.json` and `astra/examples/sol_blog/moon.mod.json`, replace any `mizchi/sol` dependency with `mizchi/astra`. Versions resolve through `moon.work` so leave them blank (`""`) or use the astra workspace version.

- [ ] **Step 3: Update each example's npm scripts to invoke `astra` instead of `sol`**

Edit `package.json`:
```diff
- "dev": "sol dev",
- "build": "sol build",
+ "dev": "astra dev",
+ "build": "astra build",
```
Make sure the astra CLI is on `$PATH` for development (link from the workspace target dir if needed).

- [ ] **Step 4: Run each example end-to-end**

```
cd astra/examples/sol_docs
pnpm install
pnpm run build
ls dist
```
Expected: dist tree matches the pre-migration output.

- [ ] **Step 5: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "chore(astra): move sol_docs / sol_blog examples under astra"
```

## Task 16: Split e2e suites along the same axis

**Files:**
- Move: documentation-flavored Playwright specs from `sol/e2e/` → `astra/e2e/`
- Keep: app/api/auth/sqlite specs in `sol/e2e/`

- [ ] **Step 1: Inventory `sol/e2e/`**

```
ls sol/e2e
```
Sort each spec into "documentation rendering" (docs, blog, MDX, theming) vs "SSR app behavior" (routing, server actions, auth, SQLite, islands).

- [ ] **Step 2: Move documentation specs**

For each spec in the documentation set:
```
git -C ~/ghq/github.com/mizchi/luna.mbt mv sol/e2e/<spec>.spec.ts astra/e2e/<spec>.spec.ts
```
Update import paths inside each spec to point at the new fixture locations under `astra/examples/`.

- [ ] **Step 3: Update both `playwright.config.ts` files**

Sol's config no longer launches `sol dev --mode ssg`; astra's config launches `astra dev` against `astra/examples/sol_docs/`.

- [ ] **Step 4: Run both suites**

```
cd astra && pnpm playwright test
cd ../sol && pnpm playwright test
```
Expected: green on both sides.

- [ ] **Step 5: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "test: split e2e — docs/blog under astra, SSR under sol"
```

## Task 17: Update READMEs and root docs

**Files:**
- Modify: `~/ghq/github.com/mizchi/luna.mbt/README.md`
- Modify: `sol/README.md` (drop SSG sections)
- Modify: `astra/README.md` (full usage docs)

- [ ] **Step 1: Author the monorepo root README**

`~/ghq/github.com/mizchi/luna.mbt/README.md`:
```markdown
# luna.mbt — UI / SSR / SSG monorepo for MoonBit

Three packages share this repository:

- `luna/` — UI primitive: VDOM, render, stream renderer.
- `sol/` — Mars-based SSR framework with file-based routing and Island Architecture.
- `astra/` — Mars middleware for static site generation; mountable on any Mars app.

Each package publishes independently to mooncakes. `moon.work` ties them together for development.
```

- [ ] **Step 2: Strip SSG content from `sol/README.md`**

Remove every paragraph that talks about SSG / `--mode ssg` / docs sites. Keep SSR / Islands / routing.

- [ ] **Step 3: Author the astra README**

`astra/README.md`: full usage doc covering `astra dev`, `astra build`, mounting on a Mars `Server`, configuration schema, and a worked example pointing at `astra/examples/sol_docs/`.

- [ ] **Step 4: Commit**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "docs: monorepo + astra README, drop SSG from sol README"
```

## Task 18: Tag a coordinated release

**Files:**
- Modify: `luna/moon.mod.json`, `sol/moon.mod.json`, `astra/moon.mod.json` versions
- Modify: each package's CHANGELOG (if present)

- [ ] **Step 1: Bump versions**

- `luna` → minor bump (workspace-only changes; downstream is unaffected).
- `sol` → minor bump (ssg removal is breaking for SSG consumers, but sol's contract is now narrower; document migration in CHANGELOG).
- `astra` → `0.1.0` (first release as a standalone package).

- [ ] **Step 2: Update CHANGELOGs**

For sol, add a "Breaking" entry: "SSG removed; use mizchi/astra instead. See migration notes in astra/README.md."

- [ ] **Step 3: Commit and tag**

```bash
git -C ~/ghq/github.com/mizchi/luna.mbt add -A
git -C ~/ghq/github.com/mizchi/luna.mbt commit -m "chore: release luna vX, sol vY, astra v0.1.0"
git -C ~/ghq/github.com/mizchi/luna.mbt tag luna-vX.Y.Z
git -C ~/ghq/github.com/mizchi/luna.mbt tag sol-vX.Y.Z
git -C ~/ghq/github.com/mizchi/luna.mbt tag astra-v0.1.0
```

- [ ] **Step 4: Publish each package to mooncakes**

Use the existing publishing flow per package (the npm-release / mooncake publish mechanism already in place). Publish in dependency order: luna → astra/sol (parallel).

- [ ] **Step 5: Retire `~/ghq/github.com/mizchi/sol.mbt`**

Push a final commit there that updates README to point at `mizchi/luna.mbt` as the canonical home, then archive the GitHub repo.

**Phase C exit criterion:** sol contains no SSG code, astra is published as `mizchi/astra v0.1.0`, examples and e2e suites live under their respective owners, and the monorepo README documents the new layout.
