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
    command: `cd ../.. && moon build --target js && cd examples/sol_app && node ../../target/js/release/build/sol/cli/cli.js build && PORT=${TEST_PORT} node .sol/prod/server/main.js`,
    port: TEST_PORT,
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
