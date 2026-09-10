import { afterEach, expect, test, vi } from "vitest";
import { createServer, build as viteBuild, type ViteDevServer } from "vite";
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, rmSync, readdirSync, copyFileSync, realpathSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { lunaCssCompile } from "../src/vite-plugin.js";

const roots: string[] = [];
const servers: ViteDevServer[] = [];
afterEach(async () => {
  for (const server of servers.splice(0)) await server.close();
  for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true });
});
function fixture() {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "luna-css-vite-")));
  roots.push(root);
  mkdirSync(join(root, "input"));
  writeFileSync(join(root, "input/moon.pkg"), 'import { "mizchi/luna/x/css" }\n');
  writeFileSync(join(root, "input/style.mbt"), declaration("red"));
  writeFileSync(join(root, "index.html"), "<html><body>test</body></html>");
  return root;
}
function declaration(color: string) { return `pub fn style() -> @css.Style { @css.create([@css.rule(@css.Color, "${color}")]) }`; }
async function start(root: string, builder: NonNullable<Parameters<typeof lunaCssCompile>[0]["build"]>) {
  const server = await createServer({
    configFile: false, root, logLevel: "silent",
    plugins: [lunaCssCompile({ input: "input", outputDir: "output", debounceMs: 10, build: builder })],
    server: { port: 0, watch: { usePolling: true, interval: 20 } },
    optimizeDeps: { noDiscovery: true, include: [] },
  });
  servers.push(server);
  await server.listen();
  return server;
}

test("real Vite watcher compiles edits, additions, deletions and invalidates CSS", async () => {
  const root = fixture();
  const builder = vi.fn();
  const server = await start(root, builder);
  expect(builder).toHaveBeenCalledTimes(1);
  expect((await server.transformRequest("virtual:luna-compiled.css"))!.code).toContain("color:red");
  const send = vi.spyOn(server.ws, "send");
  writeFileSync(join(root, "input/style.mbt"), declaration("green"));
  await vi.waitFor(() => expect(builder).toHaveBeenCalledTimes(2));
  await vi.waitFor(async () => expect((await server.transformRequest("virtual:luna-compiled.css"))!.code).toContain("color:green"));
  expect(send).toHaveBeenCalledWith({ type: "full-reload" });
  writeFileSync(join(root, "input/new.mbt"), declaration("blue"));
  await vi.waitFor(() => expect(readFileSync(join(root, "output/luna.css"), "utf8")).toContain("color:blue"));
  rmSync(join(root, "input/new.mbt"));
  await vi.waitFor(() => expect(readFileSync(join(root, "output/luna.css"), "utf8")).not.toContain("color:blue"));
});

test("changes during an async build are serialized and only the latest build reloads", async () => {
  const root = fixture();
  let release!: () => void;
  let entered!: () => void;
  const blocked = new Promise<void>(resolve => { release = resolve; });
  const started = new Promise<void>(resolve => { entered = resolve; });
  let calls = 0;
  let active = 0;
  let maxActive = 0;
  const server = await start(root, async () => {
    calls++;
    maxActive = Math.max(maxActive, ++active);
    if (calls === 2) { entered(); await blocked; }
    active--;
  });
  const send = vi.spyOn(server.ws, "send");
  const file = join(root, "input/style.mbt");
  writeFileSync(file, declaration("green"));
  server.watcher.emit("all", "change", file);
  await started;
  writeFileSync(file, declaration("blue"));
  server.watcher.emit("all", "change", file);
  release();
  await vi.waitFor(() => expect(calls).toBe(3));
  await vi.waitFor(() => expect(send.mock.calls.filter(([payload]) => typeof payload !== "string" && payload.type === "full-reload")).toHaveLength(1));
  expect(maxActive).toBe(1);
  expect((await server.transformRequest("virtual:luna-compiled.css"))!.code).toContain("color:blue");
});

test("compile and build errors show an overlay and recover on the next change", async () => {
  const root = fixture();
  let failBuild = false;
  const builder = vi.fn(async () => { if (failBuild) throw new Error("MoonBit build failed"); });
  const server = await start(root, builder);
  const send = vi.spyOn(server.ws, "send");
  const file = join(root, "input/style.mbt");
  writeFileSync(file, '@css.rule(@css.Color, runtime_value)');
  server.watcher.emit("all", "change", file);
  await vi.waitFor(() => expect(send).toHaveBeenCalledWith(expect.objectContaining({ type: "error" })));
  expect(send).not.toHaveBeenCalledWith({ type: "full-reload" });
  expect((await server.transformRequest("virtual:luna-compiled.css"))!.code).toContain("color:red");
  send.mockClear();
  failBuild = true;
  writeFileSync(file, declaration("green"));
  server.watcher.emit("all", "change", file);
  await vi.waitFor(() => expect(send).toHaveBeenCalledWith(expect.objectContaining({ type: "error", err: expect.objectContaining({ message: "MoonBit build failed" }) })));
  expect(send).not.toHaveBeenCalledWith({ type: "full-reload" });
  failBuild = false;
  server.watcher.emit("all", "change", file); // Same input still retries a failed build.
  await vi.waitFor(() => expect(send).toHaveBeenCalledWith({ type: "full-reload" }));
  expect((await server.transformRequest("virtual:luna-compiled.css"))!.code).toContain("color:green");
});

