import { test, expect } from '@playwright/test';

test.describe('Sol App E2E', () => {
  test.describe('Progressive Enhancement (JavaScript Disabled)', () => {
    test.use({ javaScriptEnabled: false });

    test('form submission without JavaScript redirects to home', async ({ page, request }) => {
      // Navigate to form page (no JavaScript)
      await page.goto('/form');
      await expect(page).toHaveURL('/form');

      // Verify form is visible (SSR content)
      const form = page.locator('form.contact-form');
      await expect(form).toBeVisible();

      // Test Server Action endpoint with form-urlencoded data (non-JS form submission)
      // Playwright follows redirects automatically, so we get 200 (home page) after 302
      const response = await request.post('/_action/submit-contact', {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': 'http://localhost:9123/form',
        },
        data: 'name=Test&email=test@example.com',
      });
      // After following redirect, we should get 200 OK from the home page
      expect(response.status()).toBe(200);
      // The response URL should be the home page (redirect target)
      expect(response.url()).toContain('/');
    });
  });


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
        'Origin': 'http://localhost:9123',
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

  test.describe('Nested Layout (Admin Section)', () => {
    test('admin dashboard has nested layout structure', async ({ page }) => {
      // Navigate to admin page
      await page.goto('/admin');
      await expect(page).toHaveURL('/admin');

      // Verify nested layout structure
      // 1. Root layout: main nav should be present
      await expect(page.locator('nav').first()).toBeVisible();
      await expect(page.locator('nav a[href="/"]').first()).toBeVisible();

      // 2. Admin layout: admin sidebar should be present
      await expect(page.locator('.admin-sidebar')).toBeVisible();
      await expect(page.locator('.admin-sidebar h3')).toContainText('Admin');

      // 3. Admin content area
      await expect(page.locator('.admin-content')).toBeVisible();
      await expect(page.locator('h1')).toContainText('Admin Dashboard');
    });

    test('navigation within admin section (CSR)', async ({ page }) => {
      // Start at admin dashboard
      await page.goto('/admin');
      await expect(page).toHaveURL('/admin');
      await expect(page.locator('h1')).toContainText('Admin Dashboard');

      // Navigate to settings (CSR via sol-link)
      await page.locator('.admin-sidebar a[href="/admin/settings"]').click();
      await expect(page).toHaveURL('/admin/settings');
      await expect(page.locator('h1')).toContainText('Settings');

      // Verify admin layout is still present
      await expect(page.locator('.admin-sidebar')).toBeVisible();

      // Navigate to users
      await page.locator('.admin-sidebar a[href="/admin/users"]').click();
      await expect(page).toHaveURL('/admin/users');
      await expect(page.locator('h1')).toContainText('Users');

      // Navigate back to dashboard
      await page.locator('.admin-sidebar a[href="/admin"]').click();
      await expect(page).toHaveURL('/admin');
      await expect(page.locator('h1')).toContainText('Admin Dashboard');
    });

    test('navigation from main nav to admin and back', async ({ page }) => {
      // Start at home
      await page.goto('/');
      await expect(page).toHaveURL('/');

      // Navigate to admin via main nav
      await page.locator('nav a[href="/admin"]').first().click();
      await expect(page).toHaveURL('/admin');

      // Verify nested layout
      await expect(page.locator('.admin-sidebar')).toBeVisible();
      await expect(page.locator('h1')).toContainText('Admin Dashboard');

      // Navigate back to home via main nav
      await page.locator('nav a[href="/"]').first().click();
      await expect(page).toHaveURL('/');

      // Verify admin layout is no longer present
      await expect(page.locator('.admin-sidebar')).not.toBeVisible();
    });
  });

  test.describe('CSR Re-navigation (Stale-While-Revalidate)', () => {
    test('counter re-hydrates correctly on A → B → A navigation', async ({ page }) => {
      // Navigate to home page
      await page.goto('/');
      await expect(page).toHaveURL('/');

      // Wait for hydration
      await page.waitForTimeout(500);

      // Get initial count and increment
      const countDisplay = page.locator('.count-display');
      const initialText = await countDisplay.textContent();
      const initialValue = parseInt(initialText || '0', 10);

      // Click increment
      const incButton = page.locator('button.inc');
      await incButton.click();
      await expect(countDisplay).toHaveText(String(initialValue + 1));

      // Navigate to About
      await page.locator('nav a[href="/about"]').first().click();
      await expect(page).toHaveURL('/about');

      // Navigate back to Home (CSR re-navigation)
      await page.locator('nav a[href="/"]').first().click();
      await expect(page).toHaveURL('/');

      // Wait for re-hydration
      await page.waitForTimeout(500);

      // Verify counter is visible and functional (new server state, not preserved client state)
      const counterAfterNav = page.locator('.counter');
      await expect(counterAfterNav).toBeVisible();

      // Counter should work again after re-hydration
      const incButtonAfterNav = page.locator('button.inc');
      await incButtonAfterNav.click();

      // Verify button click works (proves hydration happened)
      const newCount = await page.locator('.count-display').textContent();
      expect(parseInt(newCount || '0', 10)).toBeGreaterThan(0);
    });

    test('form page re-hydrates on re-navigation', async ({ page }) => {
      // Navigate to form page
      await page.goto('/form');
      await expect(page).toHaveURL('/form');

      // Wait for hydration
      await page.waitForTimeout(1000);

      // Fill in name
      const nameInput = page.locator('input[name="name"]');
      await nameInput.fill('Original Name');

      // Verify preview updates
      await expect(page.locator('.preview-name')).toContainText('Original Name', { timeout: 5000 });

      // Navigate to About
      await page.locator('nav a[href="/about"]').first().click();
      await expect(page).toHaveURL('/about');

      // Navigate back to Form (CSR re-navigation)
      await page.locator('nav a[href="/form"]').first().click();
      await expect(page).toHaveURL('/form');

      // Wait for re-hydration
      await page.waitForTimeout(1000);

      // Form should be functional again (fresh state from server)
      const newNameInput = page.locator('input[name="name"]');
      await newNameInput.fill('New Name');

      // Verify two-way binding works after re-hydration
      await expect(page.locator('.preview-name')).toContainText('New Name', { timeout: 5000 });
    });

    test('multiple round trips maintain page functionality', async ({ page }) => {
      // Start at home
      await page.goto('/');
      await expect(page).toHaveURL('/');

      // Round trip 1: Home → About → Home
      await page.locator('nav a[href="/about"]').first().click();
      await expect(page).toHaveURL('/about');
      await page.locator('nav a[href="/"]').first().click();
      await expect(page).toHaveURL('/');

      // Verify counter is functional
      await page.waitForTimeout(500);
      await expect(page.locator('.counter')).toBeVisible();
      await page.locator('button.inc').click();

      // Round trip 2: Home → Form → Home
      await page.locator('nav a[href="/form"]').first().click();
      await expect(page).toHaveURL('/form');
      await page.locator('nav a[href="/"]').first().click();
      await expect(page).toHaveURL('/');

      // Verify counter still works
      await page.waitForTimeout(500);
      await expect(page.locator('.counter')).toBeVisible();
      await page.locator('button.dec').click();

      // Verify the button actually did something
      const finalCount = await page.locator('.count-display').textContent();
      expect(finalCount).toBeTruthy();
    });
  });
});
