/**
 * Unified Coverage Tool
 * Merges coverage from multiple sources using source maps
 *
 * Sources:
 * - MoonBit: Native coverage from `moon test --enable-coverage`
 * - Vitest: Istanbul coverage from `vitest --coverage`
 * - Playwright: V8 coverage from browser tests
 *
 * Uses source maps to map JS coverage back to .mbt source files
 *
 * Usage: node scripts/coverage-unified.ts [command]
 * Commands:
 *   collect   - Run all coverage tests and collect data
 *   report    - Generate unified report from existing data
 *   html      - Generate HTML coverage report
 */

import { readdir, readFile, mkdir, writeFile } from "node:fs/promises";
import { join, dirname, basename, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
import { SourceMapConsumer } from "source-map";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");
const COVERAGE_DIR = join(PROJECT_ROOT, "coverage");
const SOURCE_MAP_DIR = join(PROJECT_ROOT, "target/js/debug/build");

// Types
interface LineCoverage {
  line: number;
  count: number;
}

interface FileCoverage {
  path: string;           // Relative path from project root
  lines: LineCoverage[];
  source?: string;        // Source content for HTML report
}

interface UnifiedCoverage {
  timestamp: string;
  sources: {
    moonbit: boolean;
    vitest: boolean;
    e2e: boolean;
  };
  files: Map<string, FileCoverage>;
}

// Parse MoonBit cobertura coverage
async function parseMoonbitCoverage(): Promise<Map<string, FileCoverage>> {
  const coberturaFile = join(COVERAGE_DIR, "moonbit-coverage.xml");
  if (!existsSync(coberturaFile)) {
    console.log("  MoonBit coverage not found");
    return new Map();
  }

  const content = await readFile(coberturaFile, "utf-8");
  const files = new Map<string, FileCoverage>();

  // Parse class elements (each class = one file)
  const classRegex = /<class[^>]*filename="([^"]+)"[^>]*>([\s\S]*?)<\/class>/g;
  let classMatch;

  while ((classMatch = classRegex.exec(content)) !== null) {
    const filename = classMatch[1];
    const classContent = classMatch[2];

    // Only include project source files (src/*)
    if (!filename.startsWith("src/")) continue;

    const lines: LineCoverage[] = [];

    // Parse line elements
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

  console.log(`  MoonBit: ${files.size} files`);
  return files;
}

// Load all source maps from debug build
async function loadSourceMaps(): Promise<Map<string, SourceMapConsumer>> {
  const maps = new Map<string, SourceMapConsumer>();

  if (!existsSync(SOURCE_MAP_DIR)) {
    console.log("  No source maps found (run: moon build --target js -g)");
    return maps;
  }

  async function scanDir(dir: string) {
    const entries = await readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = join(dir, entry.name);
      if (entry.isDirectory()) {
        await scanDir(fullPath);
      } else if (entry.name.endsWith(".js.map")) {
        const content = await readFile(fullPath, "utf-8");
        const rawMap = JSON.parse(content);
        const consumer = await new SourceMapConsumer(rawMap);
        const jsFile = fullPath.replace(".map", "");
        maps.set(jsFile, consumer);
      }
    }
  }

  await scanDir(SOURCE_MAP_DIR);
  console.log(`  Loaded ${maps.size} source maps`);
  return maps;
}

