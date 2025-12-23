import { describe, test, expect, beforeEach } from "vitest";
import {
  createStore,
  createEffect,
  createRoot,
  produce,
  reconcile,
} from "../src/index";

describe("createStore", () => {
  describe("Basic functionality", () => {
    test("creates a store with initial value", () => {
      const [state] = createStore({ count: 0 });
      expect(state.count).toBe(0);
    });

    test("nested property access works", () => {
      const [state] = createStore({
        user: { name: "John", age: 30 },
      });
      expect(state.user.name).toBe("John");
      expect(state.user.age).toBe(30);
    });

    test("deeply nested access works", () => {
      const [state] = createStore({
        a: { b: { c: { d: 42 } } },
      });
      expect(state.a.b.c.d).toBe(42);
    });
  });

  describe("setState with path", () => {
    test("updates single property", () => {
      const [state, setState] = createStore({ count: 0 });
      setState("count", 1);
      expect(state.count).toBe(1);
    });

    test("updates nested property", () => {
      const [state, setState] = createStore({
        user: { name: "John" },
      });
      setState("user", "name", "Jane");
      expect(state.user.name).toBe("Jane");
    });

    test("functional update works", () => {
      const [state, setState] = createStore({ count: 5 });
      setState("count", (c: number) => c + 1);
      expect(state.count).toBe(6);
    });

    test("merges objects at path", () => {
      const [state, setState] = createStore({
        user: { name: "John", age: 30 },
      });
      setState("user", { age: 31 });
      expect(state.user.name).toBe("John");
      expect(state.user.age).toBe(31);
    });

    test("merges at root level", () => {
      const [state, setState] = createStore({
        count: 0,
        name: "test",
      });
      setState({ count: 10 });
      expect(state.count).toBe(10);
      expect(state.name).toBe("test");
    });
  });

  describe("Reactivity", () => {
    test("tracks property access in effects", () => {
      createRoot(() => {
        const [state, setState] = createStore({ count: 0 });
        const values: number[] = [];

        createEffect(() => {
          values.push(state.count);
        });

        expect(values).toEqual([0]);

        setState("count", 1);
        expect(values).toEqual([0, 1]);

        setState("count", 2);
        expect(values).toEqual([0, 1, 2]);
      });
    });

    test("tracks nested property access", () => {
      createRoot(() => {
        const [state, setState] = createStore({
          user: { name: "John" },
        });
        const names: string[] = [];

        createEffect(() => {
          names.push(state.user.name);
        });

        expect(names).toEqual(["John"]);

        setState("user", "name", "Jane");
        expect(names).toEqual(["John", "Jane"]);
      });
    });

    test("only triggers when accessed property changes", () => {
      createRoot(() => {
        const [state, setState] = createStore({
          a: 1,
          b: 2,
        });
        const aValues: number[] = [];

        createEffect(() => {
          aValues.push(state.a);
        });

        expect(aValues).toEqual([1]);

        // Changing b should not trigger effect that only reads a
        setState("b", 3);
        expect(aValues).toEqual([1]);

        // Changing a should trigger
        setState("a", 10);
        expect(aValues).toEqual([1, 10]);
      });
    });

    test("parent path change notifies child accessors", () => {
      createRoot(() => {
        const [state, setState] = createStore({
          user: { name: "John", age: 30 },
        });
        const names: string[] = [];

        createEffect(() => {
          names.push(state.user.name);
        });

        expect(names).toEqual(["John"]);

        // Replacing the entire user object should trigger
        setState("user", { name: "Jane", age: 25 });
        expect(names).toEqual(["John", "Jane"]);
      });
    });
  });

  describe("Arrays", () => {
    test("array access works", () => {
      const [state] = createStore({ items: [1, 2, 3] });
      expect(state.items[0]).toBe(1);
      expect(state.items.length).toBe(3);
    });

    test("array updates work", () => {
      const [state, setState] = createStore({ items: ["a", "b", "c"] });
      setState("items", [...state.items, "d"]);
      expect(state.items).toEqual(["a", "b", "c", "d"]);
    });

    test("array with objects", () => {
      const [state, setState] = createStore({
        todos: [
          { id: 1, text: "First", done: false },
          { id: 2, text: "Second", done: true },
        ],
      });

      expect(state.todos[0].text).toBe("First");
      expect(state.todos[1].done).toBe(true);
    });
  });

  describe("produce helper", () => {
    test("produce creates a mutation function", () => {
      const [state, setState] = createStore({
        user: { name: "John", age: 30 },
      });

      setState(
        "user",
        produce((user: { name: string; age: number }) => {
          user.name = "Jane";
          user.age = 31;
        })
      );

      expect(state.user.name).toBe("Jane");
      expect(state.user.age).toBe(31);
    });

    test("produce works with arrays", () => {
      const [state, setState] = createStore({
        items: [1, 2, 3],
      });

      setState(
        "items",
        produce((items: number[]) => {
          items.push(4);
        })
      );

      expect(state.items).toEqual([1, 2, 3, 4]);
    });
  });

  describe("reconcile helper", () => {
    test("reconcile replaces entire value", () => {
      const [state, setState] = createStore({
        items: [1, 2, 3],
      });

      setState("items", reconcile([4, 5, 6]));
      expect(state.items).toEqual([4, 5, 6]);
    });
  });

  describe("Edge cases", () => {
    test("handles undefined values", () => {
      const [state, setState] = createStore<{
        value: number | undefined;
      }>({ value: undefined });
      expect(state.value).toBeUndefined();

      setState("value", 42);
      expect(state.value).toBe(42);

      setState("value", undefined);
      expect(state.value).toBeUndefined();
    });

    test("handles null values", () => {
      const [state, setState] = createStore<{
        value: string | null;
      }>({ value: null });
      expect(state.value).toBeNull();

      setState("value", "hello");
      expect(state.value).toBe("hello");

      setState("value", null);
      expect(state.value).toBeNull();
    });

    test("creates nested paths that don't exist", () => {
      const [state, setState] = createStore<{
        deep?: { nested?: { value?: number } };
      }>({});

      setState("deep", "nested", "value", 42);
      expect(state.deep?.nested?.value).toBe(42);
    });
  });
});
