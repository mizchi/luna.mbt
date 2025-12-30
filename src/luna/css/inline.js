#!/usr/bin/env node
/**
 * CSS Class Name Inliner
 *
 * Replaces CSS utility function calls with pre-computed class names.
 * This enables true zero-runtime CSS by eliminating runtime style registration.
 *
 * Usage:
 *   node inline.js [js-file] --mapping [mapping.json]
 *   node inline.js [js-file] --extract-from [src-dir]
 *
 * Options:
 *   --mapping, -m     JSON file with css -> classname mapping
 *   --extract-from    Extract mapping from source directory
 *   --output, -o      Output file (default: stdout)
 *   --dry-run         Show what would be replaced without modifying
 *   --verbose, -v     Show replacement details
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// =============================================================================
// Pattern Matching for Compiled MoonBit Output
// =============================================================================

// Pattern for register_decl calls (base CSS)
// mizchi$luna$luna$css$$register_decl("display:flex")
const REGISTER_DECL_PATTERN = /mizchi\$luna\$luna\$css\$\$register_decl\s*\(\s*"([^"]+)"\s*\)/g;

// Pattern for register_pseudo calls
// mizchi$luna$luna$css$$register_pseudo(":hover", "background", "#2563eb")
const REGISTER_PSEUDO_PATTERN = /mizchi\$luna\$luna\$css\$\$register_pseudo\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// Pattern for register_media calls
// mizchi$luna$luna$css$$register_media("min-width:768px", "padding", "2rem")
const REGISTER_MEDIA_PATTERN = /mizchi\$luna\$luna\$css\$\$register_media\s*\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g;

// =============================================================================
// Mapping Generation
// =============================================================================

/**
 * Generate mapping by running extract.js
 * @param {string} srcDir - Source directory
 * @returns {Object} - Mapping from declaration to class name
 */
function extractMapping(srcDir) {
  const extractScript = path.join(__dirname, 'extract.js');
  const output = execSync(`node "${extractScript}" "${srcDir}" --json --no-warn`, {
    encoding: 'utf-8',
  });
  const result = JSON.parse(output);
  return result.mapping;
}

/**
 * Load mapping from JSON file
 * @param {string} filePath - Path to mapping JSON
 * @returns {Object}
 */
function loadMapping(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const data = JSON.parse(content);
  return data.mapping || data;
}

// =============================================================================
// Inlining Logic
// =============================================================================

/**
 * Replace CSS function calls with pre-computed class names
 * @param {string} code - JavaScript code
 * @param {Object} mapping - Declaration to class name mapping
 * @param {Object} options
 * @returns {{code: string, replacements: Array}}
 */
function inlineCSS(code, mapping, options = {}) {
  const { verbose = false, dryRun = false } = options;
  const replacements = [];

  let result = code;

  // Replace register_decl calls (base CSS)
  result = result.replace(REGISTER_DECL_PATTERN, (match, decl) => {
    const className = mapping[decl];
    if (className) {
      replacements.push({
        type: 'base',
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
  result = result.replace(REGISTER_PSEUDO_PATTERN, (match, pseudo, property, value) => {
    const key = `${pseudo}:${property}:${value}`;
    const className = mapping[key];
    if (className) {
      replacements.push({
        type: 'pseudo',
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
  });

  // Replace register_media calls
  result = result.replace(REGISTER_MEDIA_PATTERN, (match, condition, property, value) => {
    const key = `@media(${condition}):${property}:${value}`;
    const className = mapping[key];
    if (className) {
      replacements.push({
        type: 'media',
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
  });

  return { code: result, replacements };
}

/**
 * Remove CSS registry code (dead code after inlining)
 * @param {string} code - JavaScript code
 * @returns {string}
 */
function removeRegistryCode(code) {
  // Patterns for registry-related code that can be removed
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
    result = result.replace(pattern, '');
  }

  return result;
}

// =============================================================================
// CLI
// =============================================================================

function main() {
  const args = process.argv.slice(2);
  let inputFile = null;
  let outputFile = null;
  let mappingFile = null;
  let extractFrom = null;
  let verbose = false;
  let dryRun = false;
  let removeRegistry = false;

  // Parse arguments
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--mapping' || arg === '-m') {
      mappingFile = args[++i];
    } else if (arg === '--extract-from') {
      extractFrom = args[++i];
    } else if (arg === '--output' || arg === '-o') {
      outputFile = args[++i];
    } else if (arg === '--verbose' || arg === '-v') {
      verbose = true;
    } else if (arg === '--dry-run') {
      dryRun = true;
      verbose = true;
    } else if (arg === '--remove-registry') {
      removeRegistry = true;
    } else if (!arg.startsWith('-')) {
      inputFile = arg;
    }
  }

  if (!inputFile) {
    console.error('Usage: node inline.js [js-file] --mapping [mapping.json]');
    console.error('       node inline.js [js-file] --extract-from [src-dir]');
    process.exit(1);
  }

  // Get mapping
  let mapping;
  if (mappingFile) {
    mapping = loadMapping(mappingFile);
  } else if (extractFrom) {
    mapping = extractMapping(extractFrom);
  } else {
    console.error('Error: Must specify --mapping or --extract-from');
    process.exit(1);
  }

  if (verbose) {
    console.error(`Loaded ${Object.keys(mapping).length} mappings`);
  }

  // Read input
  const code = fs.readFileSync(inputFile, 'utf-8');
  const originalSize = Buffer.byteLength(code, 'utf-8');

  // Inline CSS
  const { code: inlinedCode, replacements } = inlineCSS(code, mapping, { verbose, dryRun });

  if (verbose) {
    console.error(`\nReplacements: ${replacements.length}`);
    for (const r of replacements) {
      console.error(`  [${r.type}] ${r.key || r.decl} → ${r.to}`);
    }
  }

  // Optionally remove registry code
  let finalCode = inlinedCode;
  if (removeRegistry) {
    finalCode = removeRegistryCode(inlinedCode);
  }

  const finalSize = Buffer.byteLength(finalCode, 'utf-8');

  if (verbose) {
    console.error(`\nSize: ${originalSize} → ${finalSize} (${((1 - finalSize / originalSize) * 100).toFixed(1)}% reduction)`);
  }

  // Output
  if (dryRun) {
    console.error('\n[Dry run - no files modified]');
  } else if (outputFile) {
    fs.writeFileSync(outputFile, finalCode);
    if (verbose) {
      console.error(`Written to ${outputFile}`);
    }
  } else {
    console.log(finalCode);
  }
}

main();
