# MoonBit CSS command

`mizchi/luna/cmd/css` is Luna's JavaScript-target CLI package. It exposes the
same static compiler used by `luna css compile` and `lunaCssCompile`.
Node.js 24+ is required.

From this repository's root:

```sh
moon run --target js luna/src/cmd/css -- --help
moon run --target js luna/src/cmd/css -- compile app --output-dir build/app
moon run --target js luna/src/cmd/css -- extract app --strict -o app.css
moon run --target js luna/src/cmd/css -- watch --root web

# Repository shortcut
just css compile app --output-dir build/app
```

The Moon CLI tested here (`0.1.20260824`) resolves `moon run` arguments as
filesystem paths. Although the package name is `mizchi/luna/cmd/css`, the bare
command `moon run mizchi/luna/cmd/css` fails with that toolchain. Pass the path
to the package's source directory, as above. From another workspace, adjust
that path to the Luna source location. Command arguments resolve relative to
the caller's working directory.

`compile` and `extract` include their compiler implementation in the Mooncake;
they need no npm compiler installation. `compile` stages transformed MoonBit
sources and `luna.css`; run `moon build` on that output to build the application.
Its output directory must be outside the input directory. See the
[CSS documentation](../../x/css/README.md#static-compilation-before-debug-and-release-builds)
for supported static expressions and SSR integration.

`watch` starts the caller project's installed Vite and loads its `vite.config`.
Configure [lunaCssCompile](../../x/css/README.md#vite-watch-integration) there to
watch, compile, and reload MoonBit CSS. Options: `--root`, `--config`, `--host`,
and `--port`. The config path is relative to the project root. SIGINT and
SIGTERM close Vite and its compiler watchers.

The command is a MoonBit entry with a bundled JavaScript implementation, not
a native MoonBit compiler. The checked-in `cli_generated.mbt` is generated
from `js/luna/src/css/moon-cli.ts` and its dependencies; do not edit it by hand.
Run `just generate-css-cli` after changing those sources. `just test-css`
checks bundle freshness, compilation from an isolated consumer workspace,
argument forwarding, error exit codes, and Vite startup/shutdown.
