import { defineConfig } from "vitest/config";
import { playwright } from "@vitest/browser-playwright";

export default defineConfig({
  esbuild: {
    jsx: "automatic",
    jsxImportSource: "@luna_ui/luna",
  },
  test: {
    reporters: ["verbose"],
    browser: {
      enabled: true,
      headless: true,
      provider: playwright(),
      instances: [{ browser: "chromium" }],
    },
    include: ["js/luna/tests/*.bench.ts", "js/wcssr/tests/*.bench.ts", "js/luna/benches/*.bench.ts"],
    exclude: [
      "**/node_modules/**",
      "**/.mooncakes/**",
      "**/examples/**",
    ],
    benchmark: {
      reporters: ["default"],
    },
  },
});
