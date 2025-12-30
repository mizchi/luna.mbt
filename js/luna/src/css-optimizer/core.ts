/**
 * CSS Co-occurrence Optimizer - Core Module
 *
 * Framework-agnostic core functions for CSS class co-occurrence analysis.
 * This module contains pure functions with no framework dependencies.
 */

import type { ClassUsage, MergePattern, OptimizeResult } from "./types.js";
import { hashMergedClassName } from "./hash.js";
import { findFrequentPatterns } from "./pattern.js";

/**
 * Core optimization options (framework-agnostic)
 */
export interface CoreOptimizeOptions {
  /** Minimum frequency for a pattern to be merged (default: 2) */
  minFrequency?: number;
  /** Maximum pattern size to consider (default: 5) */
  maxPatternSize?: number;
  /** Pretty print CSS output (default: false) */
  pretty?: boolean;
  /** Enable verbose logging (default: false) */
  verbose?: boolean;
}

/**
 * Core optimization result
 */
export interface CoreOptimizeResult {
  /** Optimized CSS string */
  css: string;
  /** Mapping from sorted class combination to merged class name */
  mergeMap: Map<string, string>;
  /** Detected patterns */
  patterns: MergePattern[];
  /** Statistics */
  stats: {
    originalClasses: number;
    mergedPatterns: number;
    estimatedBytesSaved: number;
  };
}

/**
 * Core optimizer - performs pattern analysis and CSS generation
 *
 * This is the framework-agnostic core that:
 * 1. Analyzes class usages to find frequent patterns
 * 2. Generates merged CSS rules
 * 3. Returns a merge map for HTML transformation
 *
 * @param usages - Array of class usages extracted from source
 * @param css - Original CSS content
 * @param classToDeclaration - Map from class name to CSS declaration
 * @param options - Optimization options
 */
