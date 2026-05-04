import { test, expect } from "@playwright/test";

test.describe("Luna UI Browser Tests", () => {
  test.describe("Signal/Effect Reactivity", () => {
    test("hydrates and displays initial values", async ({ page }) => {
      await page.goto("/browser/signal-effect");

      // Wait for hydration
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Check initial values
      const count = page.locator("[data-count]");
      const double = page.locator("[data-double]");

      await expect(count).toHaveText("5");
      await expect(double).toHaveText("10");
    });

    test("Signal.update triggers Effect and updates derived values", async ({
      page,
    }) => {
      await page.goto("/browser/signal-effect");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      const double = page.locator("[data-double]");
      const incBtn = page.locator("[data-inc]");
      const decBtn = page.locator("[data-dec]");

      // Initial state
      await expect(count).toHaveText("5");
      await expect(double).toHaveText("10");

      // Increment - effect should update double
      await incBtn.click();
      await expect(count).toHaveText("6");
      await expect(double).toHaveText("12");

      // Increment again
      await incBtn.click();
      await expect(count).toHaveText("7");
      await expect(double).toHaveText("14");

      // Decrement
      await decBtn.click();
      await expect(count).toHaveText("6");
      await expect(double).toHaveText("12");
    });

    test("Signal.set resets value and triggers Effect", async ({ page }) => {
      await page.goto("/browser/signal-effect");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      const double = page.locator("[data-double]");
      const incBtn = page.locator("[data-inc]");
      const resetBtn = page.locator("[data-reset]");

      // Modify value
      await incBtn.click();
      await incBtn.click();
      await expect(count).toHaveText("7");
      await expect(double).toHaveText("14");

      // Reset to 0
      await resetBtn.click();
      await expect(count).toHaveText("0");
      await expect(double).toHaveText("0");
    });
  });

  test.describe("Dynamic Attributes", () => {
    test("hydrates with initial attribute values", async ({ page }) => {
      await page.goto("/browser/dynamic-attrs");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const box = page.locator("[data-box]");

      // Initial state: inactive
      await expect(box).toHaveText("Inactive");
      await expect(box).toHaveClass("box");
    });

    test("toggle updates dynamic class", async ({ page }) => {
      await page.goto("/browser/dynamic-attrs");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const box = page.locator("[data-box]");
      const toggleBtn = page.locator("[data-toggle]");

      // Toggle to active
      await toggleBtn.click();
      await expect(box).toHaveText("Active");
      await expect(box).toHaveClass("box active");

      // Toggle back to inactive
      await toggleBtn.click();
      await expect(box).toHaveText("Inactive");
      await expect(box).toHaveClass("box");
    });

    test("color buttons update dynamic style", async ({ page }) => {
      await page.goto("/browser/dynamic-attrs");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const box = page.locator("[data-box]");
      const redBtn = page.locator("[data-red]");
      const blueBtn = page.locator("[data-blue]");

      // Change to red
      await redBtn.click();
      await expect(box).toHaveAttribute(
        "style",
        /background-color:\s*red/
      );

      // Change to blue
      await blueBtn.click();
      await expect(box).toHaveAttribute(
        "style",
        /background-color:\s*blue/
      );
    });
  });

  test.describe("Conditional Rendering (vshow)", () => {
    test("content is hidden initially when visible=false", async ({ page }) => {
      await page.goto("/browser/show-toggle");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const content = page.locator("[data-content]");
      const toggleBtn = page.locator("[data-toggle]");

      // Content should not be visible
      await expect(content).toHaveCount(0);
      await expect(toggleBtn).toHaveText("Show");
    });

    test("toggle shows and hides content", async ({ page }) => {
      await page.goto("/browser/show-toggle");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const toggleBtn = page.locator("[data-toggle]");

      // Show content
      await toggleBtn.click();
      await expect(toggleBtn).toHaveText("Hide");
      await expect(page.locator("[data-content]")).toBeVisible();
      await expect(page.locator("[data-content]")).toHaveText(
        "This content is conditionally shown"
      );

      // Hide content
      await toggleBtn.click();
      await expect(toggleBtn).toHaveText("Show");
      await expect(page.locator("[data-content]")).toHaveCount(0);
    });

    test("multiple toggles work correctly", async ({ page }) => {
      await page.goto("/browser/show-toggle");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const toggleBtn = page.locator("[data-toggle]");

      // Toggle multiple times
      for (let i = 0; i < 5; i++) {
        await toggleBtn.click();
        if (i % 2 === 0) {
          await expect(page.locator("[data-content]")).toBeVisible();
        } else {
          await expect(page.locator("[data-content]")).toHaveCount(0);
        }
      }
    });
  });

  test.describe("List Rendering (vfor)", () => {
    test("renders initial list items", async ({ page }) => {
      await page.goto("/browser/for-each");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      const list = page.locator("[data-list]");

      await expect(count).toHaveText("3 items");
      await expect(list.locator("li")).toHaveCount(3);
    });

    test("add button appends new items to list", async ({ page }) => {
      await page.goto("/browser/for-each");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      const list = page.locator("[data-list]");
      const addBtn = page.locator("[data-add]");

      // Add item
      await addBtn.click();
      await expect(count).toHaveText("4 items");
      await expect(list.locator("li")).toHaveCount(4);

      // Add another
      await addBtn.click();
      await expect(count).toHaveText("5 items");
      await expect(list.locator("li")).toHaveCount(5);
    });

    test("remove buttons delete items from list", async ({ page }) => {
      await page.goto("/browser/for-each");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      const list = page.locator("[data-list]");

      // Remove first item (Apple)
      await page.locator('[data-remove="0"]').click();
      await expect(count).toHaveText("2 items");
      await expect(list.locator("li")).toHaveCount(2);

      // The first item should now be what was the second item
      await expect(list.locator("li").first().locator("span")).toContainText(
        "Banana"
      );
    });

    test("list can be emptied completely", async ({ page }) => {
      await page.goto("/browser/for-each");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const count = page.locator("[data-count]");
      const list = page.locator("[data-list]");

      // Remove all items
      await page.locator('[data-remove="0"]').click();
      await page.locator('[data-remove="0"]').click();
      await page.locator('[data-remove="0"]').click();

      await expect(count).toHaveText("0 items");
      await expect(list.locator("li")).toHaveCount(0);
    });
  });

  test.describe("Event Handlers", () => {
    test("click handler increments counter", async ({ page }) => {
      await page.goto("/browser/events");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const clickArea = page.locator("[data-click-area]");
      const clicks = page.locator("[data-clicks]");

      await expect(clicks).toHaveText("Clicks: 0");

      await clickArea.click();
      await expect(clicks).toHaveText("Clicks: 1");

      await clickArea.click();
      await clickArea.click();
      await expect(clicks).toHaveText("Clicks: 3");
    });

    test("dblclick handler increments double-click counter", async ({
      page,
    }) => {
      await page.goto("/browser/events");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const clickArea = page.locator("[data-click-area]");
      const dblclicks = page.locator("[data-dblclicks]");

      await expect(dblclicks).toHaveText("Double-clicks: 0");

      await clickArea.dblclick();
      await expect(dblclicks).toHaveText("Double-clicks: 1");
    });

    test("mouseenter and mouseleave update hover state", async ({ page }) => {
      await page.goto("/browser/events");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const clickArea = page.locator("[data-click-area]");
      const hoverState = page.locator("[data-hover]");

      await expect(hoverState).toHaveText("Hover: none");

      // Hover over the element
      await clickArea.hover();
      await expect(hoverState).toHaveText("Hover: hovering");

      // Move mouse away
      await page.locator("h1").hover();
      await expect(hoverState).toHaveText("Hover: none");
    });
  });

  test.describe("List Reorder DOM Reuse", () => {
    test("renders initial list with correct order", async ({ page }) => {
      await page.goto("/browser/sortable-list");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const list = page.locator("[data-list]");
      const items = list.locator("li");

      await expect(items).toHaveCount(4);
      await expect(items.nth(0)).toHaveText("Apple");
      await expect(items.nth(1)).toHaveText("Banana");
      await expect(items.nth(2)).toHaveText("Cherry");
      await expect(items.nth(3)).toHaveText("Date");
    });

    // NOTE: These tests verify DOM element reuse during list reordering.
    // Using reference-based reconciliation (Solid-style).
    test("reverse reorders list without destroying DOM elements", async ({
      page,
    }) => {
      await page.goto("/browser/sortable-list");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const list = page.locator("[data-list]");
      const items = list.locator("li");

      // Mark each DOM element with a unique property before reorder
      await page.evaluate(() => {
        const elements = document.querySelectorAll("[data-list] li");
        elements.forEach((el, i) => {
          (el as any).__testMarker = `marker-${i}`;
        });
      });

      // Click reverse button
      await page.locator("[data-reverse]").click();

      // Verify order is reversed
      await expect(items.nth(0)).toHaveText("Date");
      await expect(items.nth(1)).toHaveText("Cherry");
      await expect(items.nth(2)).toHaveText("Banana");
      await expect(items.nth(3)).toHaveText("Apple");

      // Verify DOM elements are reused (markers should still exist)
      const markers = await page.evaluate(() => {
        const elements = document.querySelectorAll("[data-list] li");
        return Array.from(elements).map((el) => (el as any).__testMarker);
      });

      // After reverse: Date(was 3), Cherry(was 2), Banana(was 1), Apple(was 0)
      // So markers should be: marker-3, marker-2, marker-1, marker-0
      expect(markers).toEqual(["marker-3", "marker-2", "marker-1", "marker-0"]);
    });

    test("move first to last reorders without destroying DOM elements", async ({
      page,
    }) => {
      await page.goto("/browser/sortable-list");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const list = page.locator("[data-list]");
      const items = list.locator("li");

      // Mark each DOM element with a unique property before reorder
      await page.evaluate(() => {
        const elements = document.querySelectorAll("[data-list] li");
        elements.forEach((el, i) => {
          (el as any).__testMarker = `marker-${i}`;
        });
      });

      // Click move first to last button
      await page.locator("[data-move-first-to-last]").click();

      // Verify order: Apple moved to end
      await expect(items.nth(0)).toHaveText("Banana");
      await expect(items.nth(1)).toHaveText("Cherry");
      await expect(items.nth(2)).toHaveText("Date");
      await expect(items.nth(3)).toHaveText("Apple");

      // Verify DOM elements are reused
      const markers = await page.evaluate(() => {
        const elements = document.querySelectorAll("[data-list] li");
        return Array.from(elements).map((el) => (el as any).__testMarker);
      });

      // After move: Banana(was 1), Cherry(was 2), Date(was 3), Apple(was 0)
      expect(markers).toEqual(["marker-1", "marker-2", "marker-3", "marker-0"]);
    });

    test("multiple reorders maintain DOM element identity", async ({ page }) => {
      await page.goto("/browser/sortable-list");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const list = page.locator("[data-list]");
      const items = list.locator("li");

      // Mark elements
      await page.evaluate(() => {
        const elements = document.querySelectorAll("[data-list] li");
        elements.forEach((el, i) => {
          (el as any).__testMarker = `marker-${i}`;
        });
      });

      // Reverse twice should return to original order
      await page.locator("[data-reverse]").click();
      await page.locator("[data-reverse]").click();

      // Verify order is back to original
      await expect(items.nth(0)).toHaveText("Apple");
      await expect(items.nth(1)).toHaveText("Banana");
      await expect(items.nth(2)).toHaveText("Cherry");
      await expect(items.nth(3)).toHaveText("Date");

      // Verify same DOM elements (markers should be in original order)
      const markers = await page.evaluate(() => {
        const elements = document.querySelectorAll("[data-list] li");
        return Array.from(elements).map((el) => (el as any).__testMarker);
      });

      expect(markers).toEqual(["marker-0", "marker-1", "marker-2", "marker-3"]);
    });

    test("data-key attributes are preserved during reorder", async ({
      page,
    }) => {
      await page.goto("/browser/sortable-list");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // Initial keys
      const initialKeys = await page.evaluate(() => {
        const elements = document.querySelectorAll("[data-list] li");
        return Array.from(elements).map((el) => el.getAttribute("data-key"));
      });
      expect(initialKeys).toEqual(["0", "1", "2", "3"]);

      // Reverse
      await page.locator("[data-reverse]").click();

      // Keys should follow their elements (item with key 0 is now last)
      const reversedKeys = await page.evaluate(() => {
        const elements = document.querySelectorAll("[data-list] li");
        return Array.from(elements).map((el) => el.getAttribute("data-key"));
      });
      expect(reversedKeys).toEqual(["3", "2", "1", "0"]);
    });
  });

  test.describe("Input Binding", () => {
    test("displays initial value from state", async ({ page }) => {
      await page.goto("/browser/input-binding");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const preview = page.locator("[data-preview]");
      await expect(preview).toHaveText("Preview: Initial value");
    });

    test("clear button clears the value", async ({ page }) => {
      await page.goto("/browser/input-binding");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const preview = page.locator("[data-preview]");
      const clearBtn = page.locator("[data-clear]");

      await clearBtn.click();
      await expect(preview).toHaveText("Preview: ");
    });

    test("set hello button sets predefined value", async ({ page }) => {
      await page.goto("/browser/input-binding");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const preview = page.locator("[data-preview]");
      const setHelloBtn = page.locator("[data-set-hello]");

      await setHelloBtn.click();
      await expect(preview).toHaveText("Preview: Hello World");
    });

    test("submit button captures current value", async ({ page }) => {
      await page.goto("/browser/input-binding");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const submitted = page.locator("[data-submitted]");
      const setHelloBtn = page.locator("[data-set-hello]");
      const submitBtn = page.locator("[data-submit]");

      // Set value and submit
      await setHelloBtn.click();
      await submitBtn.click();
      await expect(submitted).toHaveText("Submitted: Hello World");

      // Clear and submit again
      await page.locator("[data-clear]").click();
      await submitBtn.click();
      await expect(submitted).toHaveText("Submitted: ");
    });
  });

  test.describe("Element Ref (Solid.js style)", () => {
    test("ref callback captures element reference after hydration", async ({
      page,
    }) => {
      await page.goto("/browser/element-ref");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      // After hydration, ref should be captured
      const refStatus = page.locator("[data-ref-status]");
      await expect(refStatus).toHaveText("Ref captured: yes");
    });

    test("focus button uses ref to focus input", async ({ page }) => {
      await page.goto("/browser/element-ref");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const input = page.locator("[data-ref-input]");
      const focusBtn = page.locator("[data-focus-btn]");
      const focusCount = page.locator("[data-focus-count]");

      // Initial focus count
      await expect(focusCount).toHaveText("Focus count: 0");

      // Click focus button - should focus input via ref
      await focusBtn.click();
      await expect(focusCount).toHaveText("Focus count: 1");

      // Verify the input is actually focused
      await expect(input).toBeFocused();
    });

    test("clear & focus button clears and focuses input via ref", async ({
      page,
    }) => {
      await page.goto("/browser/element-ref");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const input = page.locator("[data-ref-input]");
      const clearFocusBtn = page.locator("[data-clear-focus-btn]");
      const focusCount = page.locator("[data-focus-count]");

      // Type something in the input first
      await input.fill("Some text");
      await expect(input).toHaveValue("Some text");

      // Click clear & focus button
      await clearFocusBtn.click();

      // Input should be cleared and focused
      await expect(input).toHaveValue("");
      await expect(input).toBeFocused();
      await expect(focusCount).toHaveText("Focus count: 1");
    });

    test("multiple focus calls increment counter", async ({ page }) => {
      await page.goto("/browser/element-ref");
      await expect(page.locator("#app")).toHaveAttribute(
        "data-hydrated",
        "true"
      );

      const focusBtn = page.locator("[data-focus-btn]");
      const clearFocusBtn = page.locator("[data-clear-focus-btn]");
      const focusCount = page.locator("[data-focus-count]");

      // Click focus multiple times
      await focusBtn.click();
      await expect(focusCount).toHaveText("Focus count: 1");

      await focusBtn.click();
      await expect(focusCount).toHaveText("Focus count: 2");

      await clearFocusBtn.click();
      await expect(focusCount).toHaveText("Focus count: 3");
    });
  });
});
