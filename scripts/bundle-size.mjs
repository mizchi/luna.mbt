#!/usr/bin/env node
import { execa } from "execa";
import { access, readFile, writeFile } from "node:fs/promises";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { gzipSync } from "node:zlib";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");
const LOADER_PACKAGE_DIR = join(PROJECT_ROOT, "js/loader");
const LOADER_PACKAGE_JSON = join(LOADER_PACKAGE_DIR, "package.json");
const STATIC_IMPORT_RE =
  /\bimport\s*(?!\()(?:(?:[\w*\s{},$]+)\s*from\s*)?["']([^"']+)["']/g;
const DYNAMIC_IMPORT_RE = /import\(\s*["']([^"']+)["']\s*\)/gm;

function parseArgs() {
  const argv = process.argv.slice(2);
  const flags = new Set();
  const values = new Map();

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) continue;

    if (arg === "--baseline" || arg === "--report") {
      const value = argv[i + 1];
      if (!value || value.startsWith("--")) {
        throw new Error(`${arg} requires a path`);
      }
      values.set(arg.slice(2), value);
      i += 1;
      continue;
    }
    flags.add(arg);
  }

  return {
    build: flags.has("--build"),
    check: flags.has("--check"),
    strict: flags.has("--strict"),
    json: flags.has("--json"),
    writeBaseline: flags.has("--write-baseline"),
    baseline: values.get("baseline"),
    report: values.get("report"),
  };
}

function normalizePath(path) {
  return path.replaceAll("\\", "/");
}

function formatBytes(bytes) {
  return `${bytes.toString().padStart(6, " ")} B`;
}

