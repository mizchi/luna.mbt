/**
 * @luna_ui/playwright-chaos
 *
 * Playwright-based chaos testing library for web applications.
 * Inspired by monkey testing with additional features for error detection and reporting.
 */

// Core
export { ChaosCrawler, COMMON_IGNORE_PATTERNS } from "./crawler.js";
export { formatReport, formatCompactReport, saveReport, printReport, getExitCode } from "./reporter.js";
export { Logger, createNullLogger, type LogEntry, type LogLevel, type LoggerOptions } from "./logger.js";

// Playwright Test integration
export { chaosTest, withChaos, runChaosTest, chaosExpect, type ChaosFixture, type ChaosFixtures } from "./fixture.js";

// Types
export type {
  CrawlerOptions,
  CrawlerEvents,
  ChaosTestOptions,
  PageResult,
  PageError,
  ActionResult,
  ActionTarget,
  ActionWeights,
  PerformanceMetrics,
  CrawlReport,
  CrawlSummary,
} from "./types.js";
