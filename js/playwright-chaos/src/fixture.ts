/**
 * Playwright Test Fixture for Chaos Testing
 *
 * Usage:
 * ```typescript
 * import { test, expect } from '@playwright/test';
 * import { chaosTest, withChaos } from '@luna_ui/playwright-chaos/fixture';
 *
 * // Option 1: Use chaosTest directly
 * chaosTest('chaos test homepage', async ({ page, chaos }) => {
 *   const result = await chaos.testPage(page, 'http://localhost:3000');
 *   expect(result.errors).toHaveLength(0);
 * });
 *
 * // Option 2: Extend your existing test
 * const test = base.extend(withChaos());
 * test('my test', async ({ page, chaos }) => { ... });
 * ```
 */

import { test as base, expect, type Page } from "@playwright/test";
import { ChaosCrawler, COMMON_IGNORE_PATTERNS } from "./crawler.js";
import type { ChaosTestOptions, PageResult, CrawlReport } from "./types.js";

export interface ChaosFixture {
  /** Test a single page with chaos testing */
  testPage(page: Page, url: string): Promise<PageResult>;

  /** Crawl multiple pages starting from a URL */
  crawl(startUrl: string): Promise<CrawlReport>;

  /** Assert no errors were found */
  expectNoErrors(result: PageResult | CrawlReport): void;

  /** Get the underlying crawler instance */
  crawler: ChaosCrawler;
}

export interface ChaosFixtures {
  chaos: ChaosFixture;
  chaosOptions: ChaosTestOptions;
}

/**
 * Create chaos fixture with custom options
 */
export function withChaos(defaultOptions: ChaosTestOptions = {}) {
  return {
    chaosOptions: [{}, { option: true }] as [ChaosTestOptions, { option: true }],

    chaos: async (
      { page, chaosOptions }: { page: Page; chaosOptions: ChaosTestOptions },
      use: (fixture: ChaosFixture) => Promise<void>
    ) => {
      const options = { ...defaultOptions, ...chaosOptions };

      // Get base URL from playwright config or options
      const baseUrl = options.baseUrl || page.context().pages()[0]?.url() || "http://localhost:3000";

      const crawler = new ChaosCrawler({
        baseUrl,
        maxPages: options.maxPages ?? 10,
        maxActionsPerPage: options.maxActionsPerPage ?? 5,
        ignoreErrorPatterns: options.ignoreErrorPatterns ?? COMMON_IGNORE_PATTERNS,
        blockExternalNavigation: options.blockExternalNavigation ?? true,
        actionWeights: options.actionWeights,
        headless: true,
      });

      const fixture: ChaosFixture = {
        crawler,

        async testPage(testPage: Page, url: string): Promise<PageResult> {
          return crawler.testPage(testPage, url);
        },

        async crawl(startUrl: string): Promise<CrawlReport> {
          // Update base URL for crawling
          (crawler as any).options.baseUrl = startUrl;
          (crawler as any).baseOrigin = new URL(startUrl).origin;
          return crawler.start();
        },

        expectNoErrors(result: PageResult | CrawlReport): void {
          if ("pages" in result) {
            // CrawlReport
            const allErrors = result.pages.flatMap((p) => p.errors);
            if (allErrors.length > 0) {
              const errorMessages = allErrors.map((e) => `[${e.type}] ${e.message}`).join("\n");
              throw new Error(`Found ${allErrors.length} errors:\n${errorMessages}`);
            }
          } else {
            // PageResult
            if (result.errors.length > 0) {
              const errorMessages = result.errors.map((e) => `[${e.type}] ${e.message}`).join("\n");
              throw new Error(`Found ${result.errors.length} errors:\n${errorMessages}`);
            }
          }
        },
      };

      await use(fixture);
    },
  };
}

/**
 * Pre-configured test with chaos fixture
 */
export const chaosTest = base.extend<ChaosFixtures>(withChaos());

/**
 * Helper to run chaos test on current page
 */
export async function runChaosTest(
  page: Page,
  options: ChaosTestOptions = {}
): Promise<PageResult> {
  const url = page.url();
  const crawler = new ChaosCrawler({
    baseUrl: url,
    maxPages: 1,
    maxActionsPerPage: options.maxActionsPerPage ?? 5,
    ignoreErrorPatterns: options.ignoreErrorPatterns ?? COMMON_IGNORE_PATTERNS,
    blockExternalNavigation: options.blockExternalNavigation ?? true,
    actionWeights: options.actionWeights,
    headless: true,
  });

  return crawler.testPage(page, url);
}

/**
 * Expect helper for chaos results
 */
export const chaosExpect = {
  toHaveNoErrors(result: PageResult | CrawlReport) {
    if ("pages" in result) {
      const allErrors = result.pages.flatMap((p) => p.errors);
      expect(allErrors, `Expected no errors but found: ${JSON.stringify(allErrors)}`).toHaveLength(0);
    } else {
      expect(
        result.errors,
        `Expected no errors but found: ${JSON.stringify(result.errors)}`
      ).toHaveLength(0);
    }
  },

  toHaveNoExceptions(result: PageResult | CrawlReport) {
    const errors = "pages" in result ? result.pages.flatMap((p) => p.errors) : result.errors;
    const exceptions = errors.filter((e) => e.type === "exception" || e.type === "unhandled-rejection");
    expect(
      exceptions,
      `Expected no exceptions but found: ${JSON.stringify(exceptions)}`
    ).toHaveLength(0);
  },

  toLoadWithin(result: PageResult, maxMs: number) {
    expect(result.loadTime, `Page load time ${result.loadTime}ms exceeded ${maxMs}ms`).toBeLessThanOrEqual(
      maxMs
    );
  },
};
