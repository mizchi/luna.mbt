#!/usr/bin/env node
/**
 * CSS Utilities Benchmark
 *
 * Measures:
 * - Extraction performance (time)
 * - Output size comparison (utilities vs traditional)
 * - Deduplication effectiveness
 *
 * Usage:
 *   node src/luna/css/benchmark.js [--scale small|medium|large]
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const extractScript = path.join(__dirname, 'extract.js');
const tmpDir = path.join(__dirname, '.bench-tmp');

// =============================================================================
// Benchmark Configuration
// =============================================================================

const SCALES = {
  small: {
    components: 10,
    propsPerComponent: 5,
    variants: 3, // hover, dark, md
  },
  medium: {
    components: 50,
    propsPerComponent: 8,
    variants: 5,
  },
  large: {
    components: 200,
    propsPerComponent: 10,
    variants: 5,
  },
};

// Common CSS properties used in real apps
const CSS_PROPERTIES = [
  ['display', ['flex', 'grid', 'block', 'inline-flex', 'none']],
  ['flex-direction', ['row', 'column', 'row-reverse', 'column-reverse']],
  ['justify-content', ['flex-start', 'center', 'flex-end', 'space-between', 'space-around']],
  ['align-items', ['flex-start', 'center', 'flex-end', 'stretch', 'baseline']],
  ['padding', ['0.5rem', '1rem', '1.5rem', '2rem', '0.25rem', '0']],
  ['margin', ['0', '0.5rem', '1rem', 'auto', '0 auto']],
  ['gap', ['0.5rem', '1rem', '1.5rem', '2rem']],
  ['width', ['100%', 'auto', 'fit-content', '50%', '200px']],
  ['max-width', ['100%', '1200px', '800px', '600px', 'none']],
  ['height', ['auto', '100%', '100vh', 'fit-content']],
  ['font-size', ['0.875rem', '1rem', '1.125rem', '1.25rem', '1.5rem', '2rem']],
  ['font-weight', ['400', '500', '600', '700']],
  ['color', ['#333', '#666', '#999', 'white', 'inherit', 'var(--text)']],
  ['background', ['white', '#f5f5f5', '#1a1a1a', 'transparent', 'var(--bg)']],
  ['border-radius', ['0.25rem', '0.5rem', '0.75rem', '1rem', '9999px']],
  ['box-shadow', ['none', '0 1px 2px rgba(0,0,0,0.05)', '0 1px 3px rgba(0,0,0,0.1)', '0 4px 6px rgba(0,0,0,0.1)']],
  ['cursor', ['pointer', 'default', 'not-allowed']],
  ['opacity', ['1', '0.9', '0.8', '0.5', '0']],
  ['transition', ['all 0.2s', 'opacity 0.2s', 'transform 0.2s', 'none']],
  ['overflow', ['hidden', 'auto', 'scroll', 'visible']],
];

// =============================================================================
// Utilities
// =============================================================================

function randomChoice(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  return `${(bytes / 1024).toFixed(2)} KB`;
}

function formatTime(ms) {
  if (ms < 1) return `${(ms * 1000).toFixed(0)} μs`;
  if (ms < 1000) return `${ms.toFixed(2)} ms`;
  return `${(ms / 1000).toFixed(2)} s`;
}

// =============================================================================
// Generate Test Files
// =============================================================================

function generateComponent(index, config) {
  const lines = [];
  const componentName = `Component${index}`;

  lines.push(`fn ${componentName}() -> Node {`);
  lines.push(`  div(`);

  // Base styles
  const baseStyles = [];
  for (let i = 0; i < config.propsPerComponent; i++) {
    const [prop, values] = randomChoice(CSS_PROPERTIES);
    const value = randomChoice(values);
    baseStyles.push(`("${prop}", "${value}")`);
  }
  lines.push(`    class=styles([`);
  lines.push(`      ${baseStyles.join(',\n      ')}`);
  lines.push(`    ])`);

  // Variants
  if (config.variants >= 1) {
    const hoverProp = randomChoice(CSS_PROPERTIES);
    lines.push(`      + " " + hover("${hoverProp[0]}", "${randomChoice(hoverProp[1])}")`);
  }
  if (config.variants >= 2) {
    const focusProp = randomChoice(CSS_PROPERTIES);
    lines.push(`      + " " + focus("${focusProp[0]}", "${randomChoice(focusProp[1])}")`);
  }
  if (config.variants >= 3) {
    const darkProp = randomChoice(CSS_PROPERTIES);
    lines.push(`      + " " + dark("${darkProp[0]}", "${randomChoice(darkProp[1])}")`);
  }
  if (config.variants >= 4) {
    const mdProp = randomChoice(CSS_PROPERTIES);
    lines.push(`      + " " + at_md("${mdProp[0]}", "${randomChoice(mdProp[1])}")`);
  }
  if (config.variants >= 5) {
    const lgProp = randomChoice(CSS_PROPERTIES);
    lines.push(`      + " " + at_lg("${lgProp[0]}", "${randomChoice(lgProp[1])}")`);
  }

  lines.push(`    ,`);
  lines.push(`    [`);

  // Child elements with inline styles
  for (let i = 0; i < 3; i++) {
    const childProps = [];
    for (let j = 0; j < 2; j++) {
      const [prop, values] = randomChoice(CSS_PROPERTIES);
      childProps.push(`css("${prop}", "${randomChoice(values)}")`);
    }
    lines.push(`      span(class=${childProps.join(' + " " + ')}, [text("Child ${i}")]),`);
  }

  lines.push(`    ]`);
  lines.push(`  )`);
  lines.push(`}`);

  return lines.join('\n');
}

function generateTraditionalCSS(config) {
  // Generate equivalent traditional CSS (for comparison)
  const rules = [];
  const usedDeclarations = new Set();

  for (let c = 0; c < config.components; c++) {
    const componentClass = `.component-${c}`;
    const declarations = [];

    for (let i = 0; i < config.propsPerComponent; i++) {
      const [prop, values] = randomChoice(CSS_PROPERTIES);
      const value = randomChoice(values);
      declarations.push(`${prop}:${value}`);
      usedDeclarations.add(`${prop}:${value}`);
    }

    rules.push(`${componentClass}{${declarations.join(';')}}`);

    // Variants
    if (config.variants >= 1) {
      const hoverProp = randomChoice(CSS_PROPERTIES);
      rules.push(`${componentClass}:hover{${hoverProp[0]}:${randomChoice(hoverProp[1])}}`);
    }
    if (config.variants >= 3) {
      const darkProp = randomChoice(CSS_PROPERTIES);
      rules.push(`@media(prefers-color-scheme:dark){${componentClass}{${darkProp[0]}:${randomChoice(darkProp[1])}}}`);
    }
    if (config.variants >= 4) {
      const mdProp = randomChoice(CSS_PROPERTIES);
      rules.push(`@media(min-width:768px){${componentClass}{${mdProp[0]}:${randomChoice(mdProp[1])}}}`);
    }

    // Children
    for (let i = 0; i < 3; i++) {
      const childDecls = [];
      for (let j = 0; j < 2; j++) {
        const [prop, values] = randomChoice(CSS_PROPERTIES);
        childDecls.push(`${prop}:${randomChoice(values)}`);
      }
      rules.push(`${componentClass} .child-${i}{${childDecls.join(';')}}`);
    }
  }

  return {
    css: rules.join(''),
    uniqueDeclarations: usedDeclarations.size,
  };
}

// =============================================================================
// Run Benchmark
// =============================================================================

function runBenchmark(scaleName, config) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`Benchmark: ${scaleName.toUpperCase()}`);
  console.log(`  Components: ${config.components}`);
  console.log(`  Props/Component: ${config.propsPerComponent}`);
  console.log(`  Variants: ${config.variants}`);
  console.log(`${'='.repeat(60)}\n`);

  // Setup
  if (fs.existsSync(tmpDir)) {
    fs.rmSync(tmpDir, { recursive: true });
  }
  fs.mkdirSync(tmpDir, { recursive: true });

  // Generate test files
  console.log('Generating test files...');
  const genStart = performance.now();

  for (let i = 0; i < config.components; i++) {
    const content = generateComponent(i, config);
    fs.writeFileSync(path.join(tmpDir, `component_${i}.mbt`), content);
  }

  const genTime = performance.now() - genStart;
  console.log(`  Generated ${config.components} files in ${formatTime(genTime)}\n`);

  // Run extraction
  console.log('Running CSS extraction...');
  const extractStart = performance.now();

  let extractedCSS;
  try {
    extractedCSS = execSync(`node "${extractScript}" "${tmpDir}" --no-warn`, {
      encoding: 'utf-8',
    });
  } catch (e) {
    extractedCSS = e.stdout || '';
  }

  const extractTime = performance.now() - extractStart;
  const extractedSize = Buffer.byteLength(extractedCSS, 'utf-8');

  console.log(`  Extraction time: ${formatTime(extractTime)}`);
  console.log(`  Output size: ${formatBytes(extractedSize)}\n`);

  // Generate traditional CSS for comparison
  console.log('Generating traditional CSS (for comparison)...');
  const traditionalStart = performance.now();
  const traditional = generateTraditionalCSS(config);
  const traditionalTime = performance.now() - traditionalStart;
  const traditionalSize = Buffer.byteLength(traditional.css, 'utf-8');

  console.log(`  Generation time: ${formatTime(traditionalTime)}`);
  console.log(`  Output size: ${formatBytes(traditionalSize)}\n`);

  // Calculate deduplication
  const extractedLines = extractedCSS.split(/[{}]/).filter(s => s.includes(':'));
  const deduplicatedCount = extractedLines.length;

  // Summary
  console.log('--- Results ---\n');
  console.log(`  Traditional CSS: ${formatBytes(traditionalSize)}`);
  console.log(`  Utility CSS:     ${formatBytes(extractedSize)}`);
  console.log(`  Reduction:       ${((1 - extractedSize / traditionalSize) * 100).toFixed(1)}%`);
  console.log('');
  console.log(`  Unique declarations: ~${deduplicatedCount}`);
  console.log(`  Extraction speed: ${(config.components / (extractTime / 1000)).toFixed(0)} components/sec`);

  // Cleanup
  fs.rmSync(tmpDir, { recursive: true });

  return {
    scale: scaleName,
    components: config.components,
    extractTime,
    traditionalSize,
    extractedSize,
    reduction: ((1 - extractedSize / traditionalSize) * 100).toFixed(1),
  };
}

// =============================================================================
// Main
// =============================================================================

function main() {
  const args = process.argv.slice(2);
  let scales = ['small', 'medium'];

  // Parse arguments
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--scale') {
      const scale = args[++i];
      if (SCALES[scale]) {
        scales = [scale];
      } else if (scale === 'all') {
        scales = Object.keys(SCALES);
      }
    }
  }

  console.log('\n╔════════════════════════════════════════════════════════════╗');
  console.log('║         CSS Utilities Benchmark                            ║');
  console.log('╚════════════════════════════════════════════════════════════╝');

  const results = [];
  for (const scale of scales) {
    results.push(runBenchmark(scale, SCALES[scale]));
  }

  // Final summary
  console.log('\n' + '='.repeat(60));
  console.log('SUMMARY');
  console.log('='.repeat(60));
  console.log('');
  console.log('Scale      | Components | Traditional | Utility  | Reduction');
  console.log('-----------|------------|-------------|----------|----------');
  for (const r of results) {
    const scale = r.scale.padEnd(10);
    const comps = String(r.components).padEnd(10);
    const trad = formatBytes(r.traditionalSize).padEnd(11);
    const util = formatBytes(r.extractedSize).padEnd(8);
    console.log(`${scale} | ${comps} | ${trad} | ${util} | ${r.reduction}%`);
  }
  console.log('');
}

main();
