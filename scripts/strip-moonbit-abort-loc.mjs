#!/usr/bin/env node
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { readFile, writeFile } from "node:fs/promises";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_ROOT = join(__dirname, "..");

const TARGETS = [
  "_build/js/release/build/js/api/api.js",
  "_build/js/release/build/js/api_signals/api_signals.js",
  "_build/js/release/build/js/api_resource/api_resource.js",
  "_build/js/release/build/js/api_router/api_router.js",
];

const ABORT_RETURN_RE =
  /^\s*return _M0FP311moonbitlang4core(?:7builtin5abort|5abort5abort)/;
const BOUND_CHECK_FN_PREFIX = "function $bound_check(";
const BOUND_CHECK_CALL_RE = /^\s*\$bound_check\([^;]*\);\s*$/;

function createStats() {
  return {
    abortReturnsReplaced: 0,
    boundCheckFunctionReplaced: 0,
    boundCheckCallsRemoved: 0,
  };
}

function totalReplaced(stats) {
  return (
    stats.abortReturnsReplaced +
    stats.boundCheckFunctionReplaced +
    stats.boundCheckCallsRemoved
  );
}

function countBraceDelta(line) {
  let delta = 0;
  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (ch === "{") delta += 1;
    if (ch === "}") delta -= 1;
  }
  return delta;
}

function skipFunctionBlock(lines, startIndex) {
  let i = startIndex;
  let depth = 0;
  let opened = false;

  while (i < lines.length) {
    const line = lines[i];
    depth += countBraceDelta(line);
    if (line.includes("{")) {
      opened = true;
    }
    i += 1;

    if (opened && depth <= 0) {
      break;
    }
  }

  return i;
}

export function postProcessMoonbitJs(source) {
  const lines = source.split("\n");
  const out = [];
  const stats = createStats();

  for (let i = 0; i < lines.length; ) {
    const line = lines[i];

    if (line.startsWith(BOUND_CHECK_FN_PREFIX)) {
      out.push("function $bound_check(arr, index) {}");
      stats.boundCheckFunctionReplaced += 1;
      i = skipFunctionBlock(lines, i);
      continue;
    }

    if (BOUND_CHECK_CALL_RE.test(line)) {
      stats.boundCheckCallsRemoved += 1;
      i += 1;
      continue;
    }

    if (ABORT_RETURN_RE.test(line)) {
      const indent = line.match(/^\s*/)?.[0] ?? "";
      out.push(`${indent}return $panic();`);
      stats.abortReturnsReplaced += 1;
    } else {
      out.push(line);
    }
    i += 1;
  }

  return { output: out.join("\n"), replaced: totalReplaced(stats), stats };
}

async function processTarget(relativePath) {
  const fullPath = join(PROJECT_ROOT, relativePath);
  const input = await readFile(fullPath, "utf8");
  const { output, replaced, stats } = postProcessMoonbitJs(input);
  if (output !== input) {
    await writeFile(fullPath, output, "utf8");
  }
  return { fullPath, replaced, stats, changed: output !== input };
}

async function main() {
  const results = [];
  for (const target of TARGETS) {
    results.push(await processTarget(target));
  }

  for (const item of results) {
    const rel = item.fullPath.replace(`${PROJECT_ROOT}/`, "");
    if (item.changed) {
      const { abortReturnsReplaced, boundCheckFunctionReplaced, boundCheckCallsRemoved } =
        item.stats;
      console.log(
        `patched ${rel} (${item.replaced} changes: abort=${abortReturnsReplaced}, bound_check_fn=${boundCheckFunctionReplaced}, bound_check_calls=${boundCheckCallsRemoved})`
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

// Backward-compat export name for existing tests/scripts.
export const stripAbortLocFunctions = postProcessMoonbitJs;
