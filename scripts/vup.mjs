#!/usr/bin/env node
/**
 * Version update script for luna.mbt
 * Usage: node scripts/vup.mjs <version>
 * Example: node scripts/vup.mjs 0.2.0
 */
import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, "..");

const newVersion = process.argv[2];
if (!newVersion) {
  console.error("Usage: node scripts/vup.mjs <version>");
  console.error("Example: node scripts/vup.mjs 0.2.0");
  process.exit(1);
}

// Validate version format
if (!/^\d+\.\d+\.\d+(-[\w.]+)?$/.test(newVersion)) {
  console.error(`Invalid version format: ${newVersion}`);
  console.error("Expected format: X.Y.Z or X.Y.Z-suffix");
  process.exit(1);
}

console.log(`Updating version to ${newVersion}...\n`);

// Update JSON file helper
function updateJsonFile(filePath, updater) {
  if (!existsSync(filePath)) {
    return false;
  }
  const content = readFileSync(filePath, "utf-8");
  const json = JSON.parse(content);
  const updated = updater(json);
  if (updated) {
    writeFileSync(filePath, JSON.stringify(json, null, 2) + "\n");
    console.log(`  Updated: ${filePath}`);
    return true;
  }
  return false;
}

// 1. Update root moon.mod.json
console.log("1. Updating root moon.mod.json...");
updateJsonFile(join(rootDir, "moon.mod.json"), (json) => {
  const oldVersion = json.version;
  json.version = newVersion;
  console.log(`    version: ${oldVersion} -> ${newVersion}`);
  return true;
});

// 2. Update js/* package.json files
console.log("\n2. Updating js/* package.json files...");
const jsDir = join(rootDir, "js");
const jsPackages = readdirSync(jsDir, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name);

for (const pkg of jsPackages) {
  const pkgJsonPath = join(jsDir, pkg, "package.json");
  updateJsonFile(pkgJsonPath, (json) => {
    if (json.version) {
      const oldVersion = json.version;
      json.version = newVersion;
      console.log(`    ${pkg}: ${oldVersion} -> ${newVersion}`);
      return true;
    }
    return false;
  });
}

// 3. Update examples' moon.mod.json (mizchi/luna dependency)
console.log("\n3. Updating examples' moon.mod.json (mizchi/luna dependency)...");
const examplesDir = join(rootDir, "examples");
const examples = readdirSync(examplesDir, { withFileTypes: true })
  .filter((d) => d.isDirectory())
  .map((d) => d.name);

for (const example of examples) {
  const moonModPath = join(examplesDir, example, "moon.mod.json");
  updateJsonFile(moonModPath, (json) => {
    if (json.deps && json.deps["mizchi/luna"] !== undefined) {
      const dep = json.deps["mizchi/luna"];
      // Handle both string and object formats
      if (typeof dep === "string") {
        const oldVersion = dep;
        json.deps["mizchi/luna"] = newVersion;
        console.log(`    ${example}: mizchi/luna ${oldVersion} -> ${newVersion}`);
      } else if (typeof dep === "object" && dep.version) {
        const oldVersion = dep.version;
        dep.version = newVersion;
        console.log(`    ${example}: mizchi/luna ${oldVersion} -> ${newVersion}`);
      }
      return true;
    }
    return false;
  });
}

// 4. Update examples' package.json
console.log("\n4. Updating examples' package.json...");
for (const example of examples) {
  const pkgJsonPath = join(examplesDir, example, "package.json");
  updateJsonFile(pkgJsonPath, (json) => {
    let updated = false;
    // Update version if it matches current pattern
    if (json.version && json.version.startsWith("0.")) {
      const oldVersion = json.version;
      json.version = newVersion;
      console.log(`    ${example}: version ${oldVersion} -> ${newVersion}`);
      updated = true;
    }
    // Update @luna_ui/* dependencies
    for (const depType of ["dependencies", "devDependencies"]) {
      if (json[depType]) {
        for (const [dep, ver] of Object.entries(json[depType])) {
          if (dep.startsWith("@luna_ui/") && ver.startsWith("0.")) {
            json[depType][dep] = newVersion;
            console.log(`    ${example}: ${dep} -> ${newVersion}`);
            updated = true;
          }
        }
      }
    }
    return updated;
  });
}

console.log("\nDone!");
console.log(`\nNext steps:`);
console.log(`  1. Review changes: git diff`);
console.log(`  2. Run tests: just test-unit`);
console.log(`  3. Commit: git add -A && git commit -m "chore: bump version to ${newVersion}"`);
