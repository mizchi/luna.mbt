/**
 * Build Metrics Tracker - Essential KPIs only
 * Usage:
 *   node scripts/metrics.ts         Build, collect metrics, show trend
 *   node scripts/metrics.ts show    Show trend only (no build)
 */

import { DatabaseSync } from "node:sqlite";
import { execSync } from "node:child_process";
import { statSync, existsSync, readdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");
const DB_PATH = join(PROJECT_ROOT, ".metrics.db");

// === Database Setup ===

function getDb(): DatabaseSync {
  const db = new DatabaseSync(DB_PATH);

  db.exec(`
    CREATE TABLE IF NOT EXISTS metrics (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp TEXT NOT NULL,
      git_hash TEXT,
      is_dirty INTEGER DEFAULT 0,
      loader_min_size INTEGER,
      spa_bundle_size INTEGER,
      browser_router_bundle_size INTEGER,
      test_time_ms REAL
    );
    CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON metrics(timestamp);
  `);

  // Add is_dirty column if it doesn't exist (migration)
  try {
    db.exec(`ALTER TABLE metrics ADD COLUMN is_dirty INTEGER DEFAULT 0`);
  } catch {
    // Column already exists
  }

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

function isGitDirty(): boolean {
  try {
    const status = execSync("git status --porcelain", { cwd: PROJECT_ROOT, encoding: "utf-8" });
    return status.trim().length > 0;
  } catch {
    return false;
  }
}

// === Measure Functions ===

function getFileSize(relativePath: string): number | null {
  const fullPath = join(PROJECT_ROOT, relativePath);
  if (existsSync(fullPath)) {
    return statSync(fullPath).size;
  }
  return null;
}

function findFileByPattern(dir: string, pattern: RegExp): string | null {
  const fullDir = join(PROJECT_ROOT, dir);
  if (!existsSync(fullDir)) return null;

  const files = readdirSync(fullDir);
  const match = files.find(f => pattern.test(f));
  return match ? join(dir, match) : null;
}

function measureTestTime(): number {
  const start = performance.now();
  execSync("moon test --target js", { cwd: PROJECT_ROOT, stdio: "inherit" });
  return performance.now() - start;
}

// === Utilities ===

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes}B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
  return `${(bytes / 1024 / 1024).toFixed(2)}MB`;
}

function formatMs(ms: number): string {
  if (ms < 1000) return `${ms.toFixed(0)}ms`;
  return `${(ms / 1000).toFixed(2)}s`;
}

// === Cleanup: Keep only latest per commit hash ===

function cleanupDuplicates(db: DatabaseSync) {
  // Keep only the latest record per git_hash, except for dirty (uncommitted) entries
  // Dirty entries are kept as "current" until committed
  db.exec(`
    DELETE FROM metrics
    WHERE id NOT IN (
      SELECT MAX(id)
      FROM metrics
      GROUP BY git_hash, is_dirty
    )
  `);
}

// === Commands ===

