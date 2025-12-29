#!/usr/bin/env node
/**
 * Version update script for luna.mbt
 *
 * Recommended usage via just:
 *   just vup patch                 # bump + changelog
 *   just vup patch --release       # bump + changelog + commit + tag
 *
 * Direct usage:
 *   node scripts/vup.mjs patch|minor|major [targets...] [--release] [--dry-run]
 *
 * Targets: moon.mod.json, js/luna, js/sol, examples
 */
import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { execSync } from "node:child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, "..");

// =============================================================================
// Target definitions
// =============================================================================

const TARGETS = {
  "moon.mod.json": {
    getPath: () => join(rootDir, "moon.mod.json"),
    getVersion: (json) => json.version,
    setVersion: (json, version) => {
      json.version = version;
    },
  },
  "js/luna": {
    getPath: () => join(rootDir, "js/luna/package.json"),
    getVersion: (json) => json.version,
    setVersion: (json, version) => {
      json.version = version;
    },
  },
  "js/sol": {
    getPath: () => join(rootDir, "js/sol/package.json"),
    getVersion: (json) => json.version,
    setVersion: (json, version) => {
      json.version = version;
    },
  },
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
  // Remove prerelease suffix for increment
  const base = version.split("-")[0];
  const [major, minor, patch] = base.split(".").map(Number);

  switch (type) {
    case "major":
      return `${major + 1}.0.0`;
    case "minor":
      return `${major}.${minor + 1}.0`;
    case "patch":
      return `${major}.${minor}.${patch + 1}`;
    default:
      throw new Error(`Unknown increment type: ${type}`);
  }
}

// =============================================================================
// File update helpers
// =============================================================================

function readJsonFile(filePath) {
  if (!existsSync(filePath)) {
    return null;
  }
  const content = readFileSync(filePath, "utf-8");
  return JSON.parse(content);
}

function writeJsonFile(filePath, json, dryRun = false) {
  if (dryRun) {
    console.log(`  [dry-run] Would write: ${filePath}`);
    return;
  }
  writeFileSync(filePath, JSON.stringify(json, null, 2) + "\n");
}

function updateTarget(targetName, newVersion, dryRun = false) {
  const target = TARGETS[targetName];
  if (!target) {
    console.error(`  Unknown target: ${targetName}`);
    return false;
  }

  const filePath = target.getPath();
  const json = readJsonFile(filePath);
  if (!json) {
    console.error(`  File not found: ${filePath}`);
    return false;
  }

  const oldVersion = target.getVersion(json);
  target.setVersion(json, newVersion);
  writeJsonFile(filePath, json, dryRun);
  console.log(`  ${targetName}: ${oldVersion} -> ${newVersion}`);
  return true;
}

function getTargetVersion(targetName) {
  const target = TARGETS[targetName];
  if (!target) return null;

  const json = readJsonFile(target.getPath());
  if (!json) return null;

  return target.getVersion(json);
}

// =============================================================================
// Examples updater (updates dependencies, not own versions)
// =============================================================================

function updateExamples(newVersion, dryRun = false) {
  console.log("\nUpdating examples (dependencies)...");

  const examplesDir = join(rootDir, "examples");
  if (!existsSync(examplesDir)) {
    console.log("  No examples directory found");
    return;
  }

  const examples = readdirSync(examplesDir, { withFileTypes: true })
    .filter((d) => d.isDirectory())
    .map((d) => d.name);

  for (const example of examples) {
    // Update moon.mod.json (mizchi/luna dependency)
    const moonModPath = join(examplesDir, example, "moon.mod.json");
    const moonJson = readJsonFile(moonModPath);
    if (moonJson?.deps?.["mizchi/luna"]) {
      const dep = moonJson.deps["mizchi/luna"];
      if (typeof dep === "string") {
        const oldVersion = dep;
        moonJson.deps["mizchi/luna"] = newVersion;
        writeJsonFile(moonModPath, moonJson, dryRun);
        console.log(`  ${example}/moon.mod.json: mizchi/luna ${oldVersion} -> ${newVersion}`);
      } else if (typeof dep === "object" && dep.version) {
        const oldVersion = dep.version;
        dep.version = newVersion;
        writeJsonFile(moonModPath, moonJson, dryRun);
        console.log(`  ${example}/moon.mod.json: mizchi/luna ${oldVersion} -> ${newVersion}`);
      }
    }

    // Update package.json (@luna_ui/* dependencies)
    const pkgJsonPath = join(examplesDir, example, "package.json");
    const pkgJson = readJsonFile(pkgJsonPath);
    if (pkgJson) {
      let updated = false;
      for (const depType of ["dependencies", "devDependencies"]) {
        if (pkgJson[depType]) {
          for (const [dep, ver] of Object.entries(pkgJson[depType])) {
            if (dep.startsWith("@luna_ui/")) {
              pkgJson[depType][dep] = newVersion;
              console.log(`  ${example}/package.json: ${dep} -> ${newVersion}`);
              updated = true;
            }
          }
        }
      }
      if (updated) {
        writeJsonFile(pkgJsonPath, pkgJson, dryRun);
      }
    }
  }
}

