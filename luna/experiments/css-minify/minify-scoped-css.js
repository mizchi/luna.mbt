#!/usr/bin/env node
/**
 * Scoped CSS Minifier for MoonBit WebComponent output
 *
 * Features:
 * - CSS class name mangling (scoped CSS safety)
 * - CSS whitespace compression
 * - Selector string replacement in JS
 *
 * Usage:
 *   node minify-scoped-css.js input.js > output.js
 *   node minify-scoped-css.js input.js --output output.js
 */

const fs = require("fs");

// Tags to exclude from class name mangling
const TAG_NAMES = new Set([
  "host", "button", "input", "label", "div", "ul", "li", "style",
  "h1", "h2", "h3", "h4", "h5", "h6", "p", "form", "span", "a",
  "table", "tr", "td", "th", "thead", "tbody", "nav", "header",
  "footer", "main", "section", "article", "aside", "svg", "path"
]);

// Reserved words that shouldn't be mangled
const RESERVED = new Set([
  "self", "this", "id", "text", "start", "end", "value", "type",
  "name", "data", "key", "item", "index", "true", "false", "null"
]);

function extractClassNames(code) {
  const classNames = new Set();

  // Find all <style>...</style> blocks (including escaped versions)
  const styleBlocks = code.match(/<style>[^<]*<\/style>/g) || [];
  const escapedStyleBlocks = code.match(/<style>[^<]*<\\\/style>/g) || [];
  const allStyleBlocks = [...styleBlocks, ...escapedStyleBlocks];

  // CSS: .classname within <style> blocks only
  for (const block of allStyleBlocks) {
    const cssMatches = block.matchAll(/\.([a-zA-Z][a-zA-Z0-9_-]*)/g);
    for (const m of cssMatches) {
      classNames.add(m[1]);
    }
  }

  // HTML: class="classname" or class="a b c"
  const htmlMatches = code.matchAll(/class="([^"]+)"/g);
  for (const m of htmlMatches) {
    m[1].split(/\s+/).forEach(c => classNames.add(c));
  }

  // JS selectors: ".classname" (only if looks like a selector - starts with .)
  const selectorMatches = code.matchAll(/querySelector[^"]*"\.[a-zA-Z][a-zA-Z0-9_-]*"/g);
  for (const m of selectorMatches) {
    const dotMatch = m[0].match(/\.([a-zA-Z][a-zA-Z0-9_-]*)"/);
    if (dotMatch) classNames.add(dotMatch[1]);
  }

  // Also match nn(n,".classname") pattern from minified code
  const nnMatches = code.matchAll(/\("\.[a-zA-Z][a-zA-Z0-9_-]*"\)/g);
  for (const m of nnMatches) {
    const dotMatch = m[0].match(/\.([a-zA-Z][a-zA-Z0-9_-]*)/);
    if (dotMatch) classNames.add(dotMatch[1]);
  }

  // Filter out tag names and reserved words
  for (const name of classNames) {
    if (TAG_NAMES.has(name) || RESERVED.has(name) || name.length <= 1) {
      classNames.delete(name);
    }
  }

  return classNames;
}

function generateMangleMap(classNames) {
  const map = {};
  let idx = 0;
  const chars = "abcdefghijklmnopqrstuvwxyz";

  // Sort by frequency (most used first) for better compression
  const sorted = [...classNames].sort();

  for (const name of sorted) {
    // Generate short name: a, b, ... z, a1, b1, ...
    const shortName = chars[idx % 26] + (idx >= 26 ? Math.floor(idx / 26) : "");
    map[name] = shortName;
    idx++;
  }

  return map;
}

function minifyCss(css) {
  return css
    .replace(/\s*{\s*/g, "{")
    .replace(/\s*}\s*/g, "}")
    .replace(/\s*:\s*/g, ":")
    .replace(/\s*;\s*/g, ";")
    .replace(/;\}/g, "}")
    .replace(/\s*,\s*/g, ",")
    .replace(/\n\s*/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

function transform(code, options = {}) {
  const { verbose = false, mangleClasses = true, minifyWhitespace = true } = options;

  let result = code;
  let stats = { classReduction: 0, whitespaceReduction: 0 };

  // Step 1: Extract and mangle class names
  if (mangleClasses) {
    const classNames = extractClassNames(code);
    const mangleMap = generateMangleMap(classNames);

    if (verbose) {
      console.error("Class names found:", classNames.size);
      console.error("Mangle map:", mangleMap);
    }

    for (const [orig, mangled] of Object.entries(mangleMap)) {
      const origLen = result.length;

      // CSS: .classname → .a
      result = result.replace(
        new RegExp("\\." + escapeRegex(orig) + "(?=[^a-zA-Z0-9_-])", "g"),
        "." + mangled
      );

      // HTML class attribute: class="classname"
      result = result.replace(
        new RegExp('class="' + escapeRegex(orig) + '"', "g"),
        'class="' + mangled + '"'
      );

      // HTML class attribute: class="... classname ..."
      result = result.replace(
        new RegExp('class="([^"]*\\s)' + escapeRegex(orig) + '(\\s[^"]*)"', "g"),
        'class="$1' + mangled + '$2"'
      );
      result = result.replace(
        new RegExp('class="([^"]*\\s)' + escapeRegex(orig) + '"', "g"),
        'class="$1' + mangled + '"'
      );
      result = result.replace(
        new RegExp('class="' + escapeRegex(orig) + '(\\s[^"]*)"', "g"),
        'class="' + mangled + '$1"'
      );

      // JS selector: ".classname" → ".a"
      result = result.replace(
        new RegExp('"\\.' + escapeRegex(orig) + '"', "g"),
        '".' + mangled + '"'
      );

      stats.classReduction += origLen - result.length;
    }
  }

  // Step 2: Minify CSS whitespace in <style> blocks
  if (minifyWhitespace) {
    const origLen = result.length;

    result = result.replace(/<style>([^<]+)<\/style>/g, (match, css) => {
      return "<style>" + minifyCss(css) + "</style>";
    });

    // Also handle escaped versions (in string literals)
    result = result.replace(/<style>([^<]+)<\\\/style>/g, (match, css) => {
      return "<style>" + minifyCss(css) + "<\\/style>";
    });

    stats.whitespaceReduction = origLen - result.length;
  }

  return { result, stats };
}

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\-]/g, '\\$&');
}

