import { test, expect } from '@playwright/test';

test('debug hydration', async ({ page }) => {
  // Enable verbose logging
  await page.addInitScript(() => {
    const originalImport = (window as any).import;
    console.log('[DEBUG] Page initialized');
  });
  // Collect console logs
  const logs: string[] = [];
  page.on('console', msg => {
    logs.push(`${msg.type()}: ${msg.text()}`);
  });

  // Collect errors
  const errors: string[] = [];
  page.on('pageerror', err => {
    errors.push(err.message);
  });

  await page.goto('/');

  // Wait for hydration attempt
  await page.waitForTimeout(2000);

  // Output debug info
  console.log('=== Console Logs ===');
  logs.forEach(log => console.log(log));

  console.log('\n=== Page Errors ===');
  errors.forEach(err => console.log(err));

  // Check if counter.js was loaded
  const scripts = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('script[type="module"]'))
      .map(s => s.getAttribute('src'));
  });
  console.log('\n=== Module Scripts ===');
  console.log(scripts);

  // Check island element
  const island = await page.evaluate(() => {
    const el = document.querySelector('[ln\\:id]');
    if (!el) return null;
    return {
      id: el.getAttribute('ln:id'),
      url: el.getAttribute('ln:url'),
      state: el.getAttribute('ln:state'),
      trigger: el.getAttribute('ln:trigger'),
    };
  });
  console.log('\n=== Island Element ===');
  console.log(island);

  // Check if __LN_STATE__ is populated
  const lnState = await page.evaluate(() => {
    return (window as any).__LN_STATE__;
  });
  console.log('\n=== __LN_STATE__ ===');
  console.log(lnState);

  expect(true).toBe(true);
});
