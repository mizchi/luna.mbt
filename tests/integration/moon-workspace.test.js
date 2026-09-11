import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../../", import.meta.url));
const ignored = new Set([".git", ".agents", ".claude", "apm_modules", ".mooncakes", "node_modules", "_build", "_target", "target", "dist", "__gen__", ".sol"]);

function manifests(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    if (ignored.has(entry.name)) return [];
    const file = path.join(dir, entry.name);
    if (entry.isDirectory()) return manifests(file);
    return /^moon\.(mod|pkg)(\.json)?$/.test(entry.name) ? [file] : [];
  });
}

test("every checked-in MoonBit example belongs to the root workspace", () => {
  const work = readFileSync(path.join(root, "moon.work"), "utf8");
  const members = new Set([...work.matchAll(/"([^"]+)"/g)].map((m) => path.resolve(root, m[1])));
  const examples = manifests(root).filter((file) => file.includes(`${path.sep}examples${path.sep}`) && /moon\.mod(\.json)?$/.test(file));
  assert.ok(examples.length > 0);
  assert.deepEqual(examples.filter((file) => !members.has(path.dirname(file))).map((file) => path.relative(root, file)), []);
});

test("checked-in MoonBit manifests use the current configuration format", () => {
  assert.deepEqual(manifests(root).filter((file) => file.endsWith(".json")).map((file) => path.relative(root, file)), []);
});

test("vup synchronizes modern example imports without bumping example versions", (t) => {
  const stage = mkdtempSync(path.join(tmpdir(), "luna-vup-workspace-"));
  t.after(() => rmSync(stage, { recursive: true, force: true }));
  const files = ["luna/scripts/vup.mjs", ...["luna", "luna_components", "sol", "sol_adapter_cloudflare", "sol_adapter_node", "astra"].map((dir) => `${dir}/moon.mod`)];
  for (const file of files) {
    mkdirSync(path.dirname(path.join(stage, file)), { recursive: true });
    writeFileSync(path.join(stage, file), readFileSync(path.join(root, file)));
  }
  const example = path.join(stage, "sol/examples/sample/moon.mod");
  mkdirSync(path.dirname(example), { recursive: true });
  const before = 'name = "example/sample"\nversion = "0.1.0"\n\nimport {\n  "mizchi/luna@0.1.0",\n  "mizchi/sol@0.1.0",\n  "mizchi/js@0.12.2",\n}\n';
  writeFileSync(example, before);
  function bump(...args) {
    const result = spawnSync(process.execPath, [path.join(stage, files[0]), "9.8.7", ...args], { cwd: stage, encoding: "utf8" });
    assert.equal(result.status, 0, result.stderr);
  }
  bump("--dry-run");
  assert.equal(readFileSync(example, "utf8"), before);
  bump();
  const after = readFileSync(example, "utf8");
  assert.equal(after, before.replaceAll("@0.1.0", "@9.8.7"));
  bump();
  assert.equal(readFileSync(example, "utf8"), after);
  assert.ok(!existsSync(path.join(stage, ".git")), "version updates do not require a release");
});
