/**
 * Vitest Istanbul coverage parser with source map support
 */

import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, basename } from "node:path";
import type { SourceMapConsumer } from "source-map";
import type { FileCoverage, CoverageConfig } from "../types.ts";

export async function parseVitestCoverage(
  config: CoverageConfig,
  sourceMaps: Map<string, SourceMapConsumer>,
  projectPattern: RegExp
): Promise<Map<string, FileCoverage>> {
  const vitestFile = join(config.coverageDir, "vitest/coverage-final.json");
  if (!existsSync(vitestFile)) {
    return new Map();
  }

  const content = await readFile(vitestFile, "utf-8");
  const data = JSON.parse(content);
  const files = new Map<string, FileCoverage>();

  for (const [jsPath, fileCov] of Object.entries(data)) {
    const coverage = fileCov as any;

    let sourceMap: SourceMapConsumer | undefined;
    for (const [mapPath, sm] of sourceMaps) {
      if (jsPath.includes(basename(mapPath, ".js.map"))) {
        sourceMap = sm;
        break;
      }
    }

    if (!sourceMap) continue;

    const statementMap = coverage.statementMap || {};
    const s = coverage.s || {};

    for (const [stmtId, stmt] of Object.entries(statementMap)) {
      const stmtInfo = stmt as { start: { line: number; column: number } };
      const count = s[stmtId] || 0;

      const original = sourceMap.originalPositionFor({
        line: stmtInfo.start.line,
        column: stmtInfo.start.column,
      });

      if (original.source && original.line && original.source.includes(".mbt")) {
        const relPath = original.source.replace(projectPattern, "");

        if (config.include && !config.include.test(relPath)) continue;
        if (config.exclude && config.exclude.test(relPath)) continue;

        if (!files.has(relPath)) {
          files.set(relPath, { path: relPath, lines: [] });
        }

        const file = files.get(relPath)!;
        const existing = file.lines.find((l) => l.line === original.line);
        if (existing) {
          existing.count = Math.max(existing.count, count);
        } else {
          file.lines.push({ line: original.line, count });
        }
      }
    }
  }

  return files;
}