async function ensureBuild() {
  await execa("pnpm", ["--filter", "@luna_ui/luna-loader", "build"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
}

async function loadEntries() {
  const raw = await readFile(LOADER_PACKAGE_JSON, "utf8");
  const pkg = JSON.parse(raw);
  const exportsMap = pkg.exports || {};
  const entries = [];
  const skipped = [];

  for (const [exportKey, target] of Object.entries(exportsMap)) {
    if (typeof target !== "string") continue;
    if (!target.startsWith("./dist/") || !target.endsWith(".js")) continue;

    const id = exportKey === "." ? "main" : exportKey.replace(/^\.\//, "");
    const file = join(LOADER_PACKAGE_DIR, target.replace(/^\.\//, ""));

    try {
      await access(file);
    } catch {
      skipped.push({
        id,
        exportKey,
        file: normalizePath(relative(PROJECT_ROOT, file)),
      });
      continue;
    }

    entries.push({ id, exportKey, file });
  }

  return {
    entries: entries.sort((a, b) => a.id.localeCompare(b.id)),
    skipped: skipped.sort((a, b) => a.id.localeCompare(b.id)),
  };
}

async function writeReport(path, lines) {
  await writeFile(path, lines.join("\n") + "\n", "utf8");
}

function collectDiffs(expectedEntries, actualEntries, options = {}) {
  const strict = options.strict === true;
  const expected = new Map(expectedEntries.map((entry) => [entry.id, entry]));
  const actual = new Map(actualEntries.map((entry) => [entry.id, entry]));
  const diffs = [];

  for (const [id, exp] of expected) {
    const act = actual.get(id);
    if (!act) {
      diffs.push({ id, reason: "missing", exp });
      continue;
    }

    if (strict) {
      if (
        exp.bytes !== act.bytes ||
        exp.gzip !== act.gzip ||
        exp.file !== act.file ||
        exp.exportKey !== act.exportKey
      ) {
        diffs.push({ id, reason: "changed", exp, act });
      }
      continue;
    }

    if (act.bytes > exp.bytes || act.gzip > exp.gzip) {
      diffs.push({ id, reason: "regressed", exp, act });
    }
  }

  for (const [id, act] of actual) {
    if (!expected.has(id)) {
      diffs.push({ id, reason: "unexpected", act });
    }
  }

  return diffs;
}

function collectImprovements(expectedEntries, actualEntries) {
  const expected = new Map(expectedEntries.map((entry) => [entry.id, entry]));
  const improvements = [];

  for (const act of actualEntries) {
    const exp = expected.get(act.id);
    if (!exp) continue;

    const bytesDelta = act.bytes - exp.bytes;
    const gzipDelta = act.gzip - exp.gzip;

    if (bytesDelta < 0 || gzipDelta < 0) {
      improvements.push({
        id: act.id,
        exp,
        act,
        bytesDelta,
        gzipDelta,
      });
    }
  }

  return improvements;
}

async function readModuleInfo(file, cache) {
  const cached = cache.get(file);
  if (cached) return cached;

  const source = await readFile(file, "utf8");
  const buffer = Buffer.from(source, "utf8");
  const imports = [];

  const importSpecifiers = new Set();

  for (const match of source.matchAll(STATIC_IMPORT_RE)) {
    importSpecifiers.add(match[1]);
  }

  for (const match of source.matchAll(DYNAMIC_IMPORT_RE)) {
    importSpecifiers.add(match[1]);
  }

  for (const specifier of importSpecifiers) {
    if (!specifier.startsWith(".")) continue;
    imports.push(resolve(dirname(file), specifier));
  }

  const info = {
    bytes: buffer.byteLength,
    gzip: gzipSync(buffer).byteLength,
    imports,
  };
  cache.set(file, info);
  return info;
}

async function collectClosure(entryFile, cache) {
  const visited = new Set();
  const stack = [entryFile];

  while (stack.length > 0) {
    const current = stack.pop();
    if (!current || visited.has(current)) continue;
    visited.add(current);

    const info = await readModuleInfo(current, cache);
    for (const dep of info.imports) {
      try {
        await access(dep);
        stack.push(dep);
      } catch {
        // Ignore unresolved relative imports to keep checks stable.
      }
    }
  }

  return Array.from(visited).sort();
}

async function measureEntryWithClosure(entry, cache) {
  const files = await collectClosure(entry.file, cache);
  let bytes = 0;
  let gzip = 0;

  for (const file of files) {
    const info = await readModuleInfo(file, cache);
    bytes += info.bytes;
    gzip += info.gzip;
  }

  return {
    id: entry.id,
    exportKey: entry.exportKey,
    file: normalizePath(relative(PROJECT_ROOT, entry.file)),
    files: files.map((file) => normalizePath(relative(PROJECT_ROOT, file))),
    bytes,
    gzip,
  };
}

async function main() {
  const args = parseArgs();
  const baselinePath = args.baseline
    ? join(PROJECT_ROOT, args.baseline)
    : join(__dirname, "bundle-baseline.json");

  if (args.build) {
    console.log("building @luna_ui/luna-loader...");
    await ensureBuild();
  }

  const { entries, skipped } = await loadEntries();
  const moduleCache = new Map();
  const results = await Promise.all(
    entries.map((entry) => measureEntryWithClosure(entry, moduleCache))
  );

  if (results.length === 0) {
    const lines = ["ERROR no measurable dist entries were found for @luna_ui/luna-loader"];
    if (args.report) await writeReport(args.report, lines);
    console.log("\n" + lines.join("\n"));
    process.exit(1);
  }

  if (skipped.length > 0) {
    console.log("\nWARN skipped missing dist exports");
    for (const entry of skipped) {
      console.log(`  ${entry.id}: ${entry.file}`);
    }
  }

  if (args.writeBaseline) {
    const data = {
      generatedAt: new Date().toISOString(),
      entries: results.map((entry) => ({
        id: entry.id,
        exportKey: entry.exportKey,
        file: entry.file,
        files: entry.files,
        bytes: entry.bytes,
        gzip: entry.gzip,
      })),
    };
    await writeFile(baselinePath, JSON.stringify(data, null, 2) + "\n", "utf8");
    console.log(`\nbaseline written: ${baselinePath}`);
  }

  if (args.check) {
    let baselineData;
    try {
      baselineData = JSON.parse(await readFile(baselinePath, "utf8"));
    } catch (error) {
      const lines = [
        `ERROR Bundle baseline not found: ${normalizePath(relative(PROJECT_ROOT, baselinePath))}`,
        "Run: just bundle-baseline",
      ];
      if (args.report) await writeReport(args.report, lines);
      console.log("\n" + lines.join("\n"));
      process.exit(1);
    }

    const expectedEntries = baselineData.entries || [];
    const diffs = collectDiffs(expectedEntries, results, { strict: args.strict });
    if (diffs.length > 0) {
      const lines = ["ERROR Bundle baseline mismatch:"];
      for (const diff of diffs) {
        if (diff.reason === "changed" || diff.reason === "regressed") {
          const bytesDelta = diff.act.bytes - diff.exp.bytes;
          const gzipDelta = diff.act.gzip - diff.exp.gzip;
          lines.push(
            `  ${diff.id}: ${diff.exp.bytes} -> ${diff.act.bytes} (${bytesDelta >= 0 ? "+" : ""}${bytesDelta}), ` +
              `gzip ${diff.exp.gzip} -> ${diff.act.gzip} (${gzipDelta >= 0 ? "+" : ""}${gzipDelta})`
          );
        } else if (diff.reason === "missing") {
          lines.push(`  ${diff.id}: missing in current results`);
        } else {
          lines.push(`  ${diff.id}: unexpected entry`);
        }
      }
      if (args.report) await writeReport(args.report, lines);
      console.log("\n" + lines.join("\n"));
      process.exit(1);
    }

    const lines = args.strict
      ? ["OK Bundle baseline matches (strict)"]
      : ["OK Bundle size regression check passed"];
    if (args.report) await writeReport(args.report, lines);
    console.log(`\n${lines[0]}`);

    if (!args.strict) {
      const improvements = collectImprovements(expectedEntries, results);
      if (improvements.length > 0) {
        console.log("\nINFO size improvements detected (baseline update optional):");
        for (const item of improvements) {
          console.log(
            `  ${item.id}: ${item.exp.bytes} -> ${item.act.bytes} (${item.bytesDelta}), ` +
              `gzip ${item.exp.gzip} -> ${item.act.gzip} (${item.gzipDelta})`
          );
        }
      }
    }
  }

  if (args.json) {
    console.log(JSON.stringify(results, null, 2));
    return;
  }

  console.log("\nBundle size baseline (minified / gzip)");
  for (const entry of results) {
    const depLabel =
      entry.files.length > 1 ? ` (+${entry.files.length - 1} deps)` : "";
    console.log(
      `${entry.id.padEnd(14, " ")} ${formatBytes(entry.bytes)} / ${formatBytes(entry.gzip)}  ${entry.file}${depLabel}`
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
