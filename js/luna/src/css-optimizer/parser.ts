/**
 * HTML and CSS parsing utilities
 */

import type { ClassUsage, CssRule } from "./types.js";

/**
 * Pattern to match class attributes in HTML
 */
const CLASS_ATTR_PATTERN = /class\s*=\s*"([^"]+)"/g;

/**
 * Pattern to match CSS rules
 */
const CSS_RULE_PATTERN = /\.([a-zA-Z_][a-zA-Z0-9_-]*)\s*\{([^}]+)\}/g;

/**
 * Extract class usages from HTML content
 * @param html - HTML content
 * @param source - Source identifier for debugging
 * @param classPrefix - Only extract classes starting with this prefix
 */
export function extractClassUsages(
  html: string,
  source = "html",
  classPrefix = "_"
): ClassUsage[] {
  const usages: ClassUsage[] = [];
  let match: RegExpExecArray | null;

  CLASS_ATTR_PATTERN.lastIndex = 0;
  while ((match = CLASS_ATTR_PATTERN.exec(html)) !== null) {
    const classValue = match[1].trim();
    if (!classValue) continue;

    // Split by whitespace and filter by prefix
    const classes = classValue
      .split(/\s+/)
      .filter((c) => c.startsWith(classPrefix) && c.length > classPrefix.length);

    // Only consider elements with 2+ matching classes
    if (classes.length >= 2) {
      // Sort for consistent ordering
      classes.sort();
      usages.push({ classes, source: `${source}:${match.index}` });
    }
  }

  return usages;
}

/**
 * Parse CSS rules from CSS content
 * @param css - CSS content
 */
export function parseCssRules(css: string): CssRule[] {
  const rules: CssRule[] = [];
  let match: RegExpExecArray | null;

  CSS_RULE_PATTERN.lastIndex = 0;
  while ((match = CSS_RULE_PATTERN.exec(css)) !== null) {
    rules.push({
      selector: match[1],
      declarations: match[2].trim(),
    });
  }

  return rules;
}

/**
 * Build a mapping from class name to CSS declaration
 * @param css - CSS content
 * @param classPrefix - Class prefix filter
 */
export function buildClassToDeclarationMap(
  css: string,
  classPrefix = "_"
): Map<string, string> {
  const map = new Map<string, string>();
  const rules = parseCssRules(css);

  for (const rule of rules) {
    if (rule.selector.startsWith(classPrefix)) {
      // Normalize declarations (remove extra whitespace)
      const normalized = rule.declarations
        .split(";")
        .map((d) => d.trim())
        .filter((d) => d)
        .join(";");
      map.set(rule.selector, normalized);
    }
  }

  return map;
}

/**
 * Extract all unique classes from HTML
 * @param html - HTML content
 * @param classPrefix - Class prefix filter
 */
export function extractUniqueClasses(html: string, classPrefix = "_"): Set<string> {
  const classes = new Set<string>();
  let match: RegExpExecArray | null;

  CLASS_ATTR_PATTERN.lastIndex = 0;
  while ((match = CLASS_ATTR_PATTERN.exec(html)) !== null) {
    const classValue = match[1].trim();
    if (!classValue) continue;

    for (const cls of classValue.split(/\s+/)) {
      if (cls.startsWith(classPrefix) && cls.length > classPrefix.length) {
        classes.add(cls);
      }
    }
  }

  return classes;
}
