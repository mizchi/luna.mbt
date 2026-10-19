import { test } from "vitest";

interface Fixture {
  setup?: () => void;
  teardown?: () => void;
}

/** Each measured operation starts from the same fixture; hooks are not timed. */
export function bench(name: string, run: () => unknown, fixture: Fixture = {}) {
  test(
    name,
    async ({ bench }) => {
      await bench(name, { beforeEach: fixture.setup, afterEach: fixture.teardown }, run).run({
        time: 0,
        iterations: 100,
        warmupTime: 0,
        warmupIterations: 20,
      });
    },
    60_000,
  );
}
