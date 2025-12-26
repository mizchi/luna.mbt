import { test, expect } from '@playwright/test';

test.describe('x-counter component', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    // Wait for web component to be defined
    await page.waitForFunction(() => customElements.get('x-counter') !== undefined);
  });

  test('renders with default values', async ({ page }) => {
    const counter = page.locator('x-counter').first();

    // Wait for shadow DOM to be populated
    await page.waitForFunction(() => {
      const el = document.querySelector('x-counter');
      return el?.shadowRoot?.querySelector('.value') !== null;
    });

    // Check shadow DOM content
    const value = counter.locator('.value');
    await expect(value).toHaveText('0');

    const label = counter.locator('.label');
    await expect(label).toContainText('Count');
  });

  test('renders with custom initial value', async ({ page }) => {
    const counter = page.locator('x-counter[initial="42"]');
    const value = counter.locator('.value');
    await expect(value).toHaveText('42');
  });

  test('renders with custom label', async ({ page }) => {
    const counter = page.locator('x-counter[label="Score"]');
    const label = counter.locator('.label');
    await expect(label).toContainText('Score');
  });

  test('increment button increases value', async ({ page }) => {
    const counter = page.locator('x-counter').first();
    const value = counter.locator('.value');
    const incButton = counter.locator('.inc');

    await expect(value).toHaveText('0');
    await incButton.click();
    await expect(value).toHaveText('1');
    await incButton.click();
    await expect(value).toHaveText('2');
  });

  test('decrement button decreases value', async ({ page }) => {
    const counter = page.locator('x-counter').first();
    const value = counter.locator('.value');
    const decButton = counter.locator('.dec');

    await expect(value).toHaveText('0');
    await decButton.click();
    await expect(value).toHaveText('-1');
  });

  test('disabled state prevents clicks', async ({ page }) => {
    const counter = page.locator('x-counter[disabled]');
    const value = counter.locator('.value');
    const incButton = counter.locator('.inc');
    const decButton = counter.locator('.dec');

    const initialValue = await value.textContent();

    // Buttons should be disabled
    await expect(incButton).toBeDisabled();
    await expect(decButton).toBeDisabled();

    // Try clicking (should have no effect)
    await incButton.click({ force: true });
    await expect(value).toHaveText(initialValue!);
  });

  test('emits change event on button click', async ({ page }) => {
    const counter = page.locator('#evented');
    const incButton = counter.locator('.inc');

    // Set up event listener
    const changePromise = page.evaluate(() => {
      return new Promise<number>((resolve) => {
        document.getElementById('evented')!.addEventListener('change', (e: any) => {
          resolve(e.detail.value);
        }, { once: true });
      });
    });

    await incButton.click();
    const value = await changePromise;
    expect(value).toBe(1);
  });

  test('dynamic attribute change updates label', async ({ page }) => {
    const counter = page.locator('#dynamic');
    const label = counter.locator('.label');

    await expect(label).toContainText('Dynamic');

    // Change label via button
    await page.click('button:has-text("Set label")');
    await expect(label).toContainText('Updated');
  });

  test('dynamic attribute change updates initial value', async ({ page }) => {
    const counter = page.locator('#dynamic');
    const value = counter.locator('.value');

    // Change initial via button
    await page.click('button:has-text("Set initial=50")');
    await expect(value).toHaveText('50');
  });
});
