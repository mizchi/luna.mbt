import { defineConfig } from 'vitest/config';

// Browser name from CLI or default to chromium
// Usage: pnpm test:browser -- --browser.name=firefox
const browserName = process.env.BROWSER || 'chromium';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      name: browserName,
      provider: 'playwright',
      headless: true,
    },
    include: ['tests/**/*.browser.test.ts'],
    // Exclude bench tests from regular test runs
    exclude: ['tests/bench.browser.test.ts'],
  },
});
