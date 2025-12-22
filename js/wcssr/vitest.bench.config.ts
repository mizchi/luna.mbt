import { defineConfig } from 'vitest/config';
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      headless: true,
      provider: playwright(),
      instances: [{ browser: 'chromium' }],
    },
    include: ['tests/*.bench.ts', 'tests/bench.browser.test.ts'],
    benchmark: {
      include: ['tests/*.bench.ts', 'tests/bench.browser.test.ts'],
      reporters: ['default'],
    },
  },
});
