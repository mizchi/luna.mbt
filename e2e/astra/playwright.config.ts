import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: ".",
  testMatch: ["**/*.test.ts"],
  fullyParallel: false, // Run tests sequentially since they share the dev server
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1, // Single worker to avoid conflicts
  reporter: "dot",
  timeout: 60000, // 60 seconds per test
  use: {
    trace: "on-first-retry",
  },
  // No webServer - tests manage their own dev server
});
