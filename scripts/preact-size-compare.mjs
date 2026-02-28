#!/usr/bin/env node
import { build } from "esbuild";
import { execa } from "execa";
import { gzipSync } from "node:zlib";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { mkdir, writeFile } from "node:fs/promises";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");
const DIST_DIR = join(PROJECT_ROOT, "js/luna/dist");

const CASES = [
  {
    id: "signals-only",
    luna: `import { createSignal } from "./signals.js";\nconst [count, setCount] = createSignal(0);\nsetCount(count() + 1);\n`,
    preact: `import { signal } from "@preact/signals-core";\nconst count = signal(0);\ncount.value = count.value + 1;\n`,
  },
  {
    id: "signals-effect",
    luna: `import { createSignal, createEffect } from "./signals.js";\nconst [count, setCount] = createSignal(0);\ncreateEffect(() => { console.log(count()); });\nsetCount(1);\n`,
    preact: `import { signal, effect } from "@preact/signals-core";\nconst count = signal(0);\neffect(() => { console.log(count.value); });\ncount.value = 1;\n`,
  },
  {
    id: "memo",
    luna: `import { createSignal, createMemo } from "./signals.js";\nconst [count, setCount] = createSignal(0);\nconst doubled = createMemo(() => count() * 2);\nconsole.log(doubled());\nsetCount(1);\n`,
    preact: `import { signal, computed } from "@preact/signals-core";\nconst count = signal(0);\nconst doubled = computed(() => count.value * 2);\nconsole.log(doubled.value);\ncount.value = 1;\n`,
  },
  {
    id: "render-static",
    luna: `import { render, text, createElement } from "./index.js";\nconst app = () => createElement("div", null, [text("hello")]);\nrender(app, document.body);\n`,
    preact: `import { h, render } from "preact";\nconst app = h("div", null, "hello");\nrender(app, document.body);\n`,
  },
  {
    id: "render-reactive",
    luna: `import { render, textDyn, createElement, createSignal } from "./index.js";\nconst [count, setCount] = createSignal(0);\nconst app = () => createElement("div", null, [textDyn(count)]);\nrender(app, document.body);\nsetCount(1);\n`,
    preact: `import { h, render } from "preact";\nimport { signal } from "@preact/signals";\nconst count = signal(0);\nconst App = () => h("div", null, count);\nrender(h(App, null), document.body);\ncount.value = 1;\n`,
  },
  {
    id: "context-basic",
    luna: `import { createContext, provide, useContext } from "./index.js";\nconst Theme = createContext("light");\nprovide(Theme, "dark", () => useContext(Theme));\n`,
    preact: `import { h, render, createContext } from "preact";\nimport { useContext } from "preact/hooks";\nconst Theme = createContext("light");\nfunction Child() { return h("div", null, useContext(Theme)); }\nfunction App() { return h(Theme.Provider, { value: "dark" }, h(Child, null)); }\nrender(h(App, null), document.body);\n`,
  },
];

