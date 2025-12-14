/**
 * MoonBit Cobertura coverage parser
 */

import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";
import type { FileCoverage, LineCoverage, CoverageConfig } from "../types.ts";

export async function parseMoonbitCoverage(
  config: CoverageConfig
): Promise<Map<string, FileCoverage>> {
  const coberturaFile = join(config.coverageDir, "moonbit-coverage.xml");
  if (!existsSync(coberturaFile)) {
    return new Map();
  }

  const content = await readFile(coberturaFile, "utf-8");
  const files = new Map<string, FileCoverage>();

  const classRegex = /<class[^>]*filename="([^"]+)"[^>]*>([\s\S]*?)<\/class>/g;
  let classMatch;

  while ((classMatch = classRegex.exec(content)) !== null) {
    const filename = classMatch[1];
    const classContent = classMatch[2];

    if (config.include && !config.include.test(filename)) continue;
    if (config.exclude && config.exclude.test(filename)) continue;

    const lines: LineCoverage[] = [];

    const lineRegex = /<line number="(\d+)" hits="(\d+)"[^>]*\/>/g;
    let lineMatch;
    while ((lineMatch = lineRegex.exec(classContent)) !== null) {
      lines.push({
        line: parseInt(lineMatch[1]),
        count: parseInt(lineMatch[2]),
      });
    }

    if (lines.length > 0) {
      files.set(filename, { path: filename, lines });
    }
  }

  return files;
}
