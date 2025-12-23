import { test, expect } from "@playwright/test";

/**
 * E2E tests for middleware functionality in examples/sol-app
 * Tests Logger and CORS middleware with method-style composition
 */
test.describe("Middleware", () => {
  const BASE_URL = "http://localhost:3457";

  test.describe("Middleware Test Page", () => {
    test("renders middleware test page", async ({ page }) => {
      await page.goto(`${BASE_URL}/middleware-test`);
      await expect(page.locator("h1")).toContainText("Middleware Test");
    });

    test("displays middleware stack information", async ({ page }) => {
      await page.goto(`${BASE_URL}/middleware-test`);
      await expect(page.locator("body")).toContainText("Logger");
      await expect(page.locator("body")).toContainText("CORS");
    });

    test("has links to test API endpoints", async ({ page }) => {
      await page.goto(`${BASE_URL}/middleware-test`);
      await expect(
        page.locator('a[href="/api/middleware-test"]')
      ).toBeVisible();
      await expect(page.locator('a[href="/api/health"]')).toBeVisible();
    });
  });

  test.describe("API Endpoints", () => {
    test("middleware-test endpoint returns JSON with middleware info", async ({
      request,
    }) => {
      const response = await request.get(`${BASE_URL}/api/middleware-test`);
      expect(response.ok()).toBeTruthy();

      const json = await response.json();
      expect(json.middleware).toBe("logger >> cors");
      expect(json.message).toContain("Middleware is working");
      expect(json.timestamp).toBeDefined();
    });

    test("health endpoint works through middleware chain", async ({
      request,
    }) => {
      const response = await request.get(`${BASE_URL}/api/health`);
      expect(response.ok()).toBeTruthy();

      const json = await response.json();
      expect(json.status).toBe("ok");
    });

    test("catch-all API endpoint works", async ({ request }) => {
      const response = await request.get(`${BASE_URL}/api/test/foo/bar`);
      expect(response.ok()).toBeTruthy();

      const json = await response.json();
      expect(json.path).toBe("foo/bar");
    });
  });

  test.describe("CORS Headers", () => {
    test("API endpoint returns CORS headers with Origin", async ({
      request,
    }) => {
      const response = await request.get(`${BASE_URL}/api/middleware-test`, {
        headers: { Origin: "http://example.com" },
      });
      expect(response.ok()).toBeTruthy();
      const headers = response.headers();
      expect(headers["access-control-allow-origin"]).toBe("*");
    });
  });

  test.describe("Navigation to Middleware Test", () => {
    test("navigates from home to middleware test page", async ({ page }) => {
      await page.goto(BASE_URL);
      // Navigate via URL since there's no link from home
      await page.goto(`${BASE_URL}/middleware-test`);
      await expect(page).toHaveURL(`${BASE_URL}/middleware-test`);
      await expect(page.locator("h1")).toContainText("Middleware Test");
    });
  });
});
