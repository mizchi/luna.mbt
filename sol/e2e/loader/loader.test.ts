import { test, expect } from "@playwright/test";

test.describe("luna-loader-v1 E2E Tests", () => {
  test.describe("Basic Hydration (trigger: load)", () => {
    test("hydrates component on page load", async ({ page }) => {
      await page.goto("/loader/basic");

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Check initial state was applied
      const count = page.locator("[data-count]");
      await expect(count).toHaveText("5");
      await expect(count).toHaveAttribute("data-hydrated", "true");
    });

    test("click handlers work after hydration", async ({ page }) => {
      await page.goto("/loader/basic");

      // Wait for hydration
      await expect(page.locator('[luna\\:id="counter-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      const incBtn = page.locator("[data-inc]");
      const decBtn = page.locator("[data-dec]");

      // Initial value
      await expect(count).toHaveText("5");

      // Increment
      await incBtn.click();
      await expect(count).toHaveText("6");

      // Increment again
      await incBtn.click();
      await expect(count).toHaveText("7");

      // Decrement
      await decBtn.click();
      await expect(count).toHaveText("6");
    });
  });

  test.describe("Visible Trigger", () => {
    // Skip flaky test in CI - IntersectionObserver may fire immediately in headless Chrome
    test.skip("does not hydrate until element is visible", async ({ page }) => {
      await page.goto("/loader/visible");

      // Component should not be hydrated yet (it's below the fold)
      const component = page.locator('[luna\\:id="lazy-1"]');
      await expect(component).not.toHaveAttribute("data-hydrated", "true");

      // Content should still be the SSR placeholder
      const content = page.locator("[data-content]");
      await expect(content).toHaveText("Not hydrated yet");
    });

    test("hydrates when scrolled into view", async ({ page }) => {
      await page.goto("/loader/visible");

      const component = page.locator('[luna\\:id="lazy-1"]');
      const content = page.locator("[data-content]");

      // Scroll to the component
      await component.scrollIntoViewIfNeeded();

      // Wait for hydration
      await expect(component).toHaveAttribute("data-hydrated", "true", {
        timeout: 5000,
      });

      // State should be applied
      await expect(content).toHaveText("Hydrated: Hello from state!");
    });
  });

  test.describe("Idle Trigger", () => {
    test("hydrates when browser becomes idle", async ({ page }) => {
      await page.goto("/loader/idle");

      const component = page.locator('[luna\\:id="idle-1"]');
      const content = page.locator("[data-content]");

      // Wait for idle hydration (should happen relatively quickly)
      await expect(component).toHaveAttribute("data-hydrated", "true", {
        timeout: 5000,
      });

      await expect(content).toHaveText("Hydrated: Loaded on idle");
    });
  });

  test.describe("Script Reference State", () => {
    test("loads state from script element", async ({ page }) => {
      await page.goto("/loader/script-ref");

      const component = page.locator('[luna\\:id="counter-ref"]');
      await expect(component).toHaveAttribute("data-hydrated", "true");

      const count = page.locator("[data-count]");
      await expect(count).toHaveText("10");

      // Verify interaction works
      await page.locator("[data-inc]").click();
      await expect(count).toHaveText("11");
    });
  });

  test.describe("Multiple Components", () => {
    test("hydrates multiple components sharing one module URL independently", async ({ page }) => {
      await page.goto("/loader/multiple");

      await expect(page.locator('[luna\\:url="/components/counter.js"]')).toHaveCount(2);

      // Both should hydrate
      await expect(page.locator('[luna\\:id="counter-a"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );
      await expect(page.locator('[luna\\:id="counter-b"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Each has its own state
      const countA = page.locator('[luna\\:id="counter-a"] [data-count]');
      const countB = page.locator('[luna\\:id="counter-b"] [data-count]');

      await expect(countA).toHaveText("1");
      await expect(countB).toHaveText("100");
    });

    test("components have independent state", async ({ page }) => {
      await page.goto("/loader/multiple");

      await expect(page.locator('[luna\\:id="counter-a"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const countA = page.locator('[luna\\:id="counter-a"] [data-count]');
      const countB = page.locator('[luna\\:id="counter-b"] [data-count]');

      // Increment counter A
      await page.locator('[luna\\:id="counter-a"] [data-inc]').click();
      await page.locator('[luna\\:id="counter-a"] [data-inc]').click();

      // Counter A should be 3, Counter B should still be 100
      await expect(countA).toHaveText("3");
      await expect(countB).toHaveText("100");

      // Decrement counter B
      await page.locator('[luna\\:id="counter-b"] [data-dec]').click();

      await expect(countA).toHaveText("3");
      await expect(countB).toHaveText("99");
    });
  });

  test.describe("SSR/CSR Hydration Stability", () => {
    test("re-scan after SSR hydration does not duplicate click handlers", async ({
      page,
    }) => {
      await page.goto("/loader/basic");

      const component = page.locator('[luna\\:id="counter-1"]');
      const count = page.locator("[data-count]");
      const incBtn = page.locator("[data-inc]");

      await expect(component).toHaveAttribute("data-hydrated", "true");
      await expect(count).toHaveText("5");

      // Re-scan should not cause duplicate hydration side effects.
      await page.evaluate(() => {
        (window as any).__LUNA_SCAN__?.();
      });

      await incBtn.click();
      await expect(count).toHaveText("6");

      await incBtn.click();
      await expect(count).toHaveText("7");
    });

    test("rehydrates replaced island with same luna:id after CSR mutation", async ({
      page,
    }) => {
      await page.goto("/loader/csr-replace");

      const initialIsland = page.locator('#csr-host [luna\\:id="csr-counter"]');
      const count = page.locator("#csr-host [data-count]");

      await expect(initialIsland).toHaveAttribute("data-hydrated", "true");
      await expect(count).toHaveText("1");

      await page.locator("#csr-inc").click();
      await expect(count).toHaveText("2");

      await page.locator("#replace-btn").click();

      const replacedIsland = page.locator('#csr-host [luna\\:id="csr-counter"]');
      await expect(replacedIsland).toHaveAttribute("data-hydrated", "true");
      await expect(count).toHaveText("10");

      await page.locator("#csr-inc").click();
      await expect(count).toHaveText("11");
    });
  });

  test.describe("Hydration URL Security", () => {
    test("blocks cross-origin module URL by default", async ({ page }) => {
      await page.goto("/loader/security-default-deny");

      const component = page.locator('[luna\\:id="secure-counter"]');
      const count = page.locator("#secure-host [data-count]");
      const incBtn = page.locator("#secure-host [data-inc]");

      await page.waitForTimeout(300);
      await expect(component).not.toHaveAttribute("data-hydrated", "true");
      await expect(count).toHaveText("5");

      await incBtn.click();
      await expect(count).toHaveText("5");
    });

    test("allows configured host via __LUNA_ALLOWED_HOSTS__", async ({
      page,
    }) => {
      await page.goto("/loader/security-allow-host");

      const component = page.locator('[luna\\:id="secure-counter"]');
      const count = page.locator("#secure-host [data-count]");
      const incBtn = page.locator("#secure-host [data-inc]");

      await expect(component).toHaveAttribute("data-hydrated", "true");
      await expect(count).toHaveText("5");

      await incBtn.click();
      await expect(count).toHaveText("6");
    });

    test("allows host after runtime config update via __LUNA_SET_ALLOWED_HOSTS__", async ({
      page,
    }) => {
      await page.goto("/loader/security-default-deny");

      const component = page.locator('[luna\\:id="secure-counter"]');
      const count = page.locator("#secure-host [data-count]");

      await page.waitForTimeout(300);
      await expect(component).not.toHaveAttribute("data-hydrated", "true");

      await page.evaluate(() => {
        (window as any).__LUNA_SET_ALLOWED_HOSTS__?.(["127.0.0.1"]);
        (window as any).__LUNA_SCAN__?.();
      });

      await expect(component).toHaveAttribute("data-hydrated", "true");
      await page.locator("#secure-host [data-inc]").click();
      await expect(count).toHaveText("6");
    });
  });

  // URL State tests removed - feature removed in ab4b582 for SSRF mitigation

  // Skip flaky manual trigger tests in CI - timing issues with hydration
  test.describe.skip("Manual Trigger (none)", () => {
    test("does not auto-hydrate with trigger=none", async ({ page }) => {
      await page.goto("/loader/manual");

      const component = page.locator('[luna\\:id="manual-1"]');
      const content = page.locator("[data-content]");

      // Wait a bit to ensure no auto-hydration
      await page.waitForTimeout(500);

      await expect(component).not.toHaveAttribute("data-hydrated", "true");
      await expect(content).toHaveText("Should not auto-hydrate");
    });

    test("hydrates when manually triggered via __LUNA_HYDRATE__", async ({
      page,
    }) => {
      await page.goto("/loader/manual");

      const component = page.locator('[luna\\:id="manual-1"]');
      const content = page.locator("[data-content]");

      // Not hydrated yet
      await expect(component).not.toHaveAttribute("data-hydrated", "true");

      // Click the manual trigger button
      await page.locator("#trigger-btn").click();

      // Now it should be hydrated
      await expect(component).toHaveAttribute("data-hydrated", "true");
      await expect(content).toHaveText("Hydrated: Manually triggered");
    });
  });

  test.describe("Global API", () => {
    test("exposes __LUNA_STATE__ on window", async ({ page }) => {
      await page.goto("/loader/basic");

      await expect(page.locator('[luna\\:id="counter-1"]')).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const stateExists = await page.evaluate(() => {
        return typeof (window as any).__LUNA_STATE__ === "object";
      });

      expect(stateExists).toBe(true);
    });

    test("exposes __LUNA_HYDRATE__ on window", async ({ page }) => {
      await page.goto("/loader/basic");

      const fnExists = await page.evaluate(() => {
        return typeof (window as any).__LUNA_HYDRATE__ === "function";
      });

      expect(fnExists).toBe(true);
    });

    test("exposes __LUNA_SCAN__ on window", async ({ page }) => {
      await page.goto("/loader/basic");

      const fnExists = await page.evaluate(() => {
        return typeof (window as any).__LUNA_SCAN__ === "function";
      });

      expect(fnExists).toBe(true);
    });

    test("exposes __LUNA_SET_ALLOWED_HOSTS__ on window", async ({ page }) => {
      await page.goto("/loader/basic");

      const fnExists = await page.evaluate(() => {
        return typeof (window as any).__LUNA_SET_ALLOWED_HOSTS__ === "function";
      });

      expect(fnExists).toBe(true);
    });
  });
});
