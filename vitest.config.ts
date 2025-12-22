import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Default: Node.js environment with jsdom for DOM tests
    environment: "jsdom",
    reporters: ["dot"],
    include: [
      "src/**/*.test.ts",
      "js/loader/**/*.test.ts",
      "e2e/sol/cli/**/*.test.ts", // Only CLI tests (Vitest)
      "scripts/**/*.test.ts", // Script tests
    ],
    exclude: [
      "**/node_modules/**",
      "**/.mooncakes/**",
      "js/**/tmp/**",
      "e2e/sol/ssr-hydration.test.ts", // Playwright test
    ],
  },
});
