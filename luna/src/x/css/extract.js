#!/usr/bin/env node
/**
 * Static CSS Extractor for Luna CSS Module
 *
 * Extracts all CSS declarations from .mbt files at build time.
 * This ensures all styles are collected regardless of runtime branches.
 *
 * Usage:
 *   node extract.js [dir] [options]
 *
 * Options:
 *   --output, -o    Output file (default: stdout)
 *   --pretty        Pretty print output
 *   --json          Output as JSON mapping
 *   --verbose, -v   Show extracted declarations
 *   --warn, -w      Warn about non-literal arguments (default: true)
 *   --no-warn       Disable warnings
 *   --strict        Exit with error if warnings found
 *   --split         Output per-file CSS (JSON manifest)
 *   --split-dir     Output per-directory CSS (JSON manifest)
 */

import fs from 'fs';
import path from 'path';

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
const ON_PATTERN = /\bon\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// media("condition", "property", "value")
const MEDIA_PATTERN = /\bmedia\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

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
const UON_PATTERN = /\buon\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UAT_MD_PATTERN = /\buat_md\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UAT_LG_PATTERN = /\buat_lg\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;
const UDARK_PATTERN = /\budark\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// =============================================================================
// Warning Detection Patterns (match any arguments, not just literals)
// =============================================================================

// Matches function calls with any arguments (for detecting non-literal usage)
// These patterns use a more careful approach to handle strings with special chars

// Helper: match a string literal or a non-literal argument
// String literal: "..." (handling escaped quotes)
// Non-literal: identifier, expression, etc.
const ARG_PATTERN = `(?:"(?:[^"\\\\]|\\\\.)*"|[^,)]+)`;

