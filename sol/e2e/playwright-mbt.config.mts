import { defineConfig } from "@playwright/test";
import hydration from "./playwright-sol-app.config.mts";

export default defineConfig({
  ...hydration,
  testMatch: "moonbit.spec.ts",
  retries: 0,
  timeout: 330_000,
  webServer: {
    ...hydration.webServer,
    reuseExistingServer: false,
  },
});
