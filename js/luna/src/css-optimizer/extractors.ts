/**
 * CSS Co-occurrence Optimizer - Extractors
 *
 * Pluggable class extraction strategies for different source formats.
 * Each extractor takes source content and returns ClassUsage arrays.
 */

import type { ClassUsage } from "./types.js";

/**
 * Extractor interface - implement this for custom source formats
 */
export interface ClassExtractor {
  /** Extractor name for debugging */
  name: string;

  /**
   * Extract class usages from source content
   * @param content - Source content (HTML, JSX, etc.)
   * @param options - Extractor-specific options
   */
  extract(content: string, options?: ExtractorOptions): ClassUsage[];
}

/**
 * Common extractor options
 */
export interface ExtractorOptions {
  /** Only extract classes starting with this prefix (default: "_") */
  classPrefix?: string;
  /** Minimum classes per element to include (default: 2) */
  minClasses?: number;
  /** Source identifier for debugging */
  source?: string;
}

/**
 * HTML Class Extractor
 *
 * Extracts class usages from HTML content by parsing class="" attributes.
 * Works with static HTML, SSR output, template strings, etc.
 */
export class HtmlExtractor implements ClassExtractor {
  name = "html";

  private pattern = /class\s*=\s*"([^"]+)"/g;

  extract(content: string, options: ExtractorOptions = {}): ClassUsage[] {
    const { classPrefix = "_", minClasses = 2, source = "html" } = options;

    const usages: ClassUsage[] = [];
    let match: RegExpExecArray | null;

    this.pattern.lastIndex = 0;
    while ((match = this.pattern.exec(content)) !== null) {
      const classValue = match[1].trim();
      if (!classValue) continue;

      // Split by whitespace and filter by prefix
      const classes = classValue
        .split(/\s+/)
        .filter((c) => c.startsWith(classPrefix) && c.length > classPrefix.length);

      // Only include elements with minClasses or more matching classes
      if (classes.length >= minClasses) {
        classes.sort();
        usages.push({ classes, source: `${source}:${match.index}` });
      }
    }

    return usages;
  }
}

/**
 * JSX Class Extractor (simplified)
 *
 * Extracts class usages from JSX/TSX by finding className attributes.
 * Note: This is a simplified regex-based extractor. For full AST support,
 * consider using @babel/parser or TypeScript compiler.
 */
export class JsxExtractor implements ClassExtractor {
  name = "jsx";

  // Match className="..." and className={'...'}
  private stringPattern = /className\s*=\s*"([^"]+)"/g;
  private templatePattern = /className\s*=\s*\{['"`]([^'"`]+)['"`]\}/g;

  extract(content: string, options: ExtractorOptions = {}): ClassUsage[] {
    const { classPrefix = "_", minClasses = 2, source = "jsx" } = options;

    const usages: ClassUsage[] = [];

    // Extract from string literals
    this.extractFromPattern(content, this.stringPattern, classPrefix, minClasses, source, usages);
    // Extract from template literals
    this.extractFromPattern(content, this.templatePattern, classPrefix, minClasses, source, usages);

    return usages;
  }

  private extractFromPattern(
    content: string,
    pattern: RegExp,
    classPrefix: string,
    minClasses: number,
    source: string,
    usages: ClassUsage[]
  ): void {
    let match: RegExpExecArray | null;

    pattern.lastIndex = 0;
    while ((match = pattern.exec(content)) !== null) {
      const classValue = match[1].trim();
      if (!classValue) continue;

      const classes = classValue
        .split(/\s+/)
        .filter((c) => c.startsWith(classPrefix) && c.length > classPrefix.length);

      if (classes.length >= minClasses) {
        classes.sort();
        usages.push({ classes, source: `${source}:${match.index}` });
      }
    }
  }
}

/**
 * Svelte Class Extractor (simplified)
 *
 * Extracts class usages from Svelte templates.
 * Handles both class="..." and class:directive syntax.
 */
export class SvelteExtractor implements ClassExtractor {
  name = "svelte";

  private classPattern = /class\s*=\s*"([^"]+)"/g;

  extract(content: string, options: ExtractorOptions = {}): ClassUsage[] {
    const { classPrefix = "_", minClasses = 2, source = "svelte" } = options;

    const usages: ClassUsage[] = [];
    let match: RegExpExecArray | null;

    this.classPattern.lastIndex = 0;
    while ((match = this.classPattern.exec(content)) !== null) {
      const classValue = match[1].trim();
      if (!classValue) continue;

      // Handle Svelte's {expression} syntax by removing them
      const cleanValue = classValue.replace(/\{[^}]+\}/g, " ");

      const classes = cleanValue
        .split(/\s+/)
        .filter((c) => c.startsWith(classPrefix) && c.length > classPrefix.length);

      if (classes.length >= minClasses) {
        classes.sort();
        usages.push({ classes, source: `${source}:${match.index}` });
      }
    }

    return usages;
  }
}

/**
 * Multi-source extractor
 *
 * Combines usages from multiple sources/extractors.
 * Useful for analyzing entire projects with mixed file types.
 */
export class MultiExtractor implements ClassExtractor {
  name = "multi";

  private extractors: Map<string, ClassExtractor>;

  constructor() {
    this.extractors = new Map([
      ["html", new HtmlExtractor()],
      ["jsx", new JsxExtractor()],
      ["tsx", new JsxExtractor()],
      ["svelte", new SvelteExtractor()],
    ]);
  }

  /**
   * Register a custom extractor for a file extension
   */
  register(extension: string, extractor: ClassExtractor): void {
    this.extractors.set(extension, extractor);
  }

  /**
   * Extract from content using the appropriate extractor
   */
  extract(content: string, options: ExtractorOptions = {}): ClassUsage[] {
    // Default to HTML extractor
    const htmlExtractor = this.extractors.get("html")!;
    return htmlExtractor.extract(content, options);
  }

  /**
   * Extract from content with explicit file type
   */
  extractWithType(
    content: string,
    fileType: string,
    options: ExtractorOptions = {}
  ): ClassUsage[] {
    const extractor = this.extractors.get(fileType) || this.extractors.get("html")!;
    return extractor.extract(content, options);
  }

  /**
   * Extract from multiple files
   */
  extractFromFiles(
    files: Array<{ content: string; path: string }>,
    options: ExtractorOptions = {}
  ): ClassUsage[] {
    const allUsages: ClassUsage[] = [];

    for (const file of files) {
      const ext = file.path.split(".").pop() || "html";
      const extractor = this.extractors.get(ext) || this.extractors.get("html")!;
      const usages = extractor.extract(file.content, {
        ...options,
        source: file.path,
      });
      allUsages.push(...usages);
    }

    return allUsages;
  }
}

// Default extractors
export const htmlExtractor = new HtmlExtractor();
export const jsxExtractor = new JsxExtractor();
export const svelteExtractor = new SvelteExtractor();
export const multiExtractor = new MultiExtractor();