// Build patterns for warning detection
const WARN_PATTERNS = [
  // 2-arg functions: css, hover, focus, active, at_*, dark, ucss, etc.
  { name: 'css', pattern: new RegExp(`\\b(u?css)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2 },
  { name: 'hover', pattern: new RegExp(`\\b(u?hover)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2 },
  { name: 'focus', pattern: new RegExp(`\\b(u?focus)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2 },
  { name: 'active', pattern: new RegExp(`\\b(u?active)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2 },
  { name: 'at_sm', pattern: new RegExp(`\\bat_sm\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2, noPrefix: true },
  { name: 'at_md', pattern: new RegExp(`\\b(u?at_md)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2 },
  { name: 'at_lg', pattern: new RegExp(`\\b(u?at_lg)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2 },
  { name: 'at_xl', pattern: new RegExp(`\\bat_xl\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2, noPrefix: true },
  { name: 'dark', pattern: new RegExp(`\\b(u?dark)\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 2 },
  // 3-arg functions: on, media, uon
  // CSS on() has first arg starting with ":" or "::" (pseudo-selector/element)
  // This distinguishes from event handler on(selector, event, handler)
  { name: 'on', pattern: new RegExp(`\\b(u?on)\\s*\\(\\s*"(::?[^"]+)"\\s*,\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 3, pseudoInMatch: true },
  { name: 'media', pattern: new RegExp(`\\bmedia\\s*\\(\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*,\\s*(${ARG_PATTERN})\\s*\\)`, 'g'), args: 3, noPrefix: true },
];

// =============================================================================
// Warning Detection Logic
// =============================================================================

/**
 * @typedef {Object} Warning
 * @property {string} file - File path
 * @property {number} line - Line number
 * @property {string} func - Function name
 * @property {string} code - The matched code
 * @property {string} reason - Why this is a warning
 */

/**
 * Check if a string is a string literal (starts and ends with quotes)
 * @param {string} str - The string to check
 * @returns {boolean}
 */
function isStringLiteral(str) {
  const trimmed = str.trim();
  // Check for basic string literal pattern
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return true;
  }
  return false;
}

/**
 * Check if a match is a function definition (has type annotations)
 * @param {string} code - The matched code
 * @returns {boolean}
 */
function isFunctionDefinition(code) {
  // Function definitions have type annotations like ": String"
  return /:\s*String/.test(code);
}

/**
 * Get line number for a position in content
 * @param {string} content - File content
 * @param {number} position - Character position
 * @returns {number}
 */
function getLineNumber(content, position) {
  return content.substring(0, position).split('\n').length;
}

/**
 * Detect non-literal CSS function arguments
 * @param {string} content - File content
 * @param {string} filePath - File path for reporting
 * @returns {Warning[]}
 */
function detectWarnings(content, filePath) {
  const warnings = [];

  for (const { name, pattern, args, noPrefix, pseudoInMatch } of WARN_PATTERNS) {
    // Reset pattern lastIndex
    pattern.lastIndex = 0;

    for (const match of content.matchAll(pattern)) {
      const fullMatch = match[0];
      const position = match.index;
      const line = getLineNumber(content, position);

      // Skip function definitions (have type annotations)
      if (isFunctionDefinition(fullMatch)) {
        continue;
      }

      // Extract arguments based on count
      const extractedArgs = [];
      if (args === 2) {
        // For patterns with func name capture group vs without
        const startIdx = noPrefix ? 1 : 2;
        extractedArgs.push(match[startIdx], match[startIdx + 1]);
      } else if (args === 3) {
        if (pseudoInMatch) {
          // For on() pattern: group 1 = func name, group 2 = pseudo (already validated as literal)
          // group 3 = property, group 4 = value
          extractedArgs.push(match[3], match[4]);
        } else {
          const startIdx = noPrefix ? 1 : 2;
          extractedArgs.push(match[startIdx], match[startIdx + 1], match[startIdx + 2]);
        }
      }

      // Check each argument
      for (let i = 0; i < extractedArgs.length; i++) {
        const arg = extractedArgs[i];
        if (arg && !isStringLiteral(arg)) {
          const argNum = pseudoInMatch ? i + 2 : i + 1; // Adjust arg number for on()
          warnings.push({
            file: filePath,
            line,
            func: name,
            code: fullMatch.trim(),
            reason: `Argument ${argNum} is not a string literal: ${arg.trim()}`,
          });
          break; // One warning per call is enough
        }
      }
    }
  }

  return warnings;
}

// =============================================================================
// Extraction Logic
// =============================================================================

/**
 * @typedef {Object} ExtractedStyles
 * @property {Set<string>} base - Base declarations (property:value)
 * @property {Array<{pseudo: string, property: string, value: string}>} pseudo
 * @property {Array<{condition: string, property: string, value: string}>} media
 */

/**
 * Extract all CSS declarations from a file content
 * @param {string} content - File content
 * @returns {ExtractedStyles}
 */
function extractFromContent(content) {
  const base = new Set();
  const pseudo = [];
  const media = [];

  // Helper to extract base declarations
  function extractBase(pattern) {
    for (const match of content.matchAll(pattern)) {
      base.add(`${match[1]}:${match[2]}`);
    }
  }

  // Helper to extract styles([...]) declarations
  function extractStyles(pattern) {
    for (const match of content.matchAll(pattern)) {
      const pairs = match[1];
      for (const pair of pairs.matchAll(STYLES_PAIR_PATTERN)) {
        base.add(`${pair[1]}:${pair[2]}`);
      }
    }
  }

  // Helper to extract pseudo-class declarations
  function extractPseudo(pattern, pseudoSelector) {
    for (const match of content.matchAll(pattern)) {
      pseudo.push({
        pseudo: pseudoSelector,
        property: match[1],
        value: match[2],
      });
    }
  }

  // Helper to extract on() declarations
  function extractOn(pattern) {
    for (const match of content.matchAll(pattern)) {
      pseudo.push({
        pseudo: match[1],
        property: match[2],
        value: match[3],
      });
    }
  }

  // Helper to extract media query declarations
  function extractMedia(pattern, condition = null) {
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
  extractPseudo(HOVER_PATTERN, ':hover');
  extractPseudo(UHOVER_PATTERN, ':hover');
  extractPseudo(FOCUS_PATTERN, ':focus');
  extractPseudo(UFOCUS_PATTERN, ':focus');
  extractPseudo(ACTIVE_PATTERN, ':active');
  extractPseudo(UACTIVE_PATTERN, ':active');
  extractOn(ON_PATTERN);
  extractOn(UON_PATTERN);

  // Extract media queries
  extractMedia(MEDIA_PATTERN);
  extractMedia(AT_SM_PATTERN, 'min-width:640px');
  extractMedia(AT_MD_PATTERN, 'min-width:768px');
  extractMedia(UAT_MD_PATTERN, 'min-width:768px');
  extractMedia(AT_LG_PATTERN, 'min-width:1024px');
  extractMedia(UAT_LG_PATTERN, 'min-width:1024px');
  extractMedia(AT_XL_PATTERN, 'min-width:1280px');
  extractMedia(DARK_PATTERN, 'prefers-color-scheme:dark');
  extractMedia(UDARK_PATTERN, 'prefers-color-scheme:dark');

  return { base, pseudo, media };
}

/**
 * Recursively find all .mbt files in a directory
 * @param {string} dir - Directory path
 * @returns {string[]}
 */
function findMbtFiles(dir) {
  const files = [];

  function walk(currentDir) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);
      if (entry.isDirectory()) {
        // Skip node_modules, .git, target directories
        if (!['node_modules', '.git', 'target', '.mooncakes'].includes(entry.name)) {
          walk(fullPath);
        }
      } else if (entry.isFile() && entry.name.endsWith('.mbt')) {
        files.push(fullPath);
      }
    }
  }

  walk(dir);
  return files;
}

// =============================================================================
// CSS Generation
// =============================================================================

/**
 * Generate class name from counter
 * @param {number} n - Counter value
 * @returns {string}
 */
function generateClassName(n) {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  if (n < 26) {
    return '_' + chars[n];
  }
  return '_' + chars[n % 26] + Math.floor(n / 26);
}

/**
 * Generate CSS from extracted styles
 * @param {ExtractedStyles} styles
 * @param {Object} options
 * @returns {{css: string, mapping: Object}}
 */
function generateCSS(styles, options = {}) {
  const { pretty = false } = options;
  const mapping = {};
  let counter = 0;
  let hoverCounter = 0;
  let focusCounter = 0;
  let activeCounter = 0;
  let otherCounter = 0;
  let mediaCounter = 0;

  const parts = [];

  // Base styles
  for (const decl of styles.base) {
    const cls = generateClassName(counter++);
    mapping[decl] = cls;
    if (pretty) {
      parts.push(`.${cls} { ${decl} }`);
    } else {
      parts.push(`.${cls}{${decl}}`);
    }
  }

  // Pseudo-class styles
  for (const { pseudo, property, value } of styles.pseudo) {
    let cls;
    if (pseudo === ':hover') {
      cls = `_h${hoverCounter++}`;
    } else if (pseudo === ':focus') {
      cls = `_f${focusCounter++}`;
    } else if (pseudo === ':active') {
      cls = `_ac${activeCounter++}`;
    } else {
      cls = `_p${otherCounter++}`;
    }
    const key = `${pseudo}:${property}:${value}`;
    mapping[key] = cls;
    if (pretty) {
      parts.push(`.${cls}${pseudo} { ${property}: ${value} }`);
    } else {
      parts.push(`.${cls}${pseudo}{${property}:${value}}`);
    }
  }

  // Media query styles (grouped by condition)
  const mediaGroups = new Map();
  for (const { condition, property, value } of styles.media) {
    if (!mediaGroups.has(condition)) {
      mediaGroups.set(condition, []);
    }
    mediaGroups.get(condition).push({ property, value });
  }

  for (const [condition, declarations] of mediaGroups) {
    const rules = [];
    for (const { property, value } of declarations) {
      const cls = `_m${mediaCounter++}`;
      const key = `@media(${condition}):${property}:${value}`;
      mapping[key] = cls;
      if (pretty) {
        rules.push(`  .${cls} { ${property}: ${value} }`);
      } else {
        rules.push(`.${cls}{${property}:${value}}`);
      }
    }
    if (pretty) {
      parts.push(`@media (${condition}) {\n${rules.join('\n')}\n}`);
    } else {
      parts.push(`@media(${condition}){${rules.join('')}}`);
    }
  }

  const separator = pretty ? '\n' : '';
  return {
    css: parts.join(separator),
    mapping,
  };
}

// =============================================================================
// Per-File/Directory CSS Splitting
// =============================================================================

/**
 * Extract and generate CSS per file
 * @param {string[]} files - List of .mbt files
 * @param {Object} options
 * @returns {{perFile: Object, combined: ExtractedStyles}}
 */
function extractPerFile(files, options = {}) {
  const perFile = {};
  const combined = {
    base: new Set(),
    pseudo: [],
    media: [],
  };

  for (const file of files) {
    const content = fs.readFileSync(file, 'utf-8');
    const extracted = extractFromContent(content);

    // Store per-file results
    perFile[file] = {
      base: [...extracted.base],
      pseudo: extracted.pseudo,
      media: extracted.media,
    };

    // Also combine for global deduplication reference
    for (const decl of extracted.base) {
      combined.base.add(decl);
    }
    combined.pseudo.push(...extracted.pseudo);
    combined.media.push(...extracted.media);
  }

  return { perFile, combined };
}

/**
 * Group files by directory and extract CSS per directory
 * @param {string[]} files - List of .mbt files
 * @param {string} baseDir - Base directory for relative paths
 * @returns {{perDir: Object, combined: ExtractedStyles}}
 */
function extractPerDirectory(files, baseDir) {
  const perDir = {};
  const combined = {
    base: new Set(),
    pseudo: [],
    media: [],
  };

  for (const file of files) {
    const relPath = path.relative(baseDir, file);
    const dirName = path.dirname(relPath);

    if (!perDir[dirName]) {
      perDir[dirName] = {
        base: new Set(),
        pseudo: [],
        media: [],
        files: [],
      };
    }

    const content = fs.readFileSync(file, 'utf-8');
    const extracted = extractFromContent(content);

    perDir[dirName].files.push(file);

    for (const decl of extracted.base) {
      perDir[dirName].base.add(decl);
      combined.base.add(decl);
    }
    perDir[dirName].pseudo.push(...extracted.pseudo);
    perDir[dirName].media.push(...extracted.media);
    combined.pseudo.push(...extracted.pseudo);
    combined.media.push(...extracted.media);
  }

  // Convert Sets to Arrays for JSON serialization
  for (const dir of Object.keys(perDir)) {
    perDir[dir].base = [...perDir[dir].base];
  }

  return { perDir, combined };
}

/**
 * Generate split CSS manifest
 * @param {Object} splitData - Per-file or per-directory data
 * @param {Object} options
 * @returns {Object} - Manifest with CSS per entry
 */
function generateSplitManifest(splitData, options = {}) {
  const { pretty = false } = options;
  const manifest = {
    entries: {},
    shared: { base: [], pseudo: [], media: [] },
  };

  // Track declaration frequency for shared CSS detection
  const declFreq = new Map();

  for (const [key, data] of Object.entries(splitData)) {
    for (const decl of data.base) {
      declFreq.set(decl, (declFreq.get(decl) || 0) + 1);
    }
  }

  // Declarations used in 3+ files are considered "shared"
  const sharedDecls = new Set();
  for (const [decl, count] of declFreq) {
    if (count >= 3) {
      sharedDecls.add(decl);
      manifest.shared.base.push(decl);
    }
  }

  // Generate CSS for each entry
  for (const [key, data] of Object.entries(splitData)) {
    const entryStyles = {
      base: new Set(data.base.filter(d => !sharedDecls.has(d))),
      pseudo: data.pseudo,
      media: data.media,
    };

    const { css } = generateCSS(entryStyles, { pretty });

    manifest.entries[key] = {
      css,
      stats: {
        base: entryStyles.base.size,
        pseudo: data.pseudo.length,
        media: data.media.length,
      },
      files: data.files || [key],
    };
  }

  // Generate shared CSS
  if (manifest.shared.base.length > 0) {
    const sharedStyles = {
      base: new Set(manifest.shared.base),
      pseudo: [],
      media: [],
    };
    const { css: sharedCSS } = generateCSS(sharedStyles, { pretty });
    manifest.sharedCSS = sharedCSS;
  }

  return manifest;
}

// =============================================================================
// CLI
// =============================================================================

function main() {
  const args = process.argv.slice(2);
  let dir = '.';
  let outputFile = null;
  let pretty = false;
  let jsonOutput = false;
  let verbose = false;
  let warn = true;
  let strict = false;
  let splitMode = null; // 'file' | 'dir' | null

  // Parse arguments
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--output' || arg === '-o') {
      outputFile = args[++i];
    } else if (arg === '--pretty') {
      pretty = true;
    } else if (arg === '--json') {
      jsonOutput = true;
    } else if (arg === '--verbose' || arg === '-v') {
      verbose = true;
    } else if (arg === '--warn' || arg === '-w') {
      warn = true;
    } else if (arg === '--no-warn') {
      warn = false;
    } else if (arg === '--strict') {
      strict = true;
      warn = true; // strict implies warn
    } else if (arg === '--split') {
      splitMode = 'file';
    } else if (arg === '--split-dir') {
      splitMode = 'dir';
    } else if (!arg.startsWith('-')) {
      dir = arg;
    }
  }

  // Find all .mbt files
  const files = findMbtFiles(dir);
  if (verbose) {
    console.error(`Found ${files.length} .mbt files`);
  }

  // Handle split mode
  if (splitMode) {
    let splitData;
    if (splitMode === 'dir') {
      const { perDir } = extractPerDirectory(files, dir);
      splitData = perDir;
    } else {
      const { perFile } = extractPerFile(files);
      // Convert to expected format with files array
      for (const key of Object.keys(perFile)) {
        perFile[key].files = [key];
      }
      splitData = perFile;
    }

    const manifest = generateSplitManifest(splitData, { pretty });

    // Collect warnings
    const allWarnings = [];
    if (warn) {
      for (const file of files) {
        const content = fs.readFileSync(file, 'utf-8');
        const warnings = detectWarnings(content, file);
        allWarnings.push(...warnings);
      }
      manifest.warnings = allWarnings;
    }

    if (verbose) {
      console.error(`Split mode: ${splitMode}`);
      console.error(`  - ${Object.keys(manifest.entries).length} entries`);
      console.error(`  - ${manifest.shared.base.length} shared declarations`);
    }

    const output = JSON.stringify(manifest, null, pretty ? 2 : 0);

    if (outputFile) {
      fs.writeFileSync(outputFile, output);
      if (verbose) {
        console.error(`Written to ${outputFile}`);
      }
    } else {
      console.log(output);
    }
    return;
  }

  // Extract from all files (normal mode)
  const combined = {
    base: new Set(),
    pseudo: [],
    media: [],
  };
  const allWarnings = [];

  for (const file of files) {
    const content = fs.readFileSync(file, 'utf-8');
    const extracted = extractFromContent(content);

    for (const decl of extracted.base) {
      combined.base.add(decl);
    }
    combined.pseudo.push(...extracted.pseudo);
    combined.media.push(...extracted.media);

    // Detect warnings
    if (warn) {
      const warnings = detectWarnings(content, file);
      allWarnings.push(...warnings);
    }
  }

  // Report warnings
  if (warn && allWarnings.length > 0) {
    console.error(`\n⚠️  ${allWarnings.length} warning(s): non-literal CSS arguments detected\n`);
    for (const w of allWarnings) {
      console.error(`  ${w.file}:${w.line}`);
      console.error(`    ${w.func}(...) - ${w.reason}`);
      console.error(`    Code: ${w.code}`);
      console.error('');
    }
    console.error('  These calls cannot be statically extracted.');
    console.error('  Consider using string literals for static analysis.\n');

    if (strict) {
      console.error('❌ Strict mode: exiting with error due to warnings.');
      process.exit(1);
    }
  }

  if (verbose) {
    console.error(`Extracted:`);
    console.error(`  - ${combined.base.size} base declarations`);
    console.error(`  - ${combined.pseudo.length} pseudo-class declarations`);
    console.error(`  - ${combined.media.length} media query declarations`);
  }

  // Generate CSS
  const { css, mapping } = generateCSS(combined, { pretty });

  // Output
  let output;
  if (jsonOutput) {
    output = JSON.stringify({
      css,
      mapping,
      stats: {
        base: combined.base.size,
        pseudo: combined.pseudo.length,
        media: combined.media.length,
      },
      warnings: warn ? allWarnings : undefined,
    }, null, pretty ? 2 : 0);
  } else {
    output = css;
  }

  if (outputFile) {
    fs.writeFileSync(outputFile, output);
    if (verbose) {
      console.error(`Written to ${outputFile}`);
    }
  } else {
    console.log(output);
  }
}

main();
