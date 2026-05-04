#!/usr/bin/env node
/**
 * CSS Rule Factorization - Automatic Utility Class Derivation
 *
 * Given BEM-style CSS, automatically derives minimal utility classes
 * by finding common declaration patterns across rules.
 */

import fs from 'fs';
import { fileURLToPath } from 'url';
import path from 'path';

// ============================================================================
// CSS Parsing
// ============================================================================

/**
 * Parse CSS into rules: Map<selector, Set<declaration>>
 */
function parseCSS(css) {
  const rules = new Map();

  // Simple CSS parser (handles basic cases)
  const ruleRegex = /([^{]+)\{([^}]+)\}/g;
  let match;

  while ((match = ruleRegex.exec(css)) !== null) {
    const selector = match[1].trim();
    const body = match[2].trim();

    // Skip @rules for now
    if (selector.startsWith('@')) continue;

    // Parse declarations
    const declarations = new Set();
    const declParts = body.split(';').filter(d => d.trim());

    for (const decl of declParts) {
      const normalized = normalizeDeclaration(decl);
      if (normalized) declarations.add(normalized);
    }

    if (declarations.size > 0) {
      rules.set(selector, declarations);
    }
  }

  return rules;
}

/**
 * Normalize a CSS declaration (property: value)
 */
function normalizeDeclaration(decl) {
  const colonIndex = decl.indexOf(':');
  if (colonIndex === -1) return null;

  const prop = decl.slice(0, colonIndex).trim().toLowerCase();
  const value = decl.slice(colonIndex + 1).trim();

  return `${prop}:${value}`;
}

// ============================================================================
// Factorization Algorithm
// ============================================================================

/**
 * Find common declaration sets across rules
 * Returns: Array<{declarations: Set<string>, selectors: string[]}>
 */
function findCommonPatterns(rules) {
  // Build inverted index: declaration → [selectors]
  const declToSelectors = new Map();

  for (const [selector, declarations] of rules) {
    for (const decl of declarations) {
      if (!declToSelectors.has(decl)) {
        declToSelectors.set(decl, []);
      }
      declToSelectors.get(decl).push(selector);
    }
  }

  // Find declaration sets that appear together
  const patterns = [];
  const processed = new Set();

  // Sort by frequency (most common first)
  const sortedDecls = [...declToSelectors.entries()]
    .sort((a, b) => b[1].length - a[1].length);

  for (const [decl, selectors] of sortedDecls) {
    if (processed.has(decl)) continue;
    if (selectors.length < 2) continue; // Only factor if shared

    // Find all declarations that appear in ALL these selectors
    const commonDecls = new Set([decl]);

    for (const [otherDecl, otherSelectors] of declToSelectors) {
      if (otherDecl === decl) continue;
      if (processed.has(otherDecl)) continue;

      // Check if otherDecl appears in all selectors that have decl
      const allHave = selectors.every(sel =>
        rules.get(sel).has(otherDecl)
      );

      if (allHave) {
        commonDecls.add(otherDecl);
      }
    }

    if (commonDecls.size >= 1) {
      patterns.push({
        declarations: commonDecls,
        selectors: selectors
      });

      // Mark as processed
      for (const d of commonDecls) {
        processed.add(d);
      }
    }
  }

  return patterns;
}

/**
 * Generate utility classes from patterns
 */
function generateUtilities(patterns) {
  const utilities = [];
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  let idx = 0;

  for (const pattern of patterns) {
    // Generate short class name
    const name = idx < 26
      ? chars[idx]
      : chars[idx % 26] + Math.floor(idx / 26);

    utilities.push({
      name,
      declarations: pattern.declarations,
      selectors: pattern.selectors
    });

    idx++;
  }

  return utilities;
}

/**
 * Build selector → utility classes mapping
 */
function buildClassMapping(rules, utilities) {
  const mapping = new Map();

  for (const [selector, declarations] of rules) {
    const classes = [];
    const remaining = new Set(declarations);

    // Find which utilities apply
    for (const util of utilities) {
      let allMatch = true;
      for (const decl of util.declarations) {
        if (!remaining.has(decl)) {
          allMatch = false;
          break;
        }
      }

      if (allMatch) {
        classes.push(util.name);
        // Remove matched declarations
        for (const decl of util.declarations) {
          remaining.delete(decl);
        }
      }
    }

    mapping.set(selector, {
      utilities: classes,
      remaining: remaining
    });
  }

  return mapping;
}

// ============================================================================
// Output Generation
// ============================================================================

/**
 * Generate optimized CSS output
 */
function generateOutput(utilities, mapping) {
  const lines = [];

  // Utility classes
  lines.push('/* Derived utility classes */');
  for (const util of utilities) {
    const decls = [...util.declarations].join(';');
    lines.push(`.${util.name}{${decls}}`);
  }

  // Remaining per-selector rules
  lines.push('\n/* Remaining selector-specific rules */');
  for (const [selector, data] of mapping) {
    if (data.remaining.size > 0) {
      const decls = [...data.remaining].join(';');
      lines.push(`${selector}{${decls}}`);
    }
  }

  return lines.join('\n');
}

