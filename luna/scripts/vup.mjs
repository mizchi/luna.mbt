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
 *   luna/moon.mod
 *   luna_components/moon.mod (also updates `mizchi/luna` to match luna's new version)
 *   sol/moon.mod             (also updates `mizchi/astra` and `mizchi/luna`)
 *   sol_adapter_cloudflare/moon.mod (also updates `mizchi/sol`)
 *   sol_adapter_node/moon.mod       (also updates `mizchi/sol`)
 *   astra/moon.mod
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
 *   HEAD commit. If moon.mod in the working tree is already ahead of
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
import { readFileSync, writeFileSync, existsSync, readdirSync } from "node:fs";
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
 *   - moonModPath:   path to moon.mod
 *   - tagPrefix:     git tag prefix (e.g. "luna-v")
 */
const PACKAGES = [
  {
    id: "luna",
    moonModPath: "luna/moon.mod",
    tagPrefix: "luna-v",
  },
  {
    id: "luna_components",
    moonModPath: "luna_components/moon.mod",
    tagPrefix: "luna_components-v",
  },
  {
    id: "sol",
    moonModPath: "sol/moon.mod",
    tagPrefix: "sol-v",
  },
  {
    id: "sol_adapter_cloudflare",
    moonModPath: "sol_adapter_cloudflare/moon.mod",
    tagPrefix: "sol_adapter_cloudflare-v",
  },
  {
    id: "sol_adapter_node",
    moonModPath: "sol_adapter_node/moon.mod",
    tagPrefix: "sol_adapter_node-v",
  },
  {
    id: "astra",
    moonModPath: "astra/moon.mod",
    tagPrefix: "astra-v",
  },
];

const PACKAGE_NAME_BY_ID = {
  luna: "mizchi/luna",
  luna_components: "mizchi/luna_components",
  sol: "mizchi/sol",
  sol_adapter_cloudflare: "mizchi/sol_adapter_cloudflare",
  sol_adapter_node: "mizchi/sol_adapter_node",
  astra: "mizchi/astra",
};

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

function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function parseMoonMod(content, label) {
  const version = content.match(/^version\s*=\s*"([^"]+)"/m)?.[1];
  if (!version) throw new Error(`Cannot find version in ${label}`);
  const deps = {};
  for (const match of content.matchAll(/^\s*"([^"@]+)@([^"]+)",\s*$/gm)) {
    deps[match[1]] = match[2];
  }
  return { version, deps };
}

function readJson(absPath) {
  if (!existsSync(absPath)) throw new Error(`File not found: ${absPath}`);
  return parseMoonMod(readFileSync(absPath, "utf-8"), absPath);
}

function writeJson(absPath, json, dryRun) {
  let serialized = readFileSync(absPath, "utf-8");
  serialized = serialized.replace(
    /^version\s*=\s*"[^"]+"/m,
    `version = "${json.version}"`,
  );
  for (const [depName, depVersion] of Object.entries(json.deps ?? {})) {
    const pattern = new RegExp(
      `"${escapeRegExp(depName)}@[^"]+"`,
      "g",
    );
    serialized = serialized.replace(pattern, `"${depName}@${depVersion}"`);
  }
  if (dryRun) {
    console.log(`  [dry-run] write ${absPath}`);
    return;
  }
  writeFileSync(absPath, serialized);
}

function versionByPackage(plan) {
  const versions = {};
  for (const entry of plan) {
    const packageName = PACKAGE_NAME_BY_ID[entry.id];
    if (packageName) versions[packageName] = entry.newMoon;
  }
  return versions;
}

function findNamedFiles(rootRel, fileName) {
  const rootAbs = join(rootDir, rootRel);
  if (!existsSync(rootAbs)) return [];
  const out = [];
  function visit(absDir, relDir) {
    for (const entry of readdirSync(absDir, { withFileTypes: true })) {
      const childRel = relDir ? `${relDir}/${entry.name}` : entry.name;
      const childAbs = join(absDir, entry.name);
      if (entry.isDirectory()) {
        if (entry.name === ".mooncakes" || entry.name === "_build" || entry.name === "node_modules") {
          continue;
        }
        visit(childAbs, childRel);
      } else if (entry.isFile() && entry.name === fileName) {
        out.push(`${rootRel}/${childRel}`);
      }
    }
  }
  visit(rootAbs, "");
  return out;
}

// =============================================================================
// Bump planning
// =============================================================================

/**
 * Read the version recorded for `path` in the current HEAD commit, so we
 * can tell whether a moon.mod has already been bumped relative to HEAD.
 * Returns null if HEAD does not have the file (new package) or git is unhappy.
 */
