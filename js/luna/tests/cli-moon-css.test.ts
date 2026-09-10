import { afterEach, expect, test, vi } from "vitest";
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, cpSync, rmSync, symlinkSync } from "node:fs";
import { execFileSync, spawn, type ChildProcess } from "node:child_process";
import { once } from "node:events";
import { join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { compileStyles } from "../src/css/compile.js";

const dirs: string[] = [];
const processes: ChildProcess[] = [];
afterEach(async () => {
  for (const child of processes.splice(0)) {
    if (child.exitCode === null && child.signalCode === null) {
      const exited = once(child, "exit");
      child.kill("SIGTERM");
      await exited;
    }
  }
  for (const dir of dirs.splice(0)) rmSync(dir, { recursive: true, force: true });
});
function fixture() {
  const dir = mkdtempSync(join(tmpdir(), "luna-moon-css-"));
  dirs.push(dir);
  return dir;
}

test("moon run starts the cmd/css source package and forwards arguments", () => {
  const help = execFileSync("moon", ["run", "--target", "js", "luna/src/cmd/css", "--", "--help"], { cwd: resolve("."), encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  expect(help).toContain("compile");
  expect(help).toContain("watch");
  expect(help).toContain("\n  compile <input>");
});

test("the Mooncake CLI works from a consumer workspace with no npm compiler installed", () => {
  const root = fixture();
  const library = join(root, "luna");
  const app = join(root, "app");
  mkdirSync(join(library, "src/cmd"), { recursive: true });
  cpSync(resolve("luna/src/cmd/css"), join(library, "src/cmd/css"), { recursive: true });
  // Package resolution scans the whole consumer workspace, including its imports.
  mkdirSync(join(library, "src/x/css"), { recursive: true });
  writeFileSync(join(library, "src/x/css/moon.pkg"), "");
  mkdirSync(app);
  writeFileSync(join(root, "moon.work"), 'members = ["./luna", "./app"]\n');
  writeFileSync(join(library, "moon.mod"), 'name = "mizchi/luna"\nversion = "0.23.3"\nsource = "src"\npreferred_target = "js"\n');
  writeFileSync(join(app, "moon.mod"), 'name = "tests/css-consumer"\nimport { "mizchi/luna@0.23.3" }\npreferred_target = "js"\n');
  writeFileSync(join(app, "package.json"), '{"type":"module"}\n');
  const input = join(app, "input with spaces");
  mkdirSync(input);
  writeFileSync(join(input, "moon.pkg"), 'import { "mizchi/luna/x/css" }\n');
  const source = '@css.attrs([@css.create([@css.rule_on(@css.Hover, @css.Color, "blue")])])';
  writeFileSync(join(input, "style.mbt"), source);
  const run = (args: string[]) => execFileSync("moon", ["run", "--target", "js", "../luna/src/cmd/css", "--", ...args], { cwd: app, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  expect(run(["compile", "input with spaces", "--output-dir", "generated styles"])).toContain("CSS compiled");
  expect(readFileSync(join(app, "generated styles/style.mbt"), "utf8")).toBe(compileStyles(source).code);
  expect(JSON.parse(run(["extract", "input with spaces", "--json", "--strict"])).css).toBe(compileStyles(source).css);
  expect(() => run(["unknown"])).toThrow();
  writeFileSync(join(input, "style.mbt"), '@css.rule(@css.Color, runtime_value)');
  expect(() => run(["compile", "input with spaces", "--output-dir", "generated styles"])).toThrow();
});

test("the bundled watch command loads the caller's Vite config and closes on SIGINT", async () => {
  execFileSync("moon", ["build", "--target", "js", "luna/src/cmd/css"], { stdio: "pipe" });
  const root = fixture();
  const built = resolve("_build/js/debug/build/mizchi/luna/cmd/css/css.js");
  writeFileSync(join(root, "css.mjs"), readFileSync(built));
  symlinkSync(resolve("node_modules"), join(root, "node_modules"), "dir");
  writeFileSync(join(root, "vite.config.mjs"), 'export default {plugins:[{name:"caller-config",configureServer(server){server.middlewares.use("/probe",(_req,res)=>res.end("caller config loaded"));}}]};');
  writeFileSync(join(root, "index.html"), "<p>watch</p>");
  const child = spawn(process.execPath, [join(root, "css.mjs"), "watch", "--root", root, "--host", "127.0.0.1", "--port", "0"], { cwd: root, stdio: ["ignore", "pipe", "pipe"] });
  processes.push(child);
  let output = "";
  child.stdout!.on("data", chunk => { output += chunk.toString(); });
  child.stderr!.on("data", chunk => { output += chunk.toString(); });
  await vi.waitFor(() => expect(output).toMatch(/http:\/\/127\.0\.0\.1:\d+\//), { timeout: 10000 });
  const url = output.match(/http:\/\/127\.0\.0\.1:\d+\//)![0];
  expect(await (await fetch(url + "probe")).text()).toBe("caller config loaded");
  const exited = once(child, "exit");
  child.kill("SIGINT");
  expect((await exited)[0]).toBe(130);
}, 15000);
