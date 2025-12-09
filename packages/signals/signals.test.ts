import { test } from "node:test";
import { strict as assert } from "node:assert";
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
  type Signal,
} from "./index.js";

test("createSignal and get", () => {
  const count: Signal<number> = createSignal(0);
  assert.equal(get(count), 0);

  const name: Signal<string> = createSignal("hello");
  assert.equal(get(name), "hello");

  const flag: Signal<boolean> = createSignal(true);
  assert.equal(get(flag), true);
});

test("set updates value", () => {
  const count = createSignal(0);
  set(count, 10);
  assert.equal(get(count), 10);

  const name = createSignal("hello");
  set(name, "world");
  assert.equal(get(name), "world");
});

test("update with function", () => {
  const count = createSignal(5);
  update(count, (x) => x + 1);
  assert.equal(get(count), 6);

  update(count, (x) => x * 2);
  assert.equal(get(count), 12);
});

test("peek does not track", () => {
  const count = createSignal(42);
  let effectRuns = 0;

  effect(() => {
    peek(count); // should not track
    effectRuns++;
  });

  assert.equal(effectRuns, 1);
  set(count, 100);
  // effect should not re-run because we used peek
  assert.equal(effectRuns, 1);
});

test("subscribe to changes", () => {
  const count = createSignal(0);
  const values: number[] = [];

  const unsub = subscribe(count, (value) => {
    values.push(value);
  });

  set(count, 1);
  set(count, 2);
  set(count, 3);

  assert.deepEqual(values, [1, 2, 3]);

  unsub();
  set(count, 4);
  // should not receive after unsubscribe
  assert.deepEqual(values, [1, 2, 3]);
});

test("map derives value", () => {
  const count = createSignal(5);
  const doubled = map(count, (x) => x * 2);

  assert.equal(doubled(), 10);

  set(count, 10);
  assert.equal(doubled(), 20);
});

test("createMemo caches computation", () => {
  const count = createSignal(5);
  let computeCount = 0;

  const memo = createMemo(() => {
    computeCount++;
    return get(count) * 2;
  });

  assert.equal(memo(), 10);
  assert.equal(memo(), 10);
  // memo should cache - only computed once until dependency changes
  assert.equal(computeCount, 1);

  set(count, 10);
  assert.equal(memo(), 20);
});

test("combine two signals", () => {
  const a = createSignal(2);
  const b = createSignal(3);
  const sum = combine(a, b, (x, y) => x + y);

  assert.equal(sum(), 5);

  set(a, 10);
  assert.equal(sum(), 13);

  set(b, 7);
  assert.equal(sum(), 17);
});

test("effect runs on dependency change", () => {
  const count = createSignal(0);
  const log: number[] = [];

  const cleanup = effect(() => {
    log.push(get(count));
  });

  assert.deepEqual(log, [0]);

  set(count, 1);
  assert.deepEqual(log, [0, 1]);

  set(count, 2);
  assert.deepEqual(log, [0, 1, 2]);

  cleanup();
  set(count, 3);
  // should not run after cleanup
  assert.deepEqual(log, [0, 1, 2]);
});

test("batch delays updates", () => {
  const a = createSignal(0);
  const b = createSignal(0);
  let effectRuns = 0;

  effect(() => {
    get(a);
    get(b);
    effectRuns++;
  });

  assert.equal(effectRuns, 1);

  batchStart();
  set(a, 1);
  set(b, 1);
  // effect should not run yet
  assert.equal(effectRuns, 1);
  batchEnd();

  // effect runs once after batch
  assert.equal(effectRuns, 2);
});

test("runUntracked prevents tracking", () => {
  const count = createSignal(0);
  let effectRuns = 0;

  effect(() => {
    runUntracked(() => get(count));
    effectRuns++;
  });

  assert.equal(effectRuns, 1);
  set(count, 100);
  // effect should not re-run
  assert.equal(effectRuns, 1);
});

// Type tests (compile-time only)
test("type safety", () => {
  const count = createSignal(0);
  const name = createSignal("hello");

  // These should compile - type inference works
  const n: number = get(count);
  const s: string = get(name);
  set(count, 42);
  set(name, "world");

  // Map preserves/transforms types correctly
  const doubled = map(count, (x) => x * 2);
  const upper = map(name, (s) => s.toUpperCase());
  const _d: number = doubled();
  const _u: string = upper();

  // Combine infers return type from function
  const combined = combine(count, name, (c, n) => `${n}: ${c}`);
  const _c: string = combined();

  // Memo infers type from compute function
  const memoized = createMemo(() => get(count) * 2);
  const _m: number = memoized();

  assert.ok(true);
});
