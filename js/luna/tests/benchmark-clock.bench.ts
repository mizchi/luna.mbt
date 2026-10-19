import { expect, test } from "vitest";

test("benchmarks enable a high-resolution browser clock", () => {
  expect(globalThis.crossOriginIsolated).toBe(true);
});