// =============================================================================
// Git & Release helpers
// =============================================================================

function exec(cmd, dryRun = false) {
  if (dryRun) {
    console.log(`  [dry-run] Would run: ${cmd}`);
    return "";
  }
  console.log(`  $ ${cmd}`);
  return execSync(cmd, { cwd: rootDir, encoding: "utf-8", stdio: "pipe" });
}

function gitCommit(version, dryRun = false) {
  console.log("\nCommitting changes...");
  exec("git add -A", dryRun);
  exec(`git commit -m "chore: v${version}"`, dryRun);
}

function gitTag(version, dryRun = false) {
  console.log("\nCreating git tag...");
  exec(`git tag v${version}`, dryRun);
  console.log(`  Created tag: v${version}`);
}

// =============================================================================
// Main
// =============================================================================

function printUsage() {
  console.log(`Usage:
  node scripts/vup.mjs <version>                      # Update all targets
  node scripts/vup.mjs <version> <targets...>         # Update specific targets
  node scripts/vup.mjs patch|minor|major              # Increment all targets
  node scripts/vup.mjs patch|minor|major <targets...> # Increment specific targets

Options:
  --release    Commit and tag (use with 'just vup' for changelog)
  --dry-run    Show what would be done without making changes
  --help, -h   Show this help

Targets:
  moon.mod.json  - Root MoonBit module
  js/luna        - @luna_ui/luna package
  js/sol         - @luna_ui/sol package
  examples       - All example projects (dependencies only)

Examples:
  just vup patch                            # Recommended: bump + changelog
  just vup patch --release                  # bump + changelog + commit + tag
  node scripts/vup.mjs 0.4.0 js/luna        # Update specific target only`);
}

function main() {
  const args = process.argv.slice(2);

  // Parse flags
  const doRelease = args.includes("--release");
  const dryRun = args.includes("--dry-run");
  const showHelp = args.includes("--help") || args.includes("-h");

  // Remove flags from args
  const positionalArgs = args.filter(
    (a) => !a.startsWith("--") && a !== "-h"
  );

  if (positionalArgs.length === 0 || showHelp) {
    printUsage();
    process.exit(positionalArgs.length === 0 && !showHelp ? 1 : 0);
  }

  if (dryRun) {
    console.log("[DRY RUN MODE - No changes will be made]\n");
  }

  const firstArg = positionalArgs[0];
  const restArgs = positionalArgs.slice(1);

  // Determine if first arg is version or semver type
  const isSemver = isSemverType(firstArg);
  const isVersion = isValidVersion(firstArg);

  if (!isSemver && !isVersion) {
    console.error(`Invalid version or semver type: ${firstArg}`);
    console.error("Expected: X.Y.Z, X.Y.Z-suffix, or patch|minor|major");
    process.exit(1);
  }

  // Determine targets
  let targetNames = restArgs.length > 0 ? restArgs : Object.keys(TARGETS);

  // Validate targets
  const includesExamples = targetNames.includes("examples");
  targetNames = targetNames.filter((t) => t !== "examples");

  for (const t of targetNames) {
    if (!TARGETS[t]) {
      console.error(`Unknown target: ${t}`);
      console.error(`Available targets: ${Object.keys(TARGETS).join(", ")}, examples`);
      process.exit(1);
    }
  }

  // Calculate final version for display
  let finalVersion;
  if (isSemver) {
    const currentVersion = getTargetVersion("moon.mod.json");
    finalVersion = incrementVersion(currentVersion, firstArg);
  } else {
    finalVersion = firstArg;
  }

  // Process each target
  console.log(`Updating targets: ${[...targetNames, ...(includesExamples ? ["examples"] : [])].join(", ")}`);
  console.log(`New version: ${finalVersion}\n`);

  for (const targetName of targetNames) {
    let newVersion;

    if (isSemver) {
      // Get current version and increment
      const currentVersion = getTargetVersion(targetName);
      if (!currentVersion) {
        console.error(`  Cannot get current version for: ${targetName}`);
        continue;
      }
      newVersion = incrementVersion(currentVersion, firstArg);
    } else {
      newVersion = firstArg;
    }

    updateTarget(targetName, newVersion, dryRun);
  }

  // Update examples if specified or if updating all
  if (includesExamples || restArgs.length === 0) {
    // Re-read to get updated version if we just updated it
    const actualVersion = dryRun ? finalVersion : getTargetVersion("moon.mod.json");
    updateExamples(actualVersion, dryRun);
  }

  // Release workflow (commit + tag only, changelog is handled by justfile)
  if (doRelease) {
    gitCommit(finalVersion, dryRun);
    gitTag(finalVersion, dryRun);

    console.log("\nRelease complete!");
    console.log(`\nNext steps:`);
    console.log(`  1. Push: git push && git push --tags`);
    console.log(`  2. Publish to mooncakes: moon publish`);
    console.log(`  3. Publish to npm: cd js/luna && pnpm publish --access public`);
  } else {
    console.log("\nDone!");
  }
}

main();
