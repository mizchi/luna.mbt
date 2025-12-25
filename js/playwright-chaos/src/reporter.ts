/**
 * Report generation and formatting utilities
 */

import { writeFileSync } from "node:fs";
import type { CrawlReport, PageResult } from "./types.js";

export function formatReport(report: CrawlReport): string {
  const lines: string[] = [];

  lines.push("=".repeat(60));
  lines.push("CHAOS CRAWLER REPORT");
  lines.push("=".repeat(60));
  lines.push("");
  lines.push(`Base URL: ${report.baseUrl}`);
  lines.push(`Duration: ${(report.duration / 1000).toFixed(2)}s`);
  lines.push(`Pages Visited: ${report.pagesVisited}`);
  if (report.blockedExternalNavigations > 0) {
    lines.push(`Blocked External Navigations: ${report.blockedExternalNavigations}`);
  }
  lines.push("");

  // Summary
  lines.push("-".repeat(40));
  lines.push("SUMMARY");
  lines.push("-".repeat(40));
  lines.push(`Success: ${report.summary.successPages}`);
  lines.push(`Errors: ${report.summary.errorPages}`);
  lines.push(`Timeouts: ${report.summary.timeoutPages}`);
  if (report.summary.recoveredPages > 0) {
    lines.push(`Recovered (404/5xx): ${report.summary.recoveredPages}`);
  }
  lines.push(`Console Errors: ${report.summary.consoleErrors}`);
  lines.push(`Network Errors: ${report.summary.networkErrors}`);
  lines.push(`JS Exceptions: ${report.summary.jsExceptions}`);
  lines.push(`Unhandled Rejections: ${report.summary.unhandledRejections}`);
  lines.push(`Avg Load Time: ${report.summary.avgLoadTime.toFixed(0)}ms`);

  if (report.summary.avgMetrics) {
    lines.push("");
    lines.push("Performance Metrics (avg):");
    lines.push(`  TTFB: ${report.summary.avgMetrics.ttfb.toFixed(0)}ms`);
    lines.push(`  FCP: ${report.summary.avgMetrics.fcp.toFixed(0)}ms`);
    lines.push(`  LCP: ${report.summary.avgMetrics.lcp.toFixed(0)}ms`);
  }

  // Error details
  const pagesWithErrors = report.pages.filter((p) => p.errors.length > 0);
  if (pagesWithErrors.length > 0) {
    lines.push("");
    lines.push("-".repeat(40));
    lines.push("ERRORS BY PAGE");
    lines.push("-".repeat(40));

    for (const page of pagesWithErrors) {
      lines.push("");
      lines.push(`[${page.status.toUpperCase()}] ${page.url}`);
      for (const error of page.errors) {
        lines.push(`  [${error.type}] ${truncate(error.message, 80)}`);
      }
    }
  }

  // Timeout pages
  const timeoutPages = report.pages.filter((p) => p.status === "timeout");
  if (timeoutPages.length > 0) {
    lines.push("");
    lines.push("-".repeat(40));
    lines.push("TIMEOUT PAGES");
    lines.push("-".repeat(40));
    for (const page of timeoutPages) {
      lines.push(`  ${page.url}`);
    }
  }

  // Dead links with source information
  if (report.summary.discovery?.deadLinks && report.summary.discovery.deadLinks.length > 0) {
    lines.push("");
    lines.push("-".repeat(40));
    lines.push("DEAD LINKS (with source)");
    lines.push("-".repeat(40));
    for (const deadLink of report.summary.discovery.deadLinks) {
      lines.push("");
      lines.push(`  URL: ${deadLink.url}`);
      lines.push(`  Status: ${deadLink.statusCode}`);
      lines.push(`  Found on: ${deadLink.sourceUrl || "(initial)"}`);
      if (deadLink.sourceElement) {
        lines.push(`  Element: ${truncate(deadLink.sourceElement, 50)}`);
      }
      lines.push(`  Method: ${deadLink.method}`);
    }
  }

  // SPA issues (separate from regular errors)
  if (report.summary.discovery?.spaIssues && report.summary.discovery.spaIssues.length > 0) {
    lines.push("");
    lines.push("-".repeat(40));
    lines.push("SPA ISSUES (expected behavior)");
    lines.push("-".repeat(40));
    for (const issue of report.summary.discovery.spaIssues) {
      lines.push(`  ${issue.url}`);
      lines.push(`    Type: ${issue.type}`);
      lines.push(`    Pattern: ${issue.matchedPattern}`);
    }
  }

  // Discovery metrics
  if (report.summary.discovery) {
    lines.push("");
    lines.push("-".repeat(40));
    lines.push("DISCOVERY METRICS");
    lines.push("-".repeat(40));
    lines.push(`  Extracted links: ${report.summary.discovery.extractedLinks}`);
    lines.push(`  Clicked links: ${report.summary.discovery.clickedLinks}`);
    lines.push(`  Unique pages: ${report.summary.discovery.uniquePages}`);
    lines.push(`  Dead links: ${report.summary.discovery.deadLinks.length}`);
    if (report.summary.discovery.spaIssues.length > 0) {
      lines.push(`  SPA issues: ${report.summary.discovery.spaIssues.length}`);
    }
  }

  // Recovered pages with recent actions
  const recoveredPages = report.pages.filter((p) => p.status === "recovered" && p.recovery);
  if (recoveredPages.length > 0) {
    lines.push("");
    lines.push("-".repeat(40));
    lines.push("RECOVERED PAGES (404/5xx)");
    lines.push("-".repeat(40));
    for (const page of recoveredPages) {
      lines.push("");
      lines.push(`  Failed URL: ${page.recovery!.failedUrl}`);
      lines.push(`  Error: ${page.recovery!.error}`);
      lines.push(`  Recovered to: ${page.recovery!.recoveredTo}`);
      if (page.recovery!.recentActions.length > 0) {
        lines.push(`  Recent actions before failure:`);
        for (const action of page.recovery!.recentActions.slice(-5)) {
          const target = action.target ? ` "${truncate(action.target, 30)}"` : "";
          lines.push(`    - ${action.type}${target}`);
        }
      }
    }
  }

  lines.push("");
  lines.push("=".repeat(60));

  return lines.join("\n");
}

