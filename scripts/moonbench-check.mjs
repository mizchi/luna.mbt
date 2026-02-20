#!/usr/bin/env node
import { execa } from "execa";
import { readFile, writeFile } from "node:fs/promises";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");

const UNIT_TO_NS = {
  ns: 1,
  "µs": 1_000,
  ms: 1_000_000,
  s: 1_000_000_000,
};

const SUITES = [
  {
    id: "core/render",
    cmd: [
      "moon",
      "bench",
      "--target",
      "js",
      "-p",
      "mizchi/luna/core/render",
      "-f",
      "render_bench.mbt",
      "-i",
      "0-8",
    ],
    include: new Set([
      "render: list (10 items)",
      "render: large_list (100 items with escape)",
      "render: page",
    ]),
  },
  {
    id: "core/serialize",
    cmd: [
      "moon",
      "bench",
      "--target",
      "js",
      "-p",
      "mizchi/luna/core/serialize",
      "-f",
      "serialize_bench.mbt",
      "-i",
      "0-6",
    ],
    include: new Set([
      "state_value_to_json: large_array",
    ]),
  },
];

function parseArgs() {
  const argv = process.argv.slice(2);
  const flags = new Set();
  const values = new Map();

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) continue;

    if (
      arg === "--baseline" ||
      arg === "--report" ||
      arg === "--tolerance" ||
      arg === "--rounds"
    ) {
      const value = argv[i + 1];
      if (!value || value.startsWith("--")) {
        throw new Error(`${arg} requires a value`);
      }
      values.set(arg.slice(2), value);
      i += 1;
      continue;
    }
    flags.add(arg);
  }

  const tolerance = values.has("tolerance")
    ? Number(values.get("tolerance"))
    : 0.35;
  const rounds = values.has("rounds") ? Number(values.get("rounds")) : 2;
  if (!Number.isFinite(tolerance) || tolerance < 0) {
    throw new Error("--tolerance must be a non-negative number");
  }
  if (!Number.isInteger(rounds) || rounds <= 0) {
    throw new Error("--rounds must be an integer > 0");
  }

  return {
    check: flags.has("--check"),
    writeBaseline: flags.has("--write-baseline"),
    json: flags.has("--json"),
    baseline: values.get("baseline"),
    report: values.get("report"),
    tolerance,
    rounds,
  };
}

function toNs(value, unit) {
  const factor = UNIT_TO_NS[unit];
  if (!factor) {
    throw new Error(`unsupported unit: ${unit}`);
  }
  return value * factor;
}

function formatNs(ns) {
  if (ns < 1_000) return `${ns.toFixed(2)} ns`;
  if (ns < 1_000_000) return `${(ns / 1_000).toFixed(2)} µs`;
  return `${(ns / 1_000_000).toFixed(2)} ms`;
}

function parseBenchOutput(output, suiteId) {
  const lines = output.split(/\r?\n/);
  const results = [];
  let currentName = null;

  for (const line of lines) {
    const benchMatch = line.match(/^\[.+\]\s+bench\s+.+\("(.+)"\)\s+ok$/);
    if (benchMatch) {
      currentName = benchMatch[1];
      continue;
    }

    if (!currentName) continue;
    const meanMatch = line.match(/^\s*([0-9.]+)\s*(ns|µs|ms|s)\s*±/);
    if (meanMatch) {
      const value = Number(meanMatch[1]);
      const unit = meanMatch[2];
      results.push({
        suite: suiteId,
        name: currentName,
        nsPerOp: toNs(value, unit),
      });
      currentName = null;
    }
  }

  return results;
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0
    ? (sorted[mid - 1] + sorted[mid]) / 2
    : sorted[mid];
}

async function runSuite(suite, rounds) {
  const [cmd, ...args] = suite.cmd;
  const samples = new Map();

  for (let i = 0; i < rounds; i += 1) {
    const { stdout } = await execa(cmd, args, {
      cwd: PROJECT_ROOT,
      all: true,
    });
    const parsed = parseBenchOutput(stdout, suite.id).filter((entry) =>
      suite.include.has(entry.name)
    );
    for (const entry of parsed) {
      const id = `${entry.suite}/${entry.name}`;
      if (!samples.has(id)) {
        samples.set(id, {
          suite: entry.suite,
          name: entry.name,
          values: [],
        });
      }
      samples.get(id).values.push(entry.nsPerOp);
    }
  }

  const results = [];
  for (const sample of samples.values()) {
    results.push({
      suite: sample.suite,
      name: sample.name,
      nsPerOp: median(sample.values),
    });
  }
  return results;
}

