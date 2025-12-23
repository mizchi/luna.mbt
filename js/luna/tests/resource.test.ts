import { describe, test, expect, vi } from "vitest";
import {
  createResource,
  createDeferred,
  createEffect,
  createRoot,
} from "../src/index";

describe("Resource API (SolidJS-style)", () => {
  describe("createResource", () => {
    test("starts in pending state", () => {
      const [resource] = createResource<string>(() => {
        // Never resolves
      });

      expect(resource.loading).toBe(true);
      expect(resource.state).toBe("pending");
    });

    test("transitions to success on resolve", async () => {
      const [resource] = createResource<string>((resolve) => {
        resolve("success-data");
      });

      // Resolve happens synchronously in this case
      expect(resource.state).toBe("ready");
      expect(resource()).toBe("success-data");
    });

    test("transitions to failure on reject", () => {
      const [resource] = createResource<string>((_, reject) => {
        reject("error-message");
      });

      expect(resource.state).toBe("errored");
      expect(resource.error).toBe("error-message");
    });

    test("async resolve works", async () => {
      let resolveRef: ((value: string) => void) | null = null;

      const [resource] = createResource<string>((resolve) => {
        resolveRef = resolve;
      });

      expect(resource.loading).toBe(true);

      resolveRef!("async-data");

      expect(resource.state).toBe("ready");
      expect(resource()).toBe("async-data");
    });

    test("refetch re-runs fetcher", () => {
      let fetchCount = 0;
      const [resource, { refetch }] = createResource<string>((resolve) => {
        fetchCount++;
        resolve(`fetch-${fetchCount}`);
      });

      expect(fetchCount).toBe(1);
      expect(resource()).toBe("fetch-1");

      refetch();

      expect(fetchCount).toBe(2);
      expect(resource()).toBe("fetch-2");
    });
  });

  describe("createDeferred", () => {
    test("returns accessor, resolve, and reject", () => {
      const [resource, resolve, reject] = createDeferred<number>();

      expect(typeof resource).toBe("function");
      expect(typeof resolve).toBe("function");
      expect(typeof reject).toBe("function");
    });

    test("starts in pending state", () => {
      const [resource] = createDeferred<number>();
      expect(resource.loading).toBe(true);
    });

    test("resolve transitions to success", () => {
      const [resource, resolve] = createDeferred<number>();

      resolve(42);

      expect(resource.loading).toBe(false);
      expect(resource()).toBe(42);
    });

    test("reject transitions to failure", () => {
      const [resource, , reject] = createDeferred<number>();

      reject("deferred-error");

      expect(resource.loading).toBe(false);
      expect(resource.error).toBe("deferred-error");
    });
  });

  describe("reactivity", () => {
    test("accessor is reactive", () => {
      const [resource, resolve] = createDeferred<string>();
      let effectRunCount = 0;

      createRoot((dispose) => {
        createEffect(() => {
          resource(); // Access value to track
          effectRunCount++;
        });

        expect(effectRunCount).toBe(1);

        resolve("data");
        // Effect should re-run because accessor is reactive
        expect(effectRunCount).toBe(2);
        dispose();
      });
    });
  });

  describe("integration with Promise", () => {
    test("works with setTimeout simulation", async () => {
      vi.useFakeTimers();

      const [resource] = createResource<string>((resolve) => {
        setTimeout(() => resolve("delayed"), 100);
      });

      expect(resource.loading).toBe(true);

      vi.advanceTimersByTime(100);

      expect(resource.state).toBe("ready");
      expect(resource()).toBe("delayed");

      vi.useRealTimers();
    });

    test("can wrap fetch-like async operations", async () => {
      const mockFetch = vi.fn().mockResolvedValue({ data: "fetched" });

      const [resource] = createResource<{ data: string }>((resolve, reject) => {
        mockFetch()
          .then(resolve)
          .catch((e: Error) => reject(e.message));
      });

      // Wait for promise to resolve
      await vi.waitFor(() => {
        expect(resource.state).toBe("ready");
      });

      expect(resource()).toEqual({ data: "fetched" });
    });
  });
});
