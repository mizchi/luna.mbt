#!/usr/bin/env node
/**
 * Simple CSS Minifier
 *
 * Minifies CSS without changing class names.
 * Safe for use with existing templates.
 *
 * Usage:
 *   node minify.js input.css [--output output.css]
 */

import fs from 'fs';

/**
 * Minify CSS content
 * @param {string} css - CSS content
 * @returns {string} - Minified CSS
 */
function minifyCSS(css) {
  return css
    // Remove comments
    .replace(/\/\*[\s\S]*?\*\//g, '')
    // Remove newlines and multiple spaces
    .replace(/\s+/g, ' ')
    // Remove space around { } : ; ,
    .replace(/\s*([{};:,])\s*/g, '$1')
    // Remove trailing semicolons before }
    .replace(/;}/g, '}')
    // Remove space after ( and before )
    .replace(/\(\s+/g, '(')
    .replace(/\s+\)/g, ')')
    // Trim
    .trim();
}

/**
 * Format file size
 * @param {number} bytes
 * @returns {string}
 */
function formatSize(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  return `${(bytes / 1024).toFixed(1)} KB`;
}

function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.error('Usage: node minify.js input.css [--output output.css]');
    process.exit(1);
  }

  let inputFile = null;
  let outputFile = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--output' || args[i] === '-o') {
      outputFile = args[++i];
    } else if (!args[i].startsWith('-')) {
      inputFile = args[i];
    }
  }

  if (!inputFile) {
    console.error('Error: No input file specified');
    process.exit(1);
  }

  // Read input
  const css = fs.readFileSync(inputFile, 'utf-8');
  const originalSize = Buffer.byteLength(css, 'utf-8');

  // Minify
  const minified = minifyCSS(css);
  const minifiedSize = Buffer.byteLength(minified, 'utf-8');

  // Output
  if (outputFile) {
    fs.writeFileSync(outputFile, minified);
    console.error(`Minified: ${formatSize(originalSize)} → ${formatSize(minifiedSize)} (${((1 - minifiedSize / originalSize) * 100).toFixed(1)}% reduction)`);
    console.error(`Written to: ${outputFile}`);
  } else {
    console.log(minified);
  }
}

main();
