import { test, expect } from "@playwright/test";
import { execFileSync } from "node:child_process";
import { readFileSync, rmSync } from "node:fs";
import { resolve, basename } from "node:path";
import { randomUUID } from "node:crypto";
import { extractFromContent, generateCSS } from "../../js/luna/src/css/extract.ts";
import { compileStyleDirectory } from "../../js/luna/src/css/compile.ts";

let moduleSource: string;
let html: string;
let compiledModuleSource: string;
let compiledHtml: string;
let compiledDir: string;

test.beforeAll(async () => {
  execFileSync("moon", ["build", "--target", "js", "--release", "luna/src/tests/css_styles"], { cwd: resolve(import.meta.dirname, "../.."), stdio: "pipe" });
  moduleSource = readFileSync(resolve(import.meta.dirname, "../../_build/js/release/build/mizchi/luna/tests/css_styles/css_styles.js"), "utf8");
  const fixture = await import(`data:text/javascript;base64,${Buffer.from(moduleSource).toString("base64")}`);
  html = fixture.render_html();
  // Compare the actual MoonBit SSR stylesheet with build-time extraction.
  const source = readFileSync(resolve(import.meta.dirname, "../src/tests/css_styles/demo.mbt"), "utf8");
  expect(generateCSS(extractFromContent(source)).css).toBe(fixture.css_text());
  compiledDir = resolve(import.meta.dirname, "../src/tests", "css_precompiled_" + randomUUID().replaceAll("-", ""));
  compileStyleDirectory(resolve(import.meta.dirname, "../src/tests/css_styles"), { outputDir: compiledDir });
  execFileSync("moon", ["build", "--target", "js", "--release", compiledDir], { cwd: resolve(import.meta.dirname, "../.."), stdio: "pipe" });
  const name = basename(compiledDir);
  compiledModuleSource = readFileSync(resolve(import.meta.dirname, `../../_build/js/release/build/mizchi/luna/tests/${name}/${name}.js`), "utf8");
  const compiled = await import(`data:text/javascript;base64,${Buffer.from(compiledModuleSource).toString("base64")}`);
  compiledHtml = compiled.render_html();
  expect(compiledHtml).toBe(html);
  expect(compiled.css_text()).toBe(fixture.css_text());
  expect(compiledModuleSource).not.toContain("djb2_hash");
});

test.afterAll(() => { if (compiledDir) rmSync(compiledDir, { recursive: true, force: true }); });

for (const precompiled of [false, true]) {
const label = precompiled ? "precompiled" : "source";

test(`${label}: SSR theme, media and hover work with JavaScript disabled`, async ({ browser }) => {
  const context = await browser.newContext({ javaScriptEnabled: false, viewport: { width: 1100, height: 600 } });
  try {
    const page = await context.newPage();
    await page.route("http://styles.test/", route => route.fulfill({ contentType: "text/html", body: precompiled ? compiledHtml : html }));
    await page.goto("http://styles.test/");
    const button = page.getByRole("button", { name: "Toggle theme" });
    await expect(button).toHaveCSS("background-color", "rgb(255, 255, 255)");
    await expect(button).toHaveCSS("width", "120px");
    await expect(button).toHaveCSS("font-size", "20px");
    await expect(button).toHaveCSS("font-weight", "700");
    expect(await button.evaluate(node => getComputedStyle(node, "::before").content)).toBe('""');
    await button.hover();
    await expect(button).toHaveCSS("color", "rgb(128, 0, 128)");
    await page.setViewportSize({ width: 800, height: 600 });
    await expect(button).toHaveCSS("font-size", "16px");
    await button.hover();
    await expect(button).toHaveCSS("color", "rgb(0, 128, 0)");
    await page.setViewportSize({ width: 600, height: 600 });
    await expect(button).toHaveCSS("font-size", "12px");
  } finally { await context.close(); }
});

test(`${label}: hydration preserves the SSR node and updates variables without injecting CSS`, async ({ page }) => {
  await page.route("http://styles.test/**", route => {
    if (new URL(route.request().url()).pathname === "/demo.js") {
      return route.fulfill({ contentType: "text/javascript", body: precompiled ? compiledModuleSource : moduleSource });
    }
    return route.fulfill({ contentType: "text/html", body: precompiled ? compiledHtml : html });
  });
  await page.goto("http://styles.test/");
  const before = await page.evaluate(async () => {
    const root = document.querySelector("style-demo")!.shadowRoot!;
    const button = root.querySelector("button")!;
    const styles = root.querySelector("style")!.textContent;
    const { hydrate_demo } = await import("/demo.js");
    // The leading SSR stylesheet is outside the hydrated content container.
    hydrate_demo(root.querySelector("section"));
    return { same: button === root.querySelector("button"), classes: button.className, styles };
  });
  expect(before.same).toBe(true);
  const button = page.getByRole("button", { name: "Toggle theme" });
  await expect(button).toHaveCSS("width", "120px");
  await button.click();
  await expect(button).toHaveCSS("background-color", "rgb(0, 0, 0)");
  await expect(button).toHaveCSS("width", "160px");
  await expect(button).toHaveCSS("font-weight", "700");
  await expect(button).toHaveAttribute("class", before.classes);
  const after = await page.evaluate(() => {
    const root = document.querySelector("style-demo")!.shadowRoot!;
    return { count: root.querySelectorAll("style").length, css: root.querySelector("style")!.textContent };
  });
  expect(after).toEqual({ count: 1, css: before.styles });
});
}
