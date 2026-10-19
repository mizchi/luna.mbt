import { defineConfig } from "tsdown";

export default defineConfig([
  {
    entry: {
      ...Object.fromEntries(
        [
          "src/index.ts",
          "src/animation.ts",
          "src/easing.ts",
          "src/signals.ts",
          "src/signals-shared.ts",
          "src/resource.ts",
          "src/router-lite.ts",
          "src/raw.ts",
          "src/event-utils.ts",
          "src/jsx-runtime.ts",
          "src/jsx-dev-runtime.ts",
        ].map((path) => [path.replace(/^src\//, "").replace(/\.ts$/, ""), path]),
      ),
      void: "src/void/plugin.ts",
      "void/client": "src/void/client.ts",
      "void/hydrate": "src/void/hydrate.ts",
      "void/scheduler": "src/void/scheduler.ts",
      "void/form": "src/void/form.ts",
      "sol/form": "src/sol/form.ts",
      "void/server": "src/void/server.ts",
      ssr: "src/ssr.ts",
      "ssr/jsx-runtime": "src/ssr/jsx-runtime.ts",
      "ssr/jsx-dev-runtime": "src/ssr/jsx-dev-runtime.ts",
    },
    format: ["esm"],
    // Declarations use this package's TypeScript 6 API; the workspace CLI uses 7.
    dts: true,
    outDir: "dist",
    clean: true,
    minify: true,
    // Use .js extension for ESM (package.json has "type": "module")
    outExtensions() {
      return { js: ".js", dts: ".d.ts" };
    },
    // Bundle the MoonBit output into the package
    deps: {
      alwaysBundle: [/\.\.\/\.\.\/\.\.\/_build/],
      neverBundle: [/^void($|\/)/, /^vite($|\/)/],
    },
  },
  {
    entry: ["src/css/index.ts"],
    format: ["esm"],
    dts: true,
    outDir: "dist/css",
    minify: false,
    outExtensions() {
      return { js: ".js", dts: ".d.ts" };
    },
  },
  {
    entry: ["src/css/runtime.ts"],
    format: ["esm"],
    dts: true,
    outDir: "dist/css",
    minify: false,
    outExtensions() {
      return { js: ".js", dts: ".d.ts" };
    },
  },
  {
    entry: ["src/vite-plugin.ts"],
    format: ["esm"],
    dts: true,
    outDir: "dist",
    minify: false,
    // Bundle CSS module into plugin
    deps: {
      alwaysBundle: [/\.\/css/],
      neverBundle: [/^vite($|\/)/],
      dts: {
        neverBundle: [/^vite($|\/)/, /^postcss($|\/)/, /^esbuild($|\/)/],
      },
    },
    outExtensions() {
      return { js: ".js", dts: ".d.ts" };
    },
  },
  {
    entry: ["bin/cli.ts"],
    format: ["esm"],
    outDir: "dist",
    dts: false,
    minify: false,
    // CLI needs CSS module bundled
    deps: { alwaysBundle: [/\.\.\/src\/css/] },
  },
]);
