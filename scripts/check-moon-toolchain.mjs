#!/usr/bin/env node
import { spawnSync } from "node:child_process";

// The updated moonbitlang/x dependency uses constructors unavailable in
// older compilers. Check the compiler (moonc), not the date-based moon CLI.
const minimum = [0, 10, 12];
const result = spawnSync("moon", ["version", "--all"], { encoding: "utf8" });

if (result.error || result.status !== 0) {
  console.error("Could not run `moon version --all`. Install MoonBit and ensure `moon` is on PATH.");
  console.error(result.error?.message ?? result.stderr);
  process.exit(1);
}

const match = result.stdout.match(/^moonc v(\d+)\.(\d+)\.(\d+)/m);
if (!match) {
  console.error("Could not determine the MoonBit compiler version from `moon version --all`.");
  console.error(result.stdout.trim());
  process.exit(1);
}

const current = match.slice(1).map(Number);
const difference = current.map((part, index) => part - minimum[index]).find((part) => part !== 0) ?? 0;
if (difference < 0) {
  console.error(`This workspace requires MoonBit v${minimum.join(".")} or newer; found v${current.join(".")}.`);
  console.error("Run `moon upgrade` and `moon update`, then retry. Use `moon version --all` to check the compiler on PATH.");
  process.exit(1);
}
