import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'list',
  use: {
    baseURL: 'http://localhost:3600',
    trace: 'on-first-retry',
  },
  webServer: {
    command: 'node scripts/server.js',
    url: 'http://localhost:3600',
    reuseExistingServer: !process.env.CI,
    timeout: 10000,
  },
});
