import { test, expect } from '@playwright/test';

test.describe('Stella loader', () => {
  test('loads component automatically when detected', async ({ page }) => {
    // Navigate to the loader test page (doesn't preload component)
    await page.goto('/loader-test.html');

    // Wait for loader to be ready
    await page.waitForFunction(() => typeof (window as any).Stella !== 'undefined');

    // Add a counter element
    await page.evaluate(() => {
      const counter = document.createElement('x-counter');
      counter.id = 'test-counter';
      document.getElementById('container')!.appendChild(counter);
    });

    // Wait for custom element to be defined (loaded by the loader)
    await page.waitForFunction(() => {
      return customElements.get('x-counter') !== undefined;
    }, { timeout: 10000 });

    // Additional wait for shadow DOM to be populated
    await page.waitForFunction(() => {
      const el = document.querySelector('x-counter');
      const value = el?.shadowRoot?.querySelector('.value');
      return value !== null && value.textContent !== '';
    }, { timeout: 10000 });

    // Use evaluate to check shadow DOM value since loader dynamically loads the component
    const valueText = await page.evaluate(() => {
      const el = document.querySelector('x-counter');
      return el?.shadowRoot?.querySelector('.value')?.textContent ?? '';
    });
    expect(valueText).toBe('0');
  });

  test('exposes Stella API on window', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <script src="http://localhost:3600/loader.js"></script>
      </body>
      </html>
    `);

    // Check API exists
    const hasApi = await page.evaluate(() => {
      return typeof window.Stella === 'object' &&
        typeof window.Stella.load === 'function' &&
        typeof window.Stella.loaded === 'function' &&
        typeof window.Stella.components === 'function';
    });

    expect(hasApi).toBe(true);
  });

  test('Stella.components() returns available components', async ({ page }) => {
    await page.setContent(`
      <!DOCTYPE html>
      <html>
      <body>
        <script src="http://localhost:3600/loader.js"></script>
      </body>
      </html>
    `);

    const components = await page.evaluate(() => window.Stella.components());
    expect(components).toContain('x-counter');
  });

  test('dynamically added elements are auto-loaded', async ({ page }) => {
    // Navigate to the loader test page (doesn't preload component)
    await page.goto('/loader-test.html');

    // Wait for loader to initialize
    await page.waitForFunction(() => typeof (window as any).Stella !== 'undefined');

    // Dynamically add a counter with initial value
    await page.evaluate(() => {
      const container = document.getElementById('container')!;
      const counter = document.createElement('x-counter');
      counter.setAttribute('initial', '99');
      container.appendChild(counter);
    });

    // Wait for custom element to be defined (loaded by the loader)
    await page.waitForFunction(() => {
      return customElements.get('x-counter') !== undefined;
    }, { timeout: 10000 });

    // Wait for shadow DOM to be populated with content
    await page.waitForFunction(() => {
      const el = document.querySelector('x-counter');
      const value = el?.shadowRoot?.querySelector('.value');
      return value !== null && value.textContent !== '';
    }, { timeout: 10000 });

    // Use evaluate to check shadow DOM value
    const valueText = await page.evaluate(() => {
      const el = document.querySelector('x-counter');
      return el?.shadowRoot?.querySelector('.value')?.textContent ?? '';
    });
    expect(valueText).toBe('99');
  });
});

// Extend Window interface for TypeScript
declare global {
  interface Window {
    Stella: {
      load: (tag: string) => Promise<void>;
      loaded: () => string[];
      components: () => string[];
    };
  }
}
