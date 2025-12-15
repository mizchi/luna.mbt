/**
 * Browser App E2E tests with coverage collection
 * Uses custom fixture to collect V8 JS coverage
 */
import { test, expect } from "../coverage-fixture.mjs";

test.describe("Browser App - Coverage Tests", () => {
  test("collects coverage on home page interaction", async ({
    coveragePage: page,
  }) => {
    await page.goto("/playground/browser_router");
    await expect(page.locator(".app")).toBeVisible();

    // Interact with counter to exercise code paths
    const incrementBtn = page.locator("[data-testid='increment-btn']");
    const countDisplay = page.locator("[data-testid='count-display']");

    await incrementBtn.click();
    await incrementBtn.click();
    await incrementBtn.click();
    await expect(countDisplay).toContainText("Count: 3");

    const decrementBtn = page.locator("[data-testid='decrement-btn']");
    await decrementBtn.click();
    await expect(countDisplay).toContainText("Count: 2");

    const resetBtn = page.locator("[data-testid='reset-btn']");
    await resetBtn.click();
    await expect(countDisplay).toContainText("Count: 0");
  });

  test("collects coverage on navigation", async ({ coveragePage: page }) => {
    await page.goto("/playground/browser_router");
    await expect(page.locator(".app")).toBeVisible();

    // Navigate through pages
    await page.locator("nav").getByText("About").click();
    await expect(page.locator("[data-page='about']")).toBeVisible();

    await page.locator("nav").getByText("Users").click();
    await expect(page.locator(".users-layout")).toBeVisible();

    await page.getByRole("button", { name: "User 1" }).click();
    await expect(page.locator(".user-detail")).toBeVisible();

    await page.locator("nav").getByText("Settings").click();
    await expect(page.locator(".settings-index")).toBeVisible();

    await page.getByRole("link", { name: "Profile Settings" }).click();
    await expect(page.locator(".settings-profile")).toBeVisible();
  });

  test("collects coverage on browser navigation", async ({
    coveragePage: page,
  }) => {
    await page.goto("/playground/browser_router");
    await expect(page.locator("[data-page='home']")).toBeVisible();

    await page.locator("nav").getByText("About").click();
    await expect(page.locator("[data-page='about']")).toBeVisible();

    await page.goBack();
    await expect(page.locator("[data-page='home']")).toBeVisible();

    await page.goForward();
    await expect(page.locator("[data-page='about']")).toBeVisible();
  });
});
