import { test, expect } from "@playwright/test";

test.describe("Luna Hydration E2E Tests", () => {
  test.describe("SSR Content Visibility", () => {
    test("SSR content is visible before JavaScript loads", async ({
      browser,
    }) => {
      // Create context with JavaScript disabled
      const context = await browser.newContext({ javaScriptEnabled: false });
      const page = await context.newPage();

      await page.goto("/sol-test/hydration-match");

      // SSR content should be visible without JS
      const countDisplay = page.locator(".count-display");
      await expect(countDisplay).toHaveText("0");

      // Buttons should be present
      await expect(
        page.locator('[data-action-click="increment"]')
      ).toBeVisible();
      await expect(
        page.locator('[data-action-click="decrement"]')
      ).toBeVisible();

      await context.close();
    });

    test("SSR content with initial state is correct", async ({ browser }) => {
      const context = await browser.newContext({ javaScriptEnabled: false });
      const page = await context.newPage();

      await page.goto("/sol-test/hydration-state");

      // Initial state should be 42
      const countDisplay = page.locator(".count-display");
      await expect(countDisplay).toHaveText("42");

      await context.close();
    });
  });

  test.describe("Hydration Correctness", () => {
    test("hydration completes and sets data-hydrated attribute", async ({
      page,
    }) => {
      await page.goto("/sol-test/hydration-match");

      // Wait for hydration
      const island = page.locator('[luna\\:id="counter"]');
      await expect(island).toHaveAttribute("data-hydrated", "true", {
        timeout: 5000,
      });
    });

    test("hydration preserves SSR content (idempotent)", async ({ page }) => {
      await page.goto("/sol-test/hydration-match");

      // Capture HTML before hydration completes
      const ssrHtml = await page.locator('[luna\\:id="counter"]').innerHTML();

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Capture HTML after hydration
      const hydratedHtml = await page
        .locator('[luna\\:id="counter"]')
        .innerHTML();

      // Content should be preserved (may have minor whitespace differences)
      expect(hydratedHtml.replace(/\s+/g, " ").trim()).toBe(
        ssrHtml.replace(/\s+/g, " ").trim()
      );
    });

    test("hydration restores state from luna:state attribute", async ({
      page,
    }) => {
      await page.goto("/sol-test/hydration-state");

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // State should be 42
      const countDisplay = page.locator(".count-display");
      await expect(countDisplay).toHaveText("42");
    });
  });

  test.describe("Interactivity After Hydration", () => {
    test("click handlers work after hydration", async ({ page }) => {
      await page.goto("/sol-test/hydration-interactive");

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const countDisplay = page.locator(".count-display");
      const incBtn = page.locator('[data-action-click="increment"]');
      const decBtn = page.locator('[data-action-click="decrement"]');

      // Initial state
      await expect(countDisplay).toHaveText("0");

      // Increment
      await incBtn.click();
      await expect(countDisplay).toHaveText("1");

      // Increment again
      await incBtn.click();
      await expect(countDisplay).toHaveText("2");

      // Decrement
      await decBtn.click();
      await expect(countDisplay).toHaveText("1");
    });

    test("state persists across multiple interactions", async ({ page }) => {
      await page.goto("/sol-test/hydration-state");

      await expect(page.locator('[luna\\:id="counter"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const countDisplay = page.locator(".count-display");
      const incBtn = page.locator('[data-action-click="increment"]');

      // Start at 42
      await expect(countDisplay).toHaveText("42");

      // Click multiple times
      for (let i = 0; i < 5; i++) {
        await incBtn.click();
      }

      await expect(countDisplay).toHaveText("47");
    });
  });

  test.describe("Multiple Islands", () => {
    test("multiple islands hydrate independently", async ({ page }) => {
      await page.goto("/sol-test/multi-island");

      // Both should hydrate
      await expect(page.locator("#counter-a")).toHaveAttribute(
        "data-hydrated",
        "true"
      );
      await expect(page.locator("#counter-b")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Check initial states
      const countA = page.locator("#counter-a .count-display");
      const countB = page.locator("#counter-b .count-display");

      await expect(countA).toHaveText("10");
      await expect(countB).toHaveText("20");
    });

    test("islands maintain independent state", async ({ page }) => {
      await page.goto("/sol-test/multi-island");

      await expect(page.locator("#counter-a")).toHaveAttribute(
        "data-hydrated",
        "true"
      );
      await expect(page.locator("#counter-b")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const countA = page.locator("#counter-a .count-display");
      const countB = page.locator("#counter-b .count-display");
      const incA = page.locator('#counter-a [data-action-click="increment"]');
      const incB = page.locator('#counter-b [data-action-click="increment"]');

      // Increment A
      await incA.click();
      await expect(countA).toHaveText("11");
      await expect(countB).toHaveText("20"); // B unchanged

      // Increment B
      await incB.click();
      await expect(countA).toHaveText("11"); // A unchanged
      await expect(countB).toHaveText("21");
    });

    test("one island failure does not break others", async ({ page }) => {
      // Capture console errors
      const errors: string[] = [];
      page.on("console", (msg) => {
        if (msg.type() === "error") {
          errors.push(msg.text());
        }
      });

      await page.goto("/sol-test/island-failure");

      // Working island should still hydrate
      await expect(page.locator("#working")).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 5000 }
      );

      // Working island should be interactive
      const count = page.locator("#working .count-display");
      const inc = page.locator('#working [data-action-click="increment"]');

      await expect(count).toHaveText("5");
      await inc.click();
      await expect(count).toHaveText("6");

      // Broken island should not have hydrated attribute
      // (or may have error state depending on implementation)
    });
  });

  test.describe("State Serialization", () => {
    test("various data types are correctly serialized/deserialized", async ({
      page,
    }) => {
      await page.goto("/sol-test/state-types");

      await expect(page.locator('[luna\\:id="state-test"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      await expect(page.locator("[data-int]")).toHaveText("42");
      await expect(page.locator("[data-float]")).toHaveText("3.14");
      await expect(page.locator("[data-string]")).toHaveText("hello");
      await expect(page.locator("[data-bool]")).toHaveText("true");
    });

    test("special characters in state are handled correctly", async ({
      page,
    }) => {
      await page.goto("/sol-test/state-special-chars");

      await expect(page.locator('[luna\\:id="special"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // HTML should be escaped/handled safely
      await expect(page.locator("[data-html]")).toContainText("script");

      // Unicode should work
      await expect(page.locator("[data-unicode]")).toContainText("日本語");

      // Quotes should work
      await expect(page.locator("[data-quotes]")).toContainText("hello");
    });

    test("nested objects in state are correctly handled", async ({ page }) => {
      await page.goto("/sol-test/state-nested");

      await expect(page.locator('[luna\\:id="nested"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      await expect(page.locator("[data-user-name]")).toHaveText("Alice");
      await expect(page.locator("[data-user-email]")).toHaveText(
        "alice@example.com"
      );
      await expect(page.locator("[data-items-count]")).toHaveText("3");
    });

    test("large state via script reference works", async ({ page }) => {
      await page.goto("/sol-test/state-large");

      // Should hydrate without issues
      await expect(page.locator('[luna\\:id="large-state"]')).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 5000 }
      );
    });
  });

  test.describe("Trigger Types", () => {
    test("load trigger hydrates immediately", async ({ page }) => {
      await page.goto("/sol-test/trigger-load");

      // Should hydrate quickly
      await expect(page.locator('[luna\\:id="load-trigger"]')).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 3000 }
      );
    });

    test("idle trigger hydrates when browser is idle", async ({ page }) => {
      await page.goto("/sol-test/trigger-idle");

      // Should hydrate after idle
      await expect(page.locator('[luna\\:id="idle-trigger"]')).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 5000 }
      );
    });
  });

  test.describe("XSS Prevention", () => {
    test("XSS in state does not execute", async ({ page }) => {
      await page.goto("/sol-test/ssr-state-escape");

      // Wait for any potential hydration
      await page.waitForTimeout(1000);

      // XSS should not have triggered
      const xssTriggered = await page.evaluate(
        () => (window as any).xssTriggered
      );
      expect(xssTriggered).toBe(false);
    });

    test("HTML in SSR content is escaped", async ({ page }) => {
      await page.goto("/sol-test/ssr-escape");

      // Script tags should be escaped, not executed
      const xssTriggered = await page.evaluate(
        () => (window as any).xssTriggered
      );
      expect(xssTriggered).toBe(false);

      // Content should show escaped HTML
      const content = page.locator("[data-content]");
      await expect(content).toContainText("<script>");
    });
  });

  test.describe("Mismatch Detection", () => {
    test("detects text content mismatch", async ({ page }) => {
      const warnings: string[] = [];
      page.on("console", (msg) => {
        if (msg.type() === "warning" && msg.text().includes("mismatch")) {
          warnings.push(msg.text());
        }
      });

      await page.goto("/sol-test/mismatch-text");

      await expect(page.locator('[luna\\:id="mismatch-text"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Should have logged a mismatch warning
      expect(warnings.some((w) => w.includes("mismatch"))).toBe(true);
    });

    test("detects element tag mismatch", async ({ page }) => {
      const warnings: string[] = [];
      page.on("console", (msg) => {
        if (msg.type() === "warning" && msg.text().includes("mismatch")) {
          warnings.push(msg.text());
        }
      });

      await page.goto("/sol-test/mismatch-element");

      await expect(
        page.locator('[luna\\:id="mismatch-element"]')
      ).toHaveAttribute("data-hydrated", "true");

      expect(warnings.some((w) => w.includes("mismatch"))).toBe(true);
    });

    test("detects child count mismatch", async ({ page }) => {
      const warnings: string[] = [];
      page.on("console", (msg) => {
        if (msg.type() === "warning" && msg.text().includes("mismatch")) {
          warnings.push(msg.text());
        }
      });

      await page.goto("/sol-test/mismatch-extra-client");

      await expect(page.locator('[luna\\:id="mismatch-extra"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      expect(warnings.some((w) => w.includes("mismatch"))).toBe(true);
    });
  });

  test.describe("MoonBit SSR + Hydration (Idempotent)", () => {
    test("MoonBit SSR output hydrates correctly", async ({ page }) => {
      await page.goto("/test/idempotent-hydrate");

      // Wait for hydration
      await expect(page.locator("#counter")).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 5000 }
      );

      // Counter should work - use more specific selector
      const countSpan = page.locator("#counter span[data-count]");
      const incBtn = page.locator("#counter [data-inc]");

      await expect(countSpan).toHaveText("5");

      await incBtn.click();
      await expect(countSpan).toHaveText("6");
    });

    test("SSR HTML matches hydrated HTML structure", async ({ page }) => {
      await page.goto("/test/idempotent-hydrate");

      // Wait for hydration
      await expect(page.locator("#counter")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Wait a bit for the debug script to capture hydrated HTML
      await page.waitForTimeout(100);

      // Compare SSR and hydrated HTML (captured by the page's inline script)
      const ssrHtml = await page.locator("#ssr-html").textContent();
      const hydratedHtml = await page.locator("#hydrated-html").textContent();

      // Both should have content
      expect(ssrHtml).toBeTruthy();
      expect(hydratedHtml).toBeTruthy();

      // Normalize whitespace for comparison
      const normalize = (s: string | null) =>
        (s || "").replace(/\s+/g, " ").trim();

      // Compare structure (should be the same after hydration)
      expect(normalize(hydratedHtml)).toBe(normalize(ssrHtml));
    });
  });
});
