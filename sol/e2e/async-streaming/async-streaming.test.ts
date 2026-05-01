import { test, expect } from "@playwright/test";

test.describe("Async Streaming SSR E2E Tests", () => {
  test.describe("Basic Async Replacement", () => {
    test("renders fallback then replaces with async content", async ({
      page,
    }) => {
      await page.goto("/async/basic");

      // Static content should be visible
      await expect(page.locator("#static-content")).toHaveText(
        "This is static content"
      );

      // Async content should have replaced the fallback
      // (since this is synchronous simulation, replacement happens immediately)
      const resolved = page.locator(".resolved");
      await expect(resolved).toHaveText("Async content loaded!");

      // The loading placeholder should no longer exist
      await expect(page.locator(".loading")).toHaveCount(0);
    });

    test("placeholder div with A:id is removed after replacement", async ({
      page,
    }) => {
      await page.goto("/async/basic");

      // The placeholder div should have been replaced
      await expect(page.locator('[id^="A:"]')).toHaveCount(0);

      // Template should also be removed
      await expect(page.locator('[id^="T:"]')).toHaveCount(0);
    });
  });

  test.describe("Multiple Async Boundaries", () => {
    test("replaces multiple async boundaries independently", async ({
      page,
    }) => {
      await page.goto("/async/multiple");

      // Both resolved contents should be visible
      await expect(page.locator("#first-resolved")).toHaveText("First resolved");
      await expect(page.locator("#second-resolved")).toHaveText(
        "Second resolved"
      );

      // Static middle content should remain
      await expect(page.locator("#middle")).toHaveText("Static middle content");

      // Loading placeholders should be gone
      await expect(page.locator("#first-loading")).toHaveCount(0);
      await expect(page.locator("#second-loading")).toHaveCount(0);
    });

    test("maintains correct DOM order after replacement", async ({ page }) => {
      await page.goto("/async/multiple");

      // Check DOM order: h1 -> first-resolved -> middle -> second-resolved
      const body = page.locator("body");
      const children = body.locator("> *");

      // Get text content in order
      const texts = await children.allTextContents();

      // Find the indices
      const h1Index = texts.findIndex((t) => t.includes("Multiple Async Test"));
      const firstIndex = texts.findIndex((t) => t === "First resolved");
      const middleIndex = texts.findIndex((t) => t === "Static middle content");
      const secondIndex = texts.findIndex((t) => t === "Second resolved");

      expect(h1Index).toBeLessThan(firstIndex);
      expect(firstIndex).toBeLessThan(middleIndex);
      expect(middleIndex).toBeLessThan(secondIndex);
    });
  });

  test.describe("Nested Async Content", () => {
    test("replaces async content within nested structure", async ({ page }) => {
      await page.goto("/async/nested");

      // Container should exist
      await expect(page.locator("#container")).toBeVisible();

      // Header and footer should be present
      await expect(page.locator("header")).toHaveText("Header");
      await expect(page.locator("footer")).toHaveText("Footer");

      // Main content should be the resolved version
      const mainContent = page.locator("#main-content");
      await expect(mainContent).toBeVisible();
      await expect(mainContent.locator("p")).toHaveText("Main content loaded");

      // List items should be present
      const listItems = mainContent.locator("li");
      await expect(listItems).toHaveCount(2);
      await expect(listItems.nth(0)).toHaveText("Item 1");
      await expect(listItems.nth(1)).toHaveText("Item 2");

      // Skeleton should be gone
      await expect(page.locator(".skeleton")).toHaveCount(0);
    });
  });

  test.describe("Fallback Only (No Replacement)", () => {
    test("shows fallback when no replacement script is provided", async ({
      page,
    }) => {
      await page.goto("/async/fallback-only");

      // Fallback should be visible
      await expect(page.locator("#fallback-visible")).toHaveText(
        "Fallback is visible"
      );

      // The "never-seen" content should not appear
      await expect(page.locator("#never-seen")).toHaveCount(0);

      // Placeholder div should still exist (not replaced)
      await expect(page.locator('[id^="A:"]')).toHaveCount(1);
    });
  });

  test.describe("Template Element Cleanup", () => {
    test("template elements are removed after content replacement", async ({
      page,
    }) => {
      await page.goto("/async/basic");

      // Template should be removed after replacement script runs
      const templates = page.locator("template");
      await expect(templates).toHaveCount(0);
    });

    test("no orphaned templates in multiple async scenario", async ({
      page,
    }) => {
      await page.goto("/async/multiple");

      // All templates should be cleaned up
      await expect(page.locator("template")).toHaveCount(0);
    });
  });

  test.describe("HTML Structure Verification", () => {
    test("basic page has correct initial structure in source", async ({
      request,
    }) => {
      const response = await request.get("/async/basic");
      const html = await response.text();

      // Should contain placeholder div with A:id
      expect(html).toContain('id="A:');

      // Should contain template with T:id
      expect(html).toContain('id="T:');

      // Should contain replacement script
      expect(html).toContain("document.getElementById");
      expect(html).toContain("replaceWith");
      expect(html).toContain("t.content");
      expect(html).toContain("t.remove()");

      // Should contain fallback content in placeholder
      expect(html).toContain("Loading...");

      // Should contain resolved content in template
      expect(html).toContain("Async content loaded!");
    });
  });
});
