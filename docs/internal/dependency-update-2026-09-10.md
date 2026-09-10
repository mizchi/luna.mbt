# Dependency update — 2026-09-10

Updated MoonBit and npm dependencies across libraries, examples, and scaffold
templates. npm now uses one root workspace and lockfile, including the Sol
examples previously hidden behind a conflicting nested workspace.

## Selected versions

| Dependency | Previous | Updated |
| --- | --- | --- |
| moonbitlang/lexer | 0.3.8 | 0.3.16 |
| moonbitlang/parser | 0.3.8 | 0.3.19 |
| moonbitlang/async | 0.20.1 | 0.21.3 |
| moonbitlang/x | 0.4.46 | 0.5.4 |
| mizchi/markdown | 0.6.2 | 0.8.3 |
| mizchi/ts | 0.3.0 | 0.5.2 |
| mizchi/x | 0.3.0 | 0.6.0 |
| Vite | 8.1.3 | 8.3.0 |
| Vitest and its browser/coverage packages | 4.1.10 | 5.0.0 |
| TypeScript | 6.0.3 | 7.0.2 |
| Playwright | 1.61.1 | 1.63.0 |
| jsdom | 29.1.1 | 30.0.1 |
| execa | 9.6.1 | 10.0.1 |
| tsdown | 0.22.3 | 0.23.0 |
| Hono | 4.12.28 | 4.13.7 |
| Wrangler | 4.107.0 | 4.130.0 |

## Compatibility changes

- Validation uses MoonBit v0.10.12 and Node.js 24.21.0. Development requires
  MoonBit v0.10.12+ and Node.js 24.15+; older compilers reject collection
  constructors in the updated `moonbitlang/x` dependency.
- Markdown's MDX package moved from `experimental/mdx` to `x/mdx`. New block
  variants use the upstream HTML renderer, and inline directives preserve
  attributes and escaping.
- Vitest provides jsdom to TSX tests; those tests no longer register a second
  global DOM. `global-jsdom` remains a root dependency for MoonBit FFI tests.
- The SQLite auth instance has its own inferred type instead of asserting the
  D1 instance type. SQLite migrations and email signup were exercised against
  an in-memory database.
- `better-sqlite3` stays on the latest compatible 12.x release, 12.11.1. Better
  Auth 1.7.4 declares a `^12.0.0` peer; version 13 is intentionally excluded.
- Miniflare's sharp dependency is overridden to `^0.35.4` to address
  [GHSA-rgj7-g3m4-5g8c](https://github.com/advisories/GHSA-rgj7-g3m4-5g8c).
  Remove the override once Miniflare updates its pinned dependency.
- The Vite plugin keeps Vite external and declares it as an optional peer.
- Sol and Astra's JS entry points skip both the Node executable and script
  path now that `mizchi/x/sys.get_cli_args` returns the full Node argv.
- Public npm runtime dependencies retain registry semver ranges after pnpm
  updates, including Stella's dependency on WCR.

## Validation

- Workspace MoonBit check: zero errors with the published wit fix below.
- Workspace MoonBit tests: 2,846 passed with the published dependency. Upstream
  wit adds 33 passing tests on each of JS and native.
- Vitest: 734 tests passed across Node and browser projects.
- Playwright: 176 tests passed.
- CSS-specific tests: JS, native, Wasm GC, SSR, static extraction, CLI and Vite
  watch passed, including five browser tests.
- Full integration suite: 21 tests passed, including the seven-example matrix,
  Astra build/dev parity, npm tarball execution, and website asset/CSS checks.
- MoonBit release build, npm library builds and TypeScript checks passed.
- npm audit: zero vulnerabilities. The only remaining npm outdated entry is
  the intentionally constrained `better-sqlite3` major upgrade.

## Upstream publication

`mizchi/wit@0.3.3` was published to Mooncakes and added to Sol's dependencies.
The [tagged source](https://github.com/mizchi/wit.mbt/tree/v0.3.3) copies
`x/fs.read_dir`'s `ArrayView[String]` with `to_owned` before sorting, updates
the x dependency, and adds directory/error regression tests. Its release
checks, package check, and 33 tests on both JS and native pass.

The registry index and downloaded package both identify version 0.3.3.
Workspace checks now use the published dependency without the temporary
workspace override used during initial validation.
