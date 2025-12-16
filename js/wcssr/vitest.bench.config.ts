import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    browser: {
      enabled: true,
      name: 'chromium',
      provider: 'playwright',
      headless: true,
    },
    include: ['tests/bench.browser.test.ts'],
    benchmark: {
      include: ['tests/bench.browser.test.ts'],
      reporters: ['default'],
    },
  },
});