function parseArgs() {
  const argv = process.argv.slice(2);
  const flags = new Set();
  const values = new Map();
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (!arg.startsWith("--")) continue;
    if (arg === "--cases" || arg === "--dump-dir") {
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
  return {
    build: flags.has("--build"),
    json: flags.has("--json"),
    cases: values.get("cases"),
    dumpDir: values.get("dump-dir"),
  };
}

function formatBytes(bytes) {
  return `${bytes.toString().padStart(6, " ")} B`;
}

function formatDelta(value) {
  return `${value >= 0 ? "+" : ""}${value}`;
}

function pickCases(filterValue) {
  if (!filterValue) return CASES;
  const ids = new Set(
    filterValue
      .split(",")
      .map((v) => v.trim())
      .filter(Boolean)
  );
  const selected = CASES.filter((c) => ids.has(c.id));
  if (selected.length === 0) {
    throw new Error(
      `No matching cases. Available: ${CASES.map((c) => c.id).join(", ")}`
    );
  }
  return selected;
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
  await execa(
    "moon",
    ["build", "--target", "js", "--release", "src/js/api_signals"],
    {
      cwd: PROJECT_ROOT,
      stdio: "inherit",
    }
  );
  await execa(
    "moon",
    ["build", "--target", "js", "--release", "src/js/api_resource"],
    {
      cwd: PROJECT_ROOT,
      stdio: "inherit",
    }
  );
  await execa(
    "moon",
    ["build", "--target", "js", "--release", "src/js/api_router"],
    {
      cwd: PROJECT_ROOT,
      stdio: "inherit",
    }
  );
  await execa("pnpm", ["--filter", "@luna_ui/luna", "build"], {
    cwd: PROJECT_ROOT,
    stdio: "inherit",
  });
}

function summarizeHints(code) {
  const hints = [];
  if (code.includes("Index out of bounds")) {
    hints.push("bounds-check panic string");
  }
  if (code.includes("charCodeAt(") && code.includes("String.fromCodePoint")) {
    hints.push("stack-trace parsing path");
  }
  if (code.includes("structuredClone(")) {
    hints.push("store helper runtime");
  }
  if (code.includes("window.location") || code.includes("history.pushState")) {
    hints.push("router/browser globals");
  }
  return hints;
}

async function buildBundle({ framework, caseId, contents, resolveDir, dumpDir }) {
  const result = await build({
    stdin: {
      contents,
      resolveDir,
      sourcefile: `${framework}-${caseId}.js`,
    },
    bundle: true,
    minify: true,
    format: "esm",
    platform: "browser",
    treeShaking: true,
    write: false,
    metafile: true,
  });

  const output = result.outputFiles[0].contents;
  const outputText = new TextDecoder().decode(output);
  const gzip = gzipSync(output);
  const outputKey = Object.keys(result.metafile.outputs)[0];
  const metaOut = result.metafile.outputs[outputKey];
  const inputs = Object.entries(metaOut.inputs)
    .map(([path, info]) => ({ path, bytes: info.bytesInOutput || 0 }))
    .sort((a, b) => b.bytes - a.bytes)
    .slice(0, 6);

  if (dumpDir) {
    await mkdir(dumpDir, { recursive: true });
    await writeFile(join(dumpDir, `${framework}-${caseId}.js`), outputText, "utf8");
    await writeFile(
      join(dumpDir, `${framework}-${caseId}.meta.json`),
      JSON.stringify(result.metafile, null, 2) + "\n",
      "utf8"
    );
  }

  return {
    bytes: output.byteLength,
    gzip: gzip.byteLength,
    inputs,
    hints: framework === "luna" ? summarizeHints(outputText) : [],
  };
}

async function main() {
  const args = parseArgs();
  const selectedCases = pickCases(args.cases);
  const dumpDir = args.dumpDir ? resolve(PROJECT_ROOT, args.dumpDir) : null;

  if (args.build) {
    console.log("🔧 building MoonBit + @luna_ui/luna...");
    await ensureBuild();
  }

  const rows = [];
  for (const item of selectedCases) {
    const [luna, preact] = await Promise.all([
      buildBundle({
        framework: "luna",
        caseId: item.id,
        contents: item.luna,
        resolveDir: DIST_DIR,
        dumpDir,
      }),
      buildBundle({
        framework: "preact",
        caseId: item.id,
        contents: item.preact,
        resolveDir: PROJECT_ROOT,
        dumpDir,
      }),
    ]);
    rows.push({
      id: item.id,
      luna,
      preact,
      delta: {
        bytes: luna.bytes - preact.bytes,
        gzip: luna.gzip - preact.gzip,
      },
      winner:
        luna.gzip === preact.gzip
          ? "tie"
          : luna.gzip > preact.gzip
            ? "preact"
            : "luna",
    });
  }

  if (args.json) {
    console.log(JSON.stringify(rows, null, 2));
    return;
  }

  console.log("\nLuna vs Preact bundle size (minified / gzip)");
  for (const row of rows) {
    const hints = row.luna.hints.length > 0 ? ` hints=[${row.luna.hints.join(", ")}]` : "";
    console.log(
      `${row.id.padEnd(15, " ")} ` +
        `luna ${formatBytes(row.luna.bytes)} / ${formatBytes(row.luna.gzip)} | ` +
        `preact ${formatBytes(row.preact.bytes)} / ${formatBytes(row.preact.gzip)} | ` +
        `delta ${formatDelta(row.delta.bytes)} / ${formatDelta(row.delta.gzip)} (${row.winner})` +
        hints
    );
  }

  const preactWins = rows.filter((row) => row.winner === "preact").length;
  const lunaWins = rows.filter((row) => row.winner === "luna").length;
  const ties = rows.length - preactWins - lunaWins;
  console.log(
    `\nSummary: preact smaller in ${preactWins}/${rows.length}, ` +
      `luna smaller in ${lunaWins}/${rows.length}, ties ${ties}`
  );
  if (dumpDir) {
    console.log(`Dumped bundled outputs to ${dumpDir}`);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
