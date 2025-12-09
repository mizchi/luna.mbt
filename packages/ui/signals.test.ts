import { describe, test, expect } from "bun:test";
import {
  createSignal,
  get,
  set,
  update,
  peek,
  subscribe,
  map,
  createMemo,
  combine,
  effect,
  batchStart,
  batchEnd,
  runUntracked,
  batch,
  onCleanup,
  createRoot,
  getOwner,
  runWithOwner,
  hasOwner,
  onMount,
  type Signal,
} from "./index.js";

describe("Signal basics", () => {
  test("createSignal and get", () => {
    const count: Signal<number> = createSignal(0);
    expect(get(count)).toBe(0);

    const name: Signal<string> = createSignal("hello");
    expect(get(name)).toBe("hello");

    const flag: Signal<boolean> = createSignal(true);
    expect(get(flag)).toBe(true);
  });

  test("set updates value", () => {
    const count = createSignal(0);
    set(count, 10);
    expect(get(count)).toBe(10);

    const name = createSignal("hello");
    set(name, "world");
    expect(get(name)).toBe("world");
  });

  test("update with function", () => {
    const count = createSignal(5);
    update(count, (x) => x + 1);
    expect(get(count)).toBe(6);

    update(count, (x) => x * 2);
    expect(get(count)).toBe(12);
  });

  test("peek does not track", () => {
    const count = createSignal(42);
    let effectRuns = 0;

    effect(() => {
      peek(count);
      effectRuns++;
    });

    expect(effectRuns).toBe(1);
    set(count, 100);
    expect(effectRuns).toBe(1);
  });
});

describe("Subscriptions", () => {
  test("subscribe to changes", () => {
    const count = createSignal(0);
    const values: number[] = [];

    const unsub = subscribe(count, (value) => {
      values.push(value);
    });

    set(count, 1);
    set(count, 2);
    set(count, 3);

    expect(values).toEqual([1, 2, 3]);

    unsub();
    set(count, 4);
    expect(values).toEqual([1, 2, 3]);
  });
});

describe("Derived values", () => {
  test("map derives value", () => {
    const count = createSignal(5);
    const doubled = map(count, (x) => x * 2);

    expect(doubled()).toBe(10);

    set(count, 10);
    expect(doubled()).toBe(20);
  });

  test("createMemo caches computation", () => {
    const count = createSignal(5);
    let computeCount = 0;

    const memo = createMemo(() => {
      computeCount++;
      return get(count) * 2;
    });

    expect(memo()).toBe(10);
    expect(memo()).toBe(10);
    expect(computeCount).toBe(1);

    set(count, 10);
    expect(memo()).toBe(20);
  });

  test("combine two signals", () => {
    const a = createSignal(2);
    const b = createSignal(3);
    const sum = combine(a, b, (x, y) => x + y);

    expect(sum()).toBe(5);

    set(a, 10);
    expect(sum()).toBe(13);

    set(b, 7);
    expect(sum()).toBe(17);
  });
});

describe("Effects", () => {
  test("effect runs on dependency change", () => {
    const count = createSignal(0);
    const log: number[] = [];

    const cleanup = effect(() => {
      log.push(get(count));
    });

    expect(log).toEqual([0]);

    set(count, 1);
    expect(log).toEqual([0, 1]);

    set(count, 2);
    expect(log).toEqual([0, 1, 2]);

    cleanup();
    set(count, 3);
    expect(log).toEqual([0, 1, 2]);
  });

  test("onCleanup is called on re-run", () => {
    const count = createSignal(0);
    const cleanups: number[] = [];

    effect(() => {
      const val = get(count);
      onCleanup(() => {
        cleanups.push(val);
      });
    });

    expect(cleanups).toEqual([]);

    set(count, 1);
    expect(cleanups).toEqual([0]);

    set(count, 2);
    expect(cleanups).toEqual([0, 1]);
  });
});

describe("Batching", () => {
  test("batch delays updates", () => {
    const a = createSignal(0);
    const b = createSignal(0);
    let effectRuns = 0;

    effect(() => {
      get(a);
      get(b);
      effectRuns++;
    });

    expect(effectRuns).toBe(1);

    batchStart();
    set(a, 1);
    set(b, 1);
    expect(effectRuns).toBe(1);
    batchEnd();

    expect(effectRuns).toBe(2);
  });

  test("batch helper function", () => {
    const a = createSignal(0);
    const b = createSignal(0);
    let effectRuns = 0;

    effect(() => {
      get(a);
      get(b);
      effectRuns++;
    });

    expect(effectRuns).toBe(1);

    batch(() => {
      set(a, 1);
      set(b, 1);
    });

    expect(effectRuns).toBe(2);
  });

  test("runUntracked prevents tracking", () => {
    const count = createSignal(0);
    let effectRuns = 0;

    effect(() => {
      runUntracked(() => get(count));
      effectRuns++;
    });

    expect(effectRuns).toBe(1);
    set(count, 100);
    expect(effectRuns).toBe(1);
  });
});

describe("Owner system", () => {
  test("createRoot provides disposal", () => {
    const count = createSignal(0);
    let effectRuns = 0;

    createRoot((dispose) => {
      effect(() => {
        get(count);
        effectRuns++;
      });

      expect(effectRuns).toBe(1);
      set(count, 1);
      expect(effectRuns).toBe(2);

      dispose();
    });

    set(count, 2);
    expect(effectRuns).toBe(2);
  });

  test("hasOwner returns correct state", () => {
    expect(hasOwner()).toBe(false);

    createRoot(() => {
      expect(hasOwner()).toBe(true);
    });

    expect(hasOwner()).toBe(false);
  });

  test("getOwner and runWithOwner", () => {
    let capturedOwner: any;

    createRoot(() => {
      capturedOwner = getOwner();
      expect(capturedOwner).toBeDefined();
    });

    expect(hasOwner()).toBe(false);

    if (capturedOwner) {
      runWithOwner(capturedOwner, () => {
        expect(hasOwner()).toBe(true);
      });
    }
  });

  test("onMount runs once", () => {
    let mountCount = 0;

    createRoot(() => {
      onMount(() => {
        mountCount++;
      });
    });

    expect(mountCount).toBe(1);
  });
});

describe("Type safety", () => {
  test("type inference works correctly", () => {
    const count = createSignal(0);
    const name = createSignal("hello");

    const n: number = get(count);
    const s: string = get(name);
    set(count, 42);
    set(name, "world");

    const doubled = map(count, (x) => x * 2);
    const upper = map(name, (s) => s.toUpperCase());
    const _d: number = doubled();
    const _u: string = upper();

    const combined = combine(count, name, (c, n) => `${n}: ${c}`);
    const _c: string = combined();

    const memoized = createMemo(() => get(count) * 2);
    const _m: number = memoized();

    expect(true).toBe(true);
  });
});
