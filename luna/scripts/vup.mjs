#!/usr/bin/env node
/**
 * Mooncakes-side version bump for luna.mbt.
 *
 * Bumps ONLY the MoonBit packages
 * (luna / luna_components / sol / sol_adapter_cloudflare / sol_adapter_node / astra).
 * Each package owns its own version, but a single semver bump
 * (patch/minor/major) increments each one relative to its current value.
 *
 * The npm packages under js/* are NOT touched here — they are managed by
 * release-please (see release-please-config.json + .github/workflows/release-please.yml).
 *
 * Files touched (always run from the repo root):
 *   luna/moon.mod.json
 *   luna_components/moon.mod.json (also updates `mizchi/luna.version` to match
 *                                   luna's new version)
 *   sol/moon.mod.json             (also updates `mizchi/astra.version` to match
 *                                   astra's new version)
 *   sol_adapter_cloudflare/moon.mod.json
 *                                 (also updates `mizchi/sol.version` to match
 *                                   sol's new version)
 *   sol_adapter_node/moon.mod.json
 *                                 (also updates `mizchi/sol.version` to match
 *                                   sol's new version)
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
 * Idempotency:
 *   For semver bumps (patch/minor/major), the plan is computed against the
 *   HEAD commit. If moon.mod.json in the working tree is already ahead of
 *   HEAD (= a previous `vup patch` already ran but wasn't committed), the
 *   script REUSES that pending version instead of bumping again. This means
 *   the documented two-step flow
 *
 *     just vup patch              # bump + per-package CHANGELOG
 *     just vup patch --release    # commit + tag (no double-bump)
 *
 *   is safe: the second call detects the pending bump and only commits/tags.
 *   Explicit `vup X.Y.Z` always sets to that exact version.
 *
 * Tags created by --release are the mooncakes tags:
 *   luna-v<luna_version>
 *   luna_components-v<luna_components_version>
 *   sol-v<sol_version>
 *   sol_adapter_cloudflare-v<sol_adapter_cloudflare_version>
 *   sol_adapter_node-v<sol_adapter_node_version>
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
 * Each package is identified by its short id and has:
 *   - moonModPath:   path to moon.mod.json
 *   - tagPrefix:     git tag prefix (e.g. "luna-v")
 */
