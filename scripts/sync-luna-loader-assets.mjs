import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");

function parseArgs(argv) {
  let lunaDir = process.env.LUNA_REPO_DIR ?? path.resolve(root, "..", "luna.mbt");
  let check = false;
  let strict = false;
  let skipExamples = false;

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--luna-dir") {
      const value = argv[i + 1];
      if (!value) {
        throw new Error("--luna-dir requires a value");
      }
      lunaDir = path.resolve(value);
      i += 1;
      continue;
    }
    if (arg === "--check") {
      check = true;
      continue;
    }
    if (arg === "--strict") {
      strict = true;
      continue;
    }
    if (arg === "--skip-examples") {
      skipExamples = true;
      continue;
    }
    throw new Error(`unknown option: ${arg}`);
  }

  return { lunaDir, check, strict, skipExamples };
}

function readText(filePath) {
  return fs.readFileSync(filePath, "utf-8");
}

function hasRequiredMarkers(content, markers) {
  return markers.every((marker) => content.includes(marker));
}

function syncOrCheck({
  sourcePath,
  targetPath,
  check,
  requiredMarkers,
  strict,
}) {
  const sourceContent = readText(sourcePath);
  if (requiredMarkers && !hasRequiredMarkers(sourceContent, requiredMarkers)) {
    const message = `skip ${path.basename(
      targetPath,
    )}: missing required markers in luna source`;
    if (strict) {
      throw new Error(message);
    }
    console.warn(message);
    return { changed: false, checked: false };
  }

  const targetContent = readText(targetPath);
  if (targetContent === sourceContent) {
    return { changed: false, checked: true };
  }

  if (check) {
    throw new Error(`out of sync: ${path.relative(root, targetPath)}`);
  }

  fs.writeFileSync(targetPath, sourceContent);
  return { changed: true, checked: true };
}

function run() {
  const { lunaDir, check, strict, skipExamples } = parseArgs(process.argv.slice(2));
  const lunaDist = path.join(lunaDir, "js", "loader", "dist");
  if (!fs.existsSync(lunaDist)) {
    throw new Error(`luna dist not found: ${lunaDist}`);
  }

  const mappings = [
    {
      source: path.join(lunaDist, "loader.iife.js"),
      target: path.join(root, "src", "ssg", "assets", "scripts", "loader.js"),
      requiredMarkers: ["__LUNA_ALLOWED_HOSTS__", "__LUNA_SET_ALLOWED_HOSTS__"],
    },
    {
      source: path.join(lunaDist, "wc-loader.iife.js"),
      target: path.join(root, "src", "ssg", "assets", "scripts", "wc-loader.js"),
    },
    {
      source: path.join(lunaDist, "sol-nav.js"),
      target: path.join(root, "src", "ssg", "assets", "scripts", "sol-nav.js"),
    },
    {
      source: path.join(lunaDist, "lib.js"),
      target: path.join(root, "src", "ssg", "assets", "scripts", "lib.js"),
    },
  ];

  for (const mapping of mappings) {
    if (!fs.existsSync(mapping.source)) {
      throw new Error(`missing luna asset: ${mapping.source}`);
    }
    if (!fs.existsSync(mapping.target)) {
      throw new Error(`missing sol asset target: ${mapping.target}`);
    }
  }

  let changedCount = 0;
  for (const mapping of mappings) {
    const result = syncOrCheck({
      sourcePath: mapping.source,
      targetPath: mapping.target,
      check,
      requiredMarkers: mapping.requiredMarkers,
      strict,
    });
    if (result.changed) {
      changedCount += 1;
      console.log(`synced ${path.relative(root, mapping.target)}`);
    } else if (result.checked) {
      console.log(`ok ${path.relative(root, mapping.target)}`);
    }
  }

  if (!check && !skipExamples) {
    const scriptPath = path.join(root, "scripts", "sync-example-static-assets.mjs");
    const child = spawnSync(process.execPath, [scriptPath], {
      cwd: root,
      stdio: "inherit",
    });
    if (child.status !== 0) {
      throw new Error("failed to sync examples static assets");
    }
  }

  if (!check) {
    console.log(`done (${changedCount} core assets updated)`);
  }
}

run();
