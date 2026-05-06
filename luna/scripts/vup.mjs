#!/usr/bin/env node
/**
 * Mooncakes-side version bump for luna.mbt.
 *
 * Bumps ONLY the three MoonBit packages (luna / sol / astra). Each package
 * owns its own version, but a single semver bump (patch/minor/major)
 * increments each one relative to its current value.
 *
 * The npm packages under js/* are NOT touched here — they are managed by
 * release-please (see release-please-config.json + .github/workflows/release-please.yml).
 *
 * Files touched (always run from the repo root):
 *   luna/moon.mod.json
 *   sol/moon.mod.json   (also updates the inter-dep ref `mizchi/astra.{path,version}`
 *                        to match astra's new version)
 *   astra/moon.mod.json
 *
 * Usage:
 *   node luna/scripts/vup.mjs patch              # bump each 0.x.y -> 0.x.(y+1)
 *   node luna/scripts/vup.mjs minor              # bump each 0.x.y -> 0.(x+1).0
 *   node luna/scripts/vup.mjs major              # bump each 0.x.y -> (x+1).0.0
 *   node luna/scripts/vup.mjs 0.20.0             # set ALL mooncakes to 0.20.0
 *   node luna/scripts/vup.mjs --dry-run patch    # preview without writing
 *   node luna/scripts/vup.mjs patch --release    # write, commit, tag (per-package tags)
 *   node luna/scripts/vup.mjs patch --release --push   # release then push
 *
 * Tags created by --release are the mooncakes tags:
 *   luna-v<luna_version>
 *   sol-v<sol_version>
 *   astra-v<astra_version>
 *
 * release-please creates separate "@luna_ui/<pkg>-v<v>" tags for the npm side.
 *
 * See `just vup` for the wrapper that also regenerates per-package CHANGELOGs.
 */
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
// vup.mjs lives at <root>/luna/scripts/vup.mjs, so root is two levels up.
const rootDir = join(__dirname, "..", "..");

// =============================================================================
// Package definitions
// =============================================================================

/**
 * Each package is identified by its short id (luna / sol / astra) and has:
 *   - moonModPath:   path to moon.mod.json
 *   - tagPrefix:     git tag prefix (e.g. "luna-v")
 */
const PACKAGES = [
  { id: "luna",  moonModPath: "luna/moon.mod.json",  tagPrefix: "luna-v"  },
  { id: "sol",   moonModPath: "sol/moon.mod.json",   tagPrefix: "sol-v"   },
  { id: "astra", moonModPath: "astra/moon.mod.json", tagPrefix: "astra-v" },
];

// =============================================================================
// Semver helpers
// =============================================================================

const SEMVER_TYPES = ["major", "minor", "patch"];

function isValidVersion(version) {
  return /^\d+\.\d+\.\d+(-[\w.]+)?$/.test(version);
}

function isSemverType(arg) {
  return SEMVER_TYPES.includes(arg);
}

function incrementVersion(version, type) {
  const base = version.split("-")[0];
  const [major, minor, patch] = base.split(".").map(Number);
  switch (type) {
    case "major": return `${major + 1}.0.0`;
    case "minor": return `${major}.${minor + 1}.0`;
    case "patch": return `${major}.${minor}.${patch + 1}`;
    default: throw new Error(`Unknown increment type: ${type}`);
  }
}

// =============================================================================
// File helpers
// =============================================================================

function readJson(absPath) {
  if (!existsSync(absPath)) throw new Error(`File not found: ${absPath}`);
  return JSON.parse(readFileSync(absPath, "utf-8"));
}

function writeJson(absPath, json, dryRun) {
  const serialized = JSON.stringify(json, null, 2) + "\n";
  if (dryRun) {
    console.log(`  [dry-run] write ${absPath}`);
    return;
  }
  writeFileSync(absPath, serialized);
}

// =============================================================================
// Bump planning
// =============================================================================

/**
 * Build a plan: { id, currentMoon, newMoon } per package.
 * For an explicit version, all entries get that version.
 * For a semver bump, each is incremented relative to its OWN current version.
 */
function buildPlan(spec) {
  return PACKAGES.map(pkg => {
    const moonAbs = join(rootDir, pkg.moonModPath);
    const moon = readJson(moonAbs);
    const currentMoon = moon.version;
    const newMoon = spec.kind === "explicit"
      ? spec.version
      : incrementVersion(currentMoon, spec.kind);
    return {
      ...pkg,
      moonAbs,
      moon,
      currentMoon, newMoon,
    };
  });
}

