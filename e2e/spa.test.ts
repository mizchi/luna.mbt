import { test, expect } from "@playwright/test";

test.describe("SPA Example", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/spa");
  });

  test("renders the app title", async ({ page }) => {
    // Wait for JS to load and render
    await page.waitForSelector("h1");

    const title = page.locator("h1");
    await expect(title).toHaveText("Luna Examples");
  });

  test("counter example works", async ({ page }) => {
    // Wait for counter section to render
    await page.waitForSelector(".counter-example");

    const counterSection = page.locator(".counter-example");

    // Initial state
    await expect(counterSection.locator("p").first()).toContainText("Count: 0");
    await expect(counterSection.locator("p").nth(1)).toContainText("Doubled: 0");
    await expect(counterSection.locator("p").nth(2)).toContainText("Even");

    // Click + button
    await counterSection.locator("button", { hasText: "+" }).click();

    await expect(counterSection.locator("p").first()).toContainText("Count: 1");
    await expect(counterSection.locator("p").nth(1)).toContainText("Doubled: 2");
    await expect(counterSection.locator("p").nth(2)).toContainText("Odd");

    // Click - button
    await counterSection.locator("button", { hasText: "-" }).click();

    await expect(counterSection.locator("p").first()).toContainText("Count: 0");

    // Click Reset button
    await counterSection.locator("button", { hasText: "+" }).click();
    await counterSection.locator("button", { hasText: "+" }).click();
    await counterSection.locator("button", { hasText: "Reset" }).click();

    await expect(counterSection.locator("p").first()).toContainText("Count: 0");
  });

  test("input example works", async ({ page }) => {
    await page.waitForSelector(".input-example");

    const inputSection = page.locator(".input-example");
    const input = inputSection.locator("input[type='text']");

    // Initial state
    await expect(inputSection.locator("p").first()).toContainText("Characters: 0");
    await expect(inputSection.locator("p").nth(1)).toContainText("You typed:");

    // Type text
    await input.fill("Hello");

    await expect(inputSection.locator("p").first()).toContainText("Characters: 5");
    await expect(inputSection.locator("p").nth(1)).toContainText("You typed: Hello");
  });

  test("conditional example works", async ({ page }) => {
    await page.waitForSelector(".conditional-example");

    const conditionalSection = page.locator(".conditional-example");

    // Initial state - message should be visible
    await expect(conditionalSection.locator(".message")).toBeVisible();

    // Click to hide
    await conditionalSection.locator("button", { hasText: "Hide Message" }).click();

    // Message should be hidden
    await expect(conditionalSection.locator(".message")).toHaveCount(0);

    // Click to show
    await conditionalSection.locator("button", { hasText: "Show Message" }).click();

    // Message should be visible again
    await expect(conditionalSection.locator(".message")).toBeVisible();
  });

  test("todo example works", async ({ page }) => {
    await page.waitForSelector(".todo-example");

    const todoSection = page.locator(".todo-example");
    const input = todoSection.locator("input[type='text']");

    // Initial state
    await expect(todoSection.locator("p").first()).toContainText("0/0 completed");

    // Add a todo
    await input.fill("Buy milk");
    await todoSection.locator("button", { hasText: "Add" }).click();

    await expect(todoSection.locator("ul li")).toHaveCount(1);
    await expect(todoSection.locator("p").first()).toContainText("0/1 completed");

    // Add another todo
    await input.fill("Walk dog");
    await todoSection.locator("button", { hasText: "Add" }).click();

    await expect(todoSection.locator("ul li")).toHaveCount(2);
    await expect(todoSection.locator("p").first()).toContainText("0/2 completed");

    // Toggle first todo (click on the text span)
    await todoSection.locator("ul li").first().locator("span").click();

    await expect(todoSection.locator("p").first()).toContainText("1/2 completed");

    // Remove first todo
    await todoSection.locator("ul li").first().locator("button", { hasText: "x" }).click();

    await expect(todoSection.locator("ul li")).toHaveCount(1);
    await expect(todoSection.locator("p").first()).toContainText("0/1 completed");
  });

  test("style example range inputs work", async ({ page }) => {
    await page.waitForSelector(".style-example");

    const styleSection = page.locator(".style-example");
    // The colored div is the first direct child div after h2
    const colorBox = styleSection.locator("> div").first();
    const hueSlider = styleSection.locator("input[type='range']").first();
    const sizeSlider = styleSection.locator("input[type='range']").nth(1);

    // Wait for the color box to have a style attribute (dynamic rendering)
    await page.waitForFunction(() => {
      const box = document.querySelector(".style-example > div");
      return box && box.getAttribute("style")?.includes("hsl");
    });

    // Get initial style
    const initialStyle = await colorBox.getAttribute("style");
    expect(initialStyle).toContain("hsl(180");
    expect(initialStyle).toContain("100px");

    // Change hue slider
    await hueSlider.fill("0");
    await page.waitForTimeout(100); // Wait for signal update

    const newStyle = await colorBox.getAttribute("style");
    expect(newStyle).toContain("hsl(0");

    // Change size slider
    await sizeSlider.fill("150");
    await page.waitForTimeout(100);

    const finalStyle = await colorBox.getAttribute("style");
    expect(finalStyle).toContain("150px");
  });

  test("modal example works with portal", async ({ page }) => {
    await page.waitForSelector(".modal-example");

    const modalSection = page.locator(".modal-example");

    // Modal should not be visible initially
    await expect(page.locator("#modal-overlay")).toHaveCount(0);

    // Click to open modal
    await modalSection.locator("#open-modal-btn").click();

    // Modal should be rendered to body via Portal
    // The modal overlay should be a direct child of body, not inside .modal-example
    await expect(page.locator("body > div > #modal-overlay")).toBeVisible();
    await expect(page.locator("#modal-content")).toBeVisible();

    // Check modal content
    const modalContent = page.locator("#modal-content");
    await expect(modalContent.locator("h3")).toHaveText("Modal Title");
    await expect(modalContent.locator("p")).toContainText("rendered using Portal");

    // Close modal by clicking close button
    await page.locator("#close-modal-btn").click();

    // Modal should be removed
    await expect(page.locator("#modal-overlay")).toHaveCount(0);
  });

  test("modal closes when clicking overlay", async ({ page }) => {
    await page.waitForSelector(".modal-example");

    const modalSection = page.locator(".modal-example");

    // Open modal
    await modalSection.locator("#open-modal-btn").click();
    await expect(page.locator("#modal-overlay")).toBeVisible();

    // Click on overlay (not modal content) to close
    // Need to click on the overlay area outside the modal content
    await page.locator("#modal-overlay").click({ position: { x: 10, y: 10 } });

    // Modal should be closed
    await expect(page.locator("#modal-overlay")).toHaveCount(0);
  });

  test("modal stays open when clicking content", async ({ page }) => {
    await page.waitForSelector(".modal-example");

    const modalSection = page.locator(".modal-example");

    // Open modal
    await modalSection.locator("#open-modal-btn").click();
    await expect(page.locator("#modal-overlay")).toBeVisible();

    // Click on modal content (not overlay)
    await page.locator("#modal-content").click();

    // Modal should still be visible
    await expect(page.locator("#modal-overlay")).toBeVisible();

    // Clean up - close modal
    await page.locator("#close-modal-btn").click();
  });

  test("no console errors during rendering", async ({ page }) => {
    const errors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") {
        errors.push(msg.text());
      }
    });

    await page.goto("/spa");
    await page.waitForSelector("h1");

    // Wait a bit for any async errors
    await page.waitForTimeout(500);

    expect(errors).toEqual([]);
  });
});
