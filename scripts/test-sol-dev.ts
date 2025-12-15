/**
 * Test script for `sol dev` command
 * Verifies that sol dev properly generates, builds, bundles, and starts the server
 *
 * Usage: npx tsx scripts/test-sol-dev.ts
 */

import { execSync, spawn, type ChildProcess } from "node:child_process";
import { existsSync, rmSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { setTimeout as sleep } from "node:timers/promises";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, "..");
const testDir = "/tmp/sol-dev-test-project";
const projectName = "sol-dev-test-project";
const cliPath = join(rootDir, "target/js/release/build/sol/cli/cli.js");
const testPort = 3456;

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

async function fetchWithRetry(url: string, retries = 10, delay = 1000): Promise<Response> {
  let lastError: Error | null = null;
  for (let i = 0; i < retries; i++) {
    try {
      const res = await fetch(url);
      return res;
    } catch (e) {
      lastError = e as Error;
      if (i < retries - 1) {
        await sleep(delay);
      }
    }
  }
  throw new Error(`Failed to fetch ${url} after ${retries} retries: ${lastError?.message}`);
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
  run(`node ${cliPath} new ${projectName} --user testuser`, { cwd: "/tmp" });

  // Verify project structure
  const requiredFiles = [
    ".gitignore",
    "moon.mod.json",
    "package.json",
    "sol.config.json",
    "app/client/hydrate.mbt",
    "app/client/components/counter.mbt",
    "app/server/run/main.mbt",
    "app/server/pages/home/home.mbt",
    "static/loader.min.js",
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
    name: `testuser/${projectName}`,
    version: "0.1.0",
    deps: {
      "mizchi/luna": {
        path: rootDir,
      },
      "mizchi/js": "0.10.0",
      "mizchi/npm_typed": "0.1.1",
    },
    source: "app",
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

async function testSolDev() {
  logStep(`Testing sol dev (port ${testPort})`);

  // Kill any process using the test port
  try {
    execSync(`lsof -ti:${testPort} | xargs kill -9 2>/dev/null || true`, { stdio: "ignore" });
    await sleep(500);
  } catch {
    // ignore
  }

  // Start sol dev in background
  const devProcess: ChildProcess = spawn(
    "node",
    [cliPath, "dev", "--port", testPort.toString()],
    {
      cwd: testDir,
      stdio: ["ignore", "pipe", "pipe"],
      detached: false,
    }
  );

  let stdout = "";
  let stderr = "";

  devProcess.stdout?.on("data", (data) => {
    stdout += data.toString();
  });

  devProcess.stderr?.on("data", (data) => {
    stderr += data.toString();
  });

  const killServer = () => {
    try {
      devProcess.kill("SIGTERM");
    } catch {
      // ignore
    }
  };

  try {
    // Wait for server to be ready by polling output
    log(dim("    Waiting for sol dev to complete build pipeline..."));
    const maxWait = 60000; // 60s max
    const pollInterval = 500;
    let waited = 0;

    while (waited < maxWait) {
      const output = stdout + stderr;
      if (output.includes("Server starting at") || output.includes("Server running at")) {
        break;
      }
      if (output.includes("Build failed") || output.includes("error:")) {
        log(dim(`    Output: ${output.slice(-500)}`));
        throw new Error("sol dev failed during build");
      }
      await sleep(pollInterval);
      waited += pollInterval;
    }

    if (waited >= maxWait) {
      throw new Error(`sol dev did not start within ${maxWait / 1000}s`);
    }

    // Wait for static files to be generated
    const staticFile = join(testDir, ".sol/static/hydrate_counter.js");
    let staticWait = 0;
    while (!existsSync(staticFile) && staticWait < 10000) {
      await sleep(500);
      staticWait += 500;
    }

    // Give server a moment to be ready for requests
    await sleep(500);
    log(dim(`    Server ready in ${((waited + staticWait) / 1000).toFixed(1)}s`));

    // Check sol dev output for expected messages
    const output = stdout + stderr;

    if (!output.includes("Generate complete") && !output.includes("Generation complete")) {
      log(dim(`    Output: ${output.slice(0, 500)}`));
      throw new Error("sol dev did not complete generate step");
    }
    logSuccess("Generate step completed");

    if (!output.includes("Build complete")) {
      throw new Error("sol dev did not complete build step");
    }
    logSuccess("Build step completed");

    if (!output.includes("Client bundle complete")) {
      throw new Error("sol dev did not complete bundle step");
    }
    logSuccess("Bundle step completed");

    if (!output.includes(`http://localhost:${testPort}`)) {
      throw new Error("sol dev did not display correct port");
    }
    logSuccess(`Port display shows ${testPort}`);

    // Verify generated files
    const generatedFiles = [
      ".sol/entry.client.js",
      ".sol/entry.server.js",
      ".sol/luna-client-entry.js",
      ".sol/islands/island_client_hydrate_counter.js",
      "rolldown.config.mjs",
      ".sol/static/hydrate_counter.js",
    ];

    for (const file of generatedFiles) {
      const filePath = join(testDir, file);
      if (!existsSync(filePath)) {
        throw new Error(`Missing generated file: ${file}`);
      }
    }
    logSuccess("All intermediate files generated");

    // Test home page
    const homeResponse = await fetchWithRetry(`http://localhost:${testPort}`);
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
    if (!homeHtml.includes('ln:url="/static/hydrate_counter.js"')) {
      throw new Error("Home page missing island URL for individual hydration");
    }
    logSuccess("Home page renders correctly with island");

    // Test about page
    const aboutResponse = await fetchWithRetry(`http://localhost:${testPort}/about`);
    if (!aboutResponse.ok) {
      throw new Error(`About page returned ${aboutResponse.status}`);
    }
    const aboutHtml = await aboutResponse.text();

    if (!aboutHtml.includes("About")) {
      throw new Error("About page missing expected content");
    }
    logSuccess("About page renders correctly");

    // Test API endpoint
    const apiResponse = await fetchWithRetry(`http://localhost:${testPort}/api/health`);
    if (!apiResponse.ok) {
      throw new Error(`API endpoint returned ${apiResponse.status}`);
    }
    const apiJson = await apiResponse.json();

    if (!apiJson || typeof apiJson !== "object") {
      throw new Error("API endpoint returned invalid JSON");
    }
    logSuccess("API endpoint works correctly");

    // Test individual island bundle
    if (devProcess.exitCode !== null) {
      throw new Error(`Server process exited with code ${devProcess.exitCode}`);
    }
    const islandResponse = await fetchWithRetry(
      `http://localhost:${testPort}/static/hydrate_counter.js`
    );
    if (!islandResponse.ok) {
      throw new Error(`Island bundle returned ${islandResponse.status}`);
    }
    const islandContent = await islandResponse.text();
    if (islandContent.length < 1000) {
      throw new Error(`Island bundle too small: ${islandContent.length} bytes (content: ${islandContent.slice(0, 100)}...)`);
    }
    logSuccess(`Individual island bundle served correctly (${islandContent.length} bytes)`);

    // Test static loader
    const loaderResponse = await fetchWithRetry(
      `http://localhost:${testPort}/static/loader.min.js`
    );
    if (!loaderResponse.ok) {
      throw new Error(`Static loader returned ${loaderResponse.status}`);
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
  log(cyan("  Sol Dev Integration Test"));
  log(cyan("═══════════════════════════════════════════════════════════\n"));

  const startTime = Date.now();

  try {
    await cleanup();
    await buildCli();
    await createProject();
    await patchMoonMod();
    await installDependencies();
    await testSolDev();
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
