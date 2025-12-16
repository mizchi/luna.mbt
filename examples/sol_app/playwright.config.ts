import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  use: {
    baseURL: 'http://localhost:3000',
    headless: true,
  },
  webServer: {
    command: 'node target/js/release/build/__gen__/server/server.js',
    port: 3000,
    reuseExistingServer: !process.env.CI,
    timeout: 10000,
  },
});
