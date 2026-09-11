import { spawnSync } from "node:child_process";
import { readdirSync, existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { buildWorkspaceCli } from "./lib/workspace-cli.mjs";

const root = fileURLToPath(new URL("../", import.meta.url));
const cli = fileURLToPath(buildWorkspaceCli("sol"));

function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

for (const entry of readdirSync(path.join(root, "sol/examples"), { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  const dir = path.join(root, "sol/examples", entry.name);
  if (!existsSync(path.join(dir, "moon.mod")) || !existsSync(path.join(dir, "sol.config.json"))) continue;
  console.log(`Generating sol/examples/${entry.name}`);
  run(process.execPath, [cli, "generate"], dir);
}
