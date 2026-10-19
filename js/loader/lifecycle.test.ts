import { afterEach, describe, expect, it, vi } from "vitest";
import { createIslandLifecycle } from "../shared/runtime/islands";
import { createHydrator } from "./src/hydration";

const stops: Array<() => void> = [];
afterEach(() => {
  for (const stop of stops.splice(0)) stop();
  document.body.innerHTML = "";
});

function lifecycle() {
  const scope = createIslandLifecycle();
  stops.push(scope.dispose);
  return scope;
}

function element() {
  const el = document.createElement("section");
  document.body.append(el);
  return el;
}

describe("shared island lifetime", () => {
  it("deduplicates per element and cleans removed islands exactly once", async () => {
    const scope = lifecycle();
    const first = element();
    const second = element();
    const cleanup = vi.fn();
    const mount = vi.fn(() => cleanup);
    await scope.mount(first, mount);
    await scope.mount(first, mount);
    await scope.mount(second, mount);
    expect(mount).toHaveBeenCalledTimes(2);
    first.remove();
    await vi.waitFor(() => expect(cleanup).toHaveBeenCalledTimes(1));
    scope.unmountAll(document.body);
    scope.dispose();
    expect(cleanup).toHaveBeenCalledTimes(2);
  });

  it("disposes a late async mount without taking ownership from its replacement", async () => {
    const scope = lifecycle();
    const el = element();
    let finish!: (cleanup: () => void) => void;
    const pending = scope.mount(
      el,
      () =>
        new Promise<() => void>((resolve) => {
          finish = resolve;
        }),
    );
    scope.unmount(el);
    const replacement = vi.fn();
    await scope.mount(el, () => replacement);
    const stale = vi.fn();
    finish(stale);
    expect(await pending).toBe(false);
    expect(stale).toHaveBeenCalledOnce();
    expect(replacement).not.toHaveBeenCalled();
    scope.dispose();
    expect(replacement).toHaveBeenCalledOnce();
  });

  it("invalidates in-flight imports and can retry a failed mount", async () => {
    const scope = lifecycle();
    const el = element();
    const failed = () => {
      throw new Error("failed import");
    };
    await expect(scope.mount(el, failed)).rejects.toThrow("failed import");
    const cleanup = vi.fn();
    expect(await scope.mount(el, () => cleanup)).toBe(true);
    scope.unmountAll(el);
    expect(cleanup).toHaveBeenCalledOnce();
    let isCurrent!: () => boolean;
    await scope.mount(el, (active) => {
      isCurrent = active;
    });
    expect(isCurrent()).toBe(true);
    scope.dispose();
    expect(isCurrent()).toBe(false);
    expect(await scope.mount(el, () => cleanup)).toBe(false);
  });

  it("returns cleanup from createHydrator and permits hydration after disposal", () => {
    const el = element();
    const cleanup = vi.fn();
    const setup = vi.fn(() => cleanup);
    const hydrate = createHydrator(setup);
    const dispose = hydrate(el, {}, "sample");
    expect(typeof dispose).toBe("function");
    if (typeof dispose !== "function") throw new Error("missing cleanup");
    dispose();
    dispose();
    expect(cleanup).toHaveBeenCalledOnce();
    hydrate(el, {}, "sample");
    expect(setup).toHaveBeenCalledTimes(2);
  });
});
