# @luna_ui/astra

CLI wrapper for **Astra**, the SSG / static-export companion for
[Sol](../sol/).

This package ships the `astra` command. The MoonBit-side library lives
in the same repository under `astra/`.

## Install

The **primary** install path is `moon install`; it drops a real binary
into `$MOON_HOME/bin/`:

```sh
moon install mizchi/astra/cmd/astra
```

This npm package is a **secondary** distribution channel for users who
already have node but not moon:

```sh
pnpm add -g @luna_ui/astra
# or
npm i -g @luna_ui/astra
```

Either one exposes the same `astra` command with the same surface.

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

For library use in MoonBit, depend on `mizchi/astra`. For CLI-only
usage, `moon install mizchi/astra/cmd/astra` is the smaller install.

## License

MIT
