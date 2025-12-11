/**
 * kaguya build - Build for production
 */
import { Command } from "commander";
import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { join } from "node:path";
import pc from "picocolors";

export const buildCommand = new Command("build")
  .description("Build for production")
  .option("--target <target>", "Build target (js, wasm)", "js")
  .action(async (options: { target: string }) => {
    const cwd = process.cwd();

    // Check if this is a MoonBit project
    if (!existsSync(join(cwd, "moon.mod.json"))) {
      console.error(pc.red("Error: Not a MoonBit project (moon.mod.json not found)"));
      process.exit(1);
    }

    console.log(pc.cyan(`Building for production (target: ${options.target})...`));

    // Run moon build
    const buildResult = await runCommand("moon", [
      "build",
      "--target",
      options.target,
    ]);

    if (!buildResult.success) {
      console.error(pc.red("Build failed"));
      process.exit(1);
    }

    console.log(pc.green("✓ Build complete"));
    console.log(pc.gray(`Output: target/${options.target}/release/build/`));
  });

function runCommand(
  cmd: string,
  args: string[]
): Promise<{ success: boolean; output: string }> {
  return new Promise((resolve) => {
    const proc = spawn(cmd, args, { stdio: "inherit" });

    proc.on("close", (code) => {
      resolve({ success: code === 0, output: "" });
    });

    proc.on("error", () => {
      resolve({ success: false, output: "" });
    });
  });
}
