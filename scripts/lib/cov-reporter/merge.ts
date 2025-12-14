/**
 * Coverage merging utilities
 */

import type { FileCoverage, CoverageStats, DirectoryStats } from "./types.ts";
import { dirname } from "node:path";

export function mergeCoverage(
  ...sources: Map<string, FileCoverage>[]
): Map<string, FileCoverage> {
  const merged = new Map<string, FileCoverage>();

  for (const source of sources) {
    for (const [path, coverage] of source) {
      if (!merged.has(path)) {
        merged.set(path, { path, lines: [] });
      }

      const target = merged.get(path)!;
      for (const line of coverage.lines) {
        const existing = target.lines.find((l) => l.line === line.line);
        if (existing) {
          existing.count = Math.max(existing.count, line.count);
        } else {
          target.lines.push({ ...line });
        }
      }
    }
  }

  for (const file of merged.values()) {
    file.lines.sort((a, b) => a.line - b.line);
  }

  return merged;
}

export function calculateStats(
  files: Map<string, FileCoverage>
): CoverageStats {
  let totalLines = 0;
  let coveredLines = 0;

  for (const file of files.values()) {
    totalLines += file.lines.length;
    coveredLines += file.lines.filter((l) => l.count > 0).length;
  }

  return {
    files: files.size,
    totalLines,
    coveredLines,
    rate: totalLines > 0 ? (coveredLines / totalLines) * 100 : 0,
  };
}

export function calculateDirectoryStats(
  files: Map<string, FileCoverage>
): Map<string, DirectoryStats> {
  const byDir = new Map<string, DirectoryStats>();

  for (const file of files.values()) {
    const dir = dirname(file.path);
    if (!byDir.has(dir)) {
      byDir.set(dir, { covered: 0, total: 0 });
    }
    const dirStats = byDir.get(dir)!;
    dirStats.total += file.lines.length;
    dirStats.covered += file.lines.filter((l) => l.count > 0).length;
  }

  return byDir;
}
