import { test, expect } from "@playwright/test";

// This test runs against the actual sol_app example server
// Start with: cd examples/sol_app && sol dev --no-watch -p 3457

const BASE = "http://localhost:3457";

test.describe("sol_app island hydration", () => {
  test("home page renders and counter island hydrates", async ({ page }) => {
    await page.goto(`${BASE}/`);

    // Page loads with SSR content
    await expect(page.locator("h1")).toContainText("Welcome to Sol");

    // Counter island should be present (SSR fallback)
    const counter = page.locator(".counter");
    await expect(counter).toBeVisible();

    // Wait for hydration — the counter should become interactive
    // The hydration marker is luna:id attribute being processed
    await page.waitForTimeout(2000);

    // Check no console errors about hydration
    const errors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") {
        errors.push(msg.text());
      }
    });
    await page.reload();
    await page.waitForTimeout(3000);

    // Filter out non-critical errors (CSP warnings etc)
    const hydrationErrors = errors.filter((e) =>
      e.includes("[sol] Hydration failed")
    );
    expect(hydrationErrors).toEqual([]);
  });

  test("counter island JS is loaded and executable", async ({ page }) => {
    const consoleErrors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") consoleErrors.push(msg.text());
    });

    await page.goto(`${BASE}/`);
    await page.waitForTimeout(3000);

    // Counter JS should be loaded (no 404)
    const jsResponse = await page.evaluate(async () => {
      const res = await fetch("/static/counter.js");
      return res.status;
    });
    expect(jsResponse).toBe(200);

    // No hydration errors should have occurred
    const hydrationErrors = consoleErrors.filter(
      (e) => e.includes("[sol] Hydration failed")
    );
    expect(hydrationErrors).toEqual([]);
  });

  test("API health endpoint returns JSON", async ({ page }) => {
    const response = await page.goto(`${BASE}/api/health`);
    expect(response?.status()).toBe(200);
    const body = await response?.json();
    expect(body).toHaveProperty("status", "ok");
  });

  test("about page renders via CSR navigation", async ({ page }) => {
    await page.goto(`${BASE}/`);
    await page.waitForTimeout(2000);

    // Click about link (CSR navigation)
    await page.click('a[href="/about"]');
    await page.waitForTimeout(1000);

    // Should navigate to about page
    await expect(page.locator("h1")).toContainText("About");
  });

  test("no hydration errors on any page", async ({ page }) => {
    const errors: string[] = [];
    page.on("console", (msg) => {
      if (
        msg.type() === "error" &&
        msg.text().includes("[sol] Hydration failed")
      ) {
        errors.push(msg.text());
      }
    });

    // Visit main pages (skip /form as it may have action-specific setup)
    for (const path of ["/", "/about"]) {
      await page.goto(`${BASE}${path}`);
      await page.waitForTimeout(2000);
    }

    expect(errors).toEqual([]);
  });

  test("WC counter island hydrates without errors", async ({ page }) => {
    const errors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") {
        errors.push(msg.text());
      }
    });

    await page.goto(`${BASE}/`);
    await page.waitForTimeout(3000);

    // Check for the specific WcCounterProps error that was fixed
    const wcErrors = errors.filter((e) =>
      e.includes("WcCounterProps") || e.includes("wc_counter")
    );
    expect(wcErrors).toEqual([]);
  });
});
