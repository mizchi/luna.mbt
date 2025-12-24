import { defineConfig } from "vitest/config";

// Note: @cloudflare/vitest-pool-workers requires vitest 2.x-3.x
// For now, we run routing logic tests without the Workers runtime.
// When actual worker code testing is needed (Phase 6 _worker.js),
// consider using a separate vitest 3.x installation or wrangler dev --test.

export default defineConfig({
  test: {
    include: ["tests/cloudflare/**/*.test.ts"],
    reporters: ["dot"],
  },
});
