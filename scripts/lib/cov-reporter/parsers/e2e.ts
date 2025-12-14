/**
 * E2E Playwright V8 coverage parser with source map support
 */

import { readFile, readdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, basename } from "node:path";
import type { SourceMapConsumer } from "source-map";
import type { FileCoverage, CoverageConfig } from "../types.ts";

export async function parseE2ECoverage(
  config: CoverageConfig,
  sourceMaps: Map<string, SourceMapConsumer>,
  projectPattern: RegExp
): Promise<Map<string, FileCoverage>> {
  const e2eDir = join(config.coverageDir, "e2e-v8");
  if (!existsSync(e2eDir)) {
    return new Map();
  }

  const jsonFiles = (await readdir(e2eDir)).filter((f) => f.endsWith(".json"));
  if (jsonFiles.length === 0) {
    return new Map();
  }

  const files = new Map<string, FileCoverage>();

  for (const jsonFile of jsonFiles) {
    const content = await readFile(join(e2eDir, jsonFile), "utf-8");
    const entries = JSON.parse(content);

    for (const entry of entries) {
      const url = entry.url as string;

      let sourceMap: SourceMapConsumer | undefined;
      for (const [mapPath, sm] of sourceMaps) {
        const mapName = basename(mapPath, ".js");
        if (url.includes(mapName)) {
          sourceMap = sm;
          break;
        }
      }

      if (!sourceMap) continue;

      for (const fn of entry.functions || []) {
        for (const range of fn.ranges || []) {
          const roughLine = Math.floor(range.startOffset / 50) + 1;

          const original = sourceMap.originalPositionFor({
            line: roughLine,
            column: 0,
          });

          if (
            original.source &&
            original.line &&
            original.source.includes(".mbt")
          ) {
            const relPath = original.source.replace(projectPattern, "");

            if (config.include && !config.include.test(relPath)) continue;
            if (config.exclude && config.exclude.test(relPath)) continue;

            if (!files.has(relPath)) {
              files.set(relPath, { path: relPath, lines: [] });
            }

            const file = files.get(relPath)!;
            const existing = file.lines.find((l) => l.line === original.line);
            if (existing) {
              existing.count = Math.max(existing.count, range.count);
            } else {
              file.lines.push({ line: original.line, count: range.count });
            }
          }
        }
      }
    }
  }

  return files;
}
