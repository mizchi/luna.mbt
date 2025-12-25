/**
 * ChaosCrawler - Playwright-based chaos testing crawler
 */

import type { Browser, BrowserContext, Page, Route } from "playwright";
import { chromium } from "playwright";
import { mkdirSync, existsSync } from "node:fs";
import { join } from "node:path";
import type {
  CrawlerOptions,
  CrawlerEvents,
  PageResult,
  PageError,
  ActionResult,
  ActionTarget,
  ActionWeights,
  PerformanceMetrics,
  CrawlReport,
  CrawlSummary,
  RecoveryInfo,
  QueueEntry,
  DiscoveryMetrics,
  DeadLinkInfo,
  DiscoveryMethod,
  SpaIssueInfo,
} from "./types.js";
import { Logger, createNullLogger } from "./logger.js";

const DEFAULT_OPTIONS: Required<Omit<CrawlerOptions, "baseUrl">> = {
  maxPages: 50,
  maxActionsPerPage: 5,
  timeout: 30000,
  headless: true,
  screenshots: false,
  screenshotDir: "./screenshots",
  excludePatterns: [],
  ignoreErrorPatterns: [],
  spaPatterns: [],
  viewport: { width: 1280, height: 720 },
  userAgent: "",
  blockExternalNavigation: true,
  actionWeights: {},
  logFile: "",
  logLevel: "info",
  logToConsole: false,
  enableRecovery: true,
  recoveryHistorySize: 20,
};

const DEFAULT_ACTION_WEIGHTS: Required<ActionWeights> = {
  navigationLinks: 3,
  buttons: 2,
  inputs: 1,
  ariaInteractive: 2,
  visibleText: 1.5,
  scroll: 0.5,
};

// Common third-party scripts to ignore in dev mode
export const COMMON_IGNORE_PATTERNS = [
  "cloudflareinsights\\.com",
  "googletagmanager\\.com",
  "google-analytics\\.com",
  "analytics\\.google\\.com",
  "facebook\\.net",
  "connect\\.facebook\\.net",
  "hotjar\\.com",
  "clarity\\.ms",
  "segment\\.io",
  "amplitude\\.com",
  // Generic error message from blocked resources
  "Failed to load resource: net::ERR_FAILED$",
];

export class ChaosCrawler {
  private options: Required<CrawlerOptions>;
  private actionWeights: Required<ActionWeights>;
  private events: CrawlerEvents;
  private logger: Logger;
  private browser: Browser | null = null;
  private context: BrowserContext | null = null;
  private visited: Set<string> = new Set();
  private queue: QueueEntry[] = [];
  private results: PageResult[] = [];
  private actions: ActionResult[] = [];
  private blockedExternalCount = 0;
  private startTime = 0;
  private baseOrigin: string;
  /** Recent action history for recovery */
  private actionHistory: ActionResult[] = [];
  /** Last successfully loaded URL for recovery */
  private lastSuccessfulUrl: string = "";
  /** Recovery count for reporting */
  private recoveryCount = 0;
  /** Discovery metrics */
  private discoveryMetrics: DiscoveryMetrics = {
    extractedLinks: 0,
    clickedLinks: 0,
    uniquePages: 0,
    deadLinks: [],
    spaIssues: [],
  };
  /** Current page being crawled (for source tracking) */
  private currentEntry: QueueEntry | null = null;

  constructor(options: CrawlerOptions, events: CrawlerEvents = {}) {
    // Filter out undefined values to preserve defaults
    const filteredOptions = Object.fromEntries(
      Object.entries(options).filter(([_, v]) => v !== undefined)
    );
    this.options = { ...DEFAULT_OPTIONS, ...filteredOptions } as Required<CrawlerOptions>;
    this.actionWeights = { ...DEFAULT_ACTION_WEIGHTS, ...options.actionWeights };
    this.events = events;
    this.baseOrigin = new URL(options.baseUrl).origin;

    // Initialize logger
    if (options.logFile) {
      this.logger = new Logger({
        logFile: options.logFile,
        level: options.logLevel || "info",
        console: options.logToConsole || false,
        jsonFormat: true,
      });
    } else {
      this.logger = createNullLogger();
    }
  }