function collectDiffs(expectedEntries, actualEntries, tolerance) {
  const expected = new Map(expectedEntries.map((entry) => [entry.id, entry]));
  const actual = new Map(actualEntries.map((entry) => [entry.id, entry]));
  const diffs = [];

  for (const [id, exp] of expected) {
    const act = actual.get(id);
    if (!act) {
      diffs.push({ id, reason: "missing", exp });
      continue;
    }
    const allowed = exp.nsPerOp * (1 + tolerance);
    if (act.nsPerOp > allowed) {
      diffs.push({ id, reason: "regressed", exp, act, allowed });
    }
  }

  for (const [id, act] of actual) {
    if (!expected.has(id)) {
      diffs.push({ id, reason: "unexpected", act });
    }
  }
  return diffs;
}

async function writeReport(path, lines) {
  await writeFile(path, lines.join("\n") + "\n", "utf8");
}

async function main() {
  const args = parseArgs();
  const baselinePath = args.baseline
    ? join(PROJECT_ROOT, args.baseline)
    : join(__dirname, "moonbench-baseline.json");

  const rawResults = [];
  for (const suite of SUITES) {
    const suiteResults = await runSuite(suite, args.rounds);
    rawResults.push(...suiteResults);
  }

  const results = rawResults
    .map((entry) => ({
      id: `${entry.suite}/${entry.name}`,
      suite: entry.suite,
      name: entry.name,
      nsPerOp: Number(entry.nsPerOp.toFixed(2)),
    }))
    .sort((a, b) => a.id.localeCompare(b.id));

  if (args.writeBaseline) {
    const data = {
      generatedAt: new Date().toISOString(),
      node: process.version,
      platform: process.platform,
      arch: process.arch,
      rounds: args.rounds,
      entries: results,
    };
    await writeFile(baselinePath, JSON.stringify(data, null, 2) + "\n", "utf8");
    console.log(`baseline written: ${baselinePath}`);
  }

  if (args.check) {
    let baselineData;
    try {
      baselineData = JSON.parse(await readFile(baselinePath, "utf8"));
    } catch {
      const lines = [
        `ERROR Moon bench baseline not found: ${relative(PROJECT_ROOT, baselinePath)}`,
        "Run: just moonbench-baseline",
      ];
      if (args.report) {
        await writeReport(args.report, lines);
      }
      console.log("\n" + lines.join("\n"));
      process.exit(1);
    }

    const diffs = collectDiffs(baselineData.entries || [], results, args.tolerance);
    if (diffs.length > 0) {
      const lines = [
        `ERROR Moon bench regression (tolerance ${(args.tolerance * 100).toFixed(1)}%):`,
      ];
      for (const diff of diffs) {
        if (diff.reason === "regressed") {
          const delta = diff.act.nsPerOp - diff.exp.nsPerOp;
          const deltaPct = (delta / diff.exp.nsPerOp) * 100;
          lines.push(
            `  ${diff.id}: ${formatNs(diff.exp.nsPerOp)} -> ${formatNs(diff.act.nsPerOp)} (+${formatNs(delta)}, +${deltaPct.toFixed(1)}%), allowed <= ${formatNs(diff.allowed)}`
          );
        } else if (diff.reason === "missing") {
          lines.push(`  ${diff.id}: missing in current results`);
        } else {
          lines.push(`  ${diff.id}: unexpected entry`);
        }
      }
      if (args.report) {
        await writeReport(args.report, lines);
      }
      console.log("\n" + lines.join("\n"));
      process.exit(1);
    }

    const lines = [
      `OK Moon bench regression check passed (tolerance ${(args.tolerance * 100).toFixed(1)}%)`,
    ];
    if (args.report) {
      await writeReport(args.report, lines);
    }
    console.log("\n" + lines.join("\n"));
  }

  if (args.json) {
    console.log(JSON.stringify(results, null, 2));
    return;
  }

  console.log("\nMoon bench baseline (mean ns/op)");
  for (const entry of results) {
    console.log(`${entry.id.padEnd(72, " ")} ${formatNs(entry.nsPerOp)}`);
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
