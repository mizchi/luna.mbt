// Phase B exit smoke: astra dev boots a working docs server against the
// `examples/sol_docs` fixture. The webServer block in playwright.config
// builds the JS bundle ahead of time (via `moon build --release`) and
// starts `astra dev`; this spec just asserts that index renders to HTML
// with the expected document chrome and that an asset URL is served too.
//
// Intentionally minimal: parity with the static SSG dump is checked
// separately by `astra/docs/parity-notes.md`. This file only proves the
// listener is real — i.e. `run_dev` is wired through `node:http`.

import { test, expect } from "@playwright/test";

test("dev server serves the index page with title and h1", async ({ page }) => {
  await page.goto("/");
  await expect(page).toHaveTitle(/.+/);
  await expect(page.locator("h1").first()).toBeVisible();
});

test("dev server serves /assets/style.css with text/css content-type", async ({
  request,
}) => {
  const res = await request.get("/assets/style.css");
  expect(res.status()).toBe(200);
  const contentType = res.headers()["content-type"] ?? "";
  expect(contentType).toContain("text/css");
});
