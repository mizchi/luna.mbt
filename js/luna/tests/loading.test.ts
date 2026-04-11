/**
 * Tests for Loading component and isPending reactive accessor
 * Inspired by SolidJS v2 <Loading> and isPending()
 */
import { describe, test, expect, beforeEach } from "vitest";
import {
  createSignal,
  createDeferred,
  createEffect,
  createRenderEffect,
  createRoot,
  render,
  text,
  createElement,
  Loading,
  Show,
} from "../src/index";

// MoonBit AttrValue constructors
const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
};

function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

describe("Resource.pending (reactive accessor)", () => {
  test("pending is a reactive getter on createDeferred", () => {
    const [resource, resolve] = createDeferred<number>();

    // resource.pending should be a function (reactive accessor)
    expect(typeof resource.pending).toBe("function");

    // Initially pending
    expect(resource.pending()).toBe(true);

    // After resolve
    resolve(42);
    expect(resource.pending()).toBe(false);
  });

  test("pending tracks reactively inside effects", () => {
    const [resource, resolve] = createDeferred<string>();
    const log: boolean[] = [];

    createRoot(() => {
      createRenderEffect(() => {
        log.push(resource.pending());
      });
    });

    // Initially pending
    expect(log).toEqual([true]);

    // Resolve
    resolve("done");
    expect(log).toEqual([true, false]);
  });
});

describe("Loading component", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  test("shows fallback when pending, content when resolved", () => {
    const [resource, resolve] = createDeferred<string>();

    const node = Loading({
      when: resource.pending,
      fallback: text("Loading..."),
      children: () => text("Content loaded"),
    });

    render(container, node);

    // Initially pending → show fallback
    expect(container.textContent).toBe("Loading...");

    // Resolve
    resolve("data");

    // After resolve → show content
    expect(container.textContent).toBe("Content loaded");
  });

  test("maintains stale content during refetch (no flash)", () => {
    const [isPending, setIsPending] = createSignal(true);

    const node = Loading({
      when: isPending,
      fallback: text("Loading..."),
      children: () => text("Content"),
    });

    render(container, node);

    // Initially pending → show fallback
    expect(container.textContent).toBe("Loading...");

    // First resolve
    setIsPending(false);
    expect(container.textContent).toBe("Content");

    // Refetch (pending again) → should keep content, NOT show fallback
    setIsPending(true);
    expect(container.textContent).toBe("Content");

    // Resolve again
    setIsPending(false);
    expect(container.textContent).toBe("Content");
  });

  test("shows fallback only during initial load", () => {
    const [isPending, setIsPending] = createSignal(false);

    const node = Loading({
      when: isPending,
      fallback: text("Loading..."),
      children: () => text("Ready"),
    });

    render(container, node);

    // Not pending → show content directly
    expect(container.textContent).toBe("Ready");

    // Go pending → should NOT flash fallback (already loaded once)
    setIsPending(true);
    expect(container.textContent).toBe("Ready");
  });

  test("works with boolean when prop", () => {
    const node = Loading({
      when: false,
      fallback: text("Loading..."),
      children: () => text("Content"),
    });

    render(container, node);
    expect(container.textContent).toBe("Content");
  });
});
