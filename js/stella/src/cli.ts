#!/usr/bin/env node
/**
 * Stella CLI - Web Components generator for Luna
 */

import { parseArgs } from 'node:util';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve, basename } from 'node:path';
import { generateComponentJS, type ComponentConfig } from './codegen.js';

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    help: { type: 'boolean', short: 'h' },
    output: { type: 'string', short: 'o' },
    config: { type: 'string', short: 'c' },
  },
});

function printHelp() {
  console.log(`
Stella CLI - Web Components generator for Luna

Usage:
  stella build <config.json> [options]
  stella init <component-name>

Commands:
  build   Generate Web Component JS from config
  init    Create a new component template

Options:
  -o, --output <path>  Output file path
  -c, --config <path>  Config file path
  -h, --help           Show this help

Examples:
  stella build counter.wc.json -o dist/counter.js
  stella init my-counter
`);
}

async function main() {
  if (values.help || positionals.length === 0) {
    printHelp();
    process.exit(0);
  }

  const command = positionals[0];

  switch (command) {
    case 'build':
      await buildCommand(positionals.slice(1));
      break;
    case 'init':
      await initCommand(positionals.slice(1));
      break;
    default:
      console.error(`Unknown command: ${command}`);
      printHelp();
      process.exit(1);
  }
}

async function buildCommand(args: string[]) {
  const configPath = args[0] || values.config;

  if (!configPath) {
    console.error('Error: Config file path required');
    console.error('Usage: stella build <config.json>');
    process.exit(1);
  }

  const absoluteConfigPath = resolve(process.cwd(), configPath);

  let config: ComponentConfig;
  try {
    const content = readFileSync(absoluteConfigPath, 'utf-8');
    config = JSON.parse(content);
  } catch (e) {
    console.error(`Error reading config file: ${configPath}`);
    console.error(e);
    process.exit(1);
  }

  // Generate JS code
  const js = generateComponentJS(config);

  // Determine output path
  const outputPath = values.output || config.output || configPath.replace(/\.json$/, '.js');
  const absoluteOutputPath = resolve(process.cwd(), outputPath);

  // Ensure output directory exists
  mkdirSync(dirname(absoluteOutputPath), { recursive: true });

  // Write output
  writeFileSync(absoluteOutputPath, js);
  console.log(`Generated: ${outputPath}`);
}

async function initCommand(args: string[]) {
  const name = args[0];

  if (!name) {
    console.error('Error: Component name required');
    console.error('Usage: stella init <component-name>');
    process.exit(1);
  }

  // Convert to tag name (kebab-case)
  const tag = name.includes('-') ? name : `x-${name}`;

  const config: ComponentConfig = {
    tag,
    module: `./${name}.mbt.js`,
    attributes: [
      { name: 'value', type: 'string', default: '' },
    ],
    shadow: 'open',
    styles: `:host { display: block; }`,
  };

  const configPath = `${name}.wc.json`;
  writeFileSync(configPath, JSON.stringify(config, null, 2));
  console.log(`Created: ${configPath}`);

  console.log(`
Next steps:
  1. Edit ${configPath} to define your component
  2. Create the MoonBit module that exports setup() and optionally template()
  3. Run: stella build ${configPath}
`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
