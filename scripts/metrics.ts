/**
 * Build Metrics Tracker - Local development metrics using node:sqlite
 * Usage: node scripts/metrics.ts <command> [options]
 *
 * Commands:
 *   record              Record build time and bundle sizes
 *   bench               Run benchmarks and record results
 *   report [n]          Show last N records (default: 10)
 *   compare [hash]      Compare current with specific commit
 *   trend [metric]      Show trend for a metric
 *   clean               Remove old records (keep last 100)
 */

import { DatabaseSync } from "node:sqlite";
import { execSync, spawnSync } from "node:child_process";
import { statSync, existsSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");
const DB_PATH = join(PROJECT_ROOT, ".metrics.db");

// === Database Setup ===

function getDb(): DatabaseSync {
  const db = new DatabaseSync(DB_PATH);

  // Create tables if not exist
  db.exec(`
    CREATE TABLE IF NOT EXISTS builds (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp TEXT NOT NULL,
      git_hash TEXT,
      git_branch TEXT,
      build_time_ms REAL,
      clean_build INTEGER DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS bundle_sizes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      build_id INTEGER NOT NULL,
      file_path TEXT NOT NULL,
      size_bytes INTEGER NOT NULL,
      FOREIGN KEY (build_id) REFERENCES builds(id)
    );

    CREATE TABLE IF NOT EXISTS benchmarks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      build_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      total_ms REAL NOT NULL,
      ops_per_ms REAL,
      iterations INTEGER,
      FOREIGN KEY (build_id) REFERENCES builds(id)
    );

    CREATE INDEX IF NOT EXISTS idx_builds_timestamp ON builds(timestamp);
    CREATE INDEX IF NOT EXISTS idx_builds_git_hash ON builds(git_hash);
    CREATE INDEX IF NOT EXISTS idx_benchmarks_name ON benchmarks(name);
  `);

  return db;
}

// === Git Helpers ===

function getGitHash(): string {
  try {
    return execSync("git rev-parse --short HEAD", { cwd: PROJECT_ROOT, encoding: "utf-8" }).trim();
  } catch {
    return "unknown";
  }
}

function getGitBranch(): string {
  try {
    return execSync("git branch --show-current", { cwd: PROJECT_ROOT, encoding: "utf-8" }).trim();
  } catch {
    return "unknown";
  }
}

// === File Size Helpers ===

interface FileSize {
  path: string;
  size: number;
}

const TRACKED_FILES = [
  "packages/loader/ln-loader-v1.js",
  "packages/loader/loader.min.js",
  "target/js/release/build/lib/api_js/api_js.js",
  "target/js/release/build/platform/dom/element/element.js",
  "target/js/release/build/renderer/renderer.js",
  "target/js/release/build/renderer/shard/shard.js",
  "target/js/release/build/sol/cli/cli.js",
];

function getFileSizes(): FileSize[] {
  const sizes: FileSize[] = [];
  for (const file of TRACKED_FILES) {
    const fullPath = join(PROJECT_ROOT, file);
    if (existsSync(fullPath)) {
      sizes.push({
        path: file,
        size: statSync(fullPath).size,
      });
    }
  }
  return sizes;
}

// === Build & Measure ===

function measureBuild(clean: boolean = false): number {
  if (clean) {
    execSync("moon clean", { cwd: PROJECT_ROOT, stdio: "inherit" });
  }

  const start = performance.now();
  execSync("moon build --target js", { cwd: PROJECT_ROOT, stdio: "inherit" });
  return performance.now() - start;
}

// === Benchmark Runner ===

interface BenchResult {
  name: string;
  totalMs: number;
  opsPerMs: number;
  iterations: number;
}

function runBenchmarks(): BenchResult[] {
  const results: BenchResult[] = [];

  // Run bench/run.js and parse output
  const output = execSync("node bench/run.js", {
    cwd: PROJECT_ROOT,
    encoding: "utf-8",
    stdio: ["pipe", "pipe", "pipe"]
  });

  // Parse output: "name: 123.45ms total, 0.1234ms/op"
  const regex = /^(.+?):\s+([\d.]+)ms total,\s+([\d.]+)ms\/op$/gm;
  let match;
  while ((match = regex.exec(output)) !== null) {
    const [, name, totalMs, msPerOp] = match;
    results.push({
      name: name.trim(),
      totalMs: parseFloat(totalMs),
      opsPerMs: 1 / parseFloat(msPerOp),
      iterations: 1000, // default from bench/run.js
    });
  }

  return results;
}

// === Commands ===

function cmdRecord(options: { clean?: boolean; bench?: boolean }) {
  const db = getDb();

  console.log("📊 Recording metrics...\n");

  // Build
  console.log(options.clean ? "🔨 Clean build..." : "🔨 Incremental build...");
  const buildTime = measureBuild(options.clean);
  console.log(`   Build time: ${buildTime.toFixed(0)}ms\n`);

  // Insert build record
  const stmt = db.prepare(`
    INSERT INTO builds (timestamp, git_hash, git_branch, build_time_ms, clean_build)
    VALUES (?, ?, ?, ?, ?)
  `);
  const result = stmt.run(
    new Date().toISOString(),
    getGitHash(),
    getGitBranch(),
    buildTime,
    options.clean ? 1 : 0
  );
  const buildId = result.lastInsertRowid;

  // Record file sizes
  console.log("📦 Recording bundle sizes...");
  const sizes = getFileSizes();
  const sizeStmt = db.prepare(`
    INSERT INTO bundle_sizes (build_id, file_path, size_bytes)
    VALUES (?, ?, ?)
  `);
  for (const { path, size } of sizes) {
    sizeStmt.run(buildId, path, size);
    console.log(`   ${path}: ${formatBytes(size)}`);
  }

  // Optional: run benchmarks
  if (options.bench) {
    console.log("\n⏱️  Running benchmarks...");
    const benchResults = runBenchmarks();
    const benchStmt = db.prepare(`
      INSERT INTO benchmarks (build_id, name, total_ms, ops_per_ms, iterations)
      VALUES (?, ?, ?, ?, ?)
    `);
    for (const b of benchResults) {
      benchStmt.run(buildId, b.name, b.totalMs, b.opsPerMs, b.iterations);
    }
    console.log(`   Recorded ${benchResults.length} benchmark results`);
  }

  console.log("\n✅ Metrics recorded");
  db.close();
}

function cmdReport(limit: number = 10) {
  const db = getDb();

  const builds = db.prepare(`
    SELECT id, timestamp, git_hash, git_branch, build_time_ms, clean_build
    FROM builds
    ORDER BY timestamp DESC
    LIMIT ?
  `).all(limit) as any[];

  if (builds.length === 0) {
    console.log("No records found. Run 'node scripts/metrics.ts record' first.");
    db.close();
    return;
  }

  console.log("📊 Recent Builds\n");
  console.log("─".repeat(80));

  for (const build of builds) {
    const date = new Date(build.timestamp).toLocaleString();
    const cleanTag = build.clean_build ? " [clean]" : "";
    console.log(`${build.git_hash} (${build.git_branch}) - ${date}${cleanTag}`);
    console.log(`  Build: ${build.build_time_ms.toFixed(0)}ms`);

    // Get sizes for this build
    const sizes = db.prepare(`
      SELECT file_path, size_bytes FROM bundle_sizes WHERE build_id = ?
    `).all(build.id) as any[];

    if (sizes.length > 0) {
      console.log("  Sizes:");
      for (const s of sizes) {
        const shortPath = s.file_path.replace("target/js/release/build/", "");
        console.log(`    ${shortPath}: ${formatBytes(s.size_bytes)}`);
      }
    }
    console.log("");
  }

  db.close();
}

function cmdCompare(targetHash?: string) {
  const db = getDb();

  // Get current (latest) build
  const current = db.prepare(`
    SELECT * FROM builds ORDER BY timestamp DESC LIMIT 1
  `).get() as any;

  if (!current) {
    console.log("No current build found.");
    db.close();
    return;
  }

  // Get target build
  let target: any;
  if (targetHash) {
    target = db.prepare(`
      SELECT * FROM builds WHERE git_hash LIKE ? ORDER BY timestamp DESC LIMIT 1
    `).get(`${targetHash}%`);
  } else {
    // Compare with second latest
    target = db.prepare(`
      SELECT * FROM builds ORDER BY timestamp DESC LIMIT 1 OFFSET 1
    `).get();
  }

  if (!target) {
    console.log("No target build found for comparison.");
    db.close();
    return;
  }

  console.log(`📊 Comparing builds\n`);
  console.log(`Current: ${current.git_hash} (${current.git_branch})`);
  console.log(`Target:  ${target.git_hash} (${target.git_branch})\n`);

  // Build time comparison
  const buildDiff = current.build_time_ms - target.build_time_ms;
  const buildPct = ((buildDiff / target.build_time_ms) * 100).toFixed(1);
  const buildIcon = buildDiff > 0 ? "🔴" : buildDiff < 0 ? "🟢" : "⚪";
  console.log(`Build Time: ${current.build_time_ms.toFixed(0)}ms vs ${target.build_time_ms.toFixed(0)}ms (${buildIcon} ${buildDiff > 0 ? "+" : ""}${buildPct}%)`);

  // Size comparison
  const currentSizes = db.prepare(`
    SELECT file_path, size_bytes FROM bundle_sizes WHERE build_id = ?
  `).all(current.id) as any[];

  const targetSizes = db.prepare(`
    SELECT file_path, size_bytes FROM bundle_sizes WHERE build_id = ?
  `).all(target.id) as any[];

  const targetSizeMap = new Map(targetSizes.map((s: any) => [s.file_path, s.size_bytes]));

  console.log("\nBundle Sizes:");
  for (const s of currentSizes) {
    const targetSize = targetSizeMap.get(s.file_path);
    if (targetSize !== undefined) {
      const diff = s.size_bytes - targetSize;
      const pct = ((diff / targetSize) * 100).toFixed(1);
      const icon = diff > 0 ? "🔴" : diff < 0 ? "🟢" : "⚪";
      const shortPath = s.file_path.replace("target/js/release/build/", "");
      console.log(`  ${shortPath}: ${formatBytes(s.size_bytes)} vs ${formatBytes(targetSize)} (${icon} ${diff > 0 ? "+" : ""}${pct}%)`);
    }
  }

  // Benchmark comparison
  const currentBench = db.prepare(`
    SELECT name, total_ms FROM benchmarks WHERE build_id = ?
  `).all(current.id) as any[];

  const targetBench = db.prepare(`
    SELECT name, total_ms FROM benchmarks WHERE build_id = ?
  `).all(target.id) as any[];

  if (currentBench.length > 0 && targetBench.length > 0) {
    const targetBenchMap = new Map(targetBench.map((b: any) => [b.name, b.total_ms]));

    console.log("\nBenchmarks:");
    for (const b of currentBench) {
      const targetMs = targetBenchMap.get(b.name);
      if (targetMs !== undefined) {
        const diff = b.total_ms - targetMs;
        const pct = ((diff / targetMs) * 100).toFixed(1);
        const icon = diff > 0 ? "🔴" : diff < 0 ? "🟢" : "⚪";
        console.log(`  ${b.name}: ${b.total_ms.toFixed(2)}ms vs ${targetMs.toFixed(2)}ms (${icon} ${diff > 0 ? "+" : ""}${pct}%)`);
      }
    }
  }

  db.close();
}

function cmdTrend(metric: string = "build_time") {
  const db = getDb();

  console.log(`📈 Trend: ${metric}\n`);

  if (metric === "build_time") {
    const builds = db.prepare(`
      SELECT git_hash, timestamp, build_time_ms
      FROM builds
      ORDER BY timestamp DESC
      LIMIT 20
    `).all() as any[];

    if (builds.length === 0) {
      console.log("No data found.");
      db.close();
      return;
    }

    const max = Math.max(...builds.map(b => b.build_time_ms));
    const barWidth = 40;

    for (const b of builds.reverse()) {
      const barLen = Math.round((b.build_time_ms / max) * barWidth);
      const bar = "█".repeat(barLen) + "░".repeat(barWidth - barLen);
      console.log(`${b.git_hash} │${bar}│ ${b.build_time_ms.toFixed(0)}ms`);
    }
  } else {
    // Assume it's a file path pattern
    const sizes = db.prepare(`
      SELECT b.git_hash, b.timestamp, s.size_bytes
      FROM bundle_sizes s
      JOIN builds b ON s.build_id = b.id
      WHERE s.file_path LIKE ?
      ORDER BY b.timestamp DESC
      LIMIT 20
    `).all(`%${metric}%`) as any[];

    if (sizes.length === 0) {
      console.log(`No data found for metric: ${metric}`);
      db.close();
      return;
    }

    const max = Math.max(...sizes.map(s => s.size_bytes));
    const barWidth = 40;

    for (const s of sizes.reverse()) {
      const barLen = Math.round((s.size_bytes / max) * barWidth);
      const bar = "█".repeat(barLen) + "░".repeat(barWidth - barLen);
      console.log(`${s.git_hash} │${bar}│ ${formatBytes(s.size_bytes)}`);
    }
  }

  db.close();
}

function cmdClean(keep: number = 100) {
  const db = getDb();

  // Get IDs to delete
  const toDelete = db.prepare(`
    SELECT id FROM builds
    ORDER BY timestamp DESC
    LIMIT -1 OFFSET ?
  `).all(keep) as any[];

  if (toDelete.length === 0) {
    console.log("Nothing to clean.");
    db.close();
    return;
  }

  const ids = toDelete.map(r => r.id);

  db.exec(`DELETE FROM benchmarks WHERE build_id IN (${ids.join(",")})`);
  db.exec(`DELETE FROM bundle_sizes WHERE build_id IN (${ids.join(",")})`);
  db.exec(`DELETE FROM builds WHERE id IN (${ids.join(",")})`);
  db.exec("VACUUM");

  console.log(`🧹 Cleaned ${toDelete.length} old records`);
  db.close();
}

// === Utilities ===

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes}B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
  return `${(bytes / 1024 / 1024).toFixed(2)}MB`;
}

