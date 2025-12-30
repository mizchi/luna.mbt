/**
 * CSS Co-occurrence Optimizer
 *
 * A standalone, framework-agnostic library for optimizing CSS by merging
 * frequently co-occurring classes. Works with HTML, React, Svelte, and more.
 *
 * ## Architecture
 *
 * - **Core**: Pure functions for pattern analysis (no framework dependency)
 * - **Extractors**: Pluggable class extraction (HTML, JSX, Svelte, etc.)
 * - **Transformers**: Pluggable output transformation
 *
 * ## Quick Start (Framework-agnostic)
 *
 * ```typescript
 * import {
 *   optimizeCore,
 *   htmlExtractor,
 *   htmlTransformer
 * } from "@luna_ui/luna/css-optimizer";
 *
 * // 1. Extract class usages
 * const usages = htmlExtractor.extract(html);
 *
 * // 2. Optimize
 * const classToDecl = new Map([["_flex", "display:flex"], ...]);
 * const result = optimizeCore(usages, css, classToDecl);
 *
 * // 3. Transform output
 * const optimizedHtml = htmlTransformer.transform(html, result.mergeMap);
 * ```
 *
 * ## Legacy API (Luna-specific convenience)
 *
 * ```typescript
 * import { optimizeCss, optimizeHtml } from "@luna_ui/luna/css-optimizer";
 *
 * const result = optimizeCss(css, html, mapping, { minFrequency: 2 });
 * const optimizedHtml = optimizeHtml(html, result.mergeMap);
 * ```
 */

// Types
export type {
  ClassUsage,
  CoOccurrence,
  MergePattern,
  OptimizeResult,
  OptimizeOptions,
  ClassNameGenerator,
  CssRule,
  // MoonBit analyzer types
  ClassCooccurrence,
  AnalyzerWarning,
} from "./types.js";

// Core (framework-agnostic)
export {
  optimizeCore,
  applyMergeToClasses,
  type CoreOptimizeOptions,
  type CoreOptimizeResult,
} from "./core.js";

// Extractors
export {
  HtmlExtractor,
  JsxExtractor,
  SvelteExtractor,
  MultiExtractor,
  htmlExtractor,
  jsxExtractor,
  svelteExtractor,
  multiExtractor,
  type ClassExtractor,
  type ExtractorOptions,
} from "./extractors.js";

// Transformers
export {
  HtmlTransformer,
  JsxTransformer,
  SvelteTransformer,
  MultiTransformer,
  htmlTransformer,
  jsxTransformer,
  svelteTransformer,
  multiTransformer,
  type ClassTransformer,
  type TransformerOptions,
} from "./transformers.js";

// Hash utilities
export { djb2Hash, toBase36, hashClassName, hashMergedClassName } from "./hash.js";

// Parsing utilities (for advanced use)
export {
  extractClassUsages,
  parseCssRules,
  buildClassToDeclarationMap,
  extractUniqueClasses,
} from "./parser.js";

// Co-occurrence analysis (for advanced use)
export {
  buildCooccurrenceMatrix,
  matrixToCooccurrences,
  getTopCooccurrences,
  buildAdjacencyList,
} from "./cooccurrence.js";

// Pattern mining (for advanced use)
export {
  findFrequentPatterns,
  removeSubsumedPatterns,
  groupByClassSet,
} from "./pattern.js";

// Legacy API (convenience wrappers)
export { optimizeCss, optimizeHtml, optimize } from "./merge.js";

// MoonBit static analyzer (for Luna projects)
export {
  analyzeFile,
  analyzeDirectory,
  convertToOptimizerInput,
  type MoonBitAnalysisResult,
  type ConvertedResult,
} from "./moonbit-analyzer.js";