function applyPlan(plan, dryRun) {
  // First: figure out astra's new version so sol's inter-dep ref can be updated.
  const astraEntry = plan.find(p => p.id === "astra");
  const astraNewVersion = astraEntry?.newMoon;

  for (const entry of plan) {
    // Update moon.mod.json own version.
    entry.moon.version = entry.newMoon;

    // Special-case sol: bump the inter-package ref to astra.
    if (entry.id === "sol" && astraNewVersion && entry.moon.deps?.["mizchi/astra"]) {
      const dep = entry.moon.deps["mizchi/astra"];
      if (typeof dep === "object" && dep !== null) {
        const oldRef = dep.version;
        dep.version = astraNewVersion;
        // path stays as-is; only version field gets bumped.
        console.log(`  sol/moon.mod.json: deps.mizchi/astra.version ${oldRef} -> ${astraNewVersion}`);
      } else if (typeof dep === "string") {
        console.log(`  sol/moon.mod.json: deps.mizchi/astra ${dep} -> ${astraNewVersion}`);
        entry.moon.deps["mizchi/astra"] = astraNewVersion;
      }
    }

    writeJson(entry.moonAbs, entry.moon, dryRun);
    console.log(`  ${entry.moonModPath}: ${entry.currentMoon} -> ${entry.newMoon}`);
  }
}

// =============================================================================
// Git helpers
// =============================================================================

function exec(cmd, dryRun) {
  if (dryRun) {
    console.log(`  [dry-run] $ ${cmd}`);
    return "";
  }
  console.log(`  $ ${cmd}`);
  return execSync(cmd, { cwd: rootDir, encoding: "utf-8", stdio: "pipe" });
}

function release(plan, kind, dryRun, doPush) {
  console.log("\nReleasing...");
  exec("git add -A", dryRun);
  const kindLabel = kind === "explicit" ? "set version" : `bump ${kind}`;
  exec(`git commit -m "chore: ${kindLabel} all mooncakes packages"`, dryRun);
  for (const entry of plan) {
    exec(`git tag ${entry.tagPrefix}${entry.newMoon}`, dryRun);
  }
  if (doPush) {
    exec("git push", dryRun);
    exec("git push --tags", dryRun);
  } else {
    console.log("\n  (skip push — pass --push to push branch and tags)");
  }
}

// =============================================================================
// Main
// =============================================================================

function printUsage() {
  console.log(`Usage:
  node luna/scripts/vup.mjs patch|minor|major [--dry-run] [--release [--push]]
  node luna/scripts/vup.mjs <X.Y.Z>            [--dry-run] [--release [--push]]

Scope:
  This script bumps ONLY the 3 mooncakes packages (mizchi/{luna,sol,astra}).
  The npm packages under js/* are managed by release-please — do not edit
  their versions by hand. See docs/internal/npm-release-onboarding.md.

Touches 3 manifests:
  luna/moon.mod.json, sol/moon.mod.json, astra/moon.mod.json
  (sol/moon.mod.json deps.mizchi/astra.version is also bumped to match astra)

Tags created by --release: luna-v<v>, sol-v<v>, astra-v<v>.

Examples:
  node luna/scripts/vup.mjs --dry-run patch         # preview
  node luna/scripts/vup.mjs patch                   # bump each mooncakes package
  node luna/scripts/vup.mjs 0.20.0                  # set all mooncakes to 0.20.0
  node luna/scripts/vup.mjs patch --release         # bump + commit + per-pkg tags
  node luna/scripts/vup.mjs patch --release --push  # ... and push
`);
}

function main() {
  const argv = process.argv.slice(2);
  const dryRun = argv.includes("--dry-run");
  const doRelease = argv.includes("--release");
  const doPush = argv.includes("--push");
  const showHelp = argv.includes("--help") || argv.includes("-h");
  const positional = argv.filter(a => !a.startsWith("--") && a !== "-h");

  if (showHelp || positional.length === 0) {
    printUsage();
    process.exit(showHelp ? 0 : 1);
  }
  if (positional.length > 1) {
    console.error(`Unexpected extra args: ${positional.slice(1).join(" ")}`);
    printUsage();
    process.exit(1);
  }

  const arg = positional[0];
  let spec;
  if (isSemverType(arg)) {
    spec = { kind: arg };
  } else if (isValidVersion(arg)) {
    spec = { kind: "explicit", version: arg };
  } else {
    console.error(`Invalid argument: ${arg}`);
    console.error("Expected: patch | minor | major | X.Y.Z");
    process.exit(1);
  }

  if (dryRun) console.log("[DRY RUN — no files written]\n");

  console.log(`Plan (${spec.kind === "explicit" ? `set ${spec.version}` : `${spec.kind} bump`}):`);
  const plan = buildPlan(spec);
  applyPlan(plan, dryRun);

  if (doRelease) {
    release(plan, spec.kind, dryRun, doPush);
  }

  console.log("\nDone.");
  if (!doRelease) {
    console.log("Next: review diff, regenerate per-package CHANGELOGs, then commit/tag manually");
    console.log("      or re-run with --release.");
  }
}

main();
