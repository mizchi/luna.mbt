import { test, expect } from "@playwright/test";

test.describe("TodoMVC", () => {
  test.beforeEach(async ({ page }) => {
    // Clear localStorage before each test
    await page.goto("/todomvc");
    await page.evaluate(() => localStorage.clear());
    await page.reload();
    await page.waitForSelector(".todoapp");
  });

  // Helper to add a todo
  async function addTodo(page: import("@playwright/test").Page, text: string) {
    const input = page.locator(".new-todo");
    await input.fill(text);
    await input.press("Enter");
  }

  test("renders the app with empty state", async ({ page }) => {
    // Check title is rendered
    const title = page.locator(".todoapp h1");
    await expect(title).toHaveText("todos");

    // Check input field is visible
    const input = page.locator(".new-todo");
    await expect(input).toBeVisible();
    await expect(input).toHaveAttribute("placeholder", "What needs to be done?");

    // Main section and footer should be hidden when no todos
    await expect(page.locator(".main")).not.toBeVisible();
    await expect(page.locator(".footer")).not.toBeVisible();
  });

  test("can add a new todo", async ({ page }) => {
    const input = page.locator(".new-todo");

    // Type and submit a todo
    await input.fill("Buy milk");
    await input.press("Enter");

    // Check todo appears in the list
    const todoItems = page.locator(".todo-list li");
    await expect(todoItems).toHaveCount(1);
    await expect(todoItems.first().locator("label")).toHaveText("Buy milk");

    // Check counter shows 1 item left
    await expect(page.locator(".todo-count")).toContainText("1 item left");

    // Input should be cleared
    await expect(input).toHaveValue("");
  });

  test("can add multiple todos", async ({ page }) => {
    const input = page.locator(".new-todo");

    // Add first todo
    await input.fill("Buy milk");
    await input.press("Enter");

    // Add second todo
    await input.fill("Walk the dog");
    await input.press("Enter");

    // Add third todo
    await input.fill("Do laundry");
    await input.press("Enter");

    // Check all todos appear
    const todoItems = page.locator(".todo-list li");
    await expect(todoItems).toHaveCount(3);

    // Check counter
    await expect(page.locator(".todo-count")).toContainText("3 items left");
  });

  test("can toggle a todo complete", async ({ page }) => {
    const input = page.locator(".new-todo");

    // Add a todo
    await input.fill("Buy milk");
    await input.press("Enter");

    // Find the toggle checkbox
    const todoItem = page.locator(".todo-list li").first();
    const toggle = todoItem.locator(".toggle");

    // Toggle should not be checked initially
    await expect(todoItem).not.toHaveClass(/completed/);

    // Click to complete
    await toggle.click();

    // Todo should now be completed
    await expect(todoItem).toHaveClass(/completed/);
    await expect(page.locator(".todo-count")).toContainText("0 items left");
  });

  test("can delete a todo", async ({ page }) => {
    const input = page.locator(".new-todo");

    // Add a todo
    await input.fill("Buy milk");
    await input.press("Enter");

    // Verify it exists
    await expect(page.locator(".todo-list li")).toHaveCount(1);

    // Hover to show destroy button and click
    const todoItem = page.locator(".todo-list li").first();
    await todoItem.hover();
    await todoItem.locator(".destroy").click();

    // Todo should be removed
    await expect(page.locator(".todo-list li")).toHaveCount(0);

    // Footer should be hidden when no todos
    await expect(page.locator(".footer")).not.toBeVisible();
  });

  test("footer shows correct count after operations", async ({ page }) => {
    const input = page.locator(".new-todo");

    // Add 3 todos
    await input.fill("Todo 1");
    await input.press("Enter");
    await input.fill("Todo 2");
    await input.press("Enter");
    await input.fill("Todo 3");
    await input.press("Enter");

    await expect(page.locator(".todo-count")).toContainText("3 items left");

    // Complete one
    await page.locator(".todo-list li").first().locator(".toggle").click();
    await expect(page.locator(".todo-count")).toContainText("2 items left");

    // Delete one
    const secondTodo = page.locator(".todo-list li").nth(1);
    await secondTodo.hover();
    await secondTodo.locator(".destroy").click();

    await expect(page.locator(".todo-count")).toContainText("1 item left");
  });

  test("can edit a todo by double-clicking", async ({ page }) => {
    await addTodo(page, "Original text");

    // Double-click to enter edit mode
    const todoItem = page.locator(".todo-list li").first();
    const label = todoItem.locator("label");
    await label.dblclick();

    // Check editing mode is active
    await expect(todoItem).toHaveClass(/editing/);

    // Find edit input and change text
    const editInput = todoItem.locator(".edit");
    await expect(editInput).toBeVisible();
    await editInput.fill("Updated text");
    await editInput.press("Enter");

    // Check todo is updated
    await expect(todoItem).not.toHaveClass(/editing/);
    await expect(todoItem.locator("label")).toHaveText("Updated text");
  });

  test("can cancel editing with Escape", async ({ page }) => {
    await addTodo(page, "Original text");

    // Double-click to enter edit mode
    const todoItem = page.locator(".todo-list li").first();
    await todoItem.locator("label").dblclick();

    // Change text but cancel
    const editInput = todoItem.locator(".edit");
    await editInput.fill("Changed text");
    await editInput.press("Escape");

    // Check todo is NOT updated
    await expect(todoItem).not.toHaveClass(/editing/);
    await expect(todoItem.locator("label")).toHaveText("Original text");
  });

  test("filter: All shows all todos", async ({ page }) => {
    await addTodo(page, "Active todo");
    await addTodo(page, "Completed todo");

    // Complete second todo
    await page.locator(".todo-list li").nth(1).locator(".toggle").click();

    // Click All filter
    await page.click("a[href='#/']");

    // Should show both todos
    await expect(page.locator(".todo-list li")).toHaveCount(2);
  });

  test("filter: Active shows only active todos", async ({ page }) => {
    await addTodo(page, "Active todo");
    await addTodo(page, "Completed todo");

    // Complete second todo
    await page.locator(".todo-list li").nth(1).locator(".toggle").click();

    // Click Active filter
    await page.click("a[href='#/active']");

    // Should show only active todo
    await expect(page.locator(".todo-list li")).toHaveCount(1);
    await expect(page.locator(".todo-list li label")).toHaveText("Active todo");
  });

  test("filter: Completed shows only completed todos", async ({ page }) => {
    await addTodo(page, "Active todo");
    await addTodo(page, "Completed todo");

    // Complete second todo
    await page.locator(".todo-list li").nth(1).locator(".toggle").click();

    // Click Completed filter
    await page.click("a[href='#/completed']");

    // Should show only completed todo
    await expect(page.locator(".todo-list li")).toHaveCount(1);
    await expect(page.locator(".todo-list li label")).toHaveText("Completed todo");
  });

  test("Clear completed removes only completed todos", async ({ page }) => {
    await addTodo(page, "Active todo");
    await addTodo(page, "Completed todo 1");
    await addTodo(page, "Completed todo 2");

    // Complete last two todos
    await page.locator(".todo-list li").nth(1).locator(".toggle").click();
    await page.locator(".todo-list li").nth(2).locator(".toggle").click();

    // Click Clear completed
    await page.click(".clear-completed");

    // Should only have active todo
    await expect(page.locator(".todo-list li")).toHaveCount(1);
    await expect(page.locator(".todo-list li label")).toHaveText("Active todo");
  });

  test("rapid add and delete operations", async ({ page }) => {
    // Add todos rapidly
    for (let i = 1; i <= 5; i++) {
      await addTodo(page, `Todo ${i}`);
    }

    await expect(page.locator(".todo-list li")).toHaveCount(5);

    // Delete all todos one by one
    for (let i = 0; i < 5; i++) {
      const todoItem = page.locator(".todo-list li").first();
      await todoItem.hover();
      await todoItem.locator(".destroy").click();
    }

    await expect(page.locator(".todo-list li")).toHaveCount(0);
  });

  test("toggle all completes all todos", async ({ page }) => {
    await addTodo(page, "Todo 1");
    await addTodo(page, "Todo 2");
    await addTodo(page, "Todo 3");

    // Click toggle-all
    await page.click("#toggle-all");

    // All todos should be completed
    const todoItems = page.locator(".todo-list li");
    await expect(todoItems.nth(0)).toHaveClass(/completed/);
    await expect(todoItems.nth(1)).toHaveClass(/completed/);
    await expect(todoItems.nth(2)).toHaveClass(/completed/);

    await expect(page.locator(".todo-count")).toContainText("0 items left");
  });

  test("toggle and delete in sequence maintains consistency", async ({ page }) => {
    await addTodo(page, "Todo 1");
    await addTodo(page, "Todo 2");
    await addTodo(page, "Todo 3");

    // Toggle first todo complete
    await page.locator(".todo-list li").first().locator(".toggle").click();
    await expect(page.locator(".todo-count")).toContainText("2 items left");

    // Delete second todo
    const secondTodo = page.locator(".todo-list li").nth(1);
    await secondTodo.hover();
    await secondTodo.locator(".destroy").click();

    await expect(page.locator(".todo-list li")).toHaveCount(2);
    await expect(page.locator(".todo-count")).toContainText("1 item left");

    // Toggle first todo back to active
    await page.locator(".todo-list li").first().locator(".toggle").click();
    await expect(page.locator(".todo-count")).toContainText("2 items left");
  });

  test("persists todos in localStorage", async ({ page }) => {
    await addTodo(page, "Persisted todo");

    // Reload the page
    await page.reload();
    await page.waitForSelector(".todoapp");

    // Todo should still be there
    await expect(page.locator(".todo-list li")).toHaveCount(1);
    await expect(page.locator(".todo-list li label")).toHaveText("Persisted todo");
  });

  test("no console errors during operations", async ({ page }) => {
    const errors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") {
        errors.push(msg.text());
      }
    });

    // Perform various operations
    await addTodo(page, "Test todo");
    await page.locator(".todo-list li").first().locator(".toggle").click();
    await page.locator(".todo-list li label").dblclick();
    await page.locator(".todo-list li .edit").fill("Updated");
    await page.locator(".todo-list li .edit").press("Enter");
    await page.locator(".todo-list li").hover();
    await page.locator(".todo-list li .destroy").click();

    // Wait for any async errors
    await page.waitForTimeout(500);

    expect(errors).toEqual([]);
  });

  // Bug reproduction: after deleting an item, subsequent items cannot be deleted
  test("BUG: add, delete, add, delete sequence works correctly", async ({ page }) => {
    const logs: string[] = [];
    page.on("console", (msg) => {
      logs.push(msg.text());
    });

    // Add first item
    await addTodo(page, "First item");
    await page.waitForTimeout(100);
    console.log("After add first:", logs.slice());
    await expect(page.locator(".todo-list li")).toHaveCount(1);

    // Delete first item
    const firstItem = page.locator(".todo-list li").first();
    await firstItem.hover();
    await firstItem.locator(".destroy").click();
    await page.waitForTimeout(100);
    console.log("After delete first:", logs.slice());
    await expect(page.locator(".todo-list li")).toHaveCount(0);

    // Add second item - check input state first
    const input2 = page.locator(".new-todo");
    console.log("Input visible:", await input2.isVisible());
    console.log("Input enabled:", await input2.isEnabled());

    await input2.fill("Second item");
    console.log("Input value after fill:", await input2.inputValue());
    await page.waitForTimeout(50);

    // Try pressing Enter
    await input2.press("Enter");
    await page.waitForTimeout(200);
    console.log("After add second:", logs.slice());

    // Debug: check the current DOM state
    const liCount = await page.locator(".todo-list li").count();
    console.log("LI count after adding second item:", liCount);

    // Check the todos signal state via localStorage
    const stored = await page.evaluate(() => localStorage.getItem("todos-luna"));
    console.log("localStorage todos:", stored);

    await expect(page.locator(".todo-list li")).toHaveCount(1);

    // Delete second item - this should work
    const secondItem = page.locator(".todo-list li").first();
    await secondItem.hover();
    await secondItem.locator(".destroy").click();
    await expect(page.locator(".todo-list li")).toHaveCount(0);

    // Add third item
    await addTodo(page, "Third item");
    await expect(page.locator(".todo-list li")).toHaveCount(1);

    // Delete third item - this should also work
    const thirdItem = page.locator(".todo-list li").first();
    await thirdItem.hover();
    await thirdItem.locator(".destroy").click();
    await expect(page.locator(".todo-list li")).toHaveCount(0);
  });

  test("BUG: delete all then add new items works", async ({ page }) => {
    // Add multiple items
    await addTodo(page, "Item 1");
    await addTodo(page, "Item 2");
    await addTodo(page, "Item 3");
    await expect(page.locator(".todo-list li")).toHaveCount(3);

    // Delete all items
    for (let i = 0; i < 3; i++) {
      const item = page.locator(".todo-list li").first();
      await item.hover();
      await item.locator(".destroy").click();
    }
    await expect(page.locator(".todo-list li")).toHaveCount(0);

    // Add new items after deletion
    await addTodo(page, "New Item 1");
    await addTodo(page, "New Item 2");
    await expect(page.locator(".todo-list li")).toHaveCount(2);

    // Should be able to delete these new items
    const newItem = page.locator(".todo-list li").first();
    await newItem.hover();
    await newItem.locator(".destroy").click();
    await expect(page.locator(".todo-list li")).toHaveCount(1);
  });

  test("BUG: internal state matches DOM after delete", async ({ page }) => {
    // Add items
    await addTodo(page, "Item A");
    await addTodo(page, "Item B");

    // Verify initial state
    await expect(page.locator(".todo-list li")).toHaveCount(2);
    await expect(page.locator(".todo-count")).toContainText("2 items left");

    // Delete first item
    const firstItem = page.locator(".todo-list li").first();
    await firstItem.hover();
    await firstItem.locator(".destroy").click();

    // Verify state is consistent
    await expect(page.locator(".todo-list li")).toHaveCount(1);
    await expect(page.locator(".todo-count")).toContainText("1 item left");
    await expect(page.locator(".todo-list li label")).toHaveText("Item B");

    // Add another item
    await addTodo(page, "Item C");
    await expect(page.locator(".todo-list li")).toHaveCount(2);
    await expect(page.locator(".todo-count")).toContainText("2 items left");

    // Check the labels are correct
    const labels = page.locator(".todo-list li label");
    await expect(labels.nth(0)).toHaveText("Item B");
    await expect(labels.nth(1)).toHaveText("Item C");
  });
});
