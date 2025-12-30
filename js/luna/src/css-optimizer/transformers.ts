/**
 * CSS Co-occurrence Optimizer - Transformers
 *
 * Pluggable output transformation strategies for different formats.
 * Each transformer applies merge maps to source content.
 */

/**
 * Transformer interface - implement this for custom output formats
 */
export interface ClassTransformer {
  /** Transformer name for debugging */
  name: string;

  /**
   * Transform content by applying merge map
   * @param content - Source content to transform
   * @param mergeMap - Mapping from "class1 class2" to "merged_class"
   * @param options - Transformer-specific options
   */
  transform(
    content: string,
    mergeMap: Map<string, string>,
    options?: TransformerOptions
  ): string;
}

/**
 * Common transformer options
 */
export interface TransformerOptions {
  /** Class prefix for identifying mergeable classes (default: "_") */
  classPrefix?: string;
}

/**
 * HTML Transformer
 *
 * Transforms HTML by replacing class="" attribute values with merged classes.
 */
export class HtmlTransformer implements ClassTransformer {
  name = "html";

  private pattern = /class\s*=\s*"([^"]+)"/g;

  transform(
    content: string,
    mergeMap: Map<string, string>,
    options: TransformerOptions = {}
  ): string {
    if (mergeMap.size === 0) {
      return content;
    }

    const { classPrefix = "_" } = options;

    // Sort merge keys by length descending (longer patterns first)
    const sortedKeys = [...mergeMap.keys()].sort((a, b) => b.length - a.length);

    return content.replace(this.pattern, (match, classValue) => {
      const classes = classValue.trim().split(/\s+/);
      const prefixedClasses = classes.filter((c: string) => c.startsWith(classPrefix));
      const otherClasses = classes.filter((c: string) => !c.startsWith(classPrefix));

      // Sort for consistent matching
      prefixedClasses.sort();

      let result = [...prefixedClasses];
      const merged: string[] = [];

      // Apply each merge pattern
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
          result = result.filter((c) => !patternClasses.includes(c));
          merged.push(mergedClass);
        }
      }

      const finalClasses = [...merged, ...result, ...otherClasses].join(" ");
      return `class="${finalClasses}"`;
    });
  }
}

/**
 * JSX Transformer
 *
 * Transforms JSX/TSX by replacing className attribute values.
 */
export class JsxTransformer implements ClassTransformer {
  name = "jsx";

  private stringPattern = /className\s*=\s*"([^"]+)"/g;

  transform(
    content: string,
    mergeMap: Map<string, string>,
    options: TransformerOptions = {}
  ): string {
    if (mergeMap.size === 0) {
      return content;
    }

    const { classPrefix = "_" } = options;
    const sortedKeys = [...mergeMap.keys()].sort((a, b) => b.length - a.length);

    return content.replace(this.stringPattern, (match, classValue) => {
      const classes = classValue.trim().split(/\s+/);
      const prefixedClasses = classes.filter((c: string) => c.startsWith(classPrefix));
      const otherClasses = classes.filter((c: string) => !c.startsWith(classPrefix));

      prefixedClasses.sort();

      let result = [...prefixedClasses];
      const merged: string[] = [];

      for (const key of sortedKeys) {
        const patternClasses = key.split(" ");
        const mergedClass = mergeMap.get(key)!;

        let allPresent = true;
        for (const cls of patternClasses) {
          if (!result.includes(cls)) {
            allPresent = false;
            break;
          }
        }

        if (allPresent) {
          result = result.filter((c) => !patternClasses.includes(c));
          merged.push(mergedClass);
        }
      }

      const finalClasses = [...merged, ...result, ...otherClasses].join(" ");
      return `className="${finalClasses}"`;
    });
  }
}

/**
 * Svelte Transformer
 *
 * Transforms Svelte templates by replacing class attribute values.
 * Preserves dynamic {expression} syntax.
 */
