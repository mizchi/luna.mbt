# @luna_ui/sol

CLI wrapper for **Sol**, an SSR-first web framework for MoonBit.

This package ships the `sol` command. The MoonBit-side framework
lives in the same repository under `sol/`.

## Install

The **primary** install path is `moon install`; it drops a real binary
into `$MOON_HOME/bin/`:

```sh
moon install mizchi/sol/cmd/sol
```

This npm package is a **secondary** distribution channel for users who
already have node but not moon:

```sh
pnpm add -g @luna_ui/sol
# or
npm i -g @luna_ui/sol
```

Either one exposes the same `sol` command with the same surface.

## Usage

```sh
sol --help
sol new my-app          # scaffold a new project
sol dev                 # run the dev server
sol build               # produce a release bundle
sol generate            # regenerate routes / types
```

Run `sol <command> --help` for command-specific options.

## What is Sol?

Sol is a server-side rendering framework for MoonBit, built on top of
[Luna](https://github.com/mizchi/luna.mbt) primitives. It supports
file-system routing, hydration islands, SQL/auth integrations, and
a static export mode (via [astra](../astra/)).

For framework development in MoonBit, depend on `mizchi/sol`. For
CLI-only usage, `moon install mizchi/sol/cmd/sol` is the smaller
install.

## License

MIT
