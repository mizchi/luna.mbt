/**
 * Core types for Chaos Crawler
 */

export interface CrawlerOptions {
  /** Base URL to start crawling */
  baseUrl: string;
  /** Maximum number of pages to visit */
  maxPages?: number;
  /** Maximum random actions per page */
  maxActionsPerPage?: number;
  /** Page load timeout in ms */
  timeout?: number;
  /** Run browser in headless mode */
  headless?: boolean;
  /** Take screenshots of visited pages */
  screenshots?: boolean;
  /** Directory to save screenshots */
  screenshotDir?: string;
  /** URL patterns to exclude (regex strings) */
  excludePatterns?: string[];
  /** Error message patterns to ignore (regex strings) */
  ignoreErrorPatterns?: string[];
  /** URL patterns to treat as SPA (regex strings) - errors from these are categorized separately */
  spaPatterns?: string[];
  /** Viewport size */
  viewport?: { width: number; height: number };
  /** Custom user agent */
  userAgent?: string;
  /** Block navigation to external domains */
  blockExternalNavigation?: boolean;
  /** Action weighting configuration */
  actionWeights?: ActionWeights;
  /** Log file path (enables file logging) */
  logFile?: string;
  /** Log level */
  logLevel?: "debug" | "info" | "warn" | "error";
  /** Also log to console */
  logToConsole?: boolean;
  /** Enable recovery from 404/dead links */
  enableRecovery?: boolean;
  /** Number of recent operations to keep for recovery dump */
  recoveryHistorySize?: number;
}

export interface ActionWeights {
  /** Weight for navigation links (default: 3) */
  navigationLinks?: number;
  /** Weight for buttons (default: 2) */
  buttons?: number;
  /** Weight for form inputs (default: 1) */
  inputs?: number;
  /** Weight for interactive elements with aria roles (default: 2) */
  ariaInteractive?: number;
  /** Weight for elements with visible text (default: 1.5) */
  visibleText?: number;
  /** Weight for scroll actions (default: 0.5) */
  scroll?: number;
}

export interface PageError {
  type: "console" | "network" | "exception" | "crash" | "unhandled-rejection";
  message: string;
  url?: string;
  stack?: string;
  timestamp: number;
}

export interface PerformanceMetrics {
  /** Time to first byte */
  ttfb?: number;
  /** First contentful paint */
  fcp?: number;
  /** Largest contentful paint */
  lcp?: number;
  /** Total blocking time approximation */
  tbt?: number;
  /** DOM content loaded */
  domContentLoaded?: number;
  /** Full page load */
  load?: number;
}

export interface PageResult {
  url: string;
  status: "success" | "error" | "timeout" | "recovered";
  statusCode?: number;
  loadTime: number;
  errors: PageError[];
  warnings: string[];
  metrics?: PerformanceMetrics;
  links: string[];
  screenshot?: string;
  blockedNavigations?: string[];
  /** Recovery info if page was recovered from error */
  recovery?: RecoveryInfo;
  /** How this page was discovered */
  discoveryMethod?: DiscoveryMethod;
  /** URL of the page that linked to this page */
  sourceUrl?: string;
  /** Element that linked to this page */
  sourceElement?: string;
}

export interface RecoveryInfo {
  /** URL that caused the error */
  failedUrl: string;
  /** Error that triggered recovery */
  error: string;
  /** URL recovered to */
  recoveredTo: string;
  /** Recent actions before failure */
  recentActions: ActionResult[];
  /** Timestamp of recovery */
  timestamp: number;
}

export interface ActionTarget {
  selector: string;
  role?: string;
  name?: string;
  weight: number;
  type: "link" | "button" | "input" | "interactive" | "scroll";
  /** For links, the href attribute */
  href?: string;
}

export interface ActionResult {
  type: "click" | "scroll" | "hover" | "navigate" | "input";
  target?: string;
  selector?: string;
  success: boolean;
  error?: string;
  blockedExternal?: boolean;
  timestamp: number;
}

export interface CrawlReport {
  baseUrl: string;
  startTime: number;
  endTime: number;
  duration: number;
  pagesVisited: number;
  totalErrors: number;
  totalWarnings: number;
  blockedExternalNavigations: number;
  recoveryCount: number;
  pages: PageResult[];
  actions: ActionResult[];
  summary: CrawlSummary;
}

export interface CrawlSummary {
  successPages: number;
  errorPages: number;
  timeoutPages: number;
  recoveredPages: number;
  consoleErrors: number;
  networkErrors: number;
  jsExceptions: number;
  unhandledRejections: number;
  avgLoadTime: number;
  avgMetrics?: {
    ttfb: number;
    fcp: number;
    lcp: number;
  };
  /** Discovery metrics - how links were found */
  discovery?: DiscoveryMetrics;
}

/** How a URL was discovered */
export type DiscoveryMethod = "initial" | "extracted" | "clicked" | "navigated";

/** Entry in the crawl queue with source tracking */
export interface QueueEntry {
  url: string;
  /** URL of the page where this link was found */
  sourceUrl: string;
  /** How this link was discovered */
  method: DiscoveryMethod;
  /** Element text/selector that contained the link */
  sourceElement?: string;
}

/** Metrics about how links were discovered */
export interface DiscoveryMetrics {
  /** Links found via extraction (parsing HTML) */
  extractedLinks: number;
  /** Links discovered via click actions */
  clickedLinks: number;
  /** Unique pages reached */
  uniquePages: number;
  /** Dead links found with their sources */
  deadLinks: DeadLinkInfo[];
  /** SPA-related issues (expected errors from client-side routing) */
  spaIssues: SpaIssueInfo[];
}

/** Information about a SPA-related issue */
export interface SpaIssueInfo {
  /** The URL that had the issue */
  url: string;
  /** Type of issue */
  type: "routing-404" | "internal-error" | "hydration-error";
  /** Error message */
  message: string;
  /** Pattern that matched as SPA */
  matchedPattern: string;
}

/** Information about a dead link */
export interface DeadLinkInfo {
  /** The broken URL */
  url: string;
  /** HTTP status code */
  statusCode: number;
  /** Where the link was found */
  sourceUrl: string;
  /** Element that contained the link */
  sourceElement?: string;
  /** How it was discovered */
  method: DiscoveryMethod;
}

export interface CrawlerEvents {
  onPageStart?: (url: string) => void;
  onPageComplete?: (result: PageResult) => void;
  onError?: (error: PageError) => void;
  onAction?: (action: ActionResult) => void;
  onProgress?: (visited: number, total: number) => void;
  onBlockedNavigation?: (url: string) => void;
}

/** Configuration for Playwright Test integration */
export interface ChaosTestOptions {
  /** Base URL (uses baseURL from Playwright config if not set) */
  baseUrl?: string;
  /** Maximum pages to visit per test */
  maxPages?: number;
  /** Maximum actions per page */
  maxActionsPerPage?: number;
  /** Patterns to ignore */
  ignoreErrorPatterns?: string[];
  /** Block external navigation */
  blockExternalNavigation?: boolean;
  /** Fail test on any error */
  strict?: boolean;
  /** Action weights */
  actionWeights?: ActionWeights;
}
