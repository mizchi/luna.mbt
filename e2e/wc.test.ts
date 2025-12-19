import { test, expect } from "@playwright/test";

const DEBUG = process.env.DEBUG === "1";

test.describe("Web Components Example", () => {
  test.beforeEach(async ({ page }) => {
    if (DEBUG) {
      // Collect console messages for debugging
      page.on("console", (msg) => {
        console.log(`[Browser ${msg.type()}]`, msg.text());
      });
    }
    await page.goto("/demo/wc");
  });

  test("renders the app title", async ({ page }) => {
    await page.waitForSelector("h1");
    const title = page.locator("h1");
    await expect(title).toHaveText("Luna WC Examples");
  });

  test("wc-counter renders and buttons work", async ({ page }) => {
    // Wait for the custom element to be defined
    await page.waitForFunction(() => customElements.get("wc-counter"));

    const counter = page.locator("wc-counter");
    await expect(counter).toBeVisible();

    // Access shadow DOM elements
    const countText = counter.locator("p.count");
    const doubledText = counter.locator("p.doubled");
    const parityText = counter.locator("p.parity");

    // Initial state check
    await expect(countText).toContainText("Count: 0");
    await expect(doubledText).toContainText("Doubled: 0");
    await expect(parityText).toContainText("Even");

    // Click + button
    const incButton = counter.locator("button.inc");
    await incButton.click();

    // Check updated state
    await expect(countText).toContainText("Count: 1");
    await expect(doubledText).toContainText("Doubled: 2");
    await expect(parityText).toContainText("Odd");

    // Click - button
    const decButton = counter.locator("button.dec");
    await decButton.click();

    await expect(countText).toContainText("Count: 0");

    // Click + twice and then Reset
    await incButton.click();
    await incButton.click();

    const resetButton = counter.locator("button.reset");
    await resetButton.click();

    await expect(countText).toContainText("Count: 0");
  });

  test("wc-input renders and input binding works", async ({ page }) => {
    await page.waitForFunction(() => customElements.get("wc-input"));

    const inputComponent = page.locator("wc-input");
    await expect(inputComponent).toBeVisible();

    const input = inputComponent.locator("input.text-input");
    const charCount = inputComponent.locator("p.char-count");
    const typedText = inputComponent.locator("p.typed");

    // Initial state
    await expect(charCount).toContainText("Characters: 0");
    await expect(typedText).toContainText("You typed:");

    // Type text
    await input.fill("Hello");

    await expect(charCount).toContainText("Characters: 5");
    await expect(typedText).toContainText("You typed: Hello");
  });

  test("wc-effect renders and toggle works", async ({ page }) => {
    await page.waitForFunction(() => customElements.get("wc-effect"));

    const effectComponent = page.locator("wc-effect");
    await expect(effectComponent).toBeVisible();

    const statusText = effectComponent.locator("p.status");
    const ticksText = effectComponent.locator("p.ticks");
    const toggleButton = effectComponent.locator("button.toggle");
    const tickButton = effectComponent.locator("button.tick");

    // Initial state
    await expect(statusText).toContainText("Status: Inactive");
    await expect(ticksText).toContainText("Ticks: 0");
    await expect(toggleButton).toContainText("Start");

    // Toggle to active
    await toggleButton.click();

    await expect(statusText).toContainText("Status: Active");
    await expect(toggleButton).toContainText("Stop");

    // Click tick button
    await tickButton.click();
    await expect(ticksText).toContainText("Ticks: 1");

    // Toggle back to inactive
    await toggleButton.click();
    await expect(statusText).toContainText("Status: Inactive");
  });

  test("wc-conditional renders and visibility toggle works", async ({ page }) => {
    await page.waitForFunction(() => customElements.get("wc-conditional"));

    const conditionalComponent = page.locator("wc-conditional");
    await expect(conditionalComponent).toBeVisible();

    const toggleButton = conditionalComponent.locator("button.toggle");
    const message = conditionalComponent.locator("div.message");

    // Initial state - message visible
    await expect(message).toBeVisible();
    await expect(toggleButton).toContainText("Hide Message");

    // Click to hide
    await toggleButton.click();

    await expect(message).toBeHidden();
    await expect(toggleButton).toContainText("Show Message");

    // Click to show
    await toggleButton.click();

    await expect(message).toBeVisible();
    await expect(toggleButton).toContainText("Hide Message");
  });

  test("wc-style renders and sliders work", async ({ page }) => {
    await page.waitForFunction(() => customElements.get("wc-style"));

    const styleComponent = page.locator("wc-style");
    await expect(styleComponent).toBeVisible();

    const box = styleComponent.locator("div.box");
    const hueSlider = styleComponent.locator("input.hue");
    const sizeSlider = styleComponent.locator("input.size");

    // Check initial style
    await expect(box).toHaveCSS("width", "100px");
    await expect(box).toHaveCSS("height", "100px");

    // Change size
    await sizeSlider.fill("150");
    await page.waitForTimeout(100);

    await expect(box).toHaveCSS("width", "150px");
    await expect(box).toHaveCSS("height", "150px");
  });

  test("wc-todo renders and todo operations work", async ({ page }) => {
    await page.waitForFunction(() => customElements.get("wc-todo"));

    const todoComponent = page.locator("wc-todo");
    await expect(todoComponent).toBeVisible();

    const input = todoComponent.locator("input.todo-input");
    const addButton = todoComponent.locator("form button[type='submit']");
    const stats = todoComponent.locator("p.stats");
    const todoList = todoComponent.locator("ul.todo-list");

    // Initial state
    await expect(stats).toContainText("0/0 completed");

    // Add a todo
    await input.fill("Buy milk");
    await addButton.click();

    await expect(todoList.locator("li")).toHaveCount(1);
    await expect(stats).toContainText("0/1 completed");

    // Add another todo
    await input.fill("Walk dog");
    await addButton.click();

    await expect(todoList.locator("li")).toHaveCount(2);
    await expect(stats).toContainText("0/2 completed");

    // Toggle first todo
    await todoList.locator("li").first().locator(".todo-text").click();
    await expect(stats).toContainText("1/2 completed");

    // Remove first todo
    await todoList.locator("li").first().locator("button.remove").click();
    await expect(todoList.locator("li")).toHaveCount(1);
    await expect(stats).toContainText("0/1 completed");
  });

  test("wc-nested-parent renders and receives events from children", async ({ page }) => {
    // Wait for nested components to be defined
    await page.waitForFunction(() =>
      customElements.get("wc-child-button") &&
      customElements.get("wc-nested-parent")
    );

    const parentComponent = page.locator("wc-nested-parent");
    await expect(parentComponent).toBeVisible();

    // Get the total clicks counter in parent
    const totalClicks = parentComponent.locator(".total-clicks");
    await expect(totalClicks).toContainText("0");

    // Get all child buttons (3 of them inside the parent's shadow DOM)
    const childButtons = parentComponent.locator("wc-child-button");
    await expect(childButtons).toHaveCount(3);

    // Click the first child's button
    const firstChild = childButtons.first();
    const firstChildButton = firstChild.locator("button.child-btn");
    await firstChildButton.click();

    // Check that parent received the event
    await expect(totalClicks).toContainText("1");

    // Check that child's local count updated
    const firstChildLocalCount = firstChild.locator(".local-count");
    await expect(firstChildLocalCount).toContainText("1");

    // Click the second child's button twice
    const secondChild = childButtons.nth(1);
    const secondChildButton = secondChild.locator("button.child-btn");
    await secondChildButton.click();
    await secondChildButton.click();

    // Parent should have received all events (1 + 2 = 3)
    await expect(totalClicks).toContainText("3");

    // Second child's local count should be 2
    const secondChildLocalCount = secondChild.locator(".local-count");
    await expect(secondChildLocalCount).toContainText("2");

    // First child's local count should still be 1
    await expect(firstChildLocalCount).toContainText("1");
  });

  test("child components work independently", async ({ page }) => {
    await page.waitForFunction(() => customElements.get("wc-child-button"));

    const parentComponent = page.locator("wc-nested-parent");
    const childButtons = parentComponent.locator("wc-child-button");

    // Click third child multiple times
    const thirdChild = childButtons.nth(2);
    const thirdChildButton = thirdChild.locator("button.child-btn");
    const thirdChildLocalCount = thirdChild.locator(".local-count");

    await thirdChildButton.click();
    await thirdChildButton.click();
    await thirdChildButton.click();

    // Third child should have 3 local clicks
    await expect(thirdChildLocalCount).toContainText("3");

    // Other children should still be at 0 (fresh page)
    const firstChildLocalCount = childButtons.first().locator(".local-count");
    await expect(firstChildLocalCount).toContainText("0");
  });

  test("events bubble through shadow DOM boundary (composed: true)", async ({ page }) => {
    // This test verifies that CustomEvent with composed: true crosses shadow DOM boundaries
    await page.waitForFunction(() =>
      customElements.get("wc-child-button") &&
      customElements.get("wc-nested-parent")
    );

    const parentComponent = page.locator("wc-nested-parent");
    const totalClicks = parentComponent.locator(".total-clicks");

    // The parent component's shadow DOM contains child components
    // When a child dispatches an event, it must cross:
    // 1. child's shadow DOM boundary
    // 2. bubble up to parent's shadow DOM
    // 3. be caught by parent's event listener on host element

    // Initial state
    await expect(totalClicks).toContainText("0");

    // Click a button deep inside nested shadow DOMs
    const childButtons = parentComponent.locator("wc-child-button");
    const firstChild = childButtons.first();

    // The button is inside child's shadow DOM
    const buttonInsideShadow = firstChild.locator("button.child-btn");
    await buttonInsideShadow.click();

    // Parent should receive the event that crossed shadow DOM boundary
    await expect(totalClicks).toContainText("1");
  });

  test("all children contribute to parent total correctly", async ({ page }) => {
    await page.waitForFunction(() =>
      customElements.get("wc-child-button") &&
      customElements.get("wc-nested-parent")
    );

    const parentComponent = page.locator("wc-nested-parent");
    const totalClicks = parentComponent.locator(".total-clicks");
    const childButtons = parentComponent.locator("wc-child-button");

    // Click each child once
    for (let i = 0; i < 3; i++) {
      const child = childButtons.nth(i);
      const btn = child.locator("button.child-btn");
      await btn.click();
    }

    // Parent should have received 3 events (one from each child)
    await expect(totalClicks).toContainText("3");

    // Each child should have local count of 1
    for (let i = 0; i < 3; i++) {
      const child = childButtons.nth(i);
      const localCount = child.locator(".local-count");
      await expect(localCount).toContainText("1");
    }
  });

  test("rapid clicks are all captured", async ({ page }) => {
    await page.waitForFunction(() =>
      customElements.get("wc-child-button") &&
      customElements.get("wc-nested-parent")
    );

    const parentComponent = page.locator("wc-nested-parent");
    const totalClicks = parentComponent.locator(".total-clicks");
    const childButtons = parentComponent.locator("wc-child-button");
    const firstChildButton = childButtons.first().locator("button.child-btn");

    // Rapid clicks
    const clickCount = 5;
    for (let i = 0; i < clickCount; i++) {
      await firstChildButton.click();
    }

    // All clicks should be registered
    await expect(totalClicks).toContainText(clickCount.toString());

    // Child's local count should match
    const localCount = childButtons.first().locator(".local-count");
    await expect(localCount).toContainText(clickCount.toString());
  });

  test("parent and child states are isolated", async ({ page }) => {
    await page.waitForFunction(() =>
      customElements.get("wc-child-button") &&
      customElements.get("wc-nested-parent")
    );

    const parentComponent = page.locator("wc-nested-parent");
    const childButtons = parentComponent.locator("wc-child-button");

    // Click first child 3 times
    const firstChild = childButtons.first();
    const firstBtn = firstChild.locator("button.child-btn");
    await firstBtn.click();
    await firstBtn.click();
    await firstBtn.click();

    // Click second child 1 time
    const secondChild = childButtons.nth(1);
    const secondBtn = secondChild.locator("button.child-btn");
    await secondBtn.click();

    // Verify each component has independent state
    const firstLocalCount = firstChild.locator(".local-count");
    const secondLocalCount = secondChild.locator(".local-count");
    const thirdLocalCount = childButtons.nth(2).locator(".local-count");
    const parentTotal = parentComponent.locator(".total-clicks");

    await expect(firstLocalCount).toContainText("3");
    await expect(secondLocalCount).toContainText("1");
    await expect(thirdLocalCount).toContainText("0");
    await expect(parentTotal).toContainText("4"); // 3 + 1 = 4
  });

  test("no console errors during rendering", async ({ page }) => {
    const errors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") {
        errors.push(msg.text());
      }
    });

    await page.goto("/demo/wc");
    await page.waitForSelector("h1");

    // Wait for all custom elements to be defined
    await page.waitForFunction(() =>
      customElements.get("wc-counter") &&
      customElements.get("wc-input") &&
      customElements.get("wc-effect") &&
      customElements.get("wc-conditional") &&
      customElements.get("wc-style") &&
      customElements.get("wc-todo") &&
      customElements.get("wc-child-button") &&
      customElements.get("wc-nested-parent")
    );

    // Wait for any async errors
    await page.waitForTimeout(500);

    expect(errors).toEqual([]);
  });
});
