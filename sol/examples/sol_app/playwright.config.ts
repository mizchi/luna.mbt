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
      ? `PORT=${TEST_PORT} node .sol/prod/server/main.js`
      : `cd ../.. && moon build --target js --release src/cli && cd examples/sol_app && node ../../_build/js/release/build/cli/cli.js build && PORT=${TEST_PORT} node .sol/prod/server/main.js`,
    port: TEST_PORT,
    reuseExistingServer: !process.env.CI,
    timeout: process.env.CI ? 30000 : 120000,
  },
});
