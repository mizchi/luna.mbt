/**
 * Hash functions for CSS class name generation
 */

/**
 * DJB2 hash function
 * A simple but effective string hashing algorithm
 */
export function djb2Hash(s: string): number {
  let hash = 5381;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    // hash * 33 + c (using unsigned 32-bit arithmetic)
    hash = ((hash << 5) + hash + c) >>> 0;
  }
  return hash;
}

/**
 * Convert a number to base36 string (0-9a-z)
 * Takes lower 24 bits to keep class names short (4-5 chars)
 */
export function toBase36(n: number): string {
  const chars = "0123456789abcdefghijklmnopqrstuvwxyz";
  // Take lower 24 bits
  n = n & 0xffffff;
  if (n === 0) return "0";
  let result = "";
  while (n > 0) {
    result = chars[n % 36] + result;
    n = Math.floor(n / 36);
  }
  return result;
}

/**
 * Generate a class name from a CSS declaration string
 * @param decl - CSS declaration like "display:flex"
 * @param prefix - Class name prefix (default: "_")
 */
export function hashClassName(decl: string, prefix = "_"): string {
  const hash = djb2Hash(decl);
  return prefix + toBase36(hash);
}

/**
 * Generate a merged class name from combined declarations
 * @param declarations - Array of CSS declarations
 * @param prefix - Class name prefix (default: "_m" for merged)
 */
export function hashMergedClassName(declarations: string[], prefix = "_m"): string {
  const combined = declarations.sort().join(";");
  return prefix + toBase36(djb2Hash(combined));
}
