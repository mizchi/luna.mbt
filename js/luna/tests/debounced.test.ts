import { describe, test, expect, beforeEach, afterEach, vi } from "vitest";
import { createSignal, debounced, createRenderEffect } from "../src/index";

describe("debounced signal", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  test("debounced returns initial value immediately", () => {
    const [value, setValue] = createSignal(42);
    const [debouncedValue] = debounced([value, setValue], 100);

    expect(debouncedValue()).toBe(42);
  });

  test("debounced delays value updates", () => {
    const [value, setValue] = createSignal("initial");
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 100);

    // Update the value
    setDebouncedValue("updated");

    // Debounced value should still be initial (before timeout)
    expect(debouncedValue()).toBe("initial");

    // Advance time by less than delay
    vi.advanceTimersByTime(50);
    expect(debouncedValue()).toBe("initial");

    // Advance time to complete the delay
    vi.advanceTimersByTime(50);
    expect(debouncedValue()).toBe("updated");
  });

  test("debounced cancels previous timer on rapid updates", () => {
    const [value, setValue] = createSignal(0);
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 100);

    // Rapid updates
    setDebouncedValue(1);
    vi.advanceTimersByTime(50);
    setDebouncedValue(2);
    vi.advanceTimersByTime(50);
    setDebouncedValue(3);

    // Should still be initial value
    expect(debouncedValue()).toBe(0);

    // Advance to complete the delay from last update
    vi.advanceTimersByTime(100);
    expect(debouncedValue()).toBe(3);
  });

  test("debounced with 0ms delay updates immediately after microtask", () => {
    const [value, setValue] = createSignal("start");
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 0);

    setDebouncedValue("end");

    // Even 0ms delay needs timer to fire
    vi.advanceTimersByTime(0);
    expect(debouncedValue()).toBe("end");
  });

  test("debounced triggers reactive effects after delay", () => {
    const [value, setValue] = createSignal(0);
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 100);

    const log: number[] = [];
    createRenderEffect(() => {
      log.push(debouncedValue());
    });

    // Initial effect run
    expect(log).toEqual([0]);

    // Update value
    setDebouncedValue(10);
    expect(log).toEqual([0]); // Not yet updated

    // After delay, effect should run
    vi.advanceTimersByTime(100);
    expect(log).toEqual([0, 10]);
  });

  test("debounced handles multiple sequential updates correctly", () => {
    const [value, setValue] = createSignal("a");
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 50);

    // First update
    setDebouncedValue("b");
    vi.advanceTimersByTime(50);
    expect(debouncedValue()).toBe("b");

    // Second update (after first completed)
    setDebouncedValue("c");
    vi.advanceTimersByTime(50);
    expect(debouncedValue()).toBe("c");
  });

  test("debounced works with object values", () => {
    const [value, setValue] = createSignal({ count: 0 });
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 100);

    const newObj = { count: 5 };
    setDebouncedValue(newObj);

    expect(debouncedValue().count).toBe(0);

    vi.advanceTimersByTime(100);
    expect(debouncedValue().count).toBe(5);
    expect(debouncedValue()).toBe(newObj); // Same reference
  });

  test("debounced works with array values", () => {
    const [value, setValue] = createSignal<number[]>([1, 2, 3]);
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 100);

    setDebouncedValue([4, 5, 6]);

    expect(debouncedValue()).toEqual([1, 2, 3]);

    vi.advanceTimersByTime(100);
    expect(debouncedValue()).toEqual([4, 5, 6]);
  });

  test("debounced with long delay", () => {
    const [value, setValue] = createSignal("original");
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 1000);

    setDebouncedValue("delayed");

    // Check at various points
    vi.advanceTimersByTime(500);
    expect(debouncedValue()).toBe("original");

    vi.advanceTimersByTime(499);
    expect(debouncedValue()).toBe("original");

    vi.advanceTimersByTime(1);
    expect(debouncedValue()).toBe("delayed");
  });

  test("debounced handles many rapid updates efficiently", () => {
    const [value, setValue] = createSignal(0);
    const [debouncedValue, setDebouncedValue] = debounced([value, setValue], 100);

    // Simulate 100 rapid updates
    for (let i = 1; i <= 100; i++) {
      setDebouncedValue(i);
      vi.advanceTimersByTime(10); // 10ms between each
    }

    // Should still be 0 because timer keeps getting reset
    expect(debouncedValue()).toBe(0);

    // Wait for final debounce to complete
    vi.advanceTimersByTime(100);
    expect(debouncedValue()).toBe(100);
  });
});