export function formatCompactReport(report: CrawlReport): string {
  const status = report.summary.errorPages > 0 || report.summary.timeoutPages > 0 ? "FAIL" : "PASS";
  const errors = report.summary.consoleErrors + report.summary.networkErrors + report.summary.jsExceptions;

  return [
    `[${status}] ${report.pagesVisited} pages, ${errors} errors, ${(report.duration / 1000).toFixed(1)}s`,
    report.summary.avgMetrics
      ? `  Metrics: TTFB=${report.summary.avgMetrics.ttfb.toFixed(0)}ms, FCP=${report.summary.avgMetrics.fcp.toFixed(0)}ms`
      : "",
  ]
    .filter(Boolean)
    .join("\n");
}

export function saveReport(report: CrawlReport, path: string): void {
  writeFileSync(path, JSON.stringify(report, null, 2));
}

export function printReport(report: CrawlReport, compact = false): void {
  console.log(compact ? formatCompactReport(report) : formatReport(report));
}

function truncate(str: string, maxLen: number): string {
  if (str.length <= maxLen) return str;
  return str.slice(0, maxLen - 3) + "...";
}

// CI-friendly exit code helper
export function getExitCode(report: CrawlReport, strict = false): number {
  if (report.summary.errorPages > 0 || report.summary.timeoutPages > 0) {
    return 1;
  }
  if (strict && (report.summary.consoleErrors > 0 || report.summary.jsExceptions > 0)) {
    return 1;
  }
  return 0;
}