  /** Get the logger instance for external use */
  getLogger(): Logger {
    return this.logger;
  }

  /** Add action to history buffer */
  private addToHistory(action: ActionResult): void {
    this.actionHistory.push(action);
    // Keep only recent actions
    if (this.actionHistory.length > this.options.recoveryHistorySize) {
      this.actionHistory.shift();
    }
  }

  /** Get recent actions for recovery dump */
  getRecentActions(): ActionResult[] {
    return [...this.actionHistory];
  }

  /** Create recovery info from current state */
  private createRecoveryInfo(failedUrl: string, error: string): RecoveryInfo {
    return {
      failedUrl,
      error,
      recoveredTo: this.lastSuccessfulUrl,
      recentActions: this.getRecentActions(),
      timestamp: Date.now(),
    };
  }

  async start(): Promise<CrawlReport> {
    this.startTime = Date.now();
    this.visited.clear();
    this.queue = [{
      url: this.options.baseUrl,
      sourceUrl: "",
      method: "initial",
    }];
    this.results = [];
    this.actions = [];
    this.blockedExternalCount = 0;

    // Reset recovery state
    this.actionHistory = [];
    this.lastSuccessfulUrl = this.options.baseUrl;
    this.recoveryCount = 0;

    // Reset discovery metrics
    this.discoveryMetrics = {
      extractedLinks: 0,
      clickedLinks: 0,
      uniquePages: 0,
      deadLinks: [],
      spaIssues: [],
    };

    // Log crawl start
    this.logger.logCrawlStart(this.options.baseUrl, {
      maxPages: this.options.maxPages,
      maxActionsPerPage: this.options.maxActionsPerPage,
      timeout: this.options.timeout,
      blockExternalNavigation: this.options.blockExternalNavigation,
      enableRecovery: this.options.enableRecovery,
    });

    if (this.options.screenshots && !existsSync(this.options.screenshotDir)) {
      mkdirSync(this.options.screenshotDir, { recursive: true });
    }

    this.browser = await chromium.launch({ headless: this.options.headless });
    this.context = await this.browser.newContext({
      viewport: this.options.viewport,
      userAgent: this.options.userAgent || undefined,
    });

    try {
      while (this.queue.length > 0 && this.visited.size < this.options.maxPages) {
        const entry = this.queue.shift()!;
        if (this.visited.has(entry.url)) continue;
        if (this.shouldExclude(entry.url)) {
          this.logger.debug("page_excluded", { url: entry.url });
          continue;
        }

        this.visited.add(entry.url);
        this.currentEntry = entry;
        this.discoveryMetrics.uniquePages++;
        this.events.onProgress?.(this.visited.size, this.options.maxPages);
        this.logger.logProgress(this.visited.size, this.options.maxPages);

        const result = await this.crawlPage(entry);
        this.results.push(result);

        // Add discovered links to queue with source tracking
        for (const link of result.links) {
          const alreadyQueued = this.queue.some(e => e.url === link);
          if (!this.visited.has(link) && !alreadyQueued) {
            this.queue.push({
              url: link,
              sourceUrl: entry.url,
              method: "extracted",
            });
            this.discoveryMetrics.extractedLinks++;
          }
        }
      }
    } finally {
      await this.browser.close();
    }

    const endTime = Date.now();
    const report = this.generateReport(endTime);

    // Log crawl end
    this.logger.logCrawlEnd({
      duration: report.duration,
      pagesVisited: report.pagesVisited,
      totalErrors: report.totalErrors,
      blockedExternalNavigations: report.blockedExternalNavigations,
      recoveryCount: this.recoveryCount,
    });

    // Close logger
    await this.logger.close();

    return report;
  }

