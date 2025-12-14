#!/usr/bin/env node
/**
 * Unified Coverage Tool
 *
 * Merges coverage from multiple sources using source maps:
 * - MoonBit: Native coverage from `moon test --enable-coverage`
 * - Vitest: Istanbul coverage from `vitest --coverage`
 * - Playwright: V8 coverage from browser tests
 *
 * Usage: node scripts/coverage-unified.ts [command]
 * Commands:
 *   report (default) - Generate console report
 *   html             - Generate HTML coverage report
 */

import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import {
  createDefaultConfig,
  loadSourceMaps,
  destroySourceMaps,
  parseMoonbitCoverage,
  parseVitestCoverage,
  parseE2ECoverage,
  mergeCoverage,
  reportToConsole,
  reportToHtml,
} from "./lib/cov-reporter/index.ts";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");

// Project-specific pattern to extract relative paths from absolute source paths
const PROJECT_PATTERN = /.*luna\.mbt\//;

async function main() {
  const command = process.argv[2] || "report";
  const config = createDefaultConfig(PROJECT_ROOT);

  console.log("🔍 Loading coverage data...\n");

  // Load source maps
  const sourceMaps = await loadSourceMaps(config.sourceMapDir);
  console.log(`  Loaded ${sourceMaps.size} source maps`);

  // Parse coverage from all sources
  console.log("\n📥 Parsing coverage sources:");

  const moonbit = await parseMoonbitCoverage(config);
  console.log(`  MoonBit: ${moonbit.size} files`);

  const vitest = await parseVitestCoverage(config, sourceMaps, PROJECT_PATTERN);
  console.log(`  Vitest: ${vitest.size} .mbt files mapped`);

  const e2e = await parseE2ECoverage(config, sourceMaps, PROJECT_PATTERN);
  console.log(`  E2E: ${e2e.size} .mbt files mapped`);

  // Cleanup source maps
  destroySourceMaps(sourceMaps);

  // Check if we have any data
  if (moonbit.size === 0 && vitest.size === 0 && e2e.size === 0) {
    console.log("\n❌ No coverage data found. Run:");
    console.log("   just coverage-moonbit  # MoonBit unit tests");
    console.log("   just coverage-vitest   # Vitest tests");
    console.log("   just coverage-e2e      # E2E browser tests");
    process.exit(1);
  }

  // Merge coverage
  console.log("\n🔀 Merging coverage data...");
  const merged = mergeCoverage(moonbit, vitest, e2e);
  console.log(`   Total: ${merged.size} .mbt files`);

  // Generate reports
  reportToConsole(merged);

  if (command === "html") {
    const outputPath = await reportToHtml(
      merged,
      config,
      "Luna Unified Coverage Report"
    );
    console.log(`\n✅ HTML report: ${outputPath}`);
  }
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
