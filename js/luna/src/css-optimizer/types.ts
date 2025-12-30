/**
 * CSS Co-occurrence Optimizer Types
 * Standalone types for CSS class optimization based on co-occurrence analysis
 */

/**
 * Represents a set of classes used together on an HTML element
 */
export interface ClassUsage {
  /** Array of class names used on the element */
  classes: string[];
  /** Source location for debugging (e.g., "file.html:42") */
  source: string;
}

/**
 * Co-occurrence pair with frequency count
 */
export interface CoOccurrence {
  /** First class name (alphabetically) */
  classA: string;
  /** Second class name (alphabetically) */
  classB: string;
  /** Number of times these classes appear together */
  frequency: number;
}

/**
 * A pattern of classes that frequently appear together
 */
export interface MergePattern {
  /** Original class names to merge */
  originalClasses: string[];
  /** New merged class name (generated) */
  mergedClass: string;
  /** Combined CSS declarations */
  declarations: string[];
  /** How many times this pattern appears in HTML */
  frequency: number;
  /** Estimated bytes saved by merging */
  bytesSaved: number;
}

/**
 * Result of CSS optimization
 */
export interface OptimizeResult {
  /** Optimized CSS output */
  css: string;
  /** Mapping from original class combination to merged class */
  mergeMap: Map<string, string>;
  /** Patterns that were merged */
  patterns: MergePattern[];
  /** Optimization statistics */
  stats: {
    /** Number of original unique classes */
    originalClasses: number;
    /** Number of patterns merged */
    mergedPatterns: number;
    /** Estimated bytes saved */
    estimatedBytesSaved: number;
  };
}

/**
 * Options for CSS optimization
 */
export interface OptimizeOptions {
  /** Minimum frequency for a pattern to be considered (default: 2) */
  minFrequency?: number;
  /** Maximum pattern size to consider (default: 5) */
  maxPatternSize?: number;
  /** Class name prefix filter (only classes starting with this will be optimized) */
  classPrefix?: string;
  /** Pretty print CSS output */
  pretty?: boolean;
  /** Enable verbose logging */
  verbose?: boolean;
}

/**
 * Function to generate class names from declarations
 */
export type ClassNameGenerator = (decl: string) => string;

/**
 * CSS rule with selector and declarations
 */
export interface CssRule {
  selector: string;
  declarations: string;
}

// =============================================================================
// MoonBit Static Analyzer Types
// =============================================================================

/**
 * CSS class co-occurrence detected in MoonBit source
 */
export interface ClassCooccurrence {
  /** CSS declarations (e.g., ["color:red", "font-size:16px"]) */
  classes: string[];
  /** Source file path */
  file: string;
  /** Line number in source */
  line: number;
  /** Whether this can be statically analyzed (no conditionals) */
  isStatic: boolean;
}

/**
 * Warning from static analyzer about non-analyzable patterns
 */
export interface AnalyzerWarning {
  /** Warning type */
  kind:
    | "dynamic_conditional"
    | "dynamic_function_call"
    | "untraceable_variable"
    | "dynamic_array_construction";
  /** Source file path */
  file: string;
  /** Line number in source */
  line: number;
  /** Human-readable warning message */
  message: string;
}