  /**
   * Run chaos testing on a single page (for Playwright Test integration)
   */
  async testPage(page: Page, url: string): Promise<PageResult> {
    this.startTime = Date.now();
    this.baseOrigin = new URL(url).origin;

    // Set up external navigation blocking
    if (this.options.blockExternalNavigation) {
      await this.setupNavigationBlocking(page);
    }

    const result = await this.crawlPageWithExistingPage(page, url);
    this.results.push(result);

    return result;
  }

  private shouldExclude(url: string): boolean {
    const patterns = this.options.excludePatterns || [];
    return patterns.some((pattern) => {
      try {
        return new RegExp(pattern).test(url);
      } catch {
        return false;
      }
    });
  }

  /** Check if URL matches SPA patterns */
  private matchesSpaPattern(url: string): string | null {
    const patterns = this.options.spaPatterns || [];
    for (const pattern of patterns) {
      try {
        if (new RegExp(pattern).test(url)) {
          return pattern;
        }
      } catch {
        // Invalid regex, skip
      }
    }
    return null;
  }

  private shouldIgnoreError(message: string): boolean {
    const patterns = this.options.ignoreErrorPatterns || [];
    return patterns.some((pattern) => {
      try {
        return new RegExp(pattern, "i").test(message);
      } catch {
        return false;
      }
    });
  }

  private isExternalUrl(url: string): boolean {
    try {
      const urlOrigin = new URL(url).origin;
      return urlOrigin !== this.baseOrigin;
    } catch {
      return false;
    }
  }

  private async setupNavigationBlocking(page: Page): Promise<void> {
    // Block navigation to external domains
    await page.route("**/*", async (route: Route) => {
      const request = route.request();
      const url = request.url();

      // Allow same-origin requests
      if (!this.isExternalUrl(url)) {
        await route.continue();
        return;
      }

      // Block navigation requests to external domains
      if (request.isNavigationRequest()) {
        this.blockedExternalCount++;
        this.events.onBlockedNavigation?.(url);
        this.logger.logBlockedNavigation(url);
        await route.abort("blockedbyclient");
        return;
      }

      // Allow non-navigation external requests (images, scripts, etc.)
      await route.continue();
    });
  }

  private async crawlPage(entry: QueueEntry): Promise<PageResult> {
    const page = await this.context!.newPage();
    const { url, sourceUrl, method, sourceElement } = entry;

    if (this.options.blockExternalNavigation) {
      await this.setupNavigationBlocking(page);
    }

    try {
      const result = await this.crawlPageWithExistingPage(page, url);

      // Add source tracking to result
      result.discoveryMethod = method;
      result.sourceUrl = sourceUrl;
      result.sourceElement = sourceElement;

      // Handle recovery from 404 or error status
      if (
        this.options.enableRecovery &&
        result.statusCode &&
        (result.statusCode === 404 || result.statusCode >= 500)
      ) {
        // Track dead link with source information
        this.discoveryMetrics.deadLinks.push({
          url,
          statusCode: result.statusCode,
          sourceUrl,
          sourceElement,
          method,
        });

        const recovery = this.createRecoveryInfo(
          url,
          `HTTP ${result.statusCode}`
        );
        this.logger.logRecovery(recovery);
        this.logger.logNavigationError(url, result.statusCode, `HTTP ${result.statusCode}`);
        this.recoveryCount++;

        // Try to recover by going back to last successful URL
        if (this.lastSuccessfulUrl && this.lastSuccessfulUrl !== url) {
          try {
            await page.goto(this.lastSuccessfulUrl, {
              timeout: this.options.timeout,
              waitUntil: "networkidle",
            });
            this.logger.info("recovery_success", { recoveredTo: this.lastSuccessfulUrl });
          } catch {
            // Recovery navigation failed, just continue
            this.logger.warn("recovery_failed", { url: this.lastSuccessfulUrl });
          }
        }

        // Mark result as recovered
        result.recovery = recovery;
        result.status = "recovered";
      } else if (result.status === "success" && result.statusCode === 200) {
        // Update last successful URL
        this.lastSuccessfulUrl = url;
      }

      return result;
    } finally {
      await page.close();
    }
  }

