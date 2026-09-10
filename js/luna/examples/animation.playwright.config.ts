import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  testMatch: 'animation.test.ts',
  use: { baseURL: 'http://127.0.0.1:4179', browserName: 'chromium' },
  reporter: 'list',
  webServer: {
    command: 'pnpm exec vite --host 127.0.0.1 --port 4179 --strictPort',
    url: 'http://127.0.0.1:4179',
    reuseExistingServer: !process.env.CI,
  },
});
