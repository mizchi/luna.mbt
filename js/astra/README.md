# @luna_ui/astra

CLI wrapper for **Astra**, the SSG / static-export companion for
[Sol](../sol/).

This package ships the `astra` command. It is the npm-distributable
front for `mizchi/astra` on [mooncakes.io](https://mooncakes.io). The
MoonBit-side library lives in the same repository under `astra/`.

## Install

```sh
pnpm add -g @luna_ui/astra
# or
npm i -g @luna_ui/astra
```

## Usage

```sh
astra --help
astra build             # crawl a Sol app and dump every URL to disk
astra dev               # serve the same crawl at runtime for parity testing
```

Run `astra <command> --help` for command-specific options.

## What is Astra?

Astra is mountable Mars middleware for static site generation. Point
it at a Sol-compatible Hono app, declare which routes you want
materialised, and Astra will walk and snapshot them — verifying that
build-output and runtime-served HTML stay byte-for-byte identical
(see `astra/e2e/build_dev_parity.test.js`).

For library use in MoonBit, depend on `mizchi/astra`. For CLI usage
in any project, install this package.

## License

MIT