  private async crawlPageWithExistingPage(page: Page, url: string): Promise<PageResult> {
    const errors: PageError[] = [];
    const warnings: string[] = [];
    const blockedNavigations: string[] = [];
    const startTime = Date.now();

    this.events.onPageStart?.(url);
    this.logger.logPageStart(url);

    // Set up error listeners
    page.on("console", (msg) => {
      const type = msg.type();
      const text = msg.text();
      if (type === "error") {
        if (this.shouldIgnoreError(text)) return;
        const error: PageError = {
          type: "console",
          message: text,
          url,
          timestamp: Date.now(),
        };
        errors.push(error);
        this.events.onError?.(error);
        this.logger.logPageError(error);
      } else if (type === "warning") {
        warnings.push(text);
      }
    });

    // Capture unhandled exceptions
    page.on("pageerror", (err) => {
      if (this.shouldIgnoreError(err.message)) return;
      const error: PageError = {
        type: "exception",
        message: err.message,
        stack: err.stack,
        url,
        timestamp: Date.now(),
      };
      errors.push(error);
      this.events.onError?.(error);
      this.logger.logPageError(error);
    });

    // Capture unhandled promise rejections
    page.addInitScript(() => {
      window.addEventListener("unhandledrejection", (event) => {
        const message = event.reason?.message || String(event.reason);
        const stack = event.reason?.stack;
        // @ts-ignore - custom event for playwright
        window.__chaosUnhandledRejection = { message, stack };
      });
    });

    page.on("requestfailed", (request) => {
      const requestUrl = request.url();
      if (this.shouldIgnoreError(requestUrl)) return;

      // Check if this is a SPA-related error
      const spaPattern = this.matchesSpaPattern(requestUrl);
      if (spaPattern) {
        this.discoveryMetrics.spaIssues.push({
          url: requestUrl,
          type: "routing-404",
          message: request.failure()?.errorText || "SPA routing issue",
          matchedPattern: spaPattern,
        });
        this.logger.debug("spa_issue", { url: requestUrl, pattern: spaPattern });
        return; // Don't count as regular error
      }

      const failure = request.failure();
      const error: PageError = {
        type: "network",
        message: `${requestUrl} - ${failure?.errorText || "Unknown error"}`,
        url,
        timestamp: Date.now(),
      };
      errors.push(error);
      this.events.onError?.(error);
      this.logger.logPageError(error);
    });

    // Track blocked external navigations
    const originalBlockedCount = this.blockedExternalCount;

    let result: PageResult;

    try {
      const response = await page.goto(url, {
        timeout: this.options.timeout,
        waitUntil: "networkidle",
      });

      // Check for unhandled rejections
      const unhandledRejection = await page.evaluate(() => {
        // @ts-ignore
        const rejection = window.__chaosUnhandledRejection;
        // @ts-ignore
        window.__chaosUnhandledRejection = null;
        return rejection;
      });

      if (unhandledRejection) {
        const error: PageError = {
          type: "unhandled-rejection",
          message: unhandledRejection.message,
          stack: unhandledRejection.stack,
          url,
          timestamp: Date.now(),
        };
        errors.push(error);
        this.events.onError?.(error);
      }

      const loadTime = Date.now() - startTime;
      const metrics = await this.collectMetrics(page);
      const links = await this.extractLinks(page);

      // Perform random actions with accessibility-based weighting
      await this.performWeightedActions(page, url);

      // Check for any rejections after actions
      const postActionRejection = await page.evaluate(() => {
        // @ts-ignore
        const rejection = window.__chaosUnhandledRejection;
        // @ts-ignore
        window.__chaosUnhandledRejection = null;
        return rejection;
      });

      if (postActionRejection) {
        const error: PageError = {
          type: "unhandled-rejection",
          message: postActionRejection.message,
          stack: postActionRejection.stack,
          url,
          timestamp: Date.now(),
        };
        errors.push(error);
        this.events.onError?.(error);
      }

      let screenshot: string | undefined;
      if (this.options.screenshots) {
        const filename = this.getScreenshotFilename(url);
        await page.screenshot({ path: filename, fullPage: true });
        screenshot = filename;
      }

      result = {
        url,
        status: "success",
        statusCode: response?.status(),
        loadTime,
        errors,
        warnings,
        metrics,
        links,
        screenshot,
        blockedNavigations:
          this.blockedExternalCount > originalBlockedCount ? blockedNavigations : undefined,
      };
    } catch (err) {
      const loadTime = Date.now() - startTime;
      const isTimeout = err instanceof Error && err.message.includes("Timeout");

      result = {
        url,
        status: isTimeout ? "timeout" : "error",
        loadTime,
        errors: [
          ...errors,
          {
            type: "exception",
            message: err instanceof Error ? err.message : String(err),
            stack: err instanceof Error ? err.stack : undefined,
            url,
            timestamp: Date.now(),
          },
        ],
        warnings,
        links: [],
      };
    }

    this.events.onPageComplete?.(result);
    this.logger.logPageComplete(result);
    return result;
  }

