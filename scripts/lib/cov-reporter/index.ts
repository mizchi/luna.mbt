/**
 * Unified Coverage Library
 *
 * Merges coverage from multiple sources using source maps.
 * Supports MoonBit, Vitest (Istanbul), and Playwright (V8) coverage formats.
 *
 * @example
 * ```ts
 * import {
 *   createDefaultConfig,
 *   loadSourceMaps,
 *   destroySourceMaps,
 *   parseMoonbitCoverage,
 *   parseVitestCoverage,
 *   parseE2ECoverage,
 *   mergeCoverage,
 *   reportToConsole,
 *   reportToHtml,
 * } from "./lib/coverage/index.ts";
 *
 * const config = createDefaultConfig(projectRoot);
 * const sourceMaps = await loadSourceMaps(config.sourceMapDir);
 *
 * const moonbit = await parseMoonbitCoverage(config);
 * const vitest = await parseVitestCoverage(config, sourceMaps, /.*myproject\//);
 * const e2e = await parseE2ECoverage(config, sourceMaps, /.*myproject\//);
 *
 * destroySourceMaps(sourceMaps);
 *
 * const merged = mergeCoverage(moonbit, vitest, e2e);
 * reportToConsole(merged);
 * await reportToHtml(merged, config, "My Coverage Report");
 * ```
 */

// Types
export type {
  LineCoverage,
  FileCoverage,
  CoverageStats,
  DirectoryStats,
  CoverageConfig,
} from "./types.ts";
export { createDefaultConfig } from "./types.ts";

// Source map utilities
export { loadSourceMaps, destroySourceMaps } from "./sourcemap.ts";

// Parsers
export { parseMoonbitCoverage } from "./parsers/moonbit.ts";
export { parseVitestCoverage } from "./parsers/vitest.ts";
export { parseE2ECoverage } from "./parsers/e2e.ts";

// Merge utilities
export {
  mergeCoverage,
  calculateStats,
  calculateDirectoryStats,
} from "./merge.ts";

// Reporters
export { reportToConsole } from "./reporters/console.ts";
export { reportToHtml } from "./reporters/html.ts";