export class SvelteTransformer implements ClassTransformer {
  name = "svelte";

  private pattern = /class\s*=\s*"([^"]+)"/g;

  transform(
    content: string,
    mergeMap: Map<string, string>,
    options: TransformerOptions = {}
  ): string {
    if (mergeMap.size === 0) {
      return content;
    }

    const { classPrefix = "_" } = options;
    const sortedKeys = [...mergeMap.keys()].sort((a, b) => b.length - a.length);

    return content.replace(this.pattern, (match, classValue) => {
      // Preserve dynamic expressions
      const expressions: string[] = [];
      const cleanValue = classValue.replace(/\{[^}]+\}/g, (expr: string) => {
        expressions.push(expr);
        return `__EXPR_${expressions.length - 1}__`;
      });

      const classes = cleanValue.trim().split(/\s+/);
      const prefixedClasses = classes.filter(
        (c: string) => c.startsWith(classPrefix) && !c.startsWith("__EXPR_")
      );
      const otherClasses = classes.filter(
        (c: string) => !c.startsWith(classPrefix) || c.startsWith("__EXPR_")
      );

      prefixedClasses.sort();

      let result = [...prefixedClasses];
      const merged: string[] = [];

      for (const key of sortedKeys) {
        const patternClasses = key.split(" ");
        const mergedClass = mergeMap.get(key)!;

        let allPresent = true;
        for (const cls of patternClasses) {
          if (!result.includes(cls)) {
            allPresent = false;
            break;
          }
        }

        if (allPresent) {
          result = result.filter((c) => !patternClasses.includes(c));
          merged.push(mergedClass);
        }
      }

      let finalClasses = [...merged, ...result, ...otherClasses].join(" ");

      // Restore expressions
      expressions.forEach((expr, i) => {
        finalClasses = finalClasses.replace(`__EXPR_${i}__`, expr);
      });

      return `class="${finalClasses}"`;
    });
  }
}

/**
 * Multi-format transformer
 *
 * Automatically selects the appropriate transformer based on content or file type.
 */
export class MultiTransformer implements ClassTransformer {
  name = "multi";

  private transformers: Map<string, ClassTransformer>;

  constructor() {
    this.transformers = new Map([
      ["html", new HtmlTransformer()],
      ["jsx", new JsxTransformer()],
      ["tsx", new JsxTransformer()],
      ["svelte", new SvelteTransformer()],
    ]);
  }

  /**
   * Register a custom transformer for a file extension
   */
  register(extension: string, transformer: ClassTransformer): void {
    this.transformers.set(extension, transformer);
  }

  transform(
    content: string,
    mergeMap: Map<string, string>,
    options?: TransformerOptions
  ): string {
    // Default to HTML transformer
    const htmlTransformer = this.transformers.get("html")!;
    return htmlTransformer.transform(content, mergeMap, options);
  }

  /**
   * Transform with explicit file type
   */
  transformWithType(
    content: string,
    mergeMap: Map<string, string>,
    fileType: string,
    options?: TransformerOptions
  ): string {
    const transformer =
      this.transformers.get(fileType) || this.transformers.get("html")!;
    return transformer.transform(content, mergeMap, options);
  }

  /**
   * Transform multiple files
   */
  transformFiles(
    files: Array<{ content: string; path: string }>,
    mergeMap: Map<string, string>,
    options?: TransformerOptions
  ): Array<{ content: string; path: string }> {
    return files.map((file) => {
      const ext = file.path.split(".").pop() || "html";
      const transformer =
        this.transformers.get(ext) || this.transformers.get("html")!;
      return {
        path: file.path,
        content: transformer.transform(file.content, mergeMap, options),
      };
    });
  }
}

// Default transformers
export const htmlTransformer = new HtmlTransformer();
export const jsxTransformer = new JsxTransformer();
export const svelteTransformer = new SvelteTransformer();
export const multiTransformer = new MultiTransformer();
