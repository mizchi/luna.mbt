/**
 * CSS class merging utilities
 *
 * This module provides Luna-specific convenience wrappers around the
 * framework-agnostic core optimizer.
 */

import type { ClassUsage, OptimizeResult, OptimizeOptions } from "./types.js";
import { optimizeCore } from "./core.js";
import { htmlExtractor } from "./extractors.js";
import { htmlTransformer } from "./transformers.js";

/**
 * Framework-agnostic optimize function
 *
 * This is the recommended API for non-Luna projects.
 * It takes pre-extracted class usages and a class-to-declaration map.
 *
 * @param usages - Class usages extracted from your source files
 * @param css - Original CSS content
 * @param classToDeclaration - Map from class name to CSS declaration
 * @param options - Optimization options
 */
export function optimize(
  usages: ClassUsage[],
  css: string,
  classToDeclaration: Map<string, string>,
  options: OptimizeOptions = {}
): OptimizeResult {
  return optimizeCore(usages, css, classToDeclaration, options);
}

/**
 * Optimize CSS by merging co-occurring classes (Luna convenience wrapper)
 *
 * This is a convenience function that:
 * 1. Extracts class usages from HTML using HtmlExtractor
 * 2. Converts Luna's declaration mapping format
 * 3. Calls the core optimizer
 *
 * For non-Luna projects, use the `optimize` function instead.
 *
 * @param css - Original CSS content
 * @param html - HTML content to analyze
 * @param declarationMapping - Luna's declaration -> class name mapping
 * @param options - Optimization options
 */
export function optimizeCss(
  css: string,
  html: string,
  declarationMapping: Record<string, string>,
  options: OptimizeOptions = {}
): OptimizeResult {
  const { classPrefix = "_", verbose = false } = options;

  const log = (msg: string) => {
    if (verbose) {
      console.log(`[optimizer] ${msg}`);
    }
  };

  // Step 1: Extract class usages using the HTML extractor
  const usages = htmlExtractor.extract(html, {
    classPrefix,
    source: "html",
  });

  log(`Found ${usages.length} class usage sites`);

  if (usages.length === 0) {
    return {
      css,
      mergeMap: new Map(),
      patterns: [],
      stats: {
        originalClasses: Object.keys(declarationMapping).length,
        mergedPatterns: 0,
        estimatedBytesSaved: 0,
      },
    };
  }

  // Step 2: Build class -> declaration map (reverse of Luna's mapping)
  const classToDecl = new Map<string, string>();
  for (const [decl, cls] of Object.entries(declarationMapping)) {
    classToDecl.set(cls, decl);
  }

  // Step 3: Call core optimizer
  return optimizeCore(usages, css, classToDecl, options);
}

/**
 * Apply optimization to HTML by replacing class combinations (Luna convenience wrapper)
 *
 * This is a convenience function that uses HtmlTransformer.
 * For non-Luna projects, use the transformer directly.
 *
 * @param html - HTML content to transform
 * @param mergeMap - Merge map from optimizeCss result
 * @param classPrefix - Class prefix (default: "_")
 */
export function optimizeHtml(
  html: string,
  mergeMap: Map<string, string>,
  classPrefix = "_"
): string {
  return htmlTransformer.transform(html, mergeMap, { classPrefix });
}