export function optimizeCore(
  usages: ClassUsage[],
  css: string,
  classToDeclaration: Map<string, string>,
  options: CoreOptimizeOptions = {}
): CoreOptimizeResult {
  const {
    minFrequency = 2,
    maxPatternSize = 5,
    pretty = false,
    verbose = false,
  } = options;

  const log = (msg: string) => {
    if (verbose) {
      console.log(`[css-optimizer] ${msg}`);
    }
  };

  // Early return for empty input
  if (usages.length === 0) {
    return {
      css,
      mergeMap: new Map(),
      patterns: [],
      stats: {
        originalClasses: classToDeclaration.size,
        mergedPatterns: 0,
        estimatedBytesSaved: 0,
      },
    };
  }

  log(`Analyzing ${usages.length} class usage sites`);

  // Step 1: Find frequent patterns
  const patterns = findFrequentPatterns(usages, minFrequency, maxPatternSize);
  log(`Found ${patterns.length} frequent patterns`);

  // Step 2: Generate merged classes
  const mergeMap = new Map<string, string>();
  const cssRules: string[] = [];
  const usedClasses = new Set<string>();
  let totalBytesSaved = 0;

  for (const pattern of patterns) {
    // Collect declarations for all classes in pattern
    const declarations: string[] = [];
    let allFound = true;

    for (const cls of pattern.originalClasses) {
      const decl = classToDeclaration.get(cls);
      if (decl) {
        declarations.push(decl);
      } else {
        allFound = false;
        break;
      }
    }

    if (!allFound || declarations.length === 0) {
      continue;
    }

    // Check for conflicts (class already used in another merge)
    let hasConflict = false;
    for (const cls of pattern.originalClasses) {
      if (usedClasses.has(cls)) {
        hasConflict = true;
        break;
      }
    }

    if (hasConflict) {
      continue;
    }

    // Generate merged class name
    const mergedClass = hashMergedClassName(declarations);

    pattern.mergedClass = mergedClass;
    pattern.declarations = declarations;

    // Create merge key (sorted classes joined by space)
    const mergeKey = pattern.originalClasses.join(" ");
    mergeMap.set(mergeKey, mergedClass);

    // Mark classes as used
    for (const cls of pattern.originalClasses) {
      usedClasses.add(cls);
    }

    // Generate CSS rule
    const declStr = declarations.join(";");
    if (pretty) {
      cssRules.push(`.${mergedClass} { ${declStr.replace(/;/g, "; ")} }`);
    } else {
      cssRules.push(`.${mergedClass}{${declStr}}`);
    }

    totalBytesSaved += pattern.bytesSaved;
  }

  // Step 3: Filter out merged classes from original CSS
  const originalRules: string[] = [];
  const rulePattern = /\.([a-zA-Z_][a-zA-Z0-9_-]*)\{([^}]+)\}/g;

  let match: RegExpExecArray | null;
  rulePattern.lastIndex = 0;
  while ((match = rulePattern.exec(css)) !== null) {
    const cls = match[1];
    if (!usedClasses.has(cls)) {
      originalRules.push(match[0]);
    }
  }

  // Preserve @media rules
  const mediaPattern = /@media[^{]+\{[^}]+\}/g;
  mediaPattern.lastIndex = 0;
  while ((match = mediaPattern.exec(css)) !== null) {
    originalRules.push(match[0]);
  }

  // Preserve pseudo-class rules
  const pseudoPattern = /\.([a-zA-Z_][a-zA-Z0-9_-]*)(:[a-zA-Z-]+)\{([^}]+)\}/g;
  pseudoPattern.lastIndex = 0;
  while ((match = pseudoPattern.exec(css)) !== null) {
    originalRules.push(match[0]);
  }

  // Combine merged + remaining original rules
  const separator = pretty ? "\n" : "";
  const optimizedCss = [...cssRules, ...originalRules].join(separator);

  const actualPatterns = patterns.filter((p) => p.mergedClass !== "");

  log(`Merged ${actualPatterns.length} patterns`);
  log(`Estimated savings: ${totalBytesSaved} bytes`);

  return {
    css: optimizedCss,
    mergeMap,
    patterns: actualPatterns,
    stats: {
      originalClasses: classToDeclaration.size,
      mergedPatterns: actualPatterns.length,
      estimatedBytesSaved: totalBytesSaved,
    },
  };
}

/**
 * Apply merge map to class list
 *
 * Takes a list of classes and returns the optimized list
 * with merged classes replacing original combinations.
 *
 * @param classes - Array of class names
 * @param mergeMap - Merge map from optimizeCore
 * @param classPrefix - Prefix for classes to consider for merging
 */
export function applyMergeToClasses(
  classes: string[],
  mergeMap: Map<string, string>,
  classPrefix = "_"
): string[] {
  if (mergeMap.size === 0) {
    return classes;
  }

  // Separate prefixed and non-prefixed classes
  const prefixedClasses = classes.filter((c) => c.startsWith(classPrefix));
  const otherClasses = classes.filter((c) => !c.startsWith(classPrefix));

  // Sort for consistent matching
  prefixedClasses.sort();

  let result = [...prefixedClasses];
  const merged: string[] = [];

  // Sort merge keys by length descending (longer patterns first)
  const sortedKeys = [...mergeMap.keys()].sort((a, b) => b.length - a.length);

  // Try to apply each merge pattern
  for (const key of sortedKeys) {
    const patternClasses = key.split(" ");
    const mergedClass = mergeMap.get(key)!;

    // Check if all pattern classes are present
    let allPresent = true;
    for (const cls of patternClasses) {
      if (!result.includes(cls)) {
        allPresent = false;
        break;
      }
    }

    if (allPresent) {
      // Remove pattern classes and add merged class
      result = result.filter((c) => !patternClasses.includes(c));
      merged.push(mergedClass);
    }
  }

  // Return: merged classes + remaining prefixed + other classes
  return [...merged, ...result, ...otherClasses];
}
