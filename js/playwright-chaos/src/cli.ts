#!/usr/bin/env node
/**
 * Chaos Crawler CLI
 *
 * Usage:
 *   pnpm tsx src/cli.ts [options]
 *   chaos-crawler [options]  (when installed globally)
 *
 * Options:
 *   --url <url>           Base URL to crawl (required)
 *   --max-pages <n>       Max pages to visit (default: 50)
 *   --max-actions <n>     Max random actions per page (default: 5)
 *   --timeout <ms>        Page load timeout (default: 30000)
 *   --headless            Run headless (default: true)
 *   --no-headless         Show browser window
 *   --screenshots         Take screenshots
 *   --screenshot-dir      Screenshot directory (default: ./screenshots)
 *   --output <path>       Output report path (default: chaos-report.json)
 *   --exclude <pattern>   Exclude URL patterns (can be repeated)
 *   --compact             Compact output format
 *   --strict              Exit with error on console errors
 *   --quiet               Minimal output
 *   --help                Show this help
 */

import { parseArgs } from "node:util";
import { ChaosCrawler, COMMON_IGNORE_PATTERNS } from "./crawler.js";
import { printReport, saveReport, getExitCode } from "./reporter.js";
import type { CrawlerOptions } from "./types.js";

const { values, positionals } = parseArgs({
  options: {
    url: { type: "string" },
    "max-pages": { type: "string" },
    "max-actions": { type: "string" },
    timeout: { type: "string" },
    headless: { type: "boolean", default: true },
    screenshots: { type: "boolean", default: false },
    "screenshot-dir": { type: "string" },
    output: { type: "string" },
    exclude: { type: "string", multiple: true },
    "ignore-error": { type: "string", multiple: true },
    "ignore-analytics": { type: "boolean", default: false },
    spa: { type: "string", multiple: true },
    "log-file": { type: "string" },
    "log-level": { type: "string" },
    "log-console": { type: "boolean", default: false },
    compact: { type: "boolean", default: false },
    strict: { type: "boolean", default: false },
    quiet: { type: "boolean", default: false },
    help: { type: "boolean", default: false },
  },
  allowPositionals: true,
});

if (values.help) {
  console.log(`
Chaos Crawler - Playwright-based chaos testing tool

USAGE:
  chaos-crawler --url <url> [options]

OPTIONS:
  --url <url>           Base URL to crawl (required)
  --max-pages <n>       Max pages to visit (default: 50)
  --max-actions <n>     Max random actions per page (default: 5)
  --timeout <ms>        Page load timeout (default: 30000)
  --headless            Run headless (default: true)
  --no-headless         Show browser window
  --screenshots         Take screenshots
  --screenshot-dir      Screenshot directory (default: ./screenshots)
  --output <path>       Output report path (default: chaos-report.json)
  --exclude <pattern>   Exclude URL patterns (regex, can be repeated)
  --ignore-error <p>    Ignore error patterns (regex, can be repeated)
  --ignore-analytics    Ignore common analytics script errors
  --spa <pattern>       Mark URLs as SPA (errors shown separately, can be repeated)
  --log-file <path>     Write execution log to file (JSON format)
  --log-level <level>   Log level: debug, info, warn, error (default: info)
  --log-console         Also output logs to console
  --compact             Compact output format
  --strict              Exit with error on any console errors
  --quiet               Minimal output
  --help                Show this help

EXAMPLES:
  # Basic crawl
  chaos-crawler --url http://localhost:3000

  # With screenshots and limited pages
  chaos-crawler --url https://docs.example.com --max-pages 20 --screenshots

  # CI mode with strict checking (ignore analytics errors)
  chaos-crawler --url http://localhost:3000 --strict --compact --ignore-analytics

  # With detailed logging to file
  chaos-crawler --url http://localhost:3000 --log-file crawl.log --log-level debug

  # Exclude patterns and ignore specific errors
  chaos-crawler --url http://localhost:3000 --exclude "/api/" --ignore-error "third-party"
`);
  process.exit(0);
}

// URL from --url or first positional
const baseUrl = values.url || positionals[0];

if (!baseUrl) {
  console.error("Error: --url is required");
  console.error("Run with --help for usage information");
  process.exit(1);
}

// Build ignore patterns
const ignoreErrorPatterns: string[] = [...(values["ignore-error"] || [])];
if (values["ignore-analytics"]) {
  ignoreErrorPatterns.push(...COMMON_IGNORE_PATTERNS);
}

// Validate log level
const validLogLevels = ["debug", "info", "warn", "error"] as const;
const logLevel = values["log-level"] as (typeof validLogLevels)[number] | undefined;
if (logLevel && !validLogLevels.includes(logLevel)) {
  console.error(`Error: Invalid log level "${logLevel}". Valid levels: ${validLogLevels.join(", ")}`);
  process.exit(1);
}

const options: CrawlerOptions = {
  baseUrl,
  maxPages: values["max-pages"] ? parseInt(values["max-pages"], 10) : undefined,
  maxActionsPerPage: values["max-actions"] ? parseInt(values["max-actions"], 10) : undefined,
  timeout: values.timeout ? parseInt(values.timeout, 10) : undefined,
  headless: values.headless,
  screenshots: values.screenshots,
  screenshotDir: values["screenshot-dir"],
  excludePatterns: values.exclude,
  ignoreErrorPatterns: ignoreErrorPatterns.length > 0 ? ignoreErrorPatterns : undefined,
  spaPatterns: values.spa,
  logFile: values["log-file"],
  logLevel: logLevel,
  logToConsole: values["log-console"],
};

const outputPath = values.output || "chaos-report.json";
const isQuiet = values.quiet;
const isCompact = values.compact;
const isStrict = values.strict;

async function main() {
  if (!isQuiet) {
    console.log(`Starting chaos crawl: ${baseUrl}`);
    console.log(`Max pages: ${options.maxPages || 50}`);
    console.log("");
  }

  const crawler = new ChaosCrawler(options, {
    onPageStart: (url) => {
      if (!isQuiet && !isCompact) {
        process.stdout.write(`Crawling: ${url}...`);
      }
    },
    onPageComplete: (result) => {
      if (!isQuiet && !isCompact) {
        const status = result.status === "success" ? "OK" : result.status.toUpperCase();
        const errors = result.errors.length > 0 ? ` (${result.errors.length} errors)` : "";
        console.log(` ${status}${errors} [${result.loadTime}ms]`);
      }
    },
    onProgress: (visited, total) => {
      if (!isQuiet && isCompact) {
        process.stdout.write(`\rProgress: ${visited}/${total} pages`);
      }
    },
  });

  try {
    const report = await crawler.start();

    if (isCompact && !isQuiet) {
      console.log(""); // New line after progress
    }

    // Save report
    saveReport(report, outputPath);
    if (!isQuiet) {
      console.log(`\nReport saved to: ${outputPath}`);
    }

    // Print report
    printReport(report, isCompact);

    // Exit with appropriate code
    const exitCode = getExitCode(report, isStrict);
    process.exit(exitCode);
  } catch (err) {
    console.error("Crawl failed:", err);
    process.exit(1);
  }
}

main();
