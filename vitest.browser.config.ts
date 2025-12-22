import { defineConfig } from "vitest/config";
import { playwright } from "@vitest/browser-playwright";

export default defineConfig({
  esbuild: {
    jsx: "automatic",
    jsxImportSource: "@mizchi/luna",
  },
  test: {
    reporters: ["dot"],
    browser: {
      enabled: true,
      headless: true,
      provider: playwright(),
      instances: [
        { browser: "chromium" },
      ],
    },
    include: [
      "js/luna/**/*.test.ts",
    ],
    exclude: [
      "**/node_modules/**",
      "**/.mooncakes/**",
      "js/**/tmp/**",
      // TSX tests use old bun:test format - need migration
      "js/luna/**/*.test.tsx",
      // Benchmarks should only run with `vitest bench`
      "js/luna/**/*.bench.ts",
    ],
  },
});