  private async collectMetrics(page: Page): Promise<PerformanceMetrics> {
    try {
      const metrics = await page.evaluate(() => {
        const perf = performance;
        const navigation = perf.getEntriesByType("navigation")[0] as PerformanceNavigationTiming;
        const paint = perf.getEntriesByType("paint");

        const fcp = paint.find((e) => e.name === "first-contentful-paint");

        return {
          ttfb: navigation?.responseStart - navigation?.requestStart,
          domContentLoaded: navigation?.domContentLoadedEventEnd - navigation?.startTime,
          load: navigation?.loadEventEnd - navigation?.startTime,
          fcp: fcp?.startTime,
        };
      });

      return metrics;
    } catch {
      return {};
    }
  }

  private async extractLinks(page: Page): Promise<string[]> {
    try {
      const links = await page.evaluate(() => {
        return Array.from(document.querySelectorAll("a[href]"))
          .map((a) => (a as HTMLAnchorElement).href)
          .filter((href) => href && !href.startsWith("javascript:") && !href.startsWith("mailto:"));
      });

      // Filter to same-origin links only
      return links.filter((link) => !this.isExternalUrl(link));
    } catch {
      return [];
    }
  }

  /**
   * Get action targets from DOM with accessibility-based weighting
   */
  private async getWeightedActionTargets(page: Page): Promise<ActionTarget[]> {
    const targets: ActionTarget[] = [];

    try {
      // Collect interactive elements from DOM with ARIA info
      const domTargets = await page.evaluate(() => {
        const results: Array<{
          tag: string;
          text: string;
          role: string | null;
          ariaLabel: string | null;
          index: number;
          hasVisibleText: boolean;
          isNavLink: boolean;
          href?: string;
          isInMainContent: boolean;
        }> = [];

        // Links with priority for navigation
        document.querySelectorAll("a[href]").forEach((el, i) => {
          const anchor = el as HTMLAnchorElement;
          const text = anchor.innerText?.trim() || "";
          const ariaLabel = anchor.getAttribute("aria-label");
          const role = anchor.getAttribute("role");
          // Navigation links are in nav, header, or have specific roles
          const isNavLink = !!anchor.closest("nav, header, [role='navigation']");
          // Check if link is in main content area
          const isInMainContent = !!anchor.closest("main, article, [role='main'], .content, #content");

          if (text.length < 100 || ariaLabel) {
            results.push({
              tag: "a",
              text: text || ariaLabel || "",
              role,
              ariaLabel,
              index: i,
              hasVisibleText: text.length > 0,
              isNavLink,
              href: anchor.href,
              isInMainContent,
            });
          }
        });

        // Buttons
        document.querySelectorAll("button, [role='button']").forEach((el, i) => {
          const text = (el as HTMLElement).innerText?.trim() || "";
          const ariaLabel = el.getAttribute("aria-label");
          const role = el.getAttribute("role") || "button";
          const isInMainContent = !!el.closest("main, article, [role='main'], .content, #content");

          if (text.length < 100 || ariaLabel) {
            results.push({
              tag: "button",
              text: text || ariaLabel || "",
              role,
              ariaLabel,
              index: i,
              hasVisibleText: text.length > 0,
              isNavLink: false,
              isInMainContent,
            });
          }
        });

        // Interactive ARIA roles
        const ariaSelectors = [
          "[role='menuitem']",
          "[role='tab']",
          "[role='checkbox']",
          "[role='radio']",
          "[role='switch']",
          "[role='slider']",
          "[role='listbox']",
          "[role='option']",
        ];

        document.querySelectorAll(ariaSelectors.join(", ")).forEach((el, i) => {
          const text = (el as HTMLElement).innerText?.trim() || "";
          const ariaLabel = el.getAttribute("aria-label");
          const role = el.getAttribute("role")!;
          const isInMainContent = !!el.closest("main, article, [role='main'], .content, #content");

          results.push({
            tag: el.tagName.toLowerCase(),
            text: text || ariaLabel || "",
            role,
            ariaLabel,
            index: i,
            hasVisibleText: text.length > 0,
            isNavLink: false,
            isInMainContent,
          });
        });

        // Input fields
        document.querySelectorAll("input, textarea, [role='textbox'], [role='searchbox']").forEach((el, i) => {
          const ariaLabel = el.getAttribute("aria-label");
          const placeholder = el.getAttribute("placeholder");
          const role = el.getAttribute("role") || "input";
          const isInMainContent = !!el.closest("main, article, [role='main'], .content, #content");

          results.push({
            tag: "input",
            text: ariaLabel || placeholder || "",
            role,
            ariaLabel,
            index: i,
            hasVisibleText: false,
            isNavLink: false,
            isInMainContent,
          });
        });

        return results.slice(0, 50); // Limit to prevent too many targets
      });

      // Convert to weighted targets
      for (const t of domTargets) {
        let weight = 1;
        let type: ActionTarget["type"] = "interactive";

        if (t.tag === "a") {
          type = "link";
          weight = this.actionWeights.navigationLinks;
          if (t.isNavLink) weight *= 1.5; // Boost navigation links

          // Boost unvisited links significantly
          if (t.href) {
            try {
              const absoluteUrl = new URL(t.href, this.baseOrigin).toString();
              const isQueued = this.queue.some(e => e.url === absoluteUrl);
              if (!this.visited.has(absoluteUrl) && !isQueued) {
                weight *= 3; // Strong boost for unvisited links
              } else if (this.visited.has(absoluteUrl)) {
                weight *= 0.2; // Reduce weight for already visited
              }
            } catch {
              // Invalid URL, keep default weight
            }
          }
        } else if (t.tag === "button" || t.role === "button") {
          type = "button";
          weight = this.actionWeights.buttons;
        } else if (t.tag === "input" || t.role === "textbox" || t.role === "searchbox") {
          type = "input";
          weight = this.actionWeights.inputs;
        } else if (t.role) {
          type = "interactive";
          weight = this.actionWeights.ariaInteractive;
        }

        // Boost elements with visible text
        if (t.hasVisibleText) {
          weight *= this.actionWeights.visibleText;
        }

        // Boost elements in main content area
        if (t.isInMainContent) {
          weight *= 1.5;
        }

        // Build selector
        let selector: string;
        if (t.text && t.text.length > 0 && t.text.length < 50) {
          selector = `${t.tag}:has-text("${this.escapeSelector(t.text)}")`;
        } else if (t.ariaLabel) {
          selector = `${t.tag}[aria-label="${this.escapeSelector(t.ariaLabel)}"]`;
        } else if (t.role) {
          selector = `[role="${t.role}"]:nth-of-type(${t.index + 1})`;
        } else {
          selector = `${t.tag}:nth-of-type(${t.index + 1})`;
        }

        targets.push({
          selector,
          role: t.role || undefined,
          name: t.text || t.ariaLabel || undefined,
          weight,
          type,
          href: t.href,
        });
      }

      // Add scroll as low-weight option
      targets.push({
        selector: "window",
        weight: this.actionWeights.scroll,
        type: "scroll",
      });
    } catch {
      // Fallback to basic scroll
      targets.push({
        selector: "window",
        weight: 1,
        type: "scroll",
      });
    }

    return targets;
  }

