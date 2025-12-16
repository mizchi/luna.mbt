import { test, expect } from "@playwright/test";

test.describe("Shard Module E2E Tests", () => {
  test.describe("generate_minimal_shard", () => {
    test("generates correct HTML structure", async ({ page }) => {
      await page.goto("/shard/minimal");

      // Check ln:* attributes are present
      const component = page.locator('[ln\\:id="counter-1"]');
      await expect(component).toHaveAttribute("ln:url", "/components/counter.js");
      // State attribute is HTML-escaped in source but browser parses it correctly
      const state = await component.getAttribute("ln:state");
      expect(state).toBe('{"count":42}');
    });

    test("hydrates and responds to interactions", async ({ page }) => {
      await page.goto("/shard/minimal");

      // Wait for hydration
      await expect(page.locator('[ln\\:id="counter-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      await expect(count).toHaveText("42");

      // Increment
      await page.locator("[data-inc]").click();
      await expect(count).toHaveText("43");

      // Decrement
      await page.locator("[data-dec]").click();
      await expect(count).toHaveText("42");
    });
  });

  test.describe("generate_standalone_shard", () => {
    test("includes loader script in output", async ({ page }) => {
      await page.goto("/shard/standalone");

      // Loader should be embedded
      const loaderScript = page.locator('script[src="/loader.js"]');
      await expect(loaderScript).toHaveCount(1);
    });

    test("hydrates correctly", async ({ page }) => {
      await page.goto("/shard/standalone");

      await expect(page.locator('[ln\\:id="greeting-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      await expect(page.locator("[data-name]")).toHaveText("World");
    });
  });

  test.describe("generate_lazy_shard", () => {
    test("sets visible trigger", async ({ page }) => {
      await page.goto("/shard/lazy");

      const component = page.locator('[ln\\:id="lazy-counter"]');
      await expect(component).toHaveAttribute("ln:trigger", "visible");
    });

    test("does not hydrate until visible", async ({ page }) => {
      await page.goto("/shard/lazy");

      const component = page.locator('[ln\\:id="lazy-counter"]');

      // Should not be hydrated yet (below fold)
      await expect(component).not.toHaveAttribute("data-hydrated", "true");
    });

    test("hydrates when scrolled into view", async ({ page }) => {
      await page.goto("/shard/lazy");

      const component = page.locator('[ln\\:id="lazy-counter"]');

      // Scroll to component
      await component.scrollIntoViewIfNeeded();

      // Should hydrate
      await expect(component).toHaveAttribute("data-hydrated", "true", {
        timeout: 5000,
      });

      // Check state was applied
      await expect(page.locator("[data-count]")).toHaveText("100");
    });
  });

  test.describe("XSS Safety", () => {
    test("escapes dangerous content in state", async ({ page }) => {
      await page.goto("/shard/xss-safety");

      // XSS should not have been triggered
      const xssTriggered = await page.evaluate(() => (window as any).xssTriggered);
      expect(xssTriggered).toBe(false);
    });

    test("escape_json_for_html properly escapes script tags", async ({ page }) => {
      await page.goto("/shard/xss-safety");

      // Verify the component rendered (was not broken by XSS)
      const component = page.locator('[ln\\:id="xss-test"]');
      await expect(component).toBeVisible();

      // The state value contains dangerous content but it was safely escaped in HTML
      // Browser parses the HTML entities back, so we just verify the component exists
      const stateValue = await component.getAttribute("ln:state");
      expect(stateValue).toContain("<script>");
      expect(stateValue).toContain("</script>");

      // Most importantly: XSS was not triggered
      const xssTriggered = await page.evaluate(() => (window as any).xssTriggered);
      expect(xssTriggered).toBe(false);
    });
  });

  test.describe("generate_state_script", () => {
    test("creates script element with correct type", async ({ page }) => {
      await page.goto("/shard/state-script");

      const stateScript = page.locator('script[type="ln/json"]#counter-state');
      await expect(stateScript).toHaveCount(1);
    });

    test("state is loaded from script reference", async ({ page }) => {
      await page.goto("/shard/state-script");

      await expect(page.locator('[ln\\:id="counter-script"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      await expect(page.locator("[data-count]")).toHaveText("999");
    });

    test("interactions work with script-referenced state", async ({ page }) => {
      await page.goto("/shard/state-script");

      await expect(page.locator('[ln\\:id="counter-script"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      await expect(count).toHaveText("999");

      await page.locator("[data-inc]").click();
      await expect(count).toHaveText("1000");
    });
  });

  test.describe("Idempotent Hydration (MoonBit SSR + MoonBit Hydrate)", () => {
    test("SSR HTML matches hydrated DOM structure", async ({ page }) => {
      await page.goto("/test/idempotent-hydrate");

      // Wait for hydration
      await expect(page.locator("#counter")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Wait for debug elements to be populated
      await expect(page.locator("#hydrated-html")).not.toBeEmpty();

      // Get SSR and hydrated HTML from debug elements
      const ssrHtml = await page.locator("#ssr-html").textContent();
      const hydratedHtml = await page.locator("#hydrated-html").textContent();

      // The core content should match
      // SSR generates: <div class="counter" data-count="5">...</div>
      // After hydration: same structure with data-hydrated attribute on span
      expect(ssrHtml).toBeTruthy();
      expect(hydratedHtml).toBeTruthy();

      // Both should contain the count value
      expect(ssrHtml).toContain("5");
      expect(hydratedHtml).toContain("5");

      // Both should have the counter structure
      expect(ssrHtml).toContain("data-count");
      expect(ssrHtml).toContain("data-inc");
      expect(ssrHtml).toContain("data-dec");
    });

    test("initial state is preserved after hydration", async ({ page }) => {
      await page.goto("/test/idempotent-hydrate");

      // Wait for hydration
      await expect(page.locator("#counter")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Count should be 5 (from SSR state) - use span[data-count="true"] to be specific
      await expect(page.locator('#counter span[data-count="true"]')).toHaveText("5");
    });

    test("hydrated component is interactive", async ({ page }) => {
      await page.goto("/test/idempotent-hydrate");

      // Wait for hydration
      await expect(page.locator("#counter")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Use specific selector for the span containing count
      const count = page.locator('#counter span[data-count="true"]');
      await expect(count).toHaveText("5");

      // Test increment
      await page.locator('#counter [data-inc="true"]').click();
      await expect(count).toHaveText("6");

      // Test decrement
      await page.locator('#counter [data-dec="true"]').click();
      await expect(count).toHaveText("5");

      // Multiple increments
      await page.locator('#counter [data-inc="true"]').click();
      await page.locator('#counter [data-inc="true"]').click();
      await expect(count).toHaveText("7");
    });

    test("MoonBit SSR output is valid HTML", async ({ page }) => {
      await page.goto("/test/idempotent-hydrate");

      // The counter div should exist with proper SSR content
      const counter = page.locator("#counter");
      await expect(counter).toBeVisible();

      // SSR should have rendered child elements
      const childDiv = counter.locator(".counter");
      await expect(childDiv).toBeVisible();

      // Check the inner HTML structure
      const counterHtml = await counter.innerHTML();
      expect(counterHtml).toContain("data-count");
      expect(counterHtml).toContain("data-inc");
      expect(counterHtml).toContain("data-dec");
    });

    test("hydration uses MoonBit compiled module", async ({ page }) => {
      // Verify the MoonBit hydrate module is loaded
      const requests: string[] = [];
      page.on("request", (request) => {
        if (request.url().includes("counter-mbt.js")) {
          requests.push(request.url());
        }
      });

      await page.goto("/test/idempotent-hydrate");

      // Wait for hydration
      await expect(page.locator("#counter")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Verify MoonBit module was loaded
      expect(requests.length).toBeGreaterThan(0);
      expect(requests[0]).toContain("counter-mbt.js");
    });
  });
});
