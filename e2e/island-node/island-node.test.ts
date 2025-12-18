import { test, expect } from "@playwright/test";

test.describe("Island Node SSR E2E Tests", () => {
  test.describe("Basic SSR Output", () => {
    test("renders island with luna:* attributes", async ({ page }) => {
      await page.goto("/island-node/basic-ssr");

      // Check that the island element exists with correct attributes
      const island = page.locator('[luna\\:id="counter-1"]');
      await expect(island).toBeVisible();
      await expect(island).toHaveAttribute("luna:url", "/components/counter.js");
      await expect(island).toHaveAttribute("luna:client-trigger", "load");

      // Check state attribute (entity-encoded JSON)
      const state = await island.getAttribute("luna:state");
      expect(state).toBe('{"count":5}');
    });

    test("SSR content is visible before hydration", async ({ page }) => {
      await page.goto("/island-node/basic-ssr");

      // SSR content should be immediately visible
      const count = page.locator("[data-count]");
      await expect(count).toHaveText("5");

      const incBtn = page.locator("[data-inc]");
      await expect(incBtn).toBeVisible();
    });

    test("hydrates and becomes interactive", async ({ page }) => {
      await page.goto("/island-node/basic-ssr");

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      const incBtn = page.locator("[data-inc]");

      // Initial value
      await expect(count).toHaveText("5");

      // Click and verify
      await incBtn.click();
      await expect(count).toHaveText("6");

      await incBtn.click();
      await expect(count).toHaveText("7");
    });

    test("HTML comment markers are present in source", async ({ page }) => {
      const response = await page.goto("/island-node/basic-ssr");
      const html = await response?.text();

      // Check opening comment marker
      expect(html).toContain(
        "<!--luna:island:counter-1 url=/components/counter.js trigger=load-->"
      );
      // Check closing comment marker
      expect(html).toContain("<!--/luna:island:counter-1-->");
    });
  });

  test.describe("Trigger Types", () => {
    test("load trigger hydrates immediately", async ({ page }) => {
      await page.goto("/island-node/triggers");

      // Load trigger should hydrate immediately
      await expect(page.locator('[luna\\:id="load-1"]')).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 3000 }
      );
    });

    test("idle trigger hydrates when idle", async ({ page }) => {
      await page.goto("/island-node/triggers");

      // Idle trigger should hydrate after browser becomes idle
      await expect(page.locator('[luna\\:id="idle-1"]')).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 5000 }
      );
    });

    test("visible trigger does not hydrate until scrolled", async ({
      page,
    }) => {
      await page.goto("/island-node/triggers");

      const visibleIsland = page.locator('[luna\\:id="visible-1"]');

      // Initially not hydrated (below the fold)
      await page.waitForTimeout(500);
      await expect(visibleIsland).not.toHaveAttribute("data-hydrated", "true");

      // Scroll to make it visible
      await visibleIsland.scrollIntoViewIfNeeded();

      // Now it should hydrate
      await expect(visibleIsland).toHaveAttribute("data-hydrated", "true", {
        timeout: 5000,
      });
    });

    test("different triggers have correct attributes", async ({ page }) => {
      await page.goto("/island-node/triggers");

      // Check trigger attribute values
      await expect(page.locator('[luna\\:id="load-1"]')).toHaveAttribute(
        "luna:client-trigger",
        "load"
      );
      await expect(page.locator('[luna\\:id="idle-1"]')).toHaveAttribute(
        "luna:client-trigger",
        "idle"
      );
      await expect(page.locator('[luna\\:id="visible-1"]')).toHaveAttribute(
        "luna:client-trigger",
        "visible"
      );
    });
  });

  test.describe("Nested Islands", () => {
    test("both outer and inner islands render correctly", async ({ page }) => {
      await page.goto("/island-node/nested");

      // Both islands should be visible
      const outer = page.locator('[luna\\:id="outer-1"]');
      const inner = page.locator('[luna\\:id="inner-1"]');

      await expect(outer).toBeVisible();
      await expect(inner).toBeVisible();

      // Check attributes
      await expect(outer).toHaveAttribute("luna:url", "/components/counter.js");
      await expect(inner).toHaveAttribute("luna:url", "/components/lazy.js");
    });

    test("outer island hydrates and becomes interactive", async ({ page }) => {
      await page.goto("/island-node/nested");

      // Wait for outer island hydration
      await expect(page.locator('[luna\\:id="outer-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator('[luna\\:id="outer-1"] [data-count]');
      const incBtn = page.locator('[luna\\:id="outer-1"] [data-inc]');

      // Initial value
      await expect(count).toHaveText("10");

      // Click and verify
      await incBtn.click();
      await expect(count).toHaveText("11");
    });

    test("inner island hydrates independently", async ({ page }) => {
      await page.goto("/island-node/nested");

      // Both should hydrate
      await expect(page.locator('[luna\\:id="outer-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );
      await expect(page.locator('[luna\\:id="inner-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Inner island should show hydrated message
      const innerContent = page.locator('[luna\\:id="inner-1"] [data-content]');
      await expect(innerContent).toHaveText("Hydrated: Inner island content");
    });

    test("HTML source has both island comment markers", async ({ page }) => {
      const response = await page.goto("/island-node/nested");
      const html = await response?.text();

      // Check both island markers
      expect(html).toContain("<!--luna:island:outer-1");
      expect(html).toContain("<!--/luna:island:outer-1-->");
      expect(html).toContain("<!--luna:island:inner-1");
      expect(html).toContain("<!--/luna:island:inner-1-->");
    });
  });

  test.describe("XSS Safety", () => {
    test("dangerous state content is properly escaped", async ({ page }) => {
      await page.goto("/island-node/xss-safety");

      // Check that XSS was not triggered
      const xssTriggered = await page.evaluate(
        () => (window as any).xssTriggered
      );
      expect(xssTriggered).toBe(false);
    });

    test("island hydrates safely with escaped content", async ({ page }) => {
      await page.goto("/island-node/xss-safety");

      // Wait for hydration
      await expect(page.locator('[luna\\:id="xss-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Content should be safe
      const content = page.locator("[data-content]");
      await expect(content).toBeVisible();

      // XSS should still not be triggered
      const xssTriggered = await page.evaluate(
        () => (window as any).xssTriggered
      );
      expect(xssTriggered).toBe(false);
    });

    test("state attribute is entity-escaped in HTML source", async ({
      page,
    }) => {
      const response = await page.goto("/island-node/xss-safety");
      const html = await response?.text();

      // The state should have entity-escaped values
      // <script> should be &lt;script&gt;
      expect(html).toContain("&lt;script&gt;");
      expect(html).toContain("&lt;/script&gt;");

      // Raw <script> inside state attribute should NOT be present
      // (it would allow attribute injection attacks)
      expect(html).not.toMatch(/luna:state="[^"]*<script>/);
    });
  });

  test.describe("Global API", () => {
    test("__LUNA_STATE__ tracks island states", async ({ page }) => {
      await page.goto("/island-node/basic-ssr");

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Check global state
      const stateExists = await page.evaluate(() => {
        return typeof (window as any).__LUNA_STATE__ === "object";
      });
      expect(stateExists).toBe(true);
    });
  });
});
