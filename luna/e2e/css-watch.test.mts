import { test, expect } from "@playwright/test";
import { createServer, type ViteDevServer } from "vite";
import { mkdtempSync, realpathSync, mkdirSync, readdirSync, copyFileSync, writeFileSync, rmSync } from "node:fs";
import { join, resolve } from "node:path";
import { tmpdir } from "node:os";
import { lunaCssCompile } from "../../js/luna/src/vite-plugin.ts";

test("Vite watches MoonBit styles, rebuilds JS and CSS together, and recovers from errors", async ({ page }) => {
  const root = realpathSync(mkdtempSync(join(tmpdir(), "luna-css-watch-browser-")));
  let server: ViteDevServer | undefined;
  try {
    mkdirSync(join(root, "moon/css"), { recursive: true });
    mkdirSync(join(root, "moon/app"));
    writeFileSync(join(root, "moon/moon.mod"), 'name = "tests/css-watch"\n');
    for (const file of readdirSync(resolve(import.meta.dirname, "../src/x/css"))) {
      if (file === "moon.pkg" || (file.endsWith(".mbt") && !file.endsWith("_test.mbt"))) copyFileSync(resolve(import.meta.dirname, "../src/x/css", file), join(root, "moon/css", file));
    }
    writeFileSync(join(root, "moon/app/moon.pkg"), 'import { "tests/css-watch/css" }\nsupported_targets = "js"\noptions(link: { "js": { "exports": ["class_name"], "format": "esm" } })\n');
    const source = join(root, "moon/app/app.mbt");
    const style = (color: string) => `pub fn class_name() -> String { @css.attrs([@css.create([@css.rule(@css.Color, "${color}")])]).class_name }`;
    writeFileSync(source, style("red"));
    writeFileSync(join(root, "index.html"), '<p id="sample">Live CSS</p><script type="module" src="/main.js"></script>');
    writeFileSync(join(root, "main.js"), 'import "virtual:luna-compiled.css"; import {class_name} from "virtual:luna-compiled/app/app.js"; document.querySelector("#sample").className = class_name();');
    server = await createServer({
      configFile: false, root, logLevel: "silent",
      plugins: [lunaCssCompile({ input: "moon", outputDir: "generated", cssPackage: "tests/css-watch/css" })],
      server: { port: 0, watch: { usePolling: true, interval: 25 } },
      optimizeDeps: { noDiscovery: true, include: [] },
    });
    await server.listen();
    await page.goto(server.resolvedUrls!.local[0]);
    const sample = page.locator("#sample");
    await expect(sample).toHaveCSS("color", "rgb(255, 0, 0)");
    const serverClass = async () => (await server!.ssrLoadModule("virtual:luna-compiled/app/app.js")).class_name();
    await expect(sample).toHaveClass(await serverClass());
    writeFileSync(source, style("green"));
    await expect(sample).toHaveCSS("color", "rgb(0, 128, 0)");
    await expect(sample).toHaveClass(await serverClass());
    writeFileSync(source, 'pub fn class_name() -> String { @css.attrs([@css.create([@css.rule(@css.Color, runtime_color)])]).class_name }');
    await expect(page.locator("vite-error-overlay")).toBeVisible();
    await expect(sample).toHaveCSS("color", "rgb(0, 128, 0)");
    writeFileSync(source, style("blue"));
    await expect(sample).toHaveCSS("color", "rgb(0, 0, 255)");
    await expect(page.locator("vite-error-overlay")).toHaveCount(0);
  } finally {
    await server?.close();
    rmSync(root, { recursive: true, force: true });
  }
});