  private escapeSelector(text: string): string {
    return text.replace(/"/g, '\\"').replace(/\n/g, " ").slice(0, 50);
  }

  /**
   * Perform actions based on weighted random selection
   */
  private async performWeightedActions(page: Page, url: string): Promise<void> {
    const targets = await this.getWeightedActionTargets(page);
    this.logger.debug("action_targets", { count: targets.length, url });
    if (targets.length === 0) return;

    // Calculate total weight
    const totalWeight = targets.reduce((sum, t) => sum + t.weight, 0);

    let actionsPerformed = 0;
    let attempts = 0;
    const maxAttempts = this.options.maxActionsPerPage * 3; // Allow retries for skipped elements
    this.logger.debug("action_loop_start", { maxActionsPerPage: this.options.maxActionsPerPage, maxAttempts });

    while (actionsPerformed < this.options.maxActionsPerPage && attempts < maxAttempts) {
      attempts++;

      // Weighted random selection
      let random = Math.random() * totalWeight;
      let selectedTarget: ActionTarget | null = null;

      for (const target of targets) {
        random -= target.weight;
        if (random <= 0) {
          selectedTarget = target;
          break;
        }
      }

      if (!selectedTarget) {
        selectedTarget = targets[targets.length - 1];
      }

      const result = await this.performActionOnTarget(page, selectedTarget, url);

      // Skip null results (element not visible)
      if (result === null) {
        this.logger.debug("action_skipped", { target: selectedTarget.name || selectedTarget.selector, reason: "not visible" });
        continue;
      }

      actionsPerformed++;
      this.actions.push(result);
      this.addToHistory(result);  // Add to recovery history
      this.events.onAction?.(result);
      this.logger.logAction(result);

      // Small delay between actions
      await page.waitForTimeout(100);
    }
  }

  private async performActionOnTarget(
    page: Page,
    target: ActionTarget,
    url: string
  ): Promise<ActionResult | null> {
    const timestamp = Date.now();

    try {
      if (target.type === "scroll") {
        const scrollY = Math.floor(Math.random() * 1000);
        await page.evaluate((y) => window.scrollTo(0, y), scrollY);
        return {
          type: "scroll",
          target: `scrollY: ${scrollY}`,
          success: true,
          timestamp,
        };
      }

      const element = page.locator(target.selector).first();
      const isVisible = await element.isVisible().catch(() => false);

      // Skip non-visible elements instead of falling back to hover
      if (!isVisible) {
        return null;
      }

      if (target.type === "input") {
        await element.fill("test input", { timeout: 1000 });
        return {
          type: "input",
          target: target.name || target.selector,
          selector: target.selector,
          success: true,
          timestamp,
        };
      }

      // For links, check if it's external before clicking
      if (target.type === "link") {
        const href = target.href || await element.getAttribute("href").catch(() => null);
        if (href && this.isExternalUrl(href)) {
          return {
            type: "click",
            target: target.name || target.selector,
            selector: target.selector,
            success: true,
            blockedExternal: true,
            timestamp,
          };
        }

        // Track link clicks that navigate (only if not already tracked)
        if (href && !href.startsWith("#") && !href.startsWith("javascript:")) {
          try {
            const absoluteUrl = new URL(href, url).toString();
            const alreadyQueued = this.queue.some(e => e.url === absoluteUrl);
            if (!this.visited.has(absoluteUrl) && !alreadyQueued) {
              this.queue.push({
                url: absoluteUrl,
                sourceUrl: url,
                method: "clicked",
                sourceElement: target.name || target.selector,
              });
              this.discoveryMetrics.clickedLinks++;
              this.logger.debug("link_discovered_by_click", { href: absoluteUrl, source: url });
            }
          } catch {
            // Invalid URL, skip
          }
        }
      }

      await element.click({ timeout: 1000 });

      // Wait for any navigation to settle
      await page.waitForLoadState("networkidle", { timeout: 2000 }).catch(() => {});

      return {
        type: "click",
        target: target.name || target.selector,
        selector: target.selector,
        success: true,
        timestamp,
      };
    } catch (err) {
      return {
        type: "click",
        target: target.name || target.selector,
        selector: target.selector,
        success: false,
        error: err instanceof Error ? err.message : String(err),
        timestamp,
      };
    }
  }

  private getScreenshotFilename(url: string): string {
    const urlObj = new URL(url);
    const pathname = urlObj.pathname.replace(/\//g, "_").replace(/^_/, "") || "index";
    return join(this.options.screenshotDir, `${pathname}.png`);
  }

  private generateReport(endTime: number): CrawlReport {
    const summary = this.calculateSummary();

    return {
      baseUrl: this.options.baseUrl,
      startTime: this.startTime,
      endTime,
      duration: endTime - this.startTime,
      pagesVisited: this.results.length,
      totalErrors: this.results.reduce((sum, r) => sum + r.errors.length, 0),
      totalWarnings: this.results.reduce((sum, r) => sum + r.warnings.length, 0),
      blockedExternalNavigations: this.blockedExternalCount,
      recoveryCount: this.recoveryCount,
      pages: this.results,
      actions: this.actions,
      summary,
    };
  }

  private calculateSummary(): CrawlSummary {
    const successPages = this.results.filter((r) => r.status === "success").length;
    const errorPages = this.results.filter((r) => r.status === "error").length;
    const timeoutPages = this.results.filter((r) => r.status === "timeout").length;
    const recoveredPages = this.results.filter((r) => r.status === "recovered").length;

    const allErrors = this.results.flatMap((r) => r.errors);
    const consoleErrors = allErrors.filter((e) => e.type === "console").length;
    const networkErrors = allErrors.filter((e) => e.type === "network").length;
    const jsExceptions = allErrors.filter((e) => e.type === "exception").length;
    const unhandledRejections = allErrors.filter((e) => e.type === "unhandled-rejection").length;

    const loadTimes = this.results.map((r) => r.loadTime);
    const avgLoadTime = loadTimes.length > 0 ? loadTimes.reduce((a, b) => a + b, 0) / loadTimes.length : 0;

    // Calculate average metrics
    const metricsResults = this.results.filter((r) => r.metrics);
    let avgMetrics: CrawlSummary["avgMetrics"] = undefined;

    if (metricsResults.length > 0) {
      const ttfbs = metricsResults.map((r) => r.metrics!.ttfb).filter((v): v is number => v !== undefined);
      const fcps = metricsResults.map((r) => r.metrics!.fcp).filter((v): v is number => v !== undefined);
      const lcps = metricsResults.map((r) => r.metrics!.lcp).filter((v): v is number => v !== undefined);

      if (ttfbs.length > 0 || fcps.length > 0 || lcps.length > 0) {
        avgMetrics = {
          ttfb: ttfbs.length > 0 ? ttfbs.reduce((a, b) => a + b, 0) / ttfbs.length : 0,
          fcp: fcps.length > 0 ? fcps.reduce((a, b) => a + b, 0) / fcps.length : 0,
          lcp: lcps.length > 0 ? lcps.reduce((a, b) => a + b, 0) / lcps.length : 0,
        };
      }
    }

    return {
      successPages,
      errorPages,
      timeoutPages,
      recoveredPages,
      consoleErrors,
      networkErrors,
      jsExceptions,
      unhandledRejections,
      avgLoadTime,
      avgMetrics,
      discovery: this.discoveryMetrics,
    };
  }
}
