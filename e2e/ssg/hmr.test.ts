import { test, expect } from "@playwright/test";
import { spawn, ChildProcess, execSync } from "node:child_process";
import { writeFileSync, readFileSync, unlinkSync, existsSync } from "node:fs";
import { join } from "node:path";
import WebSocket from "ws";

const PROJECT_ROOT = join(import.meta.dirname, "../..");
const DOCS_DIR = join(PROJECT_ROOT, "docs");
const TEST_FILE = join(DOCS_DIR, "_hmr_test_temp.md");
const DEV_SERVER_PORT = 3355;
const HMR_PORT = 24679;

let devServer: ChildProcess | null = null;

// Kill any existing processes on our ports
function killExistingProcesses(): void {
  try {
    execSync(`lsof -ti:${DEV_SERVER_PORT},${HMR_PORT} | xargs kill -9 2>/dev/null || true`, {
      stdio: "ignore",
    });
  } catch {
    // Ignore errors
  }
}

async function startDevServer(): Promise<void> {
  return new Promise((resolve, reject) => {
    const cliPath = join(
      PROJECT_ROOT,
      "target/js/release/build/astra/cli/cli.js"
    );

    devServer = spawn("node", [cliPath, "dev"], {
      cwd: PROJECT_ROOT,
      stdio: ["pipe", "pipe", "pipe"],
    });

    let started = false;
    let output = "";

    devServer.stdout?.on("data", (data: Buffer) => {
      output += data.toString();
      // Wait for server to be ready
      if (output.includes("Dev server running at") && !started) {
        started = true;
        // Give it a moment to fully initialize
        setTimeout(resolve, 1000);
      }
    });

    devServer.stderr?.on("data", (data: Buffer) => {
      const errOutput = data.toString();
      console.error("[dev-server stderr]", errOutput);
      // Check for address in use error
      if (errOutput.includes("EADDRINUSE")) {
        reject(new Error(`Port already in use: ${errOutput}`));
      }
    });

    devServer.on("error", reject);

    devServer.on("exit", (code) => {
      if (!started && code !== 0) {
        reject(new Error(`Dev server exited with code ${code}`));
      }
    });

    // Timeout after 60 seconds
    setTimeout(() => {
      if (!started) {
        reject(new Error("Dev server failed to start within 60 seconds"));
      }
    }, 60000);
  });
}

function stopDevServer(): void {
  if (devServer) {
    devServer.kill("SIGTERM");
    devServer = null;
  }
}

async function connectWebSocket(): Promise<WebSocket> {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://localhost:${HMR_PORT}`);

    ws.on("open", () => {
      resolve(ws);
    });

    ws.on("error", (err) => {
      reject(err);
    });

    setTimeout(() => {
      reject(new Error("WebSocket connection timeout"));
    }, 5000);
  });
}

async function waitForReloadMessage(ws: WebSocket, timeoutMs = 30000): Promise<void> {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      reject(new Error(`Did not receive reload message within ${timeoutMs / 1000} seconds`));
    }, timeoutMs);

    ws.on("message", (data: Buffer) => {
      const message = JSON.parse(data.toString());
      if (message.type === "reload") {
        clearTimeout(timeout);
        resolve();
      }
    });
  });
}

function cleanupTestFile(): void {
  try {
    if (existsSync(TEST_FILE)) {
      unlinkSync(TEST_FILE);
    }
  } catch {
    // Ignore errors
  }
}

test.describe("Astra HMR", () => {
  test.beforeAll(async () => {
    // Kill any existing processes
    killExistingProcesses();

    // Wait a bit for ports to be released
    await new Promise((r) => setTimeout(r, 1000));

    // Clean up any existing test file
    cleanupTestFile();

    // Start dev server
    await startDevServer();
  });

  test.afterAll(async () => {
    // Stop dev server
    stopDevServer();

    // Clean up test file
    cleanupTestFile();
  });

  test("sends reload message when markdown file changes", async () => {
    // Connect to HMR WebSocket
    const ws = await connectWebSocket();

    try {
      // Set up listener for reload message before making changes
      // Use longer timeout for CI environments where fs.watch may be slow
      const reloadPromise = waitForReloadMessage(ws, 30000);

      // Wait for connection to fully stabilize
      await new Promise((r) => setTimeout(r, 1000));

      // Create a new test file (triggers "new file added" rebuild)
      const testContent = `---
title: HMR Test
---

# HMR Test Page

This is a test page for HMR.
`;
      writeFileSync(TEST_FILE, testContent);

      // Wait for reload message
      await reloadPromise;

      // If we get here, the test passed
      expect(true).toBe(true);
    } finally {
      ws.close();
    }
  });

  test("HTTP server serves pages correctly", async ({ request }) => {
    // Test that the HTTP server is working
    const response = await request.get(`http://localhost:${DEV_SERVER_PORT}/`);
    expect(response.ok()).toBeTruthy();

    const html = await response.text();
    expect(html).toContain("</html>");
  });

  test("HTML includes HMR client script", async ({ request }) => {
    const response = await request.get(`http://localhost:${DEV_SERVER_PORT}/`);
    const html = await response.text();

    // Check that HMR script is injected
    expect(html).toContain("WebSocket");
    expect(html).toContain(`ws://localhost:${HMR_PORT}`);
  });
});