// CLI
function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args.includes("--help") || args.includes("-h")) {
    console.log(`
Usage: node minify-scoped-css.js <input.js> [options]

Options:
  --output, -o <file>   Write output to file (default: stdout)
  --verbose, -v         Show debug information
  --no-mangle           Skip class name mangling
  --no-minify           Skip CSS whitespace minification
  --help, -h            Show this help
    `);
    process.exit(0);
  }

  const inputFile = args.find(a => !a.startsWith("-"));
  const outputFile = args.includes("-o")
    ? args[args.indexOf("-o") + 1]
    : args.includes("--output")
    ? args[args.indexOf("--output") + 1]
    : null;
  const verbose = args.includes("-v") || args.includes("--verbose");
  const mangleClasses = !args.includes("--no-mangle");
  const minifyWhitespace = !args.includes("--no-minify");

  if (!inputFile || !fs.existsSync(inputFile)) {
    console.error("Error: Input file not found:", inputFile);
    process.exit(1);
  }

  const code = fs.readFileSync(inputFile, "utf8");
  const { result, stats } = transform(code, { verbose, mangleClasses, minifyWhitespace });

  if (verbose) {
    console.error("\n=== Stats ===");
    console.error("Original:", code.length, "bytes");
    console.error("Result:", result.length, "bytes");
    console.error("Reduction:", code.length - result.length, "bytes",
      "(" + ((1 - result.length / code.length) * 100).toFixed(2) + "%)");
    console.error("  Class mangling:", stats.classReduction, "bytes");
    console.error("  Whitespace:", stats.whitespaceReduction, "bytes");
  }

  if (outputFile) {
    fs.writeFileSync(outputFile, result);
    if (!verbose) {
      console.log("Written to:", outputFile);
    }
  } else {
    process.stdout.write(result);
  }
}

// Export for programmatic use
module.exports = { transform, extractClassNames, generateMangleMap, minifyCss };

// Run CLI if executed directly
if (require.main === module) {
  main();
}
