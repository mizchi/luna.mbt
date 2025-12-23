import { test, expect } from '@playwright/test';

test.describe('Sol App E2E', () => {
  test('full user flow: counter interaction and navigation', async ({ page }) => {
    // 1. Navigate to home page
    await page.goto('/');
    await expect(page).toHaveURL('/');

    // 2. Verify home page content
    const counter = page.locator('.counter');
    await expect(counter).toBeVisible();

    const countDisplay = page.locator('.count-display');
    // Get initial value (can be random)
    const initialText = await countDisplay.textContent();
    const initialValue = parseInt(initialText || '0', 10);

    // 3. Wait for hydration
    await page.waitForTimeout(500);

    // 4. Click counter and verify increment
    const incButton = page.locator('button.inc');
    await incButton.click();
    await expect(countDisplay).toHaveText(String(initialValue + 1));

    // Click again to verify multiple increments work
    await incButton.click();
    await expect(countDisplay).toHaveText(String(initialValue + 2));

    // 5. Navigate to About page via navigation link (use first() for multiple nav elements)
    const aboutLink = page.locator('nav a[href="/about"]').first();
    await aboutLink.click();

    // 6. Verify URL changed to /about
    await expect(page).toHaveURL('/about');

    // 7. Verify About page content is visible
    await expect(page.locator('body')).toContainText('About');
  });

  test('navigation between all pages', async ({ page }) => {
    // Start at home
    await page.goto('/');
    await expect(page).toHaveURL('/');

    // Navigate to About (use first() to handle multiple nav elements)
    await page.locator('nav a[href="/about"]').first().click();
    await expect(page).toHaveURL('/about');

    // Navigate to Form
    await page.locator('nav a[href="/form"]').first().click();
    await expect(page).toHaveURL('/form');

    // Navigate to WC Counter
    await page.locator('nav a[href="/wc-counter"]').first().click();
    await expect(page).toHaveURL('/wc-counter');

    // Navigate back to Home
    await page.locator('nav a[href="/"]').first().click();
    await expect(page).toHaveURL('/');
  });

  test('API health endpoint', async ({ request }) => {
    const response = await request.get('/api/health');
    expect(response.ok()).toBeTruthy();
    const json = await response.json();
    expect(json.status).toBe('ok');
  });

  test('form page hydration and two-way binding', async ({ page }) => {
    // Navigate to form page
    await page.goto('/form');
    await expect(page).toHaveURL('/form');

    // Wait for hydration
    await page.waitForTimeout(1000);

    // Fill in the form
    const nameInput = page.locator('input[name="name"]');
    const emailInput = page.locator('input[name="email"]');
    await expect(nameInput).toBeVisible();
    await expect(emailInput).toBeVisible();

    await nameInput.fill('Test User');
    await emailInput.fill('test@example.com');

    // Verify preview updates (two-way binding) - this confirms hydration is working
    await expect(page.locator('.preview-name')).toContainText('Test User', { timeout: 5000 });
    await expect(page.locator('.preview-email')).toContainText('test@example.com', { timeout: 5000 });
  });

  test('Server Action API endpoint', async ({ request }) => {
    // Test Server Action endpoint directly
    const response = await request.post('/_action/submit-contact', {
      headers: {
        'Content-Type': 'application/json',
        'Origin': 'http://localhost:3457',
      },
      data: { name: 'Test', email: 'test@example.com' }
    });
    expect(response.ok()).toBeTruthy();
    const json = await response.json();
    expect(json.success).toBe(true);
    expect(json.message).toBe('Form submitted successfully!');
  });

  test('form submission via browser', async ({ page }) => {
    // Navigate to form page
    await page.goto('/form');
    await expect(page).toHaveURL('/form');

    // Wait for hydration
    await page.waitForTimeout(1000);

    // Fill in the form
    await page.fill('input[name="name"]', 'Test User');
    await page.fill('input[name="email"]', 'test@example.com');

    // Submit the form by clicking the submit button
    await page.click('button[type="submit"]');

    // Wait for the Server Action response and check result
    const result = page.locator('[data-testid="form-result"]');
    await expect(result).toContainText('Form submitted successfully', { timeout: 10000 });

    // Verify we're still on the form page (no redirect/404)
    await expect(page).toHaveURL('/form');
  });
});
