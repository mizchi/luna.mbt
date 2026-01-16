import { defineConfig } from "vitest/config";
import { resolve } from "path";
import { playwright } from "@vitest/browser-playwright";

export default defineConfig({
  test: {
    projects: [
      // Node.js environment tests (jsdom)
      {
        test: {
          name: "node",
          environment: "jsdom",
          include: [
            "js/loader/**/*.test.ts",
            "js/luna/tests/**/*.test.tsx",
            "js/luna/tests/css-optimizer*.test.ts",
            "js/stella/tests/**/*.test.ts",
            "js/components/tests/**/*.test.ts",
            "js/testing/tests/**/*.test.ts",
            "scripts/**/*.test.ts",
          ],
          exclude: [
            "**/node_modules/**",
            "**/.mooncakes/**",
          ],
        },
        esbuild: {
          jsx: "automatic",
          jsxImportSource: resolve(__dirname, "js/luna/src"),
        },
      },
      // Browser tests (Playwright)
      {
        test: {
          name: "browser",
          browser: {
            enabled: true,
            headless: true,
            provider: playwright(),
            instances: [{ browser: "chromium" }],
          },
          include: [
            "js/luna/tests/**/*.test.ts",
            "js/wcssr/tests/**/*.browser.test.ts",
          ],
          exclude: [
            "**/node_modules/**",
            "**/.mooncakes/**",
            "js/luna/tests/**/*.test.tsx",
            "js/luna/tests/css-optimizer*.test.ts",
            "**/*.bench.ts",
            "**/bench.browser.test.ts",
          ],
        },
        esbuild: {
          jsx: "automatic",
          jsxImportSource: "@luna_ui/luna",
        },
      },
      // Benchmarks (Browser)
      {
        test: {
          name: "bench",
          browser: {
            enabled: true,
            headless: true,
            provider: playwright(),
            instances: [{ browser: "chromium" }],
          },
          include: [
            "js/luna/tests/*.bench.ts",
            "js/luna/benches/*.bench.ts",
            "js/wcssr/tests/*.bench.ts",
          ],
          exclude: [
            "**/node_modules/**",
            "**/.mooncakes/**",
          ],
          benchmark: {
            reporters: ["default"],
          },
        },
        esbuild: {
          jsx: "automatic",
          jsxImportSource: "@luna_ui/luna",
        },
      },
    ],
  },
});