const PACKAGES = [
  {
    id: "luna",
    moonModPath: "luna/moon.mod.json",
    tagPrefix: "luna-v",
  },
  {
    id: "luna_components",
    moonModPath: "luna_components/moon.mod.json",
    tagPrefix: "luna_components-v",
  },
  {
    id: "sol",
    moonModPath: "sol/moon.mod.json",
    tagPrefix: "sol-v",
  },
  {
    id: "sol_adapter_cloudflare",
    moonModPath: "sol_adapter_cloudflare/moon.mod.json",
    tagPrefix: "sol_adapter_cloudflare-v",
  },
  {
    id: "sol_adapter_node",
    moonModPath: "sol_adapter_node/moon.mod.json",
    tagPrefix: "sol_adapter_node-v",
  },
  {
    id: "astra",
    moonModPath: "astra/moon.mod.json",
    tagPrefix: "astra-v",
  },
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
 * Read the version recorded for `path` in the current HEAD commit, so we
 * can tell whether a moon.mod.json has already been bumped relative to HEAD.
 * Returns null if HEAD does not have the file (new package) or git is unhappy.
 */
function readHeadVersion(path) {
  try {
    const blob = execSync(`git show HEAD:${path}`, {
      cwd: rootDir,
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    return JSON.parse(blob).version ?? null;
  } catch {
    return null;
  }
}

/**
 * Build a plan: { id, currentMoon, newMoon, alreadyBumped } per package.
 *
 * For an explicit version, all entries get that version. If the working tree
 * already records that version, the entry is flagged `alreadyBumped` so we
 * skip the write.
 *
 * For a semver bump, we compare moon.mod.json with HEAD:
 *   - clean (working == HEAD):  newMoon = incrementVersion(working, kind)
 *   - already bumped (working != HEAD): newMoon = working, no further bump
 *
 * This makes `vup patch --release` idempotent: running `just vup patch` and
 * then `just vup patch --release` does NOT double-bump. The second call sees
 * the pending bump in the working tree and just reuses it.
 */
function buildPlan(spec) {
  return PACKAGES.map(pkg => {
    const moonAbs = join(rootDir, pkg.moonModPath);
    const moon = readJson(moonAbs);
    const currentMoon = moon.version;
    const headMoon = readHeadVersion(pkg.moonModPath);
    const alreadyBumped = headMoon !== null && headMoon !== currentMoon;

    let newMoon;
    if (spec.kind === "explicit") {
      newMoon = spec.version;
    } else if (alreadyBumped) {
      // Working tree is ahead of HEAD; trust it instead of bumping again.
      newMoon = currentMoon;
    } else {
      newMoon = incrementVersion(currentMoon, spec.kind);
    }
    return {
      ...pkg,
      moonAbs,
      moon,
      currentMoon, newMoon,
      headMoon,
      alreadyBumped,
    };
  });
}

function applyPlan(plan, dryRun) {
  // Inter-dep refs to update inside other mooncakes' moon.mod.json:
  //   sol depends on astra and luna
  //   sol_adapter_cloudflare depends on sol
  //   sol_adapter_node depends on sol
  //   astra depends on luna
  //   luna_components depends on luna
  const astraEntry = plan.find(p => p.id === "astra");
  const lunaEntry = plan.find(p => p.id === "luna");
  const solEntry = plan.find(p => p.id === "sol");
  const astraNewVersion = astraEntry?.newMoon;
  const lunaNewVersion = lunaEntry?.newMoon;
  const solNewVersion = solEntry?.newMoon;

  function bumpInterDep(moon, depName, newVersion, contextLabel) {
    if (!newVersion || !moon.deps?.[depName]) return;
    const dep = moon.deps[depName];
    if (typeof dep === "object" && dep !== null) {
      const oldRef = dep.version;
      dep.version = newVersion;
      console.log(`  ${contextLabel}: deps.${depName}.version ${oldRef} -> ${newVersion}`);
    } else if (typeof dep === "string") {
      console.log(`  ${contextLabel}: deps.${depName} ${dep} -> ${newVersion}`);
      moon.deps[depName] = newVersion;
    }
  }

  for (const entry of plan) {
    // Update moon.mod.json own version.
    entry.moon.version = entry.newMoon;

    if (entry.id === "sol") {
      bumpInterDep(entry.moon, "mizchi/astra", astraNewVersion, "sol/moon.mod.json");
      bumpInterDep(entry.moon, "mizchi/luna", lunaNewVersion, "sol/moon.mod.json");
    }
    if (entry.id === "sol_adapter_cloudflare") {
      bumpInterDep(entry.moon, "mizchi/sol", solNewVersion, "sol_adapter_cloudflare/moon.mod.json");
    }
    if (entry.id === "sol_adapter_node") {
      bumpInterDep(entry.moon, "mizchi/sol", solNewVersion, "sol_adapter_node/moon.mod.json");
    }
    if (entry.id === "luna_components") {
      bumpInterDep(entry.moon, "mizchi/luna", lunaNewVersion, "luna_components/moon.mod.json");
    }
    if (entry.id === "astra") {
      bumpInterDep(entry.moon, "mizchi/luna", lunaNewVersion, "astra/moon.mod.json");
    }

    const unchanged = entry.currentMoon === entry.newMoon
      && JSON.stringify(entry.moon) === JSON.stringify(readJson(entry.moonAbs));
    if (unchanged) {
      console.log(`  ${entry.moonModPath}: ${entry.newMoon} (already bumped, no write)`);
    } else {
      writeJson(entry.moonAbs, entry.moon, dryRun);
      console.log(`  ${entry.moonModPath}: ${entry.currentMoon} -> ${entry.newMoon}`);
    }
  }

  // Rewrite version literals embedded in source templates so they match the
  // bumped moon.mod.json values. Without this `sol new` scaffolds a project
  // that pins the previous release line; tracked as TODO.md refactor #2.
  rewriteEmbeddedVersionLiterals(plan, dryRun);
}

// Re-target every "mizchi/<pkg>": "<semver>" string literal inside the
// scaffold templates and bump the standalone sol VERSION const so they all
// reference the post-bump versions. Idempotent: replaces only when the
// target is different from the current literal.
function rewriteEmbeddedVersionLiterals(plan, dryRun) {
  const versionByPkg = {};
  for (const entry of plan) {
    if (entry.id === "sol") versionByPkg["mizchi/sol"] = entry.newMoon;
    if (entry.id === "luna") versionByPkg["mizchi/luna"] = entry.newMoon;
    if (entry.id === "sol_adapter_cloudflare")
      versionByPkg["mizchi/sol_adapter_cloudflare"] = entry.newMoon;
    if (entry.id === "sol_adapter_node")
      versionByPkg["mizchi/sol_adapter_node"] = entry.newMoon;
  }
  const solNew = versionByPkg["mizchi/sol"];
  // Templates that hard-code scaffold dependency versions. Both files emit
  // the same project moon.mod.json shape; the scaffold_templates copy is
  // shared with the native launcher.
  const templateFiles = [
    "sol/src/cli/templates.mbt",
    "sol/src/scaffold_templates/templates.mbt",
  ];
  for (const rel of templateFiles) {
    const abs = join(rootDir, rel);
    if (!existsSync(abs)) continue;
    let content = readFileSync(abs, "utf-8");
    let touched = false;
    for (const [pkg, version] of Object.entries(versionByPkg)) {
      const pattern = new RegExp(
        `("${pkg.replace(/\//g, "\\/")}":\\s*)"(\\d+\\.\\d+\\.\\d+)"`,
        "g",
      );
      content = content.replace(pattern, (match, prefix, current) => {
        if (current === version) return match;
        console.log(`  ${rel}: ${pkg} ${current} -> ${version}`);
        touched = true;
        return `${prefix}"${version}"`;
      });
    }
    if (touched) {
      if (dryRun) {
        console.log(`  [dry-run] write ${rel}`);
      } else {
        writeFileSync(abs, content);
      }
    }
  }
  // Standalone sol VERSION const consumed by the native launcher and the
  // JS CLI (`sol --version`). Single source of truth for the sol literal.
  if (solNew) {
    const versionRel = "sol/src/version/version.mbt";
    const versionAbs = join(rootDir, versionRel);
    if (existsSync(versionAbs)) {
      const content = readFileSync(versionAbs, "utf-8");
      const pattern = /(pub const VERSION : String = ")(\d+\.\d+\.\d+)(")/;
      const m = content.match(pattern);
      if (m && m[2] !== solNew) {
        const next = content.replace(pattern, `$1${solNew}$3`);
        console.log(`  ${versionRel}: VERSION ${m[2]} -> ${solNew}`);
        if (dryRun) {
          console.log(`  [dry-run] write ${versionRel}`);
        } else {
          writeFileSync(versionAbs, next);
        }
      }
    }
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
  This script bumps ONLY the mooncakes packages
  (mizchi/{luna,luna_components,sol,sol_adapter_cloudflare,sol_adapter_node,astra}).
  The npm packages under js/* are managed by release-please — do not edit
  their versions by hand. See docs/internal/npm-release-onboarding.md.

Touches manifests:
  luna/moon.mod.json, luna_components/moon.mod.json,
  sol/moon.mod.json, sol_adapter_cloudflare/moon.mod.json,
  sol_adapter_node/moon.mod.json, astra/moon.mod.json
  (sol/moon.mod.json deps.mizchi/astra.version is also bumped to match astra)
  (sol/moon.mod.json deps.mizchi/luna is also bumped to match luna)
  (sol_adapter_cloudflare/moon.mod.json deps.mizchi/sol.version is also bumped)
  (sol_adapter_node/moon.mod.json deps.mizchi/sol.version is also bumped)
  (astra/moon.mod.json deps.mizchi/luna is also bumped to match luna)

Tags created by --release:
  luna-v<v>, luna_components-v<v>, sol-v<v>,
  sol_adapter_cloudflare-v<v>, sol_adapter_node-v<v>, astra-v<v>.

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
  if (spec.kind !== "explicit" && plan.every(p => p.alreadyBumped)) {
    console.log("  (idempotent: HEAD vs working tree already shows a pending bump — reusing it)");
  }
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
