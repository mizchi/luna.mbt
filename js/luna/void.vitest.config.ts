import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom",
    include: ["tests/void/**/*.test.ts"],
    restoreMocks: true,
  },
});