/**
 * Generate class mapping for HTML transformation
 */
function generateClassMap(mapping) {
  const map = {};

  for (const [selector, data] of mapping) {
    // Extract class name from selector (simple case: .classname)
    const classMatch = selector.match(/^\.([a-zA-Z0-9_-]+)$/);
    if (classMatch && data.utilities.length > 0) {
      map[classMatch[1]] = data.utilities.join(' ');
    }
  }

  return map;
}

/**
 * Generate runtime-expandable compressed format
 */
function generateRuntimeFormat(utilities, mapping) {
  // Declaration dictionary
  const declDict = {};
  let dictIdx = 0;
  const dictChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  for (const util of utilities) {
    for (const decl of util.declarations) {
      if (!declDict[decl]) {
        declDict[decl] = dictChars[dictIdx % 26] +
          (dictIdx >= 26 ? Math.floor(dictIdx / 26) : '');
        dictIdx++;
      }
    }
  }

  // Utility definitions using dictionary
  const utilDefs = {};
  for (const util of utilities) {
    const encoded = [...util.declarations]
      .map(d => declDict[d])
      .join('');
    utilDefs[util.name] = encoded;
  }

  // Class mapping
  const classMap = generateClassMap(mapping);

  return {
    // Inverted dictionary (short → full)
    D: Object.fromEntries(
      Object.entries(declDict).map(([k, v]) => [v, k])
    ),
    // Utility definitions
    U: utilDefs,
    // Class mapping
    M: classMap
  };
}

// ============================================================================
// Analysis & Stats
// ============================================================================

function analyze(originalCSS, optimizedCSS, utilities, mapping) {
  const stats = {
    originalSize: originalCSS.length,
    optimizedSize: optimizedCSS.length,
    reduction: originalCSS.length - optimizedCSS.length,
    reductionPercent: ((1 - optimizedCSS.length / originalCSS.length) * 100).toFixed(1),
    utilityCount: utilities.length,
    selectorsFactored: [...mapping.values()].filter(m => m.utilities.length > 0).length,
    totalSelectors: mapping.size
  };

  return stats;
}

// ============================================================================
// Main
// ============================================================================

function factorize(css, options = {}) {
  const { verbose = false } = options;

  // Parse
  const rules = parseCSS(css);
  if (verbose) console.error(`Parsed ${rules.size} rules`);

  // Find patterns
  const patterns = findCommonPatterns(rules);
  if (verbose) console.error(`Found ${patterns.length} common patterns`);

  // Generate utilities
  const utilities = generateUtilities(patterns);

  // Build mapping
  const mapping = buildClassMapping(rules, utilities);

  // Generate outputs
  const optimizedCSS = generateOutput(utilities, mapping);
  const classMap = generateClassMap(mapping);
  const runtime = generateRuntimeFormat(utilities, mapping);

  // Stats
  const stats = analyze(css, optimizedCSS, utilities, mapping);

  return {
    optimizedCSS,
    classMap,
    runtime,
    utilities,
    stats
  };
}

// CLI
function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes('--help')) {
    console.log(`
CSS Rule Factorization

Usage: node factorize.js <input.css> [options]

Options:
  --verbose, -v     Show debug info
  --runtime         Output runtime-expandable format
  --mapping         Output class mapping JSON
  --help            Show this help
`);
    return;
  }

  const inputFile = args.find(a => !a.startsWith('-'));
  const verbose = args.includes('-v') || args.includes('--verbose');
  const showRuntime = args.includes('--runtime');
  const showMapping = args.includes('--mapping');

  if (!inputFile || !fs.existsSync(inputFile)) {
    console.error('Error: Input file not found');
    process.exit(1);
  }

  const css = fs.readFileSync(inputFile, 'utf8');
  const result = factorize(css, { verbose });

  // Output
  if (showRuntime) {
    console.log(JSON.stringify(result.runtime, null, 2));
  } else if (showMapping) {
    console.log(JSON.stringify(result.classMap, null, 2));
  } else {
    console.log(result.optimizedCSS);
  }

  // Stats
  console.error('\n=== Stats ===');
  console.error(`Original: ${result.stats.originalSize} bytes`);
  console.error(`Optimized: ${result.stats.optimizedSize} bytes`);
  console.error(`Reduction: ${result.stats.reduction} bytes (${result.stats.reductionPercent}%)`);
  console.error(`Utilities: ${result.stats.utilityCount}`);
  console.error(`Selectors factored: ${result.stats.selectorsFactored}/${result.stats.totalSelectors}`);
}

export { factorize, parseCSS, findCommonPatterns };

// Run CLI if executed directly
const __filename = fileURLToPath(import.meta.url);
if (process.argv[1] === __filename) {
  main();
}
