import { test, expect } from '@playwright/test';

test.describe('iframe embed', () => {
  test('iframe loads with URL parameters', async ({ page }) => {
    await page.goto('/x-counter-iframe.html?initial=25&label=Test');

    const counter = page.locator('#component');
    await expect(counter).toBeVisible();

    const value = counter.locator('.value');
    await expect(value).toHaveText('25');

    const label = counter.locator('.label');
    await expect(label).toContainText('Test');
  });

  test('iframe buttons work', async ({ page }) => {
    await page.goto('/x-counter-iframe.html?initial=10');

    const counter = page.locator('#component');
    const value = counter.locator('.value');
    const incButton = counter.locator('.inc');

    await expect(value).toHaveText('10');
    await incButton.click();
    await expect(value).toHaveText('11');
  });

  test('iframe helper creates iframe correctly', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <div id="container"></div>
        <script src="http://localhost:3600/x-counter-iframe.js"></script>
        <script>
          window.testCounter = createStellaIframe('#container', {
            initial: 42,
            label: 'Iframe Test'
          });
        </script>
      </body>
      </html>
    `);

    // Wait for iframe to be created
    const iframe = page.locator('#container iframe');
    await expect(iframe).toBeVisible();

    // Check iframe src contains params
    const src = await iframe.getAttribute('src');
    expect(src).toContain('initial=42');
    expect(src).toContain('label=Iframe');
  });

  test('iframe helper receives ready event', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <div id="container"></div>
        <script src="http://localhost:3600/x-counter-iframe.js"></script>
        <script>
          window.readyReceived = false;
          window.testCounter = createStellaIframe('#container', {
            initial: 0,
            baseUrl: 'http://localhost:3600'
          });
          window.testCounter.on('ready', () => {
            window.readyReceived = true;
          });
        </script>
      </body>
      </html>
    `);

    // Wait for ready event
    await page.waitForFunction(() => window.readyReceived === true, { timeout: 10000 });

    const ready = await page.evaluate(() => window.readyReceived);
    expect(ready).toBe(true);
  });

  test('iframe helper setAttr updates component', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <div id="container"></div>
        <script src="http://localhost:3600/x-counter-iframe.js"></script>
        <script>
          window.testCounter = createStellaIframe('#container', {
            initial: 0,
            baseUrl: 'http://localhost:3600'
          });
        </script>
      </body>
      </html>
    `);

    // Wait for iframe to load
    const iframe = page.frameLocator('#container iframe');
    await iframe.locator('.value').waitFor({ timeout: 10000 });

    // Check initial value
    await expect(iframe.locator('.value')).toHaveText('0');

    // Update via setAttr
    await page.evaluate(() => {
      window.testCounter.setAttr('initial', 100);
    });

    // Wait for update
    await expect(iframe.locator('.value')).toHaveText('100');
  });

  test('iframe forwards change events to parent', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <div id="container"></div>
        <script src="http://localhost:3600/x-counter-iframe.js"></script>
        <script>
          window.lastChangeValue = null;
          window.testCounter = createStellaIframe('#container', {
            initial: 5,
            baseUrl: 'http://localhost:3600'
          });
          window.testCounter.on('change', (detail) => {
            window.lastChangeValue = detail.value;
          });
        </script>
      </body>
      </html>
    `);

    // Wait for iframe to load
    const iframe = page.frameLocator('#container iframe');
    await iframe.locator('.value').waitFor({ timeout: 10000 });

    // Click increment in iframe
    await iframe.locator('.inc').click();

    // Check parent received event
    await page.waitForFunction(() => window.lastChangeValue !== null);
    const value = await page.evaluate(() => window.lastChangeValue);
    expect(value).toBe(6);
  });

  test('declarative iframe initialization', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <div data-stella-iframe="x-counter" data-initial="77"></div>
        <script src="http://localhost:3600/x-counter-iframe.js"></script>
      </body>
      </html>
    `);

    // Wait for iframe to be created
    const iframe = page.locator('[data-stella-iframe] iframe');
    await expect(iframe).toBeVisible();

    const src = await iframe.getAttribute('src');
    expect(src).toContain('initial=77');
  });
});

// Extend Window interface for TypeScript
declare global {
  interface Window {
    testCounter: {
      setAttr: (name: string, value: unknown) => void;
      on: (event: string, callback: (detail: unknown) => void) => void;
    };
    readyReceived: boolean;
    lastChangeValue: number | null;
  }
}
