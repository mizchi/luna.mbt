/**
 * Console coverage reporter
 */

import type { FileCoverage } from "../types.ts";
import { calculateStats, calculateDirectoryStats } from "../merge.ts";

export function reportToConsole(coverage: Map<string, FileCoverage>): void {
  const stats = calculateStats(coverage);

  console.log("\n" + "─".repeat(70));
  console.log("📊 Unified Coverage Report");
  console.log("─".repeat(70));

  console.log(
    `\nOverall: ${stats.rate.toFixed(1)}% (${stats.coveredLines}/${stats.totalLines} lines in ${stats.files} files)`
  );

  console.log("\n📁 Per-directory breakdown:");

  const byDir = calculateDirectoryStats(coverage);
  const sortedDirs = [...byDir.entries()].sort((a, b) =>
    a[0].localeCompare(b[0])
  );

  for (const [dir, dirStats] of sortedDirs) {
    const rate =
      dirStats.total > 0 ? (dirStats.covered / dirStats.total) * 100 : 0;
    const icon = rate >= 80 ? "🟢" : rate >= 50 ? "🟡" : "🔴";
    console.log(
      `  ${icon} ${dir.padEnd(40)} ${rate.toFixed(1).padStart(5)}% (${dirStats.covered}/${dirStats.total})`
    );
  }

  console.log("─".repeat(70));
}