function collect() {
  const db = getDb();

  console.log("📊 Collecting metrics...\n");

  // Build MoonBit + Vite
  console.log("🔨 Building MoonBit...");
  execSync("moon build --target js", { cwd: PROJECT_ROOT, stdio: "inherit" });

  console.log("\n🔨 Minifying loader...");
  execSync("pnpm terser js/loader/src/loader.js --module --compress --mangle -o js/loader/loader.min.js", { cwd: PROJECT_ROOT, stdio: "inherit" });

  console.log("\n🔨 Building Vite...");
  execSync("pnpm vite build", { cwd: PROJECT_ROOT, stdio: "inherit" });

  // Get file sizes (use minified loader)
  const loaderSize = getFileSize("js/loader/loader.min.js");

  // Find bundled files with hash in name
  const spaFile = findFileByPattern("dist/assets", /^spa-.*\.js$/);
  const browserAppFile = findFileByPattern("dist/assets/playground", /^browser_router-.*\.js$/);

  const spaSize = spaFile ? getFileSize(spaFile) : null;
  const browserAppSize = browserAppFile ? getFileSize(browserAppFile) : null;

  console.log("\n📦 Bundle sizes:");
  if (loaderSize !== null) {
    console.log(`   loader.min.js: ${formatBytes(loaderSize)}`);
  }
  if (spaSize !== null) {
    console.log(`   spa bundle: ${formatBytes(spaSize)}`);
  }
  if (browserAppSize !== null) {
    console.log(`   browser_router bundle: ${formatBytes(browserAppSize)}`);
  }

  // Run tests and measure time
  console.log("\n⏱️  Running tests...");
  const testTime = measureTestTime();
  console.log(`   Test time: ${formatMs(testTime)}`);

  // Check if working tree is dirty
  const isDirty = isGitDirty();
  const gitHash = getGitHash();

  // Save to database
  const stmt = db.prepare(`
    INSERT INTO metrics (timestamp, git_hash, is_dirty, loader_min_size, spa_bundle_size, browser_router_bundle_size, test_time_ms)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);
  stmt.run(
    new Date().toISOString(),
    gitHash,
    isDirty ? 1 : 0,
    loaderSize,
    spaSize,
    browserAppSize,
    testTime
  );

  // Cleanup old duplicates
  cleanupDuplicates(db);

  console.log("\n✅ Metrics recorded\n");
  db.close();

  // Show trend
  showTrend();
}

function showTrend() {
  const db = getDb();

  // First cleanup duplicates
  cleanupDuplicates(db);

  const records = db.prepare(`
    SELECT git_hash, is_dirty, timestamp, loader_min_size, spa_bundle_size, browser_router_bundle_size, test_time_ms
    FROM metrics
    ORDER BY timestamp DESC
    LIMIT 15
  `).all() as any[];

  if (records.length === 0) {
    console.log("No metrics recorded yet. Run 'node scripts/metrics.ts' to collect.");
    db.close();
    return;
  }

  console.log("📈 Metrics Trend (latest per commit)\n");
  console.log("─".repeat(78));

  // Reverse for chronological display
  const data = records.reverse();

  // Show table header
  console.log("Hash      │ loader.min │ spa        │ browser_router │ test time");
  console.log("──────────┼────────────┼────────────┼─────────────┼────────────");

  for (const r of data) {
    const isDirty = r.is_dirty === 1;
    const hash = isDirty ? "current*" : r.git_hash.substring(0, 7);
    const hashDisplay = hash.padEnd(8);
    const loader = r.loader_min_size ? formatBytes(r.loader_min_size).padStart(7) : "    N/A";
    const spa = r.spa_bundle_size ? formatBytes(r.spa_bundle_size).padStart(7) : "    N/A";
    const browserApp = r.browser_router_bundle_size ? formatBytes(r.browser_router_bundle_size).padStart(8) : "     N/A";
    const test = r.test_time_ms ? formatMs(r.test_time_ms).padStart(8) : "     N/A";

    console.log(`${hashDisplay} │ ${loader}    │ ${spa}    │ ${browserApp}    │ ${test}`);
  }

  // Show summary with change from previous
  if (data.length >= 2) {
    const current = data[data.length - 1];
    const previous = data[data.length - 2];

    console.log("\n" + "─".repeat(78));
    console.log("📊 Latest vs Previous:\n");

    const showDiff = (name: string, curr: number | null, prev: number | null) => {
      if (curr && prev) {
        const diff = curr - prev;
        const pct = ((diff / prev) * 100).toFixed(1);
        const icon = diff > 0 ? "🔴" : diff < 0 ? "🟢" : "⚪";
        console.log(`   ${name}: ${formatBytes(curr)} (${icon} ${diff > 0 ? "+" : ""}${diff}B / ${diff > 0 ? "+" : ""}${pct}%)`);
      }
    };

    showDiff("loader.min.js", current.loader_min_size, previous.loader_min_size);
    showDiff("spa bundle", current.spa_bundle_size, previous.spa_bundle_size);
    showDiff("browser_router bundle", current.browser_router_bundle_size, previous.browser_router_bundle_size);

    if (current.test_time_ms && previous.test_time_ms) {
      const diff = current.test_time_ms - previous.test_time_ms;
      const pct = ((diff / previous.test_time_ms) * 100).toFixed(1);
      const icon = diff > 0 ? "🔴" : diff < 0 ? "🟢" : "⚪";
      console.log(`   test time: ${formatMs(current.test_time_ms)} (${icon} ${diff > 0 ? "+" : ""}${formatMs(Math.abs(diff))} / ${diff > 0 ? "+" : ""}${pct}%)`);
    }
  }

  console.log("\n* current = uncommitted changes");

  db.close();
}

// === Main ===

const command = process.argv[2];

switch (command) {
  case "show":
  case "--show":
  case "-s":
    showTrend();
    break;
  case "help":
  case "--help":
  case "-h":
    console.log(`
Build Metrics Tracker

Usage:
  node scripts/metrics.ts         Build, collect metrics, show trend
  node scripts/metrics.ts show    Show trend only (no build)

Tracked metrics:
  - js/loader/loader.min.js size (minified)
  - dist/assets/spa-*.js bundle size
  - dist/assets/playground/browser_router-*.js bundle size
  - moon test execution time

Data retention:
  - Only the latest record per git commit hash is kept
  - Uncommitted changes are shown as "current*"
`);
    break;
  default:
    collect();
}
