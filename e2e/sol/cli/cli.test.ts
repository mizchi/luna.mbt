/**
 * Sol CLI E2E Tests
 *
 * These tests verify the Sol CLI commands work correctly.
 * Run with: pnpm vitest e2e/sol/cli/cli.test.ts
 */
import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { execSync } from "node:child_process";
import { mkdtempSync, rmSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, "../../..");
const cliPath = join(rootDir, "target/js/release/build/sol/cli/cli.js");

// Helper to run CLI command
function runCli(
  args: string[],
  cwd?: string
): { stdout: string; stderr: string; status: number | null } {
  try {
    const result = execSync(`node ${cliPath} ${args.join(" ")}`, {
      cwd: cwd || rootDir,
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });
    return { stdout: result, stderr: "", status: 0 };
  } catch (e: any) {
    return {
      stdout: e.stdout || "",
      stderr: e.stderr || "",
      status: e.status || 1,
    };
  }
}

describe("Sol CLI", () => {
  test("shows help with --help flag", () => {
    const result = runCli(["--help"]);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("Sol CLI");
    expect(result.stdout).toContain("Usage: sol");
    expect(result.stdout).toContain("new");
    expect(result.stdout).toContain("dev");
    expect(result.stdout).toContain("build");
  });

  test("shows version with --version flag", () => {
    const result = runCli(["--version"]);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("sol 0.1.0");
  });

  test("shows help with -h flag", () => {
    const result = runCli(["-h"]);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("Sol CLI");
  });

  test("shows version with -v flag", () => {
    const result = runCli(["-v"]);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("sol 0.1.0");
  });

  test("shows error for unknown command", () => {
    const result = runCli(["unknown"]);
    expect(result.status).toBe(1);
    expect(result.stderr).toContain("Error");
    expect(result.stderr).toContain("unknown");
  });

  test("new --help shows new command help", () => {
    const result = runCli(["new", "--help"]);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("Usage: sol new");
    expect(result.stdout).toContain("<name>");
  });

  test("dev --help shows dev command help", () => {
    const result = runCli(["dev", "--help"]);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("Usage: sol dev");
    expect(result.stdout).toContain("--port");
  });

  test("build --help shows build command help", () => {
    const result = runCli(["build", "--help"]);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("Usage: sol build");
    expect(result.stdout).toContain("--target");
    expect(result.stdout).toContain("--skip-bundle");
  });

  test("new requires project name", () => {
    const result = runCli(["new"]);
    expect(result.status).toBe(1);
    expect(result.stderr).toContain("Error");
    expect(result.stderr).toContain("Project name is required");
  });
});

describe("Sol CLI - new command", () => {
  let tempDir: string;

  beforeEach(() => {
    tempDir = mkdtempSync(join(tmpdir(), "sol-cli-test-"));
  });

  afterEach(() => {
    if (tempDir && existsSync(tempDir)) {
      rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test("creates new project with embedded templates", () => {
    const projectName = "my-app";
    const result = runCli(["new", projectName, "--user", "testuser"], tempDir);

    // Should succeed with embedded templates
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("Project created successfully");

    // Verify generated files
    const projectPath = join(tempDir, projectName);
    expect(existsSync(join(projectPath, "moon.mod.json"))).toBe(true);
    expect(existsSync(join(projectPath, "package.json"))).toBe(true);
    expect(existsSync(join(projectPath, ".gitignore"))).toBe(true);
    expect(existsSync(join(projectPath, "sol.config.json"))).toBe(true);
    expect(existsSync(join(projectPath, "app/layout/layout.mbt"))).toBe(true);
    expect(existsSync(join(projectPath, "app/routes/routes.mbt"))).toBe(true);
    expect(existsSync(join(projectPath, "app/client/counter/counter.mbt"))).toBe(true);
    expect(existsSync(join(projectPath, "static/loader.js"))).toBe(true);
  });

  test("fails if directory already exists", () => {
    const projectName = "existing-dir";
    const projectPath = join(tempDir, projectName);

    // Create the directory first
    execSync(`mkdir -p ${projectPath}`);

    const result = runCli(["new", projectName, "--user", "testuser"], tempDir);
    expect(result.status).toBe(1);
    expect(result.stderr).toContain("already exists");
  });
});

describe("Sol CLI - build command", () => {
  test("fails in non-MoonBit project directory", () => {
    const tempDir = mkdtempSync(join(tmpdir(), "sol-cli-test-"));
    try {
      const result = runCli(["build"], tempDir);
      expect(result.status).toBe(1);
      expect(result.stderr).toContain("moon.mod.json not found");
    } finally {
      rmSync(tempDir, { recursive: true, force: true });
    }
  });

  test("runs build in MoonBit project", () => {
    // Run in the actual luna.mbt project directory
    const result = runCli(["build", "--skip-bundle"], rootDir);
    expect(result.status).toBe(0);
    expect(result.stdout).toContain("Moon build complete");
  });
});

describe("Sol CLI - dev command", () => {
  test("fails in non-MoonBit project directory", () => {
    const tempDir = mkdtempSync(join(tmpdir(), "sol-cli-test-"));
    try {
      const result = runCli(["dev"], tempDir);
      expect(result.status).toBe(1);
      expect(result.stderr).toContain("moon.mod.json not found");
    } finally {
      rmSync(tempDir, { recursive: true, force: true });
    }
  });
});
