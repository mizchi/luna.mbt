/**
 * Static CSS Extractor for Luna CSS Module
 *
 * Extracts all CSS declarations from .mbt files at build time.
 * This ensures all styles are collected regardless of runtime branches.
 */

import fs from "fs";
import path from "path";

// =============================================================================
// Pattern Definitions
// =============================================================================

// css("property", "value")
const CSS_PATTERN = /\bcss\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// styles([("property", "value"), ...])
const STYLES_PATTERN = /\bstyles\s*\(\s*\[([\s\S]*?)\]\s*\)/g;
const STYLES_PAIR_PATTERN = /\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// hover("property", "value"), focus(...), active(...)
const HOVER_PATTERN = /\bhover\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const FOCUS_PATTERN = /\bfocus\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const ACTIVE_PATTERN = /\bactive\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// on(":pseudo", "property", "value")
const ON_PATTERN =
  /\bon\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// media("condition", "property", "value")
const MEDIA_PATTERN =
  /\bmedia\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// at_sm, at_md, at_lg, at_xl("property", "value")
const AT_SM_PATTERN = /\bat_sm\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const AT_MD_PATTERN = /\bat_md\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const AT_LG_PATTERN = /\bat_lg\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const AT_XL_PATTERN = /\bat_xl\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// dark("property", "value")
const DARK_PATTERN = /\bdark\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// ucss, ustyles, uhover, etc. (re-exports from static_dom)
const UCSS_PATTERN = /\bucss\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const USTYLES_PATTERN = /\bustyles\s*\(\s*\[([\s\S]*?)\]\s*\)/g;
const UHOVER_PATTERN = /\buhover\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UFOCUS_PATTERN = /\bufocus\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UACTIVE_PATTERN = /\buactive\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UON_PATTERN =
  /\buon\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UAT_MD_PATTERN = /\buat_md\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UAT_LG_PATTERN = /\buat_lg\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UDARK_PATTERN = /\budark\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// =============================================================================
// Warning Detection Patterns
// =============================================================================

const ARG_PATTERN = `(?:"(?:[^"\\\\]|\\\\.)*"|[^,)]+)`;

