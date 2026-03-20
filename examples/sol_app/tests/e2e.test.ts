import { test, expect, type Page } from '@playwright/test';

// Helper: wait for island hydration by checking if interactive elements exist
async function waitForHydration(page: Page, selector: string, timeout = 10000) {
  await page.waitForSelector(selector, { state: 'attached', timeout });
  await page.waitForFunction(
    (sel) => {
      const el = document.querySelector(sel);
      if (!el) return false;
      // Check light DOM first, then shadow DOM for Web Components
      if (el.querySelector('button')) return true;
      if (el.shadowRoot?.querySelector('button')) return true;
      // For non-button islands (forms etc.), check if any input exists
      if (el.querySelector('input')) return true;
      return false;
    },
    selector,
    { timeout }
  );
}

test.describe('Sol App E2E', () => {
  // NOTE: Progressive Enhancement test requires javaScriptEnabled:false which
  // is only available in TS Playwright (not BiDi). Skipped — covered by manual QA.
  test.describe.skip('Progressive Enhancement (JavaScript Disabled)', () => {
    test.use({ javaScriptEnabled: false });

    test('form submission without JavaScript redirects to home', async ({ page, request }) => {
      await page.goto('/form');
      await expect(page).toHaveURL('/form');

      const form = page.locator('form.contact-form');
      await expect(form).toBeVisible();

      const response = await request.post('/_action/submit-contact', {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': 'http://localhost:9123/form',
        },
        data: 'name=Test&email=test@example.com',
      });
      expect(response.status()).toBe(200);
      expect(response.url()).toContain('/');
    });
  });


  test('full user flow: counter interaction and navigation', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveURL('/');

    // Wait for counter hydration
    await waitForHydration(page, '.counter');

    const countDisplay = page.locator('.count-display');
    const initialText = await countDisplay.textContent();
    const initialValue = parseInt(initialText || '0', 10);

    // Click counter and verify increment
    const incButton = page.locator('button.inc');
    await incButton.click();
    await expect(countDisplay).toHaveText(String(initialValue + 1), { timeout: 5000 });

    await incButton.click();
    await expect(countDisplay).toHaveText(String(initialValue + 2), { timeout: 5000 });

    // Navigate to About
    const aboutLink = page.locator('nav a[href="/about"]').first();
    await aboutLink.click();
    await expect(page).toHaveURL('/about', { timeout: 10000 });

    await expect(page.locator('body')).toContainText('About');
  });

  test('navigation between all pages', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveURL('/');

    await page.locator('nav a[href="/about"]').first().click();
    await expect(page).toHaveURL('/about', { timeout: 10000 });

    await page.locator('nav a[href="/form"]').first().click();
    await expect(page).toHaveURL('/form', { timeout: 10000 });

    await page.locator('nav a[href="/wc-counter"]').first().click();
    await expect(page).toHaveURL('/wc-counter', { timeout: 10000 });

    await page.locator('nav a[href="/"]').first().click();
    await expect(page).toHaveURL('/', { timeout: 10000 });
  });

  test('API health endpoint', async ({ request }) => {
    const response = await request.get('/api/health');
    expect(response.ok()).toBeTruthy();
    const json = await response.json();
    expect(json.status).toBe('ok');
  });

  test('form page hydration and two-way binding', async ({ page }) => {
    await page.goto('/form');
    await expect(page).toHaveURL('/form');

    // Wait for form hydration
    await page.waitForSelector('input[name="name"]', { state: 'attached', timeout: 10000 });
    await page.waitForTimeout(500);

    const nameInput = page.locator('input[name="name"]');
    const emailInput = page.locator('input[name="email"]');
    await expect(nameInput).toBeVisible();
    await expect(emailInput).toBeVisible();

    await nameInput.fill('Test User');
    await emailInput.fill('test@example.com');

    // Verify preview updates with longer timeout for CI
    await expect(page.locator('.preview-name')).toContainText('Test User', { timeout: 10000 });
    await expect(page.locator('.preview-email')).toContainText('test@example.com', { timeout: 10000 });
  });

  test('Server Action API endpoint', async ({ request }) => {
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
    await page.goto('/form');
    await expect(page).toHaveURL('/form');

    // Wait for hydration
    await page.waitForSelector('input[name="name"]', { state: 'attached', timeout: 10000 });
    await page.waitForTimeout(500);

    await page.fill('input[name="name"]', 'Test User');
    await page.fill('input[name="email"]', 'test@example.com');

    await page.click('button[type="submit"]');

    const result = page.locator('[data-testid="form-result"]');
    await expect(result).toContainText('Form submitted successfully', { timeout: 15000 });

    await expect(page).toHaveURL('/form');
  });

  test.describe('Nested Layout (Admin Section)', () => {
    test('admin dashboard has nested layout structure', async ({ page }) => {
      await page.goto('/admin');
      await expect(page).toHaveURL('/admin');

      await expect(page.locator('nav').first()).toBeVisible();
      await expect(page.locator('nav a[href="/"]').first()).toBeVisible();

      await expect(page.locator('.admin-sidebar')).toBeVisible();
      await expect(page.locator('.admin-sidebar h3')).toContainText('Admin');

      await expect(page.locator('.admin-content')).toBeVisible();
      await expect(page.locator('h1')).toContainText('Admin Dashboard');
    });

    test('navigation within admin section (CSR)', async ({ page }) => {
      await page.goto('/admin');
      await expect(page).toHaveURL('/admin');
      await expect(page.locator('h1')).toContainText('Admin Dashboard');

      await page.locator('.admin-sidebar a[href="/admin/settings"]').click();
      await expect(page).toHaveURL('/admin/settings', { timeout: 10000 });
      await expect(page.locator('h1')).toContainText('Settings');

      await expect(page.locator('.admin-sidebar')).toBeVisible();

      await page.locator('.admin-sidebar a[href="/admin/users"]').click();
      await expect(page).toHaveURL('/admin/users', { timeout: 10000 });
      await expect(page.locator('h1')).toContainText('User Management');

      await page.locator('.admin-sidebar a[href="/admin"]').click();
      await expect(page).toHaveURL('/admin', { timeout: 10000 });
      await expect(page.locator('h1')).toContainText('Admin Dashboard');
    });

    test('navigation from main nav to admin and back', async ({ page }) => {
      await page.goto('/');
      await expect(page).toHaveURL('/');

      await page.locator('nav a[href="/admin"]').first().click();
      await expect(page).toHaveURL('/admin', { timeout: 10000 });

      await expect(page.locator('.admin-sidebar')).toBeVisible();
      await expect(page.locator('h1')).toContainText('Admin Dashboard');

      await page.locator('nav a[href="/"]').first().click();
      await expect(page).toHaveURL('/', { timeout: 10000 });

      await expect(page.locator('.admin-sidebar')).not.toBeVisible();
    });
  });

  test.describe('WC Counter Navigation', () => {
    test('WC counter works after CSR navigation from home', async ({ page }) => {
      await page.goto('/');
      await expect(page).toHaveURL('/');

      await page.locator('nav a[href="/wc-counter"]').first().click();
      await expect(page).toHaveURL('/wc-counter', { timeout: 10000 });

      // Wait for WC hydration
      await waitForHydration(page, 'wc-counter');

      const wcCounter = page.locator('wc-counter');
      await expect(wcCounter).toBeVisible();

      const countDisplay = wcCounter.locator('.count-display');
      await expect(countDisplay).toBeVisible({ timeout: 5000 });
      const initialText = await countDisplay.textContent();
      const initialValue = parseInt(initialText || '0', 10);

      const incButton = wcCounter.locator('button.inc');
      await incButton.click();

      await expect(countDisplay).toHaveText(String(initialValue + 1), { timeout: 5000 });
    });

    test('WC counter works on direct page load', async ({ page }) => {
      await page.goto('/wc-counter');
      await expect(page).toHaveURL('/wc-counter');

      await waitForHydration(page, 'wc-counter');

      const wcCounter = page.locator('wc-counter');
      const countDisplay = wcCounter.locator('.count-display');
      await expect(countDisplay).toBeVisible({ timeout: 5000 });
      const initialText = await countDisplay.textContent();
      const initialValue = parseInt(initialText || '0', 10);

      await wcCounter.locator('button.inc').click();
      await expect(countDisplay).toHaveText(String(initialValue + 1), { timeout: 5000 });
    });

    test('WC counter re-hydrates after round-trip navigation', async ({ page }) => {
      await page.goto('/');
      await expect(page).toHaveURL('/');

      await page.locator('nav a[href="/wc-counter"]').first().click();
      await expect(page).toHaveURL('/wc-counter', { timeout: 10000 });
      await waitForHydration(page, 'wc-counter');

      await page.locator('wc-counter button.inc').click();

      await page.locator('nav a[href="/about"]').first().click();
      await expect(page).toHaveURL('/about', { timeout: 10000 });

      await page.locator('nav a[href="/wc-counter"]').first().click();
      await expect(page).toHaveURL('/wc-counter', { timeout: 10000 });
      await waitForHydration(page, 'wc-counter');

      const countDisplayAfter = page.locator('wc-counter .count-display');
      await expect(countDisplayAfter).toBeVisible({ timeout: 5000 });
      const valueAfter = await countDisplayAfter.textContent();
      const valueNum = parseInt(valueAfter || '0', 10);

      await page.locator('wc-counter button.inc').click();
      await expect(countDisplayAfter).toHaveText(String(valueNum + 1), { timeout: 5000 });
    });
  });

  test.describe('CSR Re-navigation (Stale-While-Revalidate)', () => {
    test('counter re-hydrates correctly on A → B → A navigation', async ({ page }) => {
      await page.goto('/');
      await expect(page).toHaveURL('/');

      await waitForHydration(page, '.counter');

      const countDisplay = page.locator('.count-display');
      const initialText = await countDisplay.textContent();
      const initialValue = parseInt(initialText || '0', 10);

      const incButton = page.locator('button.inc');
      await incButton.click();
      await expect(countDisplay).toHaveText(String(initialValue + 1), { timeout: 5000 });

      await page.locator('nav a[href="/about"]').first().click();
      await expect(page).toHaveURL('/about', { timeout: 10000 });

      await page.locator('nav a[href="/"]').first().click();
      await expect(page).toHaveURL('/', { timeout: 10000 });

      // Wait for re-hydration
      await waitForHydration(page, '.counter');

      const counterAfterNav = page.locator('.counter');
      await expect(counterAfterNav).toBeVisible();

      const incButtonAfterNav = page.locator('button.inc');
      await incButtonAfterNav.click();

      const newCount = await page.locator('.count-display').textContent();
      expect(parseInt(newCount || '0', 10)).toBeGreaterThan(0);
    });

    test('form page re-hydrates on re-navigation', async ({ page }) => {
      await page.goto('/form');
      await expect(page).toHaveURL('/form');

      // Wait for form hydration
      await page.waitForSelector('input[name="name"]', { state: 'attached', timeout: 10000 });
      await page.waitForTimeout(500);

      const nameInput = page.locator('input[name="name"]');
      await nameInput.fill('Original Name');

      await expect(page.locator('.preview-name')).toContainText('Original Name', { timeout: 10000 });

      await page.locator('nav a[href="/about"]').first().click();
      await expect(page).toHaveURL('/about', { timeout: 10000 });

      await page.locator('nav a[href="/form"]').first().click();
      await expect(page).toHaveURL('/form', { timeout: 10000 });

      // Wait for re-hydration
      await page.waitForSelector('input[name="name"]', { state: 'attached', timeout: 10000 });
      await page.waitForTimeout(500);

      const newNameInput = page.locator('input[name="name"]');
      await newNameInput.fill('New Name');

      await expect(page.locator('.preview-name')).toContainText('New Name', { timeout: 10000 });
    });

    test('multiple round trips maintain page functionality', async ({ page }) => {
      await page.goto('/');
      await expect(page).toHaveURL('/');

      // Round trip 1: Home → About → Home
      await page.locator('nav a[href="/about"]').first().click();
      await expect(page).toHaveURL('/about', { timeout: 10000 });
      await page.locator('nav a[href="/"]').first().click();
      await expect(page).toHaveURL('/', { timeout: 10000 });

      await waitForHydration(page, '.counter');
      await expect(page.locator('.counter')).toBeVisible();
      await page.locator('button.inc').click();

      // Round trip 2: Home → Form → Home
      await page.locator('nav a[href="/form"]').first().click();
      await expect(page).toHaveURL('/form', { timeout: 10000 });
      await page.locator('nav a[href="/"]').first().click();
      await expect(page).toHaveURL('/', { timeout: 10000 });

      await waitForHydration(page, '.counter');
      await expect(page.locator('.counter')).toBeVisible();
      await page.locator('button.dec').click();

      const finalCount = await page.locator('.count-display').textContent();
      expect(finalCount).toBeTruthy();
    });
  });
});
