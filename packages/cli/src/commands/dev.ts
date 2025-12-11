/**
 * kaguya dev - Start development server
 */
import { Command } from "commander";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import pc from "picocolors";

export const devCommand = new Command("dev")
  .description("Start development server")
  .option("-p, --port <port>", "Port to listen on", "3000")
  .action(async (options: { port: string }) => {
    const cwd = process.cwd();

    // Check if this is a MoonBit project
    if (!existsSync(join(cwd, "moon.mod.json"))) {
      console.error(pc.red("Error: Not a MoonBit project (moon.mod.json not found)"));
      process.exit(1);
    }

    console.log(pc.cyan("Starting Kaguya development server..."));

    // Step 1: Build MoonBit project
    console.log(pc.gray("Building MoonBit project..."));
    const buildResult = await runCommand("moon", ["build", "--target", "js"]);
    if (!buildResult.success) {
      console.error(pc.red("Build failed"));
      process.exit(1);
    }
    console.log(pc.green("✓ Build complete"));

    // Step 2: Find and run the server entry point
    // Look for common patterns: server/run, src/server, main
    const possibleEntries = [
      "target/js/release/build/server/run/run.js",
      "target/js/release/build/examples/example_app/example_app.js",
      "target/js/release/build/main/main.js",
    ];

    let entryPoint: string | null = null;
    for (const entry of possibleEntries) {
      if (existsSync(join(cwd, entry))) {
        entryPoint = entry;
        break;
      }
    }

    if (!entryPoint) {
      console.error(pc.red("Error: Could not find server entry point"));
      console.log(pc.gray("Expected one of:"));
      possibleEntries.forEach((e) => console.log(pc.gray(`  - ${e}`)));
      process.exit(1);
    }

    console.log(pc.cyan(`Running ${entryPoint}...`));

    // Run the server
    const serverProcess = spawn("node", [entryPoint], {
      cwd,
      stdio: "inherit",
      env: { ...process.env, PORT: options.port },
    });

    serverProcess.on("error", (err) => {
      console.error(pc.red(`Server error: ${err.message}`));
      process.exit(1);
    });

    serverProcess.on("exit", (code) => {
      process.exit(code ?? 0);
    });
  });

function runCommand(
  cmd: string,
  args: string[]
): Promise<{ success: boolean; output: string }> {
  return new Promise((resolve) => {
    const proc = spawn(cmd, args, { stdio: "pipe" });
    let output = "";

    proc.stdout?.on("data", (data) => {
      output += data.toString();
      process.stdout.write(data);
    });

    proc.stderr?.on("data", (data) => {
      output += data.toString();
      process.stderr.write(data);
    });

    proc.on("close", (code) => {
      resolve({ success: code === 0, output });
    });

    proc.on("error", () => {
      resolve({ success: false, output });
    });
  });
}
