import { defineConfig } from "tsdown";

export default defineConfig([
  {
    entry: [
      "src/index.ts",
      "src/event-utils.ts",
      "src/jsx-runtime.ts",
      "src/jsx-dev-runtime.ts",
    ],
    format: ["esm"],
    dts: true,
    outDir: "dist",
    clean: true,
    minify: true,
    // Use .js extension for ESM (package.json has "type": "module")
    outExtensions() {
      return { js: ".js", dts: ".d.ts" };
    },
    // Bundle the MoonBit output into the package
    noExternal: [/\.\.\/\.\.\/\.\.\/target/],
  },
  {
    entry: ["bin/cli.ts"],
    format: ["esm"],
    outDir: "dist",
    dts: false,
    minify: false,
  },
]);
