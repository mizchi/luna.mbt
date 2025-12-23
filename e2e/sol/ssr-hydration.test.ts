/**
 * Sol SSR/Hydration E2E Tests
 *
 * Most SSR/Hydration tests are covered by MoonBit unit tests:
 * - hydrate_test.mbt (130+ tests): Hydration integrity, mismatch detection, islands
 * - serialize_wbtest.mbt: State serialization roundtrip
 * - render_test.mbt, server_dom_test.mbt: SSR output correctness
 *
 * This file only contains browser-API-dependent tests that cannot be unit tested.
 */
import { test, expect } from "@playwright/test";

const BASE_URL = "http://localhost:3456";

test.describe("Sol SSR/Hydration E2E", () => {
  // ============================================================================
  // Hydration Triggers - Browser API dependent (cannot be unit tested)
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
});