const WARN_PATTERNS = [
  {
    name: "css",
    pattern: new RegExp(
      `\\b(u?css)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
  },
  {
    name: "hover",
    pattern: new RegExp(
      `\\b(u?hover)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
  },
  {
    name: "focus",
    pattern: new RegExp(
      `\\b(u?focus)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
  },
  {
    name: "active",
    pattern: new RegExp(
      `\\b(u?active)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
  },
  {
    name: "at_sm",
    pattern: new RegExp(
      `\\bat_sm\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
    noPrefix: true,
  },
  {
    name: "at_md",
    pattern: new RegExp(
      `\\b(u?at_md)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
  },
  {
    name: "at_lg",
    pattern: new RegExp(
      `\\b(u?at_lg)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
  },
  {
    name: "at_xl",
    pattern: new RegExp(
      `\\bat_xl\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
    noPrefix: true,
  },
  {
    name: "dark",
    pattern: new RegExp(
      `\\b(u?dark)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 2,
  },
  {
    name: "on",
    pattern: new RegExp(
      `\\b(u?on)\\s*\\(\\s*"(::?[^"]+)"\\s*,\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 3,
    pseudoInMatch: true,
  },
  {
    name: "media",
    pattern: new RegExp(
      `\\bmedia\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`,
      "g"
    ),
    args: 3,
    noPrefix: true,
  },
];

// =============================================================================
// Types
// =============================================================================

export interface Warning {
  file: string;
  line: number;
  func: string;
  code: string;
  reason: string;
}

export interface ExtractedStyles {
  base: Set<string>;
  pseudo: Array<{ pseudo: string; property: string; value: string }>;
  media: Array<{ condition: string; property: string; value: string }>;
}

export interface ExtractOptions {
  pretty?: boolean;
  json?: boolean;
  verbose?: boolean;
  warn?: boolean;
  strict?: boolean;
  splitMode?: "file" | "dir" | null;
}

export interface ExtractResult {
  css: string;
  mapping: Record<string, string>;
  stats: {
    base: number;
    pseudo: number;
    media: number;
  };
  warnings?: Warning[];
}

// =============================================================================
// Warning Detection
// =============================================================================

function isStringLiteral(str: string): boolean {
  const trimmed = str.trim();
  return (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  );
}

function isFunctionDefinition(code: string): boolean {
  return /:\s*String/.test(code);
}

function getLineNumber(content: string, position: number): number {
  return content.substring(0, position).split("\n").length;
}

export function detectWarnings(content: string, filePath: string): Warning[] {
  const warnings: Warning[] = [];

  for (const { name, pattern, args, noPrefix, pseudoInMatch } of WARN_PATTERNS) {
    pattern.lastIndex = 0;

    for (const match of content.matchAll(pattern)) {
      const fullMatch = match[0];
      const position = match.index!;
      const line = getLineNumber(content, position);

      if (isFunctionDefinition(fullMatch)) {
        continue;
      }

      const extractedArgs: string[] = [];
      if (args === 2) {
        const startIdx = noPrefix ? 1 : 2;
        extractedArgs.push(match[startIdx], match[startIdx + 1]);
      } else if (args === 3) {
        if (pseudoInMatch) {
          extractedArgs.push(match[3], match[4]);
        } else {
          const startIdx = noPrefix ? 1 : 2;
          extractedArgs.push(
            match[startIdx],
            match[startIdx + 1],
            match[startIdx + 2]
          );
        }
      }

      for (let i = 0; i < extractedArgs.length; i++) {
        const arg = extractedArgs[i];
        if (arg && !isStringLiteral(arg)) {
          const argNum = pseudoInMatch ? i + 2 : i + 1;
          warnings.push({
            file: filePath,
            line,
            func: name,
            code: fullMatch.trim(),
            reason: `Argument ${argNum} is not a string literal: ${arg.trim()}`,
          });
          break;
        }
      }
    }
  }

  return warnings;
}

// =============================================================================
// Extraction Logic
// =============================================================================

export function extractFromContent(content: string): ExtractedStyles {
  const base = new Set<string>();
  const pseudo: ExtractedStyles["pseudo"] = [];
  const media: ExtractedStyles["media"] = [];

  function extractBase(pattern: RegExp) {
    for (const match of content.matchAll(pattern)) {
      base.add(`${match[1]}:${match[2]}`);
    }
  }

  function extractStyles(pattern: RegExp) {
    for (const match of content.matchAll(pattern)) {
      const pairs = match[1];
      for (const pair of pairs.matchAll(STYLES_PAIR_PATTERN)) {
        base.add(`${pair[1]}:${pair[2]}`);
      }
    }
  }

  function extractPseudo(pattern: RegExp, pseudoSelector: string) {
    for (const match of content.matchAll(pattern)) {
      pseudo.push({
        pseudo: pseudoSelector,
        property: match[1],
        value: match[2],
      });
    }
  }

  function extractOn(pattern: RegExp) {
    for (const match of content.matchAll(pattern)) {
      pseudo.push({
        pseudo: match[1],
        property: match[2],
        value: match[3],
      });
    }
  }

  function extractMedia(pattern: RegExp, condition: string | null = null) {
    for (const match of content.matchAll(pattern)) {
      if (condition) {
        media.push({
          condition,
          property: match[1],
          value: match[2],
        });
      } else {
        media.push({
          condition: match[1],
          property: match[2],
          value: match[3],
        });
      }
    }
  }

  // Extract base styles
  extractBase(CSS_PATTERN);
  extractBase(UCSS_PATTERN);
  extractStyles(STYLES_PATTERN);
  extractStyles(USTYLES_PATTERN);

  // Extract pseudo-classes
  extractPseudo(HOVER_PATTERN, ":hover");
  extractPseudo(UHOVER_PATTERN, ":hover");
  extractPseudo(FOCUS_PATTERN, ":focus");
  extractPseudo(UFOCUS_PATTERN, ":focus");
  extractPseudo(ACTIVE_PATTERN, ":active");
  extractPseudo(UACTIVE_PATTERN, ":active");
  extractOn(ON_PATTERN);
  extractOn(UON_PATTERN);

  // Extract media queries
  extractMedia(MEDIA_PATTERN);
  extractMedia(AT_SM_PATTERN, "min-width:640px");
  extractMedia(AT_MD_PATTERN, "min-width:768px");
  extractMedia(UAT_MD_PATTERN, "min-width:768px");
  extractMedia(AT_LG_PATTERN, "min-width:1024px");
  extractMedia(UAT_LG_PATTERN, "min-width:1024px");
  extractMedia(AT_XL_PATTERN, "min-width:1280px");
  extractMedia(DARK_PATTERN, "prefers-color-scheme:dark");
  extractMedia(UDARK_PATTERN, "prefers-color-scheme:dark");

  return { base, pseudo, media };
}

export function findMbtFiles(dir: string): string[] {
  const files: string[] = [];

  function walk(currentDir: string) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);
      if (entry.isDirectory()) {
        if (
          !["node_modules", ".git", "target", ".mooncakes"].includes(entry.name)
        ) {
          walk(fullPath);
        }
      } else if (entry.isFile() && entry.name.endsWith(".mbt")) {
        files.push(fullPath);
      }
    }
  }

  walk(dir);
  return files;
}

// =============================================================================
// CSS Generation - Hash-based class names
// =============================================================================

/**
 * DJB2 hash function - must match MoonBit registry.mbt implementation
 */
function djb2Hash(s: string): number {
  let hash = 5381;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    // hash * 33 + c (using unsigned 32-bit arithmetic)
    hash = ((hash << 5) + hash + c) >>> 0;
  }
  return hash;
}

