import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Default: Node.js environment with jsdom for DOM tests
    environment: "jsdom",
    include: [
      "src/**/*.test.ts",
      "packages/loader/**/*.test.ts",
      "e2e/sol/cli/**/*.test.ts", // Only CLI tests (Vitest)
    ],
    exclude: [
      "**/node_modules/**",
      "**/.mooncakes/**",
      "packages/**/tmp/**",
      "e2e/sol/ssr-hydration.test.ts", // Playwright test
    ],
  },
});
