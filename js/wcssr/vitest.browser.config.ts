import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

// Browser name from CLI or default to chromium
// Usage: pnpm test:browser -- --browser.name=firefox
const browserName = (process.env.BROWSER || 'chromium') as 'chromium' | 'firefox' | 'webkit';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      headless: true,
      provider: playwright(),
      instances: [{ browser: browserName }],
    },
    include: ['tests/**/*.browser.test.ts'],
    // Exclude bench tests from regular test runs
    exclude: ['tests/bench.browser.test.ts'],
  },
});