/**
 * Convert hash to base36 string (0-9a-z)
 * Takes lower 24 bits to keep class names short (4-5 chars)
 */
function toBase36(n: number): string {
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
 * Generate class name from declaration hash
 */
function hashClassName(decl: string): string {
  const hash = djb2Hash(decl);
  return "_" + toBase36(hash);
}

export function generateCSS(
  styles: ExtractedStyles,
  options: { pretty?: boolean } = {}
): { css: string; mapping: Record<string, string> } {
  const { pretty = false } = options;
  const mapping: Record<string, string> = {};
  const parts: string[] = [];

  // Base styles - use hash-based class names for deterministic output
  for (const decl of styles.base) {
    const cls = hashClassName(decl);
    mapping[decl] = cls;
    if (pretty) {
      parts.push(`.${cls} { ${decl} }`);
    } else {
      parts.push(`.${cls}{${decl}}`);
    }
  }

  // Pseudo-class styles with hash-based class names
  for (const { pseudo, property, value } of styles.pseudo) {
    // Include pseudo in the hash key for uniqueness
    const hashKey = `${pseudo}:${property}:${value}`;
    const cls = hashClassName(hashKey);
    mapping[hashKey] = cls;
    if (pretty) {
      parts.push(`.${cls}${pseudo} { ${property}: ${value} }`);
    } else {
      parts.push(`.${cls}${pseudo}{${property}:${value}}`);
    }
  }

  // Media query styles (grouped by condition) with hash-based class names
  const mediaGroups = new Map<
    string,
    Array<{ property: string; value: string }>
  >();
  for (const { condition, property, value } of styles.media) {
    if (!mediaGroups.has(condition)) {
      mediaGroups.set(condition, []);
    }
    mediaGroups.get(condition)!.push({ property, value });
  }

  for (const [condition, declarations] of mediaGroups) {
    const rules: string[] = [];
    for (const { property, value } of declarations) {
      const hashKey = `@media(${condition}):${property}:${value}`;
      const cls = hashClassName(hashKey);
      mapping[hashKey] = cls;
      if (pretty) {
        rules.push(`  .${cls} { ${property}: ${value} }`);
      } else {
        rules.push(`.${cls}{${property}:${value}}`);
      }
    }
    if (pretty) {
      parts.push(`@media (${condition}) {\n${rules.join("\n")}\n}`);
    } else {
      parts.push(`@media(${condition}){${rules.join("")}}`);
    }
  }

  const separator = pretty ? "\n" : "";
  return {
    css: parts.join(separator),
    mapping,
  };
}

// =============================================================================
// Main Extract Function
// =============================================================================

export function extract(dir: string, options: ExtractOptions = {}): ExtractResult {
  const { pretty = false, warn = true, strict = false, verbose = false } = options;

  const files = findMbtFiles(dir);
  if (verbose) {
    console.error(`Found ${files.length} .mbt files`);
  }

  const combined: ExtractedStyles = {
    base: new Set(),
    pseudo: [],
    media: [],
  };
  const allWarnings: Warning[] = [];

  for (const file of files) {
    const content = fs.readFileSync(file, "utf-8");
    const extracted = extractFromContent(content);

    for (const decl of extracted.base) {
      combined.base.add(decl);
    }
    combined.pseudo.push(...extracted.pseudo);
    combined.media.push(...extracted.media);

    if (warn) {
      const warnings = detectWarnings(content, file);
      allWarnings.push(...warnings);
    }
  }

  if (warn && allWarnings.length > 0 && verbose) {
    console.error(
      `\n⚠️  ${allWarnings.length} warning(s): non-literal CSS arguments detected\n`
    );
    for (const w of allWarnings) {
      console.error(`  ${w.file}:${w.line}`);
      console.error(`    ${w.func}(...) - ${w.reason}`);
      console.error(`    Code: ${w.code}`);
      console.error("");
    }

    if (strict) {
      throw new Error("Strict mode: non-literal CSS arguments detected");
    }
  }

  if (verbose) {
    console.error(`Extracted:`);
    console.error(`  - ${combined.base.size} base declarations`);
    console.error(`  - ${combined.pseudo.length} pseudo-class declarations`);
    console.error(`  - ${combined.media.length} media query declarations`);
  }

  const { css, mapping } = generateCSS(combined, { pretty });

  return {
    css,
    mapping,
    stats: {
      base: combined.base.size,
      pseudo: combined.pseudo.length,
      media: combined.media.length,
    },
    warnings: warn ? allWarnings : undefined,
  };
}
