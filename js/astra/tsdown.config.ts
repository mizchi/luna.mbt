import { defineConfig } from "tsdown";

export default defineConfig({
  entry: [
    "src/index.ts",
    "src/cli.ts",
  ],
  format: ["esm"],
  dts: true,
  outDir: "dist",
  clean: true,
  minify: true,
  outExtensions() {
    return { js: ".js", dts: ".d.ts" };
  },
  noExternal: [/\.\.\/\.\.\/\.\.\/target/],
});
