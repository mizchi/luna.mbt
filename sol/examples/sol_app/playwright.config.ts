import { defineConfig } from '@playwright/test';

// Use a non-standard port to avoid conflicts with dev servers
const TEST_PORT = 9123;

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  use: {
    baseURL: `http://localhost:${TEST_PORT}`,
    headless: true,
  },
  webServer: {
    // CI: build is done in a prior step, just serve
    // Local: full build + serve pipeline
    command: process.env.CI
      ? `pnpm serve --port ${TEST_PORT}`
      : `pnpm build && pnpm serve --port ${TEST_PORT}`,
    port: TEST_PORT,
    reuseExistingServer: !process.env.CI,
    timeout: process.env.CI ? 30000 : 120000,
  },
});