test("production Vite build runs MoonBit and bundles compiled CSS and JS", async () => {
  const root = fixture();
  rmSync(join(root, "input"), { recursive: true });
  mkdirSync(join(root, "input/css"), { recursive: true });
  mkdirSync(join(root, "input/app"));
  writeFileSync(join(root, "input/moon.mod"), 'name = "tests/css-vite"\n');
  for (const file of readdirSync(resolve("luna/src/x/css"))) {
    if (file === "moon.pkg" || (file.endsWith(".mbt") && !file.endsWith("_test.mbt"))) copyFileSync(resolve("luna/src/x/css", file), join(root, "input/css", file));
  }
  writeFileSync(join(root, "input/app/moon.pkg"), 'import { "tests/css-vite/css" }\nsupported_targets = "js"\noptions(link: { "js": { "exports": ["class_name"], "format": "esm" } })\n');
  writeFileSync(join(root, "input/app/app.mbt"), 'pub fn class_name() -> String { @css.attrs([@css.create([@css.rule(@css.Color, "red")])]).class_name }');
  writeFileSync(join(root, "main.js"), 'import "virtual:luna-compiled.css"; import {class_name} from "virtual:luna-compiled/app/app.js"; document.body.className = class_name();');
  writeFileSync(join(root, "index.html"), '<script type="module" src="/main.js"></script>');
  await viteBuild({ configFile: false, root, logLevel: "silent", plugins: [lunaCssCompile({ input: "input", outputDir: "output", cssPackage: "tests/css-vite/css" })], build: { minify: false } });
  const assets = readdirSync(join(root, "dist/assets"));
  expect(readFileSync(join(root, "dist/assets", assets.find(f => f.endsWith(".css"))!), "utf8")).toContain("color:red");
  expect(readFileSync(join(root, "dist/assets", assets.find(f => f.endsWith(".js"))!), "utf8")).not.toContain("djb2_hash");
  const watcher = await viteBuild({ configFile: false, root, logLevel: "silent", plugins: [lunaCssCompile({ input: "input", outputDir: "output", cssPackage: "tests/css-vite/css" })], build: { minify: false, watch: {} } }) as { close(): Promise<void>; on(event: string, callback: (event: {code: string}) => void): void };
  try {
    let builds = 0;
    watcher.on("event", event => { if (event.code === "END") builds++; });
    await vi.waitFor(() => expect(builds).toBeGreaterThan(0));
    writeFileSync(join(root, "input/app/app.mbt"), 'pub fn class_name() -> String { @css.attrs([@css.create([@css.rule(@css.Color, "green")])]).class_name }');
    await vi.waitFor(() => {
      const html = readFileSync(join(root, "dist/index.html"), "utf8");
      const css = html.match(/href="([^\"]+\.css)"/)![1];
      const js = html.match(/src="([^\"]+\.js)"/)![1];
      expect(readFileSync(join(root, "dist", css), "utf8")).toContain("color:green");
      expect(readFileSync(join(root, "dist", js), "utf8")).toContain("_1hkof");
    }, { timeout: 4000 });
  } finally { await watcher.close(); }
});

test("a source error on startup can be repaired without restarting Vite", async () => {
  const root = fixture();
  const file = join(root, "input/style.mbt");
  writeFileSync(file, '@css.rule(@css.Color, dynamic_color)');
  const builder = vi.fn();
  const server = await start(root, builder);
  await expect(server.transformRequest("virtual:luna-compiled.css")).rejects.toThrow(/dynamic_color/);
  const send = vi.spyOn(server.ws, "send");
  writeFileSync(file, declaration("blue"));
  server.watcher.emit("all", "change", file);
  await vi.waitFor(() => expect(send).toHaveBeenCalledWith({ type: "full-reload" }));
  expect(builder).toHaveBeenCalledTimes(1);
  expect((await server.transformRequest("virtual:luna-compiled.css"))!.code).toContain("color:blue");
});

test("server close removes listeners and aborts the in-flight build", async () => {
  const root = fixture();
  let started!: () => void;
  const entered = new Promise<void>(resolve => { started = resolve; });
  let calls = 0;
  let aborted = false;
  const server = await start(root, async ({ signal }) => {
    if (++calls === 1) return;
    started();
    await new Promise<void>(resolve => signal.addEventListener("abort", () => { aborted = true; resolve(); }, { once: true }));
  });
  writeFileSync(join(root, "input/style.mbt"), declaration("blue"));
  server.watcher.emit("all", "change", join(root, "input/style.mbt"));
  await entered;
  await server.close();
  servers.splice(servers.indexOf(server), 1);
  expect(aborted).toBe(true);
  expect(server.watcher.listenerCount("all")).toBe(0);
});
