import { afterEach, describe, expect, it, vi } from "vitest";
import { createIslandLifecycle } from "./src/runtime/islands";
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
  it("does not scan mounted islands for insertions or text-only removals", async () => {
    const scope = lifecycle();
    const host = element();
    const sidebar = element();
    await scope.mount(host, () => {});
    await Promise.resolve();
    const connected = vi.spyOn(host, "isConnected", "get");
    try {
      sidebar.append(document.createElement("span"));
      await Promise.resolve();
      expect(connected).not.toHaveBeenCalled();
      sidebar.append("old text");
      await Promise.resolve();
      sidebar.lastChild!.textContent = "new text";
      await Promise.resolve();
      sidebar.lastChild!.remove();
      await Promise.resolve();
      expect(connected).not.toHaveBeenCalled();
    } finally {
      connected.mockRestore();
    }
  });

  it("disposes every island inside a removed ancestor", async () => {
    const scope = lifecycle();
    const container = element();
    const first = document.createElement("section");
    const second = document.createElement("section");
    container.append(first, second);
    const cleanup = vi.fn();
    await scope.mount(first, () => cleanup);
    await scope.mount(second, () => cleanup);
    container.remove();
    await Promise.resolve();
    expect(cleanup).toHaveBeenCalledTimes(2);
    scope.dispose();
    expect(cleanup).toHaveBeenCalledTimes(2);
  });

  it("keeps islands moved to another connected parent in the same mutation batch", async () => {
    const scope = lifecycle();
    const host = element();
    const destination = element();
    const cleanup = vi.fn();
    await scope.mount(host, () => cleanup);
    host.remove();
    destination.append(host);
    await Promise.resolve();
    expect(cleanup).not.toHaveBeenCalled();
    scope.dispose();
    expect(cleanup).toHaveBeenCalledOnce();
  });

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
