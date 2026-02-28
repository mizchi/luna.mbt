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

export function stripAbortLocFunctions(source) {
  const lines = source.split("\n");
  const out = [];
  let replaced = 0;

  for (const line of lines) {
    if (ABORT_RETURN_MARKERS.some((marker) => line.includes(marker))) {
      const indent = line.match(/^\s*/)?.[0] ?? "";
      out.push(`${indent}return $panic();`);
      replaced += 1;
    } else {
      out.push(line);
    }
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
