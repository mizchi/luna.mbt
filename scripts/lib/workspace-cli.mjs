import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const workspace = new URL("../", import.meta.url);

// The library-only workspace can build either CLI before example code exists.
export function buildWorkspaceCli(name) {
  if (name !== "sol" && name !== "astra") throw new Error(`Unknown workspace CLI: ${name}`);
  const target = name === "sol" ? "sol_js" : "astra";
  const result = spawnSync("moon", ["build", "--target", "js", `../${name}/src/cmd/${target}`], {
    cwd: fileURLToPath(workspace),
    stdio: ["ignore", "inherit", "inherit"],
  });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
  return new URL(`_build/js/debug/build/mizchi/${name}/cmd/${target}/${target}.js`, workspace);
}
