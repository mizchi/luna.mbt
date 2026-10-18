import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../../../", import.meta.url));

function run(command, args) {
  const result = spawnSync(command, args, { cwd: root, stdio: "inherit" });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

run(process.execPath, ["scripts/check-moon-toolchain.mjs"]);
// Build only modules imported by the npm wrapper. Packing Luna must not run
// Sol/Astra example generation or depend on their standalone MoonBit modules.
for (const entry of [
  "js/api",
  "js/api_signals",
  "js/api_resource_lite",
  "js/api_router_lite",
  "js/animation",
  "easing",
]) {
  run("moon", ["build", "--target", "js", "--release", `luna/src/${entry}`]);
}
