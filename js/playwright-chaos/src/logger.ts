/**
 * Logger for Chaos Crawler
 *
 * Writes structured logs to file and/or console during execution.
 */

import { createWriteStream, WriteStream } from "node:fs";
import { dirname } from "node:path";
import { mkdirSync, existsSync } from "node:fs";
import type { PageResult, PageError, ActionResult, RecoveryInfo } from "./types.js";

export type LogLevel = "debug" | "info" | "warn" | "error";

export interface LogEntry {
  timestamp: string;
  level: LogLevel;
  event: string;
  data?: Record<string, unknown>;
}

export interface LoggerOptions {
  /** Path to log file (if not set, no file logging) */
  logFile?: string;
  /** Minimum log level to write */
  level?: LogLevel;
  /** Also write to console */
  console?: boolean;
  /** Use JSON format for file output */
  jsonFormat?: boolean;
}

const LOG_LEVELS: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

export class Logger {
  private options: Required<LoggerOptions>;
  private stream: WriteStream | null = null;
  private buffer: LogEntry[] = [];

  constructor(options: LoggerOptions = {}) {
    this.options = {
      logFile: options.logFile || "",
      level: options.level || "info",
      console: options.console ?? false,
      jsonFormat: options.jsonFormat ?? true,
    };

    if (this.options.logFile) {
      this.initFileStream();
    }
  }

  private initFileStream(): void {
    const dir = dirname(this.options.logFile);
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }
    this.stream = createWriteStream(this.options.logFile, { flags: "a" });
  }

  private shouldLog(level: LogLevel): boolean {
    return LOG_LEVELS[level] >= LOG_LEVELS[this.options.level];
  }

  private formatEntry(entry: LogEntry): string {
    if (this.options.jsonFormat) {
      return JSON.stringify(entry);
    }
    const dataStr = entry.data ? ` ${JSON.stringify(entry.data)}` : "";
    return `[${entry.timestamp}] [${entry.level.toUpperCase()}] ${entry.event}${dataStr}`;
  }

  private write(level: LogLevel, event: string, data?: Record<string, unknown>): void {
    if (!this.shouldLog(level)) return;

    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      event,
      data,
    };

    this.buffer.push(entry);
    const formatted = this.formatEntry(entry);

    if (this.stream) {
      this.stream.write(formatted + "\n");
    }

    if (this.options.console) {
      const consoleFn = level === "error" ? console.error : level === "warn" ? console.warn : console.log;
      consoleFn(formatted);
    }
  }

  // Public logging methods
  debug(event: string, data?: Record<string, unknown>): void {
    this.write("debug", event, data);
  }

  info(event: string, data?: Record<string, unknown>): void {
    this.write("info", event, data);
  }

  warn(event: string, data?: Record<string, unknown>): void {
    this.write("warn", event, data);
  }

  error(event: string, data?: Record<string, unknown>): void {
    this.write("error", event, data);
  }

  // Crawler-specific logging methods
  logCrawlStart(baseUrl: string, options: Record<string, unknown>): void {
    this.info("crawl_start", { baseUrl, ...options });
  }

  logCrawlEnd(summary: Record<string, unknown>): void {
    this.info("crawl_end", summary);
  }

  logPageStart(url: string): void {
    this.info("page_start", { url });
  }

  logPageComplete(result: PageResult): void {
    this.info("page_complete", {
      url: result.url,
      status: result.status,
      statusCode: result.statusCode,
      loadTime: result.loadTime,
      errorCount: result.errors.length,
      linkCount: result.links.length,
    });
  }

  logPageError(error: PageError): void {
    this.error("page_error", {
      type: error.type,
      message: error.message,
      url: error.url,
      stack: error.stack,
    });
  }

  logAction(action: ActionResult): void {
    this.debug("action", {
      type: action.type,
      target: action.target,
      selector: action.selector,
      success: action.success,
      blockedExternal: action.blockedExternal,
      error: action.error,
    });
  }

  logBlockedNavigation(url: string): void {
    this.warn("blocked_navigation", { url });
  }

  logProgress(visited: number, total: number): void {
    this.debug("progress", { visited, total, percent: Math.round((visited / total) * 100) });
  }

  logRecovery(recovery: RecoveryInfo): void {
    this.warn("recovery", {
      failedUrl: recovery.failedUrl,
      error: recovery.error,
      recoveredTo: recovery.recoveredTo,
      recentActionsCount: recovery.recentActions.length,
      recentActions: recovery.recentActions.map((a) => ({
        type: a.type,
        target: a.target,
        success: a.success,
      })),
    });
  }

  logNavigationError(url: string, statusCode: number, error: string): void {
    this.error("navigation_error", { url, statusCode, error });
  }

  // Get all buffered entries
  getEntries(): LogEntry[] {
    return [...this.buffer];
  }

  // Flush and close
  async close(): Promise<void> {
    if (this.stream) {
      return new Promise((resolve) => {
        this.stream!.end(() => {
          this.stream = null;
          resolve();
        });
      });
    }
  }
}

/**
 * Create a no-op logger for when logging is disabled
 */
export function createNullLogger(): Logger {
  return new Logger({ level: "error" });
}