function printHelp() {
  console.log(`
Build Metrics Tracker

Usage: node scripts/metrics.ts <command> [options]

Commands:
  record [--clean] [--bench]  Record build time and bundle sizes
                              --clean: Do a clean build first
                              --bench: Also run benchmarks

  report [n]                  Show last N builds (default: 10)

  compare [hash]              Compare current build with:
                              - specific commit hash, or
                              - previous build if no hash given

  trend [metric]              Show trend graph for:
                              - "build_time" (default)
                              - file path pattern (e.g., "loader")

  clean [n]                   Keep last N records, delete rest (default: 100)

Examples:
  node scripts/metrics.ts record
  node scripts/metrics.ts record --clean --bench
  node scripts/metrics.ts report 5
  node scripts/metrics.ts compare abc123
  node scripts/metrics.ts trend loader.min.js
`);
}

// === Main ===

const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case "record":
    cmdRecord({
      clean: args.includes("--clean"),
      bench: args.includes("--bench"),
    });
    break;
  case "report":
    cmdReport(parseInt(args[1]) || 10);
    break;
  case "compare":
    cmdCompare(args[1]);
    break;
  case "trend":
    cmdTrend(args[1] || "build_time");
    break;
  case "clean":
    cmdClean(parseInt(args[1]) || 100);
    break;
  case "help":
  case "--help":
  case "-h":
    printHelp();
    break;
  default:
    if (command) {
      console.log(`Unknown command: ${command}\n`);
    }
    printHelp();
}
