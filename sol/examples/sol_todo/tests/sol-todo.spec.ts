import { test, expect } from '@playwright/test';

test.describe('Sol Todo App - SSR', () => {
  test('home page renders with SSR content', async ({ page }) => {
    await page.goto('/');

    // Check page title
    await expect(page).toHaveTitle('Todo List');

    // Check SSR-rendered todo items exist
    await expect(page.locator('text=Learn MoonBit')).toBeVisible();
    await expect(page.locator('text=Build a Sol app')).toBeVisible();
    await expect(page.locator('text=Write tests')).toBeVisible();
  });

  test('about page renders correctly', async ({ page }) => {
    await page.goto('/about');

    await expect(page).toHaveTitle('About');
    await expect(page.locator('h1:has-text("About Sol Todo")')).toBeVisible();
  });

  test('add page renders with form', async ({ page }) => {
    await page.goto('/add');

    await expect(page).toHaveTitle('Add Todo');
    await expect(page.locator('input[name="text"]')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();
  });
});

test.describe('Sol Todo App - CSR Navigation', () => {
  test('navigation links work with CSR (data-sol-link)', async ({ page }) => {
    await page.goto('/');

    // Click on About link (CSR navigation)
    await page.click('nav a:has-text("About")');

    // Wait for URL to change
    await expect(page).toHaveURL('/about');

    // Wait for content to be updated via CSR
    await expect(page.locator('h1:has-text("About Sol Todo")')).toBeVisible({ timeout: 5000 });

    // Navigate to Add page
    await page.click('nav a:has-text("Add Todo")');
    await expect(page).toHaveURL('/add');
    await expect(page.locator('input[name="text"]')).toBeVisible();

    // Navigate back to Home
    await page.click('nav a:has-text("Todo List")');
    await expect(page).toHaveURL('/');
    await expect(page.locator('h1:has-text("Todo List")')).toBeVisible();
  });

  test('browser back/forward works with CSR navigation', async ({ page }) => {
    await page.goto('/');

    // Navigate to about
    await page.click('nav a:has-text("About")');
    await expect(page).toHaveURL('/about');

    // Go back
    await page.goBack();
    await expect(page).toHaveURL('/');

    // Go forward
    await page.goForward();
    await expect(page).toHaveURL('/about');
  });
});

test.describe('Sol Todo App - Island Hydration', () => {
  test('stats island shows correct counts', async ({ page }) => {
    await page.goto('/');

    // Wait for page to fully load
    await page.waitForLoadState('networkidle');

    // Check stats display - look for luna:id attribute (island marker)
    const statsIsland = page.locator('[luna\\:id]');
    await expect(statsIsland).toBeVisible({ timeout: 5000 });

    // The island should show total and completed counts
    await expect(page.locator('.stat-value').first()).toBeVisible();
  });
});

test.describe('Sol Todo App - Server Actions', () => {
  test('toggle todo works via form submission', async ({ page }) => {
    await page.goto('/');

    // Find the first uncompleted todo's toggle button
    const toggleButton = page.locator('.todo-item:not(.completed) .todo-checkbox-btn').first();

    // Click toggle button (Server Action)
    await toggleButton.click();

    // Page should reload/update after form submission
    await page.waitForLoadState('networkidle');

    // Verify we're still on the home page
    await expect(page).toHaveURL('/');
  });

  test('add todo works via form submission', async ({ page }) => {
    await page.goto('/add');

    // Fill in new todo
    const newTodoText = `E2E Test Todo ${Date.now()}`;
    await page.fill('input[name="text"]', newTodoText);

    // Submit form - wait for navigation
    await Promise.all([
      page.waitForNavigation(),
      page.click('button[type="submit"]')
    ]);

    // Should redirect to home page with new todo
    await expect(page).toHaveURL('/');
    await expect(page.locator(`text=${newTodoText}`)).toBeVisible();
  });

  test('quick add todo works from home page', async ({ page }) => {
    await page.goto('/');

    // Use the quick add form on home page
    const quickAddText = `Quick Add ${Date.now()}`;
    await page.fill('.add-form input[name="text"]', quickAddText);

    // Submit form - wait for navigation
    await Promise.all([
      page.waitForNavigation(),
      page.click('.add-form button[type="submit"]')
    ]);

    // Should stay on home page with new todo
    await expect(page).toHaveURL('/');
    await expect(page.locator(`text=${quickAddText}`)).toBeVisible();
  });

  test('delete todo works via form submission', async ({ page }) => {
    // First add a todo to delete
    await page.goto('/');

    const todoToDelete = `Delete Me ${Date.now()}`;
    await page.fill('.add-form input[name="text"]', todoToDelete);

    await Promise.all([
      page.waitForNavigation(),
      page.click('.add-form button[type="submit"]')
    ]);

    await expect(page.locator(`text=${todoToDelete}`)).toBeVisible();

    // Find and delete the todo
    const todoItem = page.locator('.todo-item').filter({ hasText: todoToDelete });
    const deleteButton = todoItem.locator('.todo-delete');

    await Promise.all([
      page.waitForNavigation(),
      deleteButton.click()
    ]);

    // Todo should be removed
    await expect(page.locator(`text=${todoToDelete}`)).not.toBeVisible();
  });
});

test.describe('Sol Todo App - API Endpoints', () => {
  test('GET /api/todos returns JSON with todos', async ({ request }) => {
    const response = await request.get('/api/todos');

    expect(response.status()).toBe(200);

    const data = await response.json();
    expect(data).toHaveProperty('todos');
    expect(Array.isArray(data.todos)).toBe(true);

    // Check structure of todo items
    if (data.todos.length > 0) {
      const todo = data.todos[0];
      expect(todo).toHaveProperty('id');
      expect(todo).toHaveProperty('text');
      expect(todo).toHaveProperty('completed');
      expect(typeof todo.completed).toBe('boolean');
    }
  });

  test('POST /api/todos creates a new todo', async ({ request }) => {
    const newTodo = { text: `API Test Todo ${Date.now()}` };

    const response = await request.post('/api/todos', {
      data: newTodo,
      headers: { 'Content-Type': 'application/json' }
    });

    expect(response.status()).toBe(200);

    const data = await response.json();
    expect(data).toHaveProperty('id');
    expect(data.text).toBe(newTodo.text);
    expect(data.completed).toBe(false);
  });

  test('DELETE /api/todos/:id deletes a todo', async ({ request }) => {
    // First create a todo
    const createResponse = await request.post('/api/todos', {
      data: { text: `To Delete ${Date.now()}` },
      headers: { 'Content-Type': 'application/json' }
    });
    const created = await createResponse.json();

    // Delete it
    const deleteResponse = await request.delete(`/api/todos/${created.id}`);

    expect(deleteResponse.status()).toBe(200);

    const data = await deleteResponse.json();
    expect(data.deleted).toBe(true);
  });
});

test.describe('Sol Todo App - Progressive Enhancement', () => {
  test('forms work without JavaScript', async ({ browser }) => {
    // Create context with JavaScript disabled
    const context = await browser.newContext({ javaScriptEnabled: false });
    const page = await context.newPage();

    await page.goto('/');

    // Page should still render via SSR
    await expect(page.locator('text=Learn MoonBit')).toBeVisible();

    // Navigate to add page (will be full page navigation)
    await page.click('nav a:has-text("Add Todo")');
    await expect(page).toHaveURL('/add');

    // Form should be visible
    await expect(page.locator('input[name="text"]')).toBeVisible();

    await context.close();
  });
});
