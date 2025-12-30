/**
 * CSS Class Name Inliner
 *
 * Replaces CSS utility function calls with pre-computed class names.
 * This enables true zero-runtime CSS by eliminating runtime style registration.
 */

import { extract } from "./extract.js";

// =============================================================================
// Pattern Matching for Compiled MoonBit Output
// =============================================================================

// Pattern for register_decl calls (base CSS)
// mizchi$luna$luna$css$$register_decl("display:flex")
const REGISTER_DECL_PATTERN =
  /mizchi\$luna\$luna\$css\$\$register_decl\s*\(\s*"([^"]+)"\s*\)/g;

// Pattern for register_pseudo calls
// mizchi$luna$luna$css$$register_pseudo(":hover", "background", "#2563eb")
const REGISTER_PSEUDO_PATTERN =
  /mizchi\$luna\$luna\$css\$\$register_pseudo\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// Pattern for register_media calls
// mizchi$luna$luna$css$$register_media("min-width:768px", "padding", "2rem")
const REGISTER_MEDIA_PATTERN =
  /mizchi\$luna\$luna\$css\$\$register_media\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// =============================================================================
// Types
// =============================================================================

export interface InlineOptions {
  verbose?: boolean;
  dryRun?: boolean;
  removeRegistry?: boolean;
}

export interface Replacement {
  type: "base" | "pseudo" | "media";
  from: string;
  to: string;
  key?: string;
  decl?: string;
}

export interface InlineResult {
  code: string;
  replacements: Replacement[];
  originalSize: number;
  finalSize: number;
}

// =============================================================================
// Inlining Logic
// =============================================================================

/**
 * Replace CSS function calls with pre-computed class names
 */
export function inlineCSS(
  code: string,
  mapping: Record<string, string>,
  options: InlineOptions = {}
): InlineResult {
  const { verbose = false } = options;
  const replacements: Replacement[] = [];
  const originalSize = Buffer.byteLength(code, "utf-8");

  let result = code;

  // Replace register_decl calls (base CSS)
  result = result.replace(REGISTER_DECL_PATTERN, (match, decl) => {
    const className = mapping[decl];
    if (className) {
      replacements.push({
        type: "base",
        from: match,
        to: `"${className}"`,
        decl,
      });
      return `"${className}"`;
    }
    if (verbose) {
      console.error(`Warning: No mapping for base declaration: ${decl}`);
    }
    return match;
  });

  // Replace register_pseudo calls
  result = result.replace(
    REGISTER_PSEUDO_PATTERN,
    (match, pseudo, property, value) => {
      const key = `${pseudo}:${property}:${value}`;
      const className = mapping[key];
      if (className) {
        replacements.push({
          type: "pseudo",
          from: match,
          to: `"${className}"`,
          key,
        });
        return `"${className}"`;
      }
      if (verbose) {
        console.error(`Warning: No mapping for pseudo: ${key}`);
      }
      return match;
    }
  );

  // Replace register_media calls
  result = result.replace(
    REGISTER_MEDIA_PATTERN,
    (match, condition, property, value) => {
      const key = `@media(${condition}):${property}:${value}`;
      const className = mapping[key];
      if (className) {
        replacements.push({
          type: "media",
          from: match,
          to: `"${className}"`,
          key,
        });
        return `"${className}"`;
      }
      if (verbose) {
        console.error(`Warning: No mapping for media: ${key}`);
      }
      return match;
    }
  );

  const finalSize = Buffer.byteLength(result, "utf-8");

  return { code: result, replacements, originalSize, finalSize };
}

/**
 * Remove CSS registry code (dead code after inlining)
 */
export function removeRegistryCode(code: string): string {
  const patterns = [
    // Registry objects
    /const mizchi\$luna\$luna\$css\$\$registry\s*=\s*\{[^}]+\};?\n?/g,
    /const mizchi\$luna\$luna\$css\$\$pseudo_registry\s*=\s*\{[^}]+\};?\n?/g,
    /const mizchi\$luna\$luna\$css\$\$media_registry\s*=\s*\{[^}]+\};?\n?/g,
    // Class chars constant
    /const mizchi\$luna\$luna\$css\$\$class_chars\s*=\s*"[^"]+";?\n?/g,
    // Bind constants
    /const mizchi\$luna\$luna\$css\$\$[a-z_]+\$46\$42\$bind[^;]+;?\n?/g,
  ];

  let result = code;
  for (const pattern of patterns) {
    result = result.replace(pattern, "");
  }

  return result;
}

/**
 * Inline CSS with mapping extracted from source directory
 */
export function inlineFromSource(
  code: string,
  srcDir: string,
  options: InlineOptions = {}
): InlineResult {
  const { mapping } = extract(srcDir, { warn: false });
  let result = inlineCSS(code, mapping, options);

  if (options.removeRegistry) {
    result = {
      ...result,
      code: removeRegistryCode(result.code),
      finalSize: Buffer.byteLength(removeRegistryCode(result.code), "utf-8"),
    };
  }

  return result;
}
