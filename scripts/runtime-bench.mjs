#!/usr/bin/env node
import { execa } from "execa";
import { access, readFile, writeFile } from "node:fs/promises";
import { dirname, join, relative } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");
const SIGNALS_DIST = join(PROJECT_ROOT, "js/luna/dist/signals.js");
const CONTROL_SCENARIO_ID = "control-loop";

/**
 * @typedef {{
 *   id: string;
 *   iterations: number;
 *   run: (mod: any, iterations: number) => number;
 * }} Scenario
 */

/** @type {Scenario[]} */
const SCENARIOS = [
  {
    id: CONTROL_SCENARIO_ID,
    iterations: 1_000_000,
    run(_mod, iterations) {
      let x = 1;
      for (let i = 0; i < iterations; i += 1) {
        x = (Math.imul(x, 1_664_525) + 1_013_904_223) | 0;
        x ^= x >>> 7;
        x = (Math.imul(x, 1_103_515_245) + 12_345) | 0;
      }
      consumeSink(x);
      return iterations;
    },
  },
  {
    id: "signal-set-get",
    iterations: 500_000,
    run(mod, iterations) {
      const [get, set] = mod.createSignal(0);
      let sink = 0;
      for (let i = 0; i < iterations; i += 1) {
        set(i);
        sink += get();
      }
      consumeSink(sink);
      return iterations;
    },
  },
  {
    id: "signal-update-fn",
    iterations: 250_000,
    run(mod, iterations) {
      const [get, set] = mod.createSignal(0);
      for (let i = 0; i < iterations; i += 1) {
        set((prev) => prev + 1);
      }
      consumeSink(get());
      return iterations;
    },
  },
  {
    id: "memo-after-update",
    iterations: 200_000,
    run(mod, iterations) {
      const [get, set] = mod.createSignal(1);
      const memo = mod.createMemo(() => get() * 2);
      let sink = 0;
      for (let i = 0; i < iterations; i += 1) {
        set(i);
        sink += memo();
      }
      consumeSink(sink);
      return iterations;
    },
  },
  {
    id: "batch-10-updates",
    iterations: 200_000,
    run(mod, iterations) {
      const [get, set] = mod.createSignal(0);
      const rounds = Math.floor(iterations / 10);
      let sink = 0;
      for (let i = 0; i < rounds; i += 1) {
        mod.batch(() => {
          for (let j = 0; j < 10; j += 1) {
            set((prev) => prev + 1);
          }
        });
        sink += get();
      }
      consumeSink(sink);
      return rounds * 10;
    },
  },
  {
    id: "create-signal",
    iterations: 100_000,
    run(mod, iterations) {
      let sink = 0;
      for (let i = 0; i < iterations; i += 1) {
        const [get, set] = mod.createSignal(i);
        set(i + 1);
        sink += get();
      }
      consumeSink(sink);
      return iterations;
    },
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
      arg === "--warmup" ||
      arg === "--samples"
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
    : 0.2;
  const warmup = values.has("warmup") ? Number(values.get("warmup")) : 3;
  const samples = values.has("samples") ? Number(values.get("samples")) : 9;

  if (!Number.isFinite(tolerance) || tolerance < 0) {
    throw new Error("--tolerance must be a non-negative number");
  }
  if (!Number.isInteger(warmup) || warmup < 0) {
    throw new Error("--warmup must be an integer >= 0");
  }
  if (!Number.isInteger(samples) || samples <= 0) {
    throw new Error("--samples must be an integer > 0");
  }

  return {
    build: flags.has("--build"),
    check: flags.has("--check"),
    json: flags.has("--json"),
    writeBaseline: flags.has("--write-baseline"),
    baseline: values.get("baseline"),
    report: values.get("report"),
    tolerance,
    warmup,
    samples,
  };
}

async function ensureBuild() {
  await execa("moon", ["build", "--target", "js", "--release", "src"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
  await execa("moon", ["build", "--target", "js", "--release", "src/js/api"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
  await execa("moon", ["build", "--target", "js", "--release", "src/js/api_signals"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
  await execa("moon", ["build", "--target", "js", "--release", "src/js/api_resource"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
  await execa("pnpm", ["--filter", "@luna_ui/luna", "build"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
}

function median(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0
    ? (sorted[mid - 1] + sorted[mid]) / 2
    : sorted[mid];
}

function formatNsPerOp(nsPerOp) {
  return `${nsPerOp.toFixed(2).padStart(10, " ")} ns/op`;
}

function formatMops(nsPerOp) {
  const mops = 1_000 / nsPerOp;
  return `${mops.toFixed(2).padStart(8, " ")} Mops/s`;
}

let blackHole = 0;
function consumeSink(value) {
  blackHole = (blackHole + Number(value)) % 1_000_000_007;
}

async function loadSignalsModule() {
  try {
    await access(SIGNALS_DIST);
  } catch {
    throw new Error(
      `signals dist file is missing: ${relative(PROJECT_ROOT, SIGNALS_DIST)}\nRun with --build or execute: pnpm --filter @luna_ui/luna build`
    );
  }
  return import(pathToFileURL(SIGNALS_DIST).href);
}

function runScenario(mod, scenario, options) {
  const { warmup, samples } = options;

  for (let i = 0; i < warmup; i += 1) {
    scenario.run(mod, scenario.iterations);
  }

  const sampleNsPerOp = [];
  let ops = scenario.iterations;
  for (let i = 0; i < samples; i += 1) {
    const start = process.hrtime.bigint();
    ops = scenario.run(mod, scenario.iterations);
    const end = process.hrtime.bigint();
    const elapsedNs = Number(end - start);
    sampleNsPerOp.push(elapsedNs / ops);
  }

  const nsPerOp = median(sampleNsPerOp);
  return {
    id: scenario.id,
    iterations: scenario.iterations,
    ops,
    nsPerOp,
    mops: 1_000 / nsPerOp,
    samples: sampleNsPerOp,
  };
}

function addControlRatio(results) {
  const control = results.find((entry) => entry.id === CONTROL_SCENARIO_ID);
  if (!control) {
    throw new Error(`control scenario is missing: ${CONTROL_SCENARIO_ID}`);
  }
  const controlNsPerOp = control.nsPerOp;
  return results.map((entry) => ({
    ...entry,
    ratioToControl: entry.nsPerOp / controlNsPerOp,
  }));
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

    if (id === CONTROL_SCENARIO_ID) {
      continue;
    }

    const expMetric = exp.ratioToControl ?? exp.nsPerOp;
    const actMetric = act.ratioToControl ?? act.nsPerOp;
    const allowed = expMetric * (1 + tolerance);
    if (actMetric > allowed) {
      diffs.push({
        id,
        reason: "regressed",
        exp,
        act,
        allowed,
        expMetric,
        actMetric,
      });
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
    : join(__dirname, "runtime-bench-baseline.json");

  if (args.build) {
    console.log("building @luna_ui/luna runtime...");
    await ensureBuild();
  }

  const signals = await loadSignalsModule();
  const rawResults = SCENARIOS.map((scenario) =>
    runScenario(signals, scenario, { warmup: args.warmup, samples: args.samples })
  );
  const results = addControlRatio(rawResults);

  if (args.writeBaseline) {
    const data = {
      generatedAt: new Date().toISOString(),
      node: process.version,
      platform: process.platform,
      arch: process.arch,
      warmup: args.warmup,
      samples: args.samples,
      entries: results.map((entry) => ({
        id: entry.id,
        iterations: entry.iterations,
        nsPerOp: Number(entry.nsPerOp.toFixed(4)),
        ratioToControl: Number(entry.ratioToControl.toFixed(4)),
      })),
    };
    await writeFile(baselinePath, JSON.stringify(data, null, 2) + "\n", "utf8");
    console.log(`\nbaseline written: ${baselinePath}`);
  }

  if (args.check) {
    let baselineData;
    try {
      baselineData = JSON.parse(await readFile(baselinePath, "utf8"));
    } catch {
      const lines = [
        `ERROR Runtime baseline not found: ${relative(PROJECT_ROOT, baselinePath)}`,
        "Run: just runtime-baseline",
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
        `ERROR Runtime benchmark mismatch (tolerance ${(args.tolerance * 100).toFixed(1)}%):`,
      ];
      for (const diff of diffs) {
        if (diff.reason === "regressed") {
          const delta = diff.actMetric - diff.expMetric;
          const deltaPct = (delta / diff.expMetric) * 100;
          lines.push(
            `  ${diff.id}: ratio ${diff.expMetric.toFixed(4)} -> ${diff.actMetric.toFixed(4)} (+${delta.toFixed(4)}, +${deltaPct.toFixed(1)}%), allowed <= ${diff.allowed.toFixed(4)}`
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
    } else {
      const lines = [
        `OK Runtime benchmark regression check passed (tolerance ${(args.tolerance * 100).toFixed(1)}%)`,
      ];
      if (args.report) {
        await writeReport(args.report, lines);
      }
      console.log("\n" + lines.join("\n"));
    }
  }

  if (args.json) {
    console.log(
      JSON.stringify(
        {
          warmup: args.warmup,
          samples: args.samples,
          blackHole,
          entries: results,
        },
        null,
        2
      )
    );
    return;
  }

  console.log("\nRuntime benchmark (median)");
  for (const entry of results) {
    console.log(
      `${entry.id.padEnd(18, " ")} ${formatNsPerOp(entry.nsPerOp)}  ${formatMops(entry.nsPerOp)}  ratio=${entry.ratioToControl.toFixed(4)}`
    );
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
