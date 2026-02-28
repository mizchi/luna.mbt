#!/usr/bin/env node
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { readFile, writeFile } from "node:fs/promises";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");

const TARGETS = [
  "_build/js/release/build/js/api/api.js",
  "_build/js/release/build/js/api_signals/api_signals.js",
];

const ABORT_RETURN_MARKERS = [
  "return _M0FP311moonbitlang4core7builtin5abort",
  "return _M0FP311moonbitlang4core5abort5abort",
];
const BOUND_CHECK_FN_PREFIX = "function $bound_check(";

export function stripAbortLocFunctions(source) {
  const lines = source.split("\n");
  const out = [];
  let replaced = 0;

  for (let i = 0; i < lines.length; ) {
    const line = lines[i];

    if (line.startsWith(BOUND_CHECK_FN_PREFIX)) {
      out.push("function $bound_check(arr, index) {}");
      replaced += 1;
      i += 1;
      while (i < lines.length && lines[i].trim() !== "}") {
        i += 1;
      }
      if (i < lines.length && lines[i].trim() === "}") {
        i += 1;
      }
      continue;
    }

    const trimmed = line.trim();
    if (trimmed.startsWith("$bound_check(") && trimmed.endsWith(");")) {
      replaced += 1;
      i += 1;
      continue;
    }

    if (ABORT_RETURN_MARKERS.some((marker) => line.includes(marker))) {
      const indent = line.match(/^\s*/)?.[0] ?? "";
      out.push(`${indent}return $panic();`);
      replaced += 1;
    } else {
      out.push(line);
    }
    i += 1;
  }

  return { output: out.join("\n"), replaced };
}

async function processTarget(relativePath) {
  const fullPath = join(PROJECT_ROOT, relativePath);
  const input = await readFile(fullPath, "utf8");
  const { output, replaced } = stripAbortLocFunctions(input);
  if (output !== input) {
    await writeFile(fullPath, output, "utf8");
  }
  return { fullPath, replaced, changed: output !== input };
}

async function main() {
  const results = [];
  for (const target of TARGETS) {
    results.push(await processTarget(target));
  }

  for (const item of results) {
    const rel = item.fullPath.replace(`${PROJECT_ROOT}/`, "");
    if (item.changed) {
      console.log(
        `patched ${rel} (${item.replaced} abort wrappers -> direct panic)`
      );
    } else {
      console.log(`ok ${rel} (no changes)`);
    }
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  main().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