function readHeadVersion(path) {
  try {
    const blob = execSync(`git show HEAD:${path}`, {
      cwd: rootDir,
      encoding: "utf-8",
      stdio: ["ignore", "pipe", "ignore"],
    });
    return parseMoonMod(blob, path).version ?? null;
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
 * For a semver bump, we compare moon.mod with HEAD:
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
  // Inter-dep refs to update inside other mooncakes' moon.mod:
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
    // Update moon.mod own version.
    entry.moon.version = entry.newMoon;

    if (entry.id === "sol") {
      bumpInterDep(entry.moon, "mizchi/astra", astraNewVersion, "sol/moon.mod");
      bumpInterDep(entry.moon, "mizchi/luna", lunaNewVersion, "sol/moon.mod");
    }
    if (entry.id === "sol_adapter_cloudflare") {
      bumpInterDep(entry.moon, "mizchi/sol", solNewVersion, "sol_adapter_cloudflare/moon.mod");
    }
    if (entry.id === "sol_adapter_node") {
      bumpInterDep(entry.moon, "mizchi/sol", solNewVersion, "sol_adapter_node/moon.mod");
    }
    if (entry.id === "luna_components") {
      bumpInterDep(entry.moon, "mizchi/luna", lunaNewVersion, "luna_components/moon.mod");
    }
    if (entry.id === "astra") {
      bumpInterDep(entry.moon, "mizchi/luna", lunaNewVersion, "astra/moon.mod");
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
  // bumped moon.mod values. Without this `sol new` scaffolds a project
  // that pins the previous release line; tracked as TODO.md refactor #2.
  rewriteEmbeddedVersionLiterals(plan, dryRun);
  rewriteLegacyExampleManifests(plan, dryRun);
}

// Re-target every "mizchi/<pkg>@<semver>" or legacy
// "mizchi/<pkg>": "<semver>" string literal inside the scaffold templates
// and bump the standalone sol VERSION const so they all reference the
// post-bump versions. Idempotent: replaces only when the target is different
// from the current literal.
function rewriteEmbeddedVersionLiterals(plan, dryRun) {
  const versionByPkg = versionByPackage(plan);
  const solNew = versionByPkg["mizchi/sol"];
  // Templates that hard-code scaffold dependency versions. Both files emit
  // the same project moon.mod shape; the scaffold_templates copy is
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
      const moonModPattern = new RegExp(
        `"${escapeRegExp(pkg)}@(\\d+\\.\\d+\\.\\d+)"`,
        "g",
      );
      content = content.replace(moonModPattern, (match, current) => {
        if (current === version) return match;
        console.log(`  ${rel}: ${pkg} ${current} -> ${version}`);
        touched = true;
        return `"${pkg}@${version}"`;
      });
      const legacyJsonPattern = new RegExp(
        `("${escapeRegExp(pkg)}":\\s*)"(\\d+\\.\\d+\\.\\d+)"`,
        "g",
      );
      content = content.replace(legacyJsonPattern, (match, prefix, current) => {
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

// Keep checked-in example projects buildable before the just-bumped mooncakes
// are published. These examples use legacy moon.mod.json path dependencies so
// local CI can resolve the workspace packages, but their version pins must
// still match the package versions required by transitive deps.
function rewriteLegacyExampleManifests(plan, dryRun) {
  const versionByPkg = versionByPackage(plan);
  const manifestFiles = [
    ...findNamedFiles("sol/examples", "moon.mod.json"),
    ...findNamedFiles("astra/examples", "moon.mod.json"),
  ];

  for (const rel of manifestFiles) {
    const abs = join(rootDir, rel);
    const json = JSON.parse(readFileSync(abs, "utf-8"));
    if (!json.deps || typeof json.deps !== "object") continue;
    let touched = false;

    for (const [pkg, version] of Object.entries(versionByPkg)) {
      const dep = json.deps[pkg];
      if (!dep) continue;
      if (typeof dep === "object" && dep !== null && typeof dep.version === "string") {
        if (dep.version === version) continue;
        console.log(`  ${rel}: deps.${pkg}.version ${dep.version} -> ${version}`);
        dep.version = version;
        touched = true;
      } else if (typeof dep === "string" && /^\d+\.\d+\.\d+$/.test(dep)) {
        if (dep === version) continue;
        console.log(`  ${rel}: deps.${pkg} ${dep} -> ${version}`);
        json.deps[pkg] = version;
        touched = true;
      }
    }

    if (touched) {
      if (dryRun) {
        console.log(`  [dry-run] write ${rel}`);
      } else {
        writeFileSync(abs, JSON.stringify(json, null, 2) + "\n");
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
  luna/moon.mod, luna_components/moon.mod,
  sol/moon.mod, sol_adapter_cloudflare/moon.mod,
  sol_adapter_node/moon.mod, astra/moon.mod
  (sol/moon.mod import mizchi/astra is also bumped to match astra)
  (sol/moon.mod import mizchi/luna is also bumped to match luna)
  (sol_adapter_cloudflare/moon.mod import mizchi/sol is also bumped)
  (sol_adapter_node/moon.mod import mizchi/sol is also bumped)
  (astra/moon.mod import mizchi/luna is also bumped to match luna)

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
