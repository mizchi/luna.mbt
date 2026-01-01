import { defineConfig } from "@playwright/test";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  testDir: __dirname,
  testMatch: ["*.test.ts"],  // Only match files directly in this directory
  testIgnore: ["**/.mooncakes/**", "**/node_modules/**", "**/examples/**"],
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
