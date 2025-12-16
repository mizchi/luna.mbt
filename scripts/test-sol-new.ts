/**
 * Test script for `sol new` command
 * Verifies that generated templates build and run correctly
 *
 * Usage: node scripts/test-sol-new.ts
 */

import { execSync, spawn, type ChildProcess } from "node:child_process";
import { existsSync, rmSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as sleep } from "node:timers/promises";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, "..");
const testDir = "/tmp/sol-test-project";
const projectName = "sol-test-project";
const cliPath = join(rootDir, "target/js/release/build/sol/cli/cli.js");

// ANSI colors
const green = (s: string) => `\x1b[32m${s}\x1b[0m`;
const red = (s: string) => `\x1b[31m${s}\x1b[0m`;
const cyan = (s: string) => `\x1b[36m${s}\x1b[0m`;
const dim = (s: string) => `\x1b[2m${s}\x1b[0m`;

function log(msg: string) {
  console.log(msg);
}

function logStep(step: string) {
  log(`\n${cyan("▶")} ${step}`);
}

function logSuccess(msg: string) {
  log(`  ${green("✓")} ${msg}`);
}

function logError(msg: string) {
  log(`  ${red("✗")} ${msg}`);
}

function run(cmd: string, options: { cwd?: string } = {}): string {
  log(dim(`    $ ${cmd}`));
  try {
    const result = execSync(cmd, {
      cwd: options.cwd || rootDir,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    return result;
  } catch (error: any) {
    const stderr = error.stderr?.toString() || "";
    const stdout = error.stdout?.toString() || "";
    throw new Error(`Command failed: ${cmd}\nstderr: ${stderr}\nstdout: ${stdout}`);
  }
}

async function cleanup() {
  logStep("Cleaning up test directory");
  if (existsSync(testDir)) {
    rmSync(testDir, { recursive: true, force: true });
    logSuccess(`Removed ${testDir}`);
  } else {
    logSuccess("Test directory does not exist, nothing to clean");
  }
}

async function buildCli() {
  logStep("Building sol CLI");
  run("moon build --target js");
  if (!existsSync(cliPath)) {
    throw new Error(`CLI not found at ${cliPath}`);
  }
  logSuccess("CLI built successfully");
}

async function createProject() {
  logStep(`Creating new project: ${projectName}`);
  run(`node ${cliPath} new ${projectName}`, { cwd: "/tmp" });

  // Verify project structure
  const requiredFiles = [
    "moon.mod.json",
    "package.json",
    ".gitignore",
    "rolldown.config.mjs",
    "src/client/hydrate.mbt",
    "src/client/moon.pkg.json",
    "src/client/components/counter.mbt",
    "src/server/run/main.mbt",
    "static/loader.js",
  ];

  for (const file of requiredFiles) {
    const filePath = join(testDir, file);
    if (!existsSync(filePath)) {
      throw new Error(`Missing required file: ${file}`);
    }
  }
  logSuccess("Project created with all required files");
}

async function patchMoonMod() {
  logStep("Patching moon.mod.json to use local luna");
  const moonModPath = join(testDir, "moon.mod.json");
  const moonMod = {
    name: projectName,
    version: "0.1.0",
    deps: {
      "mizchi/luna": {
        path: rootDir,
      },
      "mizchi/js": "0.10.0",
    },
    source: "src",
  };
  writeFileSync(moonModPath, JSON.stringify(moonMod, null, 2));
  logSuccess("Patched moon.mod.json to use local luna path");
}

async function installDependencies() {
  logStep("Installing dependencies");
  run("moon install", { cwd: testDir });
  logSuccess("Moon dependencies installed");

  run("npm install", { cwd: testDir });
  logSuccess("NPM dependencies installed");
}

async function buildProject() {
  logStep("Building project with moon");
  run("moon build --target js", { cwd: testDir });

  // Verify build output
  const serverJsPath = join(
    testDir,
    "target/js/release/build/server/run/run.js"
  );
  if (!existsSync(serverJsPath)) {
    throw new Error("Server build output not found");
  }
  logSuccess("Project built successfully");
}

async function testServer() {
  logStep("Testing server");

  const serverJsPath = join(
    testDir,
    "target/js/release/build/server/run/run.js"
  );

  // Start server in background
  const serverProcess: ChildProcess = spawn("node", [serverJsPath], {
    cwd: testDir,
    stdio: ["ignore", "pipe", "pipe"],
    detached: false,
  });

  const killServer = () => {
    try {
      serverProcess.kill("SIGTERM");
    } catch {
      // ignore
    }
  };

  try {
    // Wait for server to start
    await sleep(2000);

    // Test home page
    const homeResponse = await fetch("http://localhost:3000");
    if (!homeResponse.ok) {
      throw new Error(`Home page returned ${homeResponse.status}`);
    }
    const homeHtml = await homeResponse.text();

    if (!homeHtml.includes("Welcome to Sol")) {
      throw new Error("Home page missing expected content");
    }
    if (!homeHtml.includes('ln:id="counter"')) {
      throw new Error("Home page missing counter island");
    }
    logSuccess("Home page renders correctly");

    // Test about page
    const aboutResponse = await fetch("http://localhost:3000/about");
    if (!aboutResponse.ok) {
      throw new Error(`About page returned ${aboutResponse.status}`);
    }
    const aboutHtml = await aboutResponse.text();

    if (!aboutHtml.includes("About")) {
      throw new Error("About page missing expected content");
    }
    logSuccess("About page renders correctly");

    // Test API endpoint
    const apiResponse = await fetch("http://localhost:3000/api/health");
    if (!apiResponse.ok) {
      throw new Error(`API endpoint returned ${apiResponse.status}`);
    }
    const apiJson = await apiResponse.json();

    if (!apiJson || typeof apiJson !== "object") {
      throw new Error("API endpoint returned invalid JSON");
    }
    logSuccess("API endpoint works correctly");

    // Test static file serving
    const loaderResponse = await fetch(
      "http://localhost:3000/static/loader.js"
    );
    if (!loaderResponse.ok) {
      throw new Error(`Static file returned ${loaderResponse.status}`);
    }
    const loaderContent = await loaderResponse.text();
    if (!loaderContent.includes("luna loader")) {
      throw new Error("Loader script missing expected content");
    }
    logSuccess("Static file serving works correctly");
  } finally {
    // Kill server process
    killServer();
    await sleep(500);
  }
}

async function main() {
  log(cyan("\n═══════════════════════════════════════════════════════════"));
  log(cyan("  Sol CLI Template Test"));
  log(cyan("═══════════════════════════════════════════════════════════\n"));

  const startTime = Date.now();

  try {
    await cleanup();
    await buildCli();
    await createProject();
    await patchMoonMod();
    await installDependencies();
    await buildProject();
    await testServer();
    await cleanup();

    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    log(`\n${green("═══════════════════════════════════════════════════════════")}`);
    log(`${green("  All tests passed!")} ${dim(`(${elapsed}s)`)}`);
    log(`${green("═══════════════════════════════════════════════════════════")}\n`);
    process.exit(0);
  } catch (error) {
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
    log(`\n${red("═══════════════════════════════════════════════════════════")}`);
    log(`${red("  Test failed!")} ${dim(`(${elapsed}s)`)}`);
    log(`${red("═══════════════════════════════════════════════════════════")}`);
    if (error instanceof Error) {
      logError(error.message);
      if (error.stack) {
        log(dim(error.stack));
      }
    }
    // Cleanup on failure
    await cleanup().catch(() => {});
    process.exit(1);
  }
}

main();
