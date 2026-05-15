---
title: Install
description: Bootstrapping an Astra project and adding PageFind as a devDependency.
---

<search-box></search-box>

# Install

This page walks through bootstrapping a fresh Astra project and adding PageFind as a devDependency.

## Prerequisites

- **MoonBit toolchain.** The host project compiles a MoonBit module against `mizchi/astra`. Install `moon` from the MoonBit website. The minimum tested version tracks `mizchi/astra`'s release notes; anything from 0.22.x onwards should work.
- **Node.js 20+.** PageFind ships as an npm package that wraps a Rust binary. Node 20 is the earliest version with reliable `--experimental-permission` support if you care about sandboxing.
- **pnpm or npm.** This example assumes pnpm because it is part of a workspace, but plain `npm` works for a standalone fork.

## Scaffolding

If you are starting from scratch (i.e. not in the `luna.mbt` monorepo), create a new directory and lay it out like so:

```
my-docs/
├── app/
│   └── routes/
│       ├── moon.pkg.json
│       └── routes.mbt
├── docs/
│   ├── index.md
│   └── guide/
│       └── 01_intro.md
├── astra.config.json
├── moon.mod.json
├── moon.pkg.json
└── package.json
```

The minimum `routes.mbt` only needs to export an empty routes array and an empty action registry — Astra's SSG mode does not need any server routes, but the symbol table check still expects the entry points to exist.

## Adding PageFind

Install the binary wrapper as a devDependency:

```sh
pnpm add -D pagefind
# or:
npm install --save-dev pagefind
```

The npm package vendors prebuilt binaries for Linux, macOS, and Windows — there is no separate Rust toolchain step.

Then chain the indexer onto your build script in `package.json`:

```json
{
  "scripts": {
    "build": "astra build && pagefind --site dist"
  }
}
```

The order matters: `astra build` writes HTML into `dist/`, and PageFind walks that directory after it is populated. Running them in the wrong order produces an empty or stale index.

## Verifying the install

After the first build, the `dist/` tree should contain a `pagefind/` subdirectory:

```
dist/
├── index.html
├── guide/
│   └── 01_intro/
│       └── index.html
├── og.svg
└── pagefind/
    ├── pagefind.js
    ├── pagefind-ui.js   (optional, only when you use --serve-ui)
    ├── wasm.*.pagefind
    └── fragment/
```

If `pagefind/` is missing, the post-build step did not run — check that `pagefind` is on the `PATH` (pnpm symlinks it into `node_modules/.bin`).
