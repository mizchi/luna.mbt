/**
 * Simple CSS Minifier
 *
 * Minifies CSS without changing class names.
 * Safe for use with existing templates.
 */

export interface MinifyOptions {
  verbose?: boolean;
}

export interface MinifyResult {
  minified: string;
  originalSize: number;
  minifiedSize: number;
  reduction: number;
}

/**
 * Minify CSS content
 */
export function minifyCSS(css: string): string {
  return (
    css
      // Remove comments
      .replace(/\/\*[\s\S]*?\*\//g, "")
      // Remove newlines and multiple spaces
      .replace(/\s+/g, " ")
      // Remove space around { } : ; ,
      .replace(/\s*([{};:,])\s*/g, "$1")
      // Remove trailing semicolons before }
      .replace(/;}/g, "}")
      // Remove space after ( and before )
      .replace(/\(\s+/g, "(")
      .replace(/\s+\)/g, ")")
      // Trim
      .trim()
  );
}

/**
 * Format file size
 */
export function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  return `${(bytes / 1024).toFixed(1)} KB`;
}

/**
 * Minify CSS and return result with stats
 */
export function minify(css: string, options: MinifyOptions = {}): MinifyResult {
  const originalSize = Buffer.byteLength(css, "utf-8");
  const minified = minifyCSS(css);
  const minifiedSize = Buffer.byteLength(minified, "utf-8");
  const reduction = ((1 - minifiedSize / originalSize) * 100);

  if (options.verbose) {
    console.error(
      `Minified: ${formatSize(originalSize)} → ${formatSize(minifiedSize)} (${reduction.toFixed(1)}% reduction)`
    );
  }

  return {
    minified,
    originalSize,
    minifiedSize,
    reduction,
  };
}
