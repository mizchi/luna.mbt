#!/usr/bin/env node
import { build } from "esbuild";
import { execa } from "execa";
import { gzipSync } from "node:zlib";
import { mkdtemp, rm, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");
const DIST_DIR = join(PROJECT_ROOT, "js/luna/dist");

const ENTRIES = [
  {
    id: "signals-only",
    contents: `import { createSignal } from "./signals.js";\nconst [count, setCount] = createSignal(0);\nsetCount(count() + 1);\n`,
  },
  {
    id: "signals-effect",
    contents: `import { createSignal, createEffect } from "./signals.js";\nconst [count, setCount] = createSignal(0);\ncreateEffect(() => { console.log(count()); });\nsetCount(1);\n`,
  },
  {
    id: "memo",
    contents: `import { createSignal, createMemo } from "./signals.js";\nconst [count, setCount] = createSignal(0);\nconst doubled = createMemo(() => count() * 2);\nconsole.log(doubled());\nsetCount(1);\n`,
  },
  {
    id: "render",
    contents: `import { render, text, createElement } from "./index.js";\nconst app = () => createElement("div", null, [text("hello")]);\nrender(app, document.body);\n`,
  },
  {
    id: "router-resource",
    contents: `import { createRouter, routePage, routerNavigate, createResource, createContext, useContext } from "./index.js";\nconst router = createRouter([routePage("/", () => "home")], { base: "/" });\nrouterNavigate(router, "/");\nconst ctx = createContext("default");\nuseContext(ctx);\ncreateResource(async () => 1);\n`,
  },
];

function parseArgs() {
  const argv = process.argv.slice(2);
  const flags = new Set();
  const values = new Map();
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg.startsWith("--")) {
      if (arg === "--baseline") {
        const value = argv[i + 1];
        if (!value || value.startsWith("--")) {
          throw new Error("--baseline requires a path");
        }
        values.set("baseline", value);
        i += 1;
      } else if (arg === "--report") {
        const value = argv[i + 1];
        if (!value || value.startsWith("--")) {
          throw new Error("--report requires a path");
        }
        values.set("report", value);
        i += 1;
      } else {
        flags.add(arg);
      }
    }
  }
  return {
    build: flags.has("--build"),
    json: flags.has("--json"),
    keepTemp: flags.has("--keep-temp"),
    writeBaseline: flags.has("--write-baseline"),
    check: flags.has("--check"),
    baseline: values.get("baseline"),
    report: values.get("report"),
  };
}

function formatBytes(bytes) {
  return `${bytes.toString().padStart(6, " ")} B`;
}

async function ensureBuild() {
  await execa("moon", ["build", "--target", "js"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
  await execa("pnpm", ["--filter", "@luna_ui/luna", "build"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
}

async function buildEntry(tempDir, entry) {
  const outfile = join(tempDir, `${entry.id}.js`);
  const result = await build({
    stdin: {
      contents: entry.contents,
      resolveDir: DIST_DIR,
      sourcefile: `${entry.id}.js`,
    },
    bundle: true,
    minify: true,
    format: "esm",
    platform: "browser",
    treeShaking: true,
    write: false,
    outfile,
    metafile: true,
  });

  const output = result.outputFiles[0].contents;
  const gzip = gzipSync(output);
  const outputKey = Object.keys(result.metafile.outputs)[0];
  const metaOut = result.metafile.outputs[outputKey];
  const inputs = Object.entries(metaOut.inputs)
    .map(([path, info]) => ({ path, bytes: info.bytesInOutput || 0 }))
    .sort((a, b) => b.bytes - a.bytes);

  return {
    id: entry.id,
    bytes: output.byteLength,
    gzip: gzip.byteLength,
    inputs,
  };
}

async function main() {
  const { build, json, keepTemp, writeBaseline, check, baseline, report } =
    parseArgs();
  const baselinePath = baseline
    ? join(PROJECT_ROOT, baseline)
    : join(__dirname, "treeshake-baseline.json");
  if (build) {
    console.log("🔧 building MoonBit + @luna_ui/luna...");
    await ensureBuild();
  }

  const tempDir = await mkdtemp(join(tmpdir(), "luna-treeshake-"));
  const results = [];

  for (const entry of ENTRIES) {
    const res = await buildEntry(tempDir, entry);
    results.push(res);
  }

  if (!keepTemp) {
    await rm(tempDir, { recursive: true, force: true });
  }

  if (writeBaseline) {
    const data = {
      generatedAt: new Date().toISOString(),
      entries: results.map((r) => ({ id: r.id, bytes: r.bytes, gzip: r.gzip })),
    };
    await writeFile(baselinePath, JSON.stringify(data, null, 2) + "\n", "utf8");
    console.log(`\n✅ baseline written: ${baselinePath}`);
  }

  if (check) {
    const raw = await readFile(baselinePath, "utf8");
    const baselineData = JSON.parse(raw);
    const expected = new Map(
      (baselineData.entries || []).map((e) => [e.id, e])
    );
    const actual = new Map(results.map((r) => [r.id, r]));
    const diffs = [];

    for (const [id, exp] of expected) {
      const act = actual.get(id);
      if (!act) {
        diffs.push({ id, reason: "missing", exp });
        continue;
      }
      if (act.bytes !== exp.bytes || act.gzip !== exp.gzip) {
        diffs.push({ id, reason: "changed", exp, act });
      }
    }
    for (const [id, act] of actual) {
      if (!expected.has(id)) {
        diffs.push({ id, reason: "unexpected", act });
      }
    }

    if (diffs.length > 0) {
      const lines = ["❌ Treeshake baseline mismatch:"];
      for (const diff of diffs) {
        if (diff.reason === "changed") {
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
      if (report) {
        await writeFile(report, lines.join("\n") + "\n", "utf8");
      }
      console.log("\n" + lines.join("\n"));
      process.exit(1);
    } else {
      if (report) {
        await writeFile(
          report,
          "✅ Treeshake baseline matches\n",
          "utf8"
        );
      }
      console.log("\n✅ Treeshake baseline matches");
    }
  }

  if (json) {
    console.log(JSON.stringify(results, null, 2));
    return;
  }

  console.log("\nTreeshake size baseline (minified / gzip)");
  for (const r of results) {
    const mainInput = r.inputs[0];
    const inputLabel = mainInput ? `${mainInput.path}` : "-";
    console.log(
      `${r.id.padEnd(16, " ")} ${formatBytes(r.bytes)} / ${formatBytes(r.gzip)}  ${inputLabel}`
    );
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
