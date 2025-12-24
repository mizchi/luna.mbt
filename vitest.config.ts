import { defineConfig } from "vitest/config";
import { resolve } from "path";

export default defineConfig({
  esbuild: {
    jsx: "automatic",
    jsxImportSource: resolve(__dirname, "js/luna/src"),
  },
  test: {
    // Default: Node.js environment with jsdom for DOM tests
    environment: "jsdom",
    reporters: ["dot"],
    include: [
      "js/loader/**/*.test.ts",
      "js/luna/tests/**/*.test.tsx", // TSX tests need jsdom (global-jsdom)
      "e2e/sol/cli/**/*.test.ts",
      "scripts/**/*.test.ts",
      "tests/cloudflare/**/*.test.ts", // Cloudflare routing logic tests
    ],
    exclude: [
      "**/node_modules/**",
      "**/.mooncakes/**",
      "js/**/tmp/**",
    ],
  },
});
