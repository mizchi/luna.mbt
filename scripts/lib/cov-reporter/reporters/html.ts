/**
 * HTML coverage reporter
 */

import { readFile, mkdir, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";
import type { FileCoverage, CoverageConfig } from "../types.ts";
import { calculateStats } from "../merge.ts";

export async function reportToHtml(
  coverage: Map<string, FileCoverage>,
  config: CoverageConfig,
  title = "Coverage Report"
): Promise<string> {
  const stats = calculateStats(coverage);

  // Load source files for display
  for (const file of coverage.values()) {
    const fullPath = join(config.projectRoot, file.path);
    if (existsSync(fullPath)) {
      file.source = await readFile(fullPath, "utf-8");
    }
  }

  const fileRows = [...coverage.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([path, file]) => {
      const covered = file.lines.filter((l) => l.count > 0).length;
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

      const lineSet = new Map(file.lines.map((l) => [l.line, l.count]));
      const sourceLines = file.source
        .split("\n")
        .map((content, idx) => {
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
        })
        .join("\n");

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
  <title>${title}</title>
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
    <h1>📊 ${title}</h1>
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

  const outputDir = join(config.coverageDir, "unified");
  const outputPath = join(outputDir, "index.html");

  await mkdir(outputDir, { recursive: true });
  await writeFile(outputPath, html);

  return outputPath;
}
