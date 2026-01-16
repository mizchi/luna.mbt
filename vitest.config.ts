import { defineConfig } from "vitest/config";
import { resolve } from "path";
import { playwright } from "@vitest/browser-playwright";

const commonExclude = ["**/node_modules/**", "**/.mooncakes/**"];

function browserConfig() {
  return {
    enabled: true,
    headless: true,
    provider: playwright(),
    instances: [{ browser: "chromium" as const }],
  };
}

export default defineConfig({
  test: {
    projects: [
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
          exclude: commonExclude,
        },
        esbuild: {
          jsx: "automatic",
          jsxImportSource: resolve(__dirname, "js/luna/src"),
        },
      },
      {
        test: {
          name: "browser",
          browser: browserConfig(),
          include: [
            "js/luna/tests/**/*.test.ts",
            "js/wcssr/tests/**/*.browser.test.ts",
          ],
          exclude: [
            ...commonExclude,
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
      {
        test: {
          name: "bench",
          browser: browserConfig(),
          include: [
            "js/luna/tests/*.bench.ts",
            "js/luna/benches/*.bench.ts",
            "js/wcssr/tests/*.bench.ts",
          ],
          exclude: commonExclude,
          benchmark: { reporters: ["default"] },
        },
        esbuild: {
          jsx: "automatic",
          jsxImportSource: "@luna_ui/luna",
        },
      },
    ],
  },
});