// Parse Vitest Istanbul coverage and map to .mbt files
async function parseVitestCoverage(
  sourceMaps: Map<string, SourceMapConsumer>
): Promise<Map<string, FileCoverage>> {
  const vitestFile = join(COVERAGE_DIR, "vitest/coverage-final.json");
  if (!existsSync(vitestFile)) {
    console.log("  Vitest coverage not found");
    return new Map();
  }

  const content = await readFile(vitestFile, "utf-8");
  const data = JSON.parse(content);
  const files = new Map<string, FileCoverage>();

  for (const [jsPath, fileCov] of Object.entries(data)) {
    const coverage = fileCov as any;

    // Find matching source map
    let sourceMap: SourceMapConsumer | undefined;
    for (const [mapPath, sm] of sourceMaps) {
      if (jsPath.includes(basename(mapPath, ".js.map"))) {
        sourceMap = sm;
        break;
      }
    }

    if (!sourceMap) continue;

    // Map statement coverage to original lines
    const statementMap = coverage.statementMap || {};
    const s = coverage.s || {};

    for (const [stmtId, stmt] of Object.entries(statementMap)) {
      const stmtInfo = stmt as { start: { line: number; column: number } };
      const count = s[stmtId] || 0;

      // Map JS position to original source
      const original = sourceMap.originalPositionFor({
        line: stmtInfo.start.line,
        column: stmtInfo.start.column,
      });

      if (original.source && original.line && original.source.includes(".mbt")) {
        const relPath = original.source.replace(/.*luna\.mbt\//, "");

        // Only include project source files (src/*)
        if (!relPath.startsWith("src/")) continue;

        if (!files.has(relPath)) {
          files.set(relPath, { path: relPath, lines: [] });
        }

        const file = files.get(relPath)!;
        const existing = file.lines.find(l => l.line === original.line);
        if (existing) {
          existing.count = Math.max(existing.count, count);
        } else {
          file.lines.push({ line: original.line, count });
        }
      }
    }
  }

  console.log(`  Vitest: ${files.size} .mbt files mapped`);
  return files;
}

// Parse E2E V8 coverage and map to .mbt files
async function parseE2ECoverage(
  sourceMaps: Map<string, SourceMapConsumer>
): Promise<Map<string, FileCoverage>> {
  const e2eDir = join(COVERAGE_DIR, "e2e-v8");
  if (!existsSync(e2eDir)) {
    console.log("  E2E coverage not found");
    return new Map();
  }

  const jsonFiles = (await readdir(e2eDir)).filter(f => f.endsWith(".json"));
  if (jsonFiles.length === 0) {
    console.log("  E2E coverage: no files");
    return new Map();
  }

  const files = new Map<string, FileCoverage>();

  for (const jsonFile of jsonFiles) {
    const content = await readFile(join(e2eDir, jsonFile), "utf-8");
    const entries = JSON.parse(content);

    for (const entry of entries) {
      const url = entry.url as string;

      // Find matching source map
      let sourceMap: SourceMapConsumer | undefined;
      for (const [mapPath, sm] of sourceMaps) {
        const mapName = basename(mapPath, ".js");
        if (url.includes(mapName)) {
          sourceMap = sm;
          break;
        }
      }

      if (!sourceMap) continue;

      // Parse V8 coverage ranges
      for (const fn of entry.functions || []) {
        for (const range of fn.ranges || []) {
          // V8 gives byte offsets, we need to convert to line numbers
          // This is a simplified approach - for accurate mapping we'd need
          // to parse the JS file and compute line numbers from offsets

          // For now, use startOffset as a rough line estimate
          const roughLine = Math.floor(range.startOffset / 50) + 1;

          const original = sourceMap.originalPositionFor({
            line: roughLine,
            column: 0,
          });

          if (original.source && original.line && original.source.includes(".mbt")) {
            const relPath = original.source.replace(/.*luna\.mbt\//, "");

            // Only include project source files (src/*)
            if (!relPath.startsWith("src/")) continue;

            if (!files.has(relPath)) {
              files.set(relPath, { path: relPath, lines: [] });
            }

            const file = files.get(relPath)!;
            const existing = file.lines.find(l => l.line === original.line);
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

  console.log(`  E2E: ${files.size} .mbt files mapped`);
  return files;
}

// Merge coverage from all sources
function mergeCoverage(
  moonbit: Map<string, FileCoverage>,
  vitest: Map<string, FileCoverage>,
  e2e: Map<string, FileCoverage>
): Map<string, FileCoverage> {
  const merged = new Map<string, FileCoverage>();

  // Helper to merge into result
  function addCoverage(source: Map<string, FileCoverage>) {
    for (const [path, coverage] of source) {
      if (!merged.has(path)) {
        merged.set(path, { path, lines: [] });
      }

      const target = merged.get(path)!;
      for (const line of coverage.lines) {
        const existing = target.lines.find(l => l.line === line.line);
        if (existing) {
          existing.count = Math.max(existing.count, line.count);
        } else {
          target.lines.push({ ...line });
        }
      }
    }
  }

  addCoverage(moonbit);
  addCoverage(vitest);
  addCoverage(e2e);

  // Sort lines
  for (const file of merged.values()) {
    file.lines.sort((a, b) => a.line - b.line);
  }

  return merged;
}

// Calculate coverage statistics
function calculateStats(files: Map<string, FileCoverage>) {
  let totalLines = 0;
  let coveredLines = 0;

  for (const file of files.values()) {
    totalLines += file.lines.length;
    coveredLines += file.lines.filter(l => l.count > 0).length;
  }

  return {
    files: files.size,
    totalLines,
    coveredLines,
    rate: totalLines > 0 ? (coveredLines / totalLines) * 100 : 0,
  };
}

// Generate summary report
async function generateReport(coverage: Map<string, FileCoverage>) {
  const stats = calculateStats(coverage);

  console.log("\n" + "─".repeat(70));
  console.log("📊 Unified Coverage Report");
  console.log("─".repeat(70));

  console.log(`\nOverall: ${stats.rate.toFixed(1)}% (${stats.coveredLines}/${stats.totalLines} lines in ${stats.files} files)`);

  console.log("\n📁 Per-directory breakdown:");

  // Group by directory
  const byDir = new Map<string, { covered: number; total: number }>();
  for (const file of coverage.values()) {
    const dir = dirname(file.path);
    if (!byDir.has(dir)) {
      byDir.set(dir, { covered: 0, total: 0 });
    }
    const dirStats = byDir.get(dir)!;
    dirStats.total += file.lines.length;
    dirStats.covered += file.lines.filter(l => l.count > 0).length;
  }

  const sortedDirs = [...byDir.entries()].sort((a, b) => a[0].localeCompare(b[0]));
  for (const [dir, dirStats] of sortedDirs) {
    const rate = dirStats.total > 0 ? (dirStats.covered / dirStats.total) * 100 : 0;
    const icon = rate >= 80 ? "🟢" : rate >= 50 ? "🟡" : "🔴";
    console.log(`  ${icon} ${dir.padEnd(40)} ${rate.toFixed(1).padStart(5)}% (${dirStats.covered}/${dirStats.total})`);
  }

  console.log("─".repeat(70));
}

// Generate HTML report
async function generateHtmlReport(coverage: Map<string, FileCoverage>) {
  const stats = calculateStats(coverage);

  // Load source files for display
  for (const file of coverage.values()) {
    const fullPath = join(PROJECT_ROOT, file.path);
    if (existsSync(fullPath)) {
      file.source = await readFile(fullPath, "utf-8");
    }
  }

  const fileRows = [...coverage.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([path, file]) => {
      const covered = file.lines.filter(l => l.count > 0).length;
      const total = file.lines.length;
      const rate = total > 0 ? (covered / total) * 100 : 0;
      const cls = rate >= 80 ? "good" : rate >= 50 ? "ok" : "bad";
      return `<tr>
        <td><a href="#${path.replace(/[^a-zA-Z0-9]/g, "_")}">${path}</a></td>
        <td class="${cls}">${rate.toFixed(1)}%</td>
        <td>${covered}</td>
        <td>${total}</td>
      </tr>`;
    })
    .join("\n");

  const fileDetails = [...coverage.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([path, file]) => {
      if (!file.source) return "";

      const lineSet = new Map(file.lines.map(l => [l.line, l.count]));
      const sourceLines = file.source.split("\n").map((content, idx) => {
        const lineNum = idx + 1;
        const count = lineSet.get(lineNum);
        let cls = "";
        if (count !== undefined) {
          cls = count > 0 ? "covered" : "uncovered";
        }
        const escaped = content
          .replace(/&/g, "&amp;")
          .replace(/</g, "&lt;")
          .replace(/>/g, "&gt;");
        return `<tr class="${cls}"><td class="line-num">${lineNum}</td><td class="count">${count ?? ""}</td><td class="code"><pre>${escaped}</pre></td></tr>`;
      }).join("\n");

      return `
        <div class="file-section" id="${path.replace(/[^a-zA-Z0-9]/g, "_")}">
          <h3>${path}</h3>
          <table class="source-code">${sourceLines}</table>
        </div>
      `;
    })
    .join("\n");

  const html = `<!DOCTYPE html>
<html>
<head>
  <title>Luna Unified Coverage Report</title>
  <style>
    * { box-sizing: border-box; }
    body { font-family: system-ui, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
    .summary { background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    table { width: 100%; border-collapse: collapse; background: white; }
    th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #eee; }
    th { background: #f9f9f9; font-weight: 600; }
    .good { color: #16a34a; }
    .ok { color: #ca8a04; }
    .bad { color: #dc2626; }
    .file-section { background: white; margin: 20px 0; border-radius: 8px; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .file-section h3 { margin: 0; padding: 12px 16px; background: #f9f9f9; border-bottom: 1px solid #eee; font-size: 14px; }
    .source-code { font-family: 'Monaco', 'Menlo', monospace; font-size: 12px; }
    .source-code td { padding: 0 8px; vertical-align: top; }
    .source-code pre { margin: 0; white-space: pre-wrap; }
    .line-num { color: #999; text-align: right; width: 40px; user-select: none; }
    .count { color: #666; text-align: right; width: 40px; }
    .covered { background: #dcfce7; }
    .uncovered { background: #fee2e2; }
    .code { width: 100%; }
    a { color: #2563eb; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class="summary">
    <h1>📊 Luna Unified Coverage Report</h1>
    <p>Generated: ${new Date().toISOString()}</p>
    <p><strong>Overall Coverage: ${stats.rate.toFixed(1)}%</strong> (${stats.coveredLines}/${stats.totalLines} lines in ${stats.files} files)</p>
  </div>

  <div class="summary">
    <h2>Files</h2>
    <table>
      <tr><th>File</th><th>Coverage</th><th>Covered</th><th>Total</th></tr>
      ${fileRows}
    </table>
  </div>

  <h2>Source Files</h2>
  ${fileDetails}
</body>
</html>`;

  await mkdir(join(COVERAGE_DIR, "unified"), { recursive: true });
  await writeFile(join(COVERAGE_DIR, "unified/index.html"), html);
  console.log(`\n✅ HTML report: coverage/unified/index.html`);
}

// Main
async function main() {
  const command = process.argv[2] || "report";

  console.log("🔍 Loading coverage data...\n");

  // Load source maps
  const sourceMaps = await loadSourceMaps();

  // Parse coverage from all sources
  console.log("\n📥 Parsing coverage sources:");
  const moonbit = await parseMoonbitCoverage();
  const vitest = await parseVitestCoverage(sourceMaps);
  const e2e = await parseE2ECoverage(sourceMaps);

  // Cleanup source maps
  for (const sm of sourceMaps.values()) {
    sm.destroy();
  }

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
  await generateReport(merged);

  if (command === "html") {
    await generateHtmlReport(merged);
  }
}

main().catch((err) => {
  console.error("Error:", err);
  process.exit(1);
});
