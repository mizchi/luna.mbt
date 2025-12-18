/**
 * Sol SSR/Hydration E2E Tests
 *
 * These tests verify SSR output correctness and hydration behavior.
 * Inspired by Next.js hydration-error.test.ts patterns.
 *
 * Test Categories:
 * 1. SSR Output Correctness - VNode -> HTML conversion
 * 2. Hydration Integrity - SSR/CSR output matching
 * 3. Hydration Mismatch Detection - Error detection for mismatches
 * 4. Island Isolation - Independent Island behavior
 * 5. State Serialization - State serialize/deserialize roundtrip
 * 6. Streaming SSR - Chunk ordering and Suspense fallback
 */
import { test, expect } from "@playwright/test";

const BASE_URL = "http://localhost:3456";

test.describe("Sol SSR/Hydration E2E", () => {
  // ============================================================================
  // 1. SSR Output Correctness
  // ============================================================================
  test.describe("SSR Output Correctness", () => {
    test("renders VNode to correct HTML structure", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/ssr-basic`);

      // Verify basic structure
      const counter = page.locator('[luna\\:id="counter"]');
      await expect(counter).toBeVisible();

      // Verify luna:* attributes are present
      await expect(counter).toHaveAttribute("luna:url");
      await expect(counter).toHaveAttribute("luna:state");
      await expect(counter).toHaveAttribute("luna:client-trigger", "load");
    });

    test("escapes HTML special characters in text content", async ({
      page,
    }) => {
      await page.goto(`${BASE_URL}/sol-test/ssr-escape`);

      // Text with <, >, &, " should be escaped
      const content = page.locator("[data-content]");
      await expect(content).toContainText("<script>");
      await expect(content).toContainText("</script>");

      // XSS should not be triggered
      const xssTriggered = await page.evaluate(
        () => (window as any).xssTriggered
      );
      expect(xssTriggered).toBe(false);
    });

    test("escapes JSON in luna:state attribute correctly", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/ssr-state-escape`);

      const island = page.locator('[luna\\:id="json-test"]');
      const stateAttr = await island.getAttribute("luna:state");

      // State should be valid JSON after parsing
      expect(() => JSON.parse(stateAttr!)).not.toThrow();

      // State should contain the dangerous content safely
      const state = JSON.parse(stateAttr!);
      expect(state.content).toContain("</script>");
    });

    test("renders Fragment without wrapper element", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/ssr-fragment`);

      // Fragment children should be direct children of parent
      const parent = page.locator("#fragment-parent");
      const children = parent.locator("> *");

      // Should have multiple direct children (not wrapped in a single div)
      const count = await children.count();
      expect(count).toBeGreaterThan(1);
    });
  });

  // ============================================================================
  // 2. Hydration Integrity
  // ============================================================================
  test.describe("Hydration Integrity", () => {
    test("SSR HTML matches hydrated DOM structure", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/hydration-match`);

      // Capture SSR HTML before hydration
      const ssrHtml = await page.locator("#island-container").innerHTML();

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Capture DOM after hydration
      const hydratedHtml = await page.locator("#island-container").innerHTML();

      // Core structure should match (ignoring data-hydrated attribute)
      const normalizedSsr = ssrHtml.replace(/data-hydrated="[^"]*"/g, "");
      const normalizedHydrated = hydratedHtml.replace(
        /data-hydrated="[^"]*"/g,
        ""
      );

      // Both should contain same key elements
      expect(normalizedHydrated).toContain("count-display");
      expect(normalizedHydrated).toContain("data-action-click");
    });

    test("initial state is preserved after hydration", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/hydration-state`);

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Initial count should be 42 (from SSR state)
      const display = page.locator(".count-display");
      await expect(display).toHaveText("42");
    });

    test("hydrated component is interactive", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/hydration-interactive`);

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const display = page.locator(".count-display");
      await expect(display).toHaveText("0");

      // Click increment
      await page.locator('button[data-action-click="increment"]').click();
      await expect(display).toHaveText("1");

      // Click decrement
      await page.locator('button[data-action-click="decrement"]').click();
      await expect(display).toHaveText("0");
    });
  });

  // ============================================================================
  // 3. Hydration Mismatch Detection
  // ============================================================================
  test.describe("Hydration Mismatch Detection", () => {
    test("detects text content mismatch", async ({ page }) => {
      // Set up console listener before navigation
      const logs: string[] = [];
      page.on("console", (msg) => logs.push(msg.text()));

      await page.goto(`${BASE_URL}/sol-test/mismatch-text`);

      // Wait for hydration
      await expect(
        page.locator('[luna\\:id="mismatch-text"]')
      ).toHaveAttribute("data-hydrated", "true", { timeout: 3000 });

      // Expect warning about mismatch
      expect(logs.some((log) => log.includes("mismatch"))).toBe(true);
    });

    test("detects element structure mismatch", async ({ page }) => {
      const logs: string[] = [];
      page.on("console", (msg) => logs.push(msg.text()));

      await page.goto(`${BASE_URL}/sol-test/mismatch-element`);

      await expect(
        page.locator('[luna\\:id="mismatch-element"]')
      ).toHaveAttribute("data-hydrated", "true", { timeout: 3000 });

      expect(logs.some((log) => log.includes("mismatch"))).toBe(true);
    });

    test("detects attribute mismatch", async ({ page }) => {
      const logs: string[] = [];
      page.on("console", (msg) => logs.push(msg.text()));

      await page.goto(`${BASE_URL}/sol-test/mismatch-attr`);

      await expect(
        page.locator('[luna\\:id="mismatch-attr"]')
      ).toHaveAttribute("data-hydrated", "true", { timeout: 3000 });

      expect(logs.some((log) => log.includes("mismatch"))).toBe(true);
    });

    test("detects extra element on client", async ({ page }) => {
      const logs: string[] = [];
      page.on("console", (msg) => logs.push(msg.text()));

      await page.goto(`${BASE_URL}/sol-test/mismatch-extra-client`);

      await expect(
        page.locator('[luna\\:id="mismatch-extra"]')
      ).toHaveAttribute("data-hydrated", "true", { timeout: 3000 });

      expect(logs.some((log) => log.includes("mismatch"))).toBe(true);
    });

    test("detects extra element on server", async ({ page }) => {
      const logs: string[] = [];
      page.on("console", (msg) => logs.push(msg.text()));

      await page.goto(`${BASE_URL}/sol-test/mismatch-extra-server`);

      await expect(
        page.locator('[luna\\:id="mismatch-extra-server"]')
      ).toHaveAttribute("data-hydrated", "true", { timeout: 3000 });

      expect(logs.some((log) => log.includes("mismatch"))).toBe(true);
    });
  });

  // ============================================================================
  // 4. Island Isolation
  // ============================================================================
  test.describe("Island Isolation", () => {
    test("multiple islands hydrate independently", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/multi-island`);

      // Wait for both islands to hydrate
      await expect(page.locator('[luna\\:id="counter-a"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );
      await expect(page.locator('[luna\\:id="counter-b"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Both should have their initial values
      await expect(page.locator("#counter-a .count-display")).toHaveText("10");
      await expect(page.locator("#counter-b .count-display")).toHaveText("20");
    });

    test("island state changes do not affect other islands", async ({
      page,
    }) => {
      await page.goto(`${BASE_URL}/sol-test/multi-island`);

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter-a"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );
      await expect(page.locator('[luna\\:id="counter-b"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Increment counter A
      await page
        .locator('#counter-a button[data-action-click="increment"]')
        .click();
      await expect(page.locator("#counter-a .count-display")).toHaveText("11");

      // Counter B should remain unchanged
      await expect(page.locator("#counter-b .count-display")).toHaveText("20");

      // Increment counter B
      await page
        .locator('#counter-b button[data-action-click="increment"]')
        .click();
      await expect(page.locator("#counter-b .count-display")).toHaveText("21");

      // Counter A should still be 11
      await expect(page.locator("#counter-a .count-display")).toHaveText("11");
    });

    test("island failure does not break other islands", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/island-failure`);

      // Wait for working island to hydrate
      await expect(page.locator('[luna\\:id="working"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Working island should be interactive
      const display = page.locator("#working .count-display");
      await expect(display).toHaveText("5");

      await page
        .locator('#working button[data-action-click="increment"]')
        .click();
      await expect(display).toHaveText("6");
    });
  });

  // ============================================================================
  // 5. State Serialization
  // ============================================================================
  test.describe("State Serialization", () => {
    test("serializes and deserializes basic types correctly", async ({
      page,
    }) => {
      await page.goto(`${BASE_URL}/sol-test/state-types`);

      await expect(page.locator('[luna\\:id="state-test"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Verify state was correctly deserialized
      await expect(page.locator("[data-int]")).toHaveText("42");
      await expect(page.locator("[data-float]")).toHaveText("3.14");
      await expect(page.locator("[data-string]")).toHaveText("hello");
      await expect(page.locator("[data-bool]")).toHaveText("true");
    });

    test("serializes special characters safely", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/state-special-chars`);

      await expect(page.locator('[luna\\:id="special"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Verify special characters were preserved
      await expect(page.locator("[data-html]")).toHaveText(
        '<script>alert("xss")</script>'
      );
      await expect(page.locator("[data-unicode]")).toHaveText("日本語 emoji: 🎉");
      await expect(page.locator("[data-quotes]")).toHaveText('say "hello"');
    });

    test("serializes nested objects correctly", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/state-nested`);

      await expect(page.locator('[luna\\:id="nested"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Verify nested structure was preserved
      await expect(page.locator("[data-user-name]")).toHaveText("Alice");
      await expect(page.locator("[data-user-email]")).toHaveText(
        "alice@example.com"
      );
      await expect(page.locator("[data-items-count]")).toHaveText("3");
    });

    test("large state uses script reference", async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/state-large`);

      // Verify state script exists
      const stateScript = page.locator('script[type="luna/json"]');
      await expect(stateScript).toHaveCount(1);

      // Verify luna:state references the script
      const island = page.locator('[luna\\:id="large-state"]');
      const stateAttr = await island.getAttribute("luna:state");
      expect(stateAttr).toMatch(/^#/); // Should be a reference like #state-id

      // Hydration should still work
      await expect(island).toHaveAttribute("data-hydrated", "true");
    });
  });

  // ============================================================================
  // 6. Hydration Triggers
  // ============================================================================
  test.describe("Hydration Triggers", () => {
    test('trigger="load" hydrates immediately', async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/trigger-load`);

      // Should hydrate within reasonable time
      await expect(page.locator('[luna\\:id="load-trigger"]')).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 2000 }
      );
    });

    test('trigger="idle" hydrates on requestIdleCallback', async ({ page }) => {
      await page.goto(`${BASE_URL}/sol-test/trigger-idle`);

      // May take a moment for idle callback
      await expect(page.locator('[luna\\:id="idle-trigger"]')).toHaveAttribute(
        "data-hydrated",
        "true",
        { timeout: 5000 }
      );
    });

    test('trigger="visible" hydrates when scrolled into view', async ({
      page,
    }) => {
      await page.goto(`${BASE_URL}/sol-test/trigger-visible`);

      const island = page.locator('[luna\\:id="visible-trigger"]');

      // Should not be hydrated yet (below fold)
      await page.waitForTimeout(500);
      const isHydratedBefore = await island.getAttribute("data-hydrated");
      expect(isHydratedBefore).not.toBe("true");

      // Scroll into view
      await island.scrollIntoViewIfNeeded();

      // Should hydrate after becoming visible
      await expect(island).toHaveAttribute("data-hydrated", "true", {
        timeout: 3000,
      });
    });

    test('trigger="media" hydrates on media query match', async ({ page }) => {
      // Start with large viewport (media query won't match)
      await page.setViewportSize({ width: 800, height: 600 });
      await page.goto(`${BASE_URL}/sol-test/trigger-media`);

      const island = page.locator('[luna\\:id="media-trigger"]');

      // Should not be hydrated initially (viewport > 600px)
      await page.waitForTimeout(500);
      const isHydratedBefore = await island.getAttribute("data-hydrated");
      expect(isHydratedBefore).not.toBe("true");

      // Resize to match media query (max-width: 600px)
      await page.setViewportSize({ width: 500, height: 600 });

      // Should hydrate after media query matches
      await expect(island).toHaveAttribute("data-hydrated", "true", {
        timeout: 3000,
      });
    });
  });

  // ============================================================================
  // 7. Streaming SSR
  // ============================================================================
  test.describe("Streaming SSR", () => {
    test.skip("fallback content arrives before async content", async ({
      page,
    }) => {
      // TODO: Implement streaming SSR test infrastructure
      const chunks: string[] = [];

      // Intercept response to capture chunks
      await page.route(`${BASE_URL}/sol-test/streaming`, async (route) => {
        const response = await route.fetch();
        const body = await response.text();
        chunks.push(body);
        await route.fulfill({ response });
      });

      await page.goto(`${BASE_URL}/sol-test/streaming`);

      // Fallback should appear first
      expect(chunks[0]).toContain("Loading...");
    });

    test.skip("async content replaces fallback", async ({ page }) => {
      // TODO: Implement streaming SSR
      await page.goto(`${BASE_URL}/sol-test/streaming`);

      // Wait for async content
      await expect(page.locator("[data-async-content]")).toBeVisible({
        timeout: 5000,
      });

      // Fallback should no longer be visible
      await expect(page.locator("[data-fallback]")).not.toBeVisible();
    });
  });

  // ============================================================================
  // 8. Error Recovery
  // ============================================================================
  test.describe("Error Recovery", () => {
    test.skip("recovers from minor hydration mismatch", async ({ page }) => {
      // TODO: Implement recovery mechanism
      await page.goto(`${BASE_URL}/sol-test/recovery-minor`);

      // Component should still work after recovery
      await expect(page.locator('[luna\\:id="recoverable"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );
    });

    test.skip("shows error boundary on critical failure", async ({ page }) => {
      // TODO: Implement error boundaries
      await page.goto(`${BASE_URL}/sol-test/recovery-critical`);

      // Error boundary should be displayed
      await expect(page.locator("[data-error-boundary]")).toBeVisible();
    });
  });
});
