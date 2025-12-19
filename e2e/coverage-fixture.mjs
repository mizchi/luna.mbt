/**
 * Playwright coverage fixture using V8 coverage API
 * Collects JS coverage during E2E tests
 */
import { test as base } from "@playwright/test";
import { mkdir, writeFile } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const COVERAGE_DIR = join(__dirname, "..", "coverage", "e2e-v8");

// Extend the base test with coverage collection
export const test = base.extend({
  coveragePage: async ({ page }, use, testInfo) => {
    // Start JS coverage before test
    await page.coverage.startJSCoverage({
      resetOnNavigation: false,
    });

    // Run the test
    await use(page);

    // Stop coverage and save
    const coverage = await page.coverage.stopJSCoverage();

    // Filter to only include our app code (exclude node_modules, etc.)
    const filtered = coverage.filter((entry) => {
      const url = entry.url;
      return (
        url.includes("/target/js/") ||
        url.includes("/js/loader/") ||
        url.includes("browser_router") ||
        url.includes("demo")
      );
    });

    if (filtered.length > 0) {
      await mkdir(COVERAGE_DIR, { recursive: true });

      // Save raw V8 coverage data
      const fileName = `${testInfo.testId.replace(/[^a-zA-Z0-9]/g, "_")}.json`;
      await writeFile(
        join(COVERAGE_DIR, fileName),
        JSON.stringify(filtered, null, 2)
      );
    }
  },
});

export { expect } from "@playwright/test";
