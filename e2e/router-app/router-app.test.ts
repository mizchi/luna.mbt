import { test, expect } from "@playwright/test";

test.describe("Router App - Hydration and Reactivity", () => {
  test("mounts and displays home page with counter", async ({ page }) => {
    await page.goto("/router-app");

    // Wait for app to mount
    await expect(page.locator(".app")).toBeVisible();

    // Check home page is displayed
    const pageContent = page.locator("[data-page='home']");
    await expect(pageContent).toBeVisible();
    await expect(pageContent.locator("h1")).toHaveText("Welcome to Router App");

    // Check counter is present
    const counter = page.locator("[data-testid='counter']");
    await expect(counter).toBeVisible();
  });

  test("counter reactivity: clicks update count display", async ({ page }) => {
    // Capture console logs
    const logs: string[] = [];
    page.on("console", (msg) => {
      logs.push(`[${msg.type()}] ${msg.text()}`);
    });

    await page.goto("/router-app");

    // Wait for app to mount
    await expect(page.locator(".app")).toBeVisible();

    // Get counter elements
    const countDisplay = page.locator("[data-testid='count-display']");
    const incrementBtn = page.locator("[data-testid='increment-btn']");
    const decrementBtn = page.locator("[data-testid='decrement-btn']");
    const resetBtn = page.locator("[data-testid='reset-btn']");

    // Initial count should be 0
    await expect(countDisplay).toContainText("Count: 0");

    console.log("Before click, logs:", logs);

    // Click increment 3 times
    await incrementBtn.click();
    await page.waitForTimeout(100);
    console.log("After click, logs:", logs);
    await expect(countDisplay).toContainText("Count: 1");

    await incrementBtn.click();
    await expect(countDisplay).toContainText("Count: 2");

    await incrementBtn.click();
    await expect(countDisplay).toContainText("Count: 3");

    // Click decrement once
    await decrementBtn.click();
    await expect(countDisplay).toContainText("Count: 2");

    // Click reset
    await resetBtn.click();
    await expect(countDisplay).toContainText("Count: 0");
  });

  test("CSR navigation: navigates to about page via nav click", async ({
    page,
  }) => {
    await page.goto("/router-app");
    await expect(page.locator(".app")).toBeVisible();

    // Click About link in nav
    await page.locator("nav").getByText("About").click();

    // Wait for URL change
    await expect(page).toHaveURL(/\/router-app\/about$/);

    // Check about page is displayed
    const aboutPage = page.locator("[data-page='about']");
    await expect(aboutPage).toBeVisible();
    await expect(aboutPage.locator("h1")).toHaveText("About");
  });

  test("CSR navigation: counter state persists when navigating back", async ({
    page,
  }) => {
    await page.goto("/router-app");
    await expect(page.locator(".app")).toBeVisible();

    // Increment counter
    const countDisplay = page.locator("[data-testid='count-display']");
    const incrementBtn = page.locator("[data-testid='increment-btn']");

    await incrementBtn.click();
    await incrementBtn.click();
    await expect(countDisplay).toContainText("Count: 2");

    // Navigate to about
    await page.locator("nav").getByText("About").click();
    await expect(page.locator("[data-page='about']")).toBeVisible();

    // Navigate back to home
    await page.locator("nav").getByText("Home").click();
    await expect(page.locator("[data-page='home']")).toBeVisible();

    // Counter should be reset (new component instance)
    await expect(page.locator("[data-testid='count-display']")).toContainText(
      "Count: 0"
    );
  });

  test("CSR navigation: navigates to users page with layout", async ({
    page,
  }) => {
    // Capture console logs
    const logs: string[] = [];
    page.on("console", (msg) => {
      logs.push(`[${msg.type()}] ${msg.text()}`);
    });

    await page.goto("/router-app");
    await expect(page.locator(".app")).toBeVisible();
    console.log("Initial logs:", logs);

    // Click Users link
    await page.locator("nav").getByText("Users").click();

    // Check URL changed
    await expect(page).toHaveURL(/\/router-app\/users$/);
    console.log("After users click logs:", logs);

    // Check layout is applied (users section header)
    await expect(page.locator(".users-layout")).toBeVisible();
    await expect(page.locator(".users-layout h2")).toHaveText("Users Section");

    // Check user list is displayed
    await expect(page.locator(".users-list")).toBeVisible();
    await expect(page.locator(".users-list h3")).toHaveText("User List");
  });

  test("CSR navigation: navigates to user detail page with dynamic param", async ({
    page,
  }) => {
    await page.goto("/router-app/users");
    await expect(page.locator(".users-layout")).toBeVisible();

    // Click User 1 button
    await page.getByRole("button", { name: "User 1" }).click();

    // Check URL changed
    await expect(page).toHaveURL(/\/router-app\/users\/1$/);

    // Check user detail is displayed
    const userDetail = page.locator(".user-detail");
    await expect(userDetail).toBeVisible();
    await expect(userDetail).toContainText("User ID: 1");
    await expect(userDetail).toContainText("Name: Alice");

    // Click User 2 button
    await page.getByRole("button", { name: "User 2" }).click();
    await expect(page).toHaveURL(/\/router-app\/users\/2$/);
    await expect(userDetail).toContainText("User ID: 2");
    await expect(userDetail).toContainText("Name: Bob");
  });

  test("CSR navigation: navigates to settings group pages", async ({
    page,
  }) => {
    await page.goto("/router-app");
    await expect(page.locator(".app")).toBeVisible();

    // Click Settings link
    await page.locator("nav").getByText("Settings").click();

    // Check URL changed
    await expect(page).toHaveURL(/\/router-app\/settings$/);

    // Check settings index is displayed
    await expect(page.locator(".settings-index")).toBeVisible();
    await expect(page.locator(".settings-index h1")).toHaveText("Settings");

    // Click Profile Settings link
    await page.getByRole("link", { name: "Profile Settings" }).click();

    // Check URL changed
    await expect(page).toHaveURL(/\/router-app\/settings\/profile$/);

    // Check profile settings is displayed
    await expect(page.locator(".settings-profile")).toBeVisible();
    await expect(page.locator(".settings-profile h1")).toHaveText(
      "Profile Settings"
    );
  });

  test("current path display updates on navigation", async ({ page }) => {
    await page.goto("/router-app");
    await expect(page.locator(".app")).toBeVisible();

    // Check initial path display on home
    const pathDisplay = page.locator("[data-testid='current-path']");
    await expect(pathDisplay).toContainText("Current path: /router-app");

    // Navigate to about and back to home
    await page.locator("nav").getByText("About").click();
    await expect(page).toHaveURL(/\/router-app\/about$/);

    // Navigate back to home and verify path updated
    await page.locator("nav").getByText("Home").click();
    await expect(pathDisplay).toContainText("Current path: /router-app");
  });

  test("browser back/forward navigation works", async ({ page }) => {
    await page.goto("/router-app");
    await expect(page.locator("[data-page='home']")).toBeVisible();

    // Navigate to about
    await page.locator("nav").getByText("About").click();
    await expect(page.locator("[data-page='about']")).toBeVisible();

    // Navigate to users
    await page.locator("nav").getByText("Users").click();
    await expect(page.locator(".users-list")).toBeVisible();

    // Go back (should show about)
    await page.goBack();
    await expect(page.locator("[data-page='about']")).toBeVisible();

    // Go back again (should show home)
    await page.goBack();
    await expect(page.locator("[data-page='home']")).toBeVisible();

    // Go forward (should show about)
    await page.goForward();
    await expect(page.locator("[data-page='about']")).toBeVisible();
  });

  test("direct URL access works (MPA navigation)", async ({ page }) => {
    // Direct access to about page
    await page.goto("/router-app/about");
    await expect(page.locator("[data-page='about']")).toBeVisible();
    await expect(page.locator("[data-page='about'] h1")).toHaveText("About");
  });

  test("direct URL access to user detail page works", async ({ page }) => {
    // Direct access to user detail page
    await page.goto("/router-app/users/3");

    // Should show user detail with layout
    await expect(page.locator(".users-layout")).toBeVisible();
    await expect(page.locator(".user-detail")).toBeVisible();
    await expect(page.locator(".user-detail")).toContainText("User ID: 3");
    await expect(page.locator(".user-detail")).toContainText("Name: Charlie");
  });

  test("displays 404 for unknown routes", async ({ page }) => {
    await page.goto("/router-app/unknown/path");

    // Should show 404 page
    await expect(page.locator(".not-found")).toBeVisible();
    await expect(page.locator(".not-found h1")).toHaveText("404 - Not Found");
  });
});
