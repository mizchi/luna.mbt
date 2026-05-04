import { defineConfig } from "vitest/config";
import { resolve } from "path";
import { playwright } from "@vitest/browser-playwright";

const commonExclude = ["**/node_modules/**", "**/.mooncakes/**"];

// This config lives in luna/ but the test files (js/loader, js/luna, js/stella, ...)
// live at the workspace root. Anchor every project's `root` to the workspace root
// so the include globs resolve regardless of which directory invokes vitest.
const workspaceRoot = resolve(__dirname, "..");

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
          root: workspaceRoot,
          environment: "jsdom",
          include: [
            "js/loader/**/*.test.ts",
            "js/luna/tests/**/*.test.tsx",
            "js/luna/tests/css-optimizer*.test.ts",
            "js/luna/tests/cli-*.test.ts",
            "js/stella/tests/**/*.test.ts",
            "js/components/tests/**/*.test.ts",
            "js/testing/tests/**/*.test.ts",
            "scripts/**/*.test.ts",
          ],
          exclude: commonExclude,
        },
        esbuild: {
          jsx: "automatic",
          jsxImportSource: resolve(workspaceRoot, "js/luna/src"),
        },
      },
      {
        test: {
          name: "browser",
          root: workspaceRoot,
          browser: browserConfig(),
          include: [
            "js/luna/tests/**/*.test.ts",
            "js/wcssr/tests/**/*.browser.test.ts",
          ],
          exclude: [
            ...commonExclude,
            "js/luna/tests/**/*.test.tsx",
            "js/luna/tests/css-optimizer*.test.ts",
            "js/luna/tests/cli-*.test.ts",
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
          root: workspaceRoot,
          browser: browserConfig(),
          include: [],
          exclude: commonExclude,
          benchmark: {
            include: [
              "js/luna/tests/*.bench.ts",
              "js/luna/benches/*.bench.ts",
              "js/wcssr/tests/*.bench.ts",
            ],
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
