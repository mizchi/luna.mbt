import { afterEach, describe, expect, it, vi } from "vitest";
import { createSignal, onCleanup } from "../../src/index";
import { jsx } from "../../src/jsx-runtime";
import { defineLunaIsland, initLunaIslands } from "../../src/void/client";

afterEach(() => {
  document.body.innerHTML = "";
});

describe("Void Luna island lifecycle", () => {
  it("renders a real Luna component, updates signals, and disposes its root", () => {
    const cleanup = vi.fn();
    const counter = defineLunaIsland<{ initial: number }>(({ initial }) => {
      const [count, setCount] = createSignal(initial);
      onCleanup(cleanup);
      return jsx("button", {
        onClick: () => setCount((n) => n + 1),
        children: () => `Luna ${count()}`,
      });
    });
    const element = document.createElement("section");
    element.innerHTML = "<button>Fallback</button>";
    const original = element.firstChild;
    const dispose = counter.mount(element, { initial: 3 });
    expect(element.firstChild).not.toBe(original);
    const button = element.querySelector("button")!;
    button.click();
    expect(button.textContent).toBe("Luna 4");
    dispose();
    expect(cleanup).toHaveBeenCalledTimes(1);
  });

  it("loads custom renderer modules and cleans up islands removed from the DOM", async () => {
    document.body.innerHTML = '<section data-island="custom" data-props="{}"></section>';
    const cleanup = vi.fn();
    const mount = vi.fn(() => cleanup);
    const dispose = initLunaIslands({ custom: async () => ({ default: { mount } }) });
    await vi.waitFor(() => expect(mount).toHaveBeenCalledTimes(1));
    document.querySelector("section")!.remove();
    await vi.waitFor(() => expect(cleanup).toHaveBeenCalledTimes(1));
    dispose();
    expect(cleanup).toHaveBeenCalledTimes(1);
  });

  it("disposes asynchronous mounts that finish after their element is removed", async () => {
    document.body.innerHTML = '<section data-island="custom"></section>';
    const cleanup = vi.fn();
    let finish!: (cleanup: () => void) => void;
    const mount = vi.fn(
      () =>
        new Promise<() => void>((resolve) => {
          finish = resolve;
        }),
    );
    const dispose = initLunaIslands({ custom: async () => ({ default: { mount } }) });
    await vi.waitFor(() => expect(mount).toHaveBeenCalledTimes(1));
    document.querySelector("section")!.remove();
    finish(cleanup);
    await vi.waitFor(() => expect(cleanup).toHaveBeenCalledTimes(1));
    dispose();
  });

  it("stops pending modules from mounting after the adapter is disposed", async () => {
    document.body.innerHTML = '<section data-island="custom"></section>';
    const mount = vi.fn();
    let loaded!: (module: { default: { mount: typeof mount } }) => void;
    const dispose = initLunaIslands({
      custom: () =>
        new Promise((resolve) => {
          loaded = resolve;
        }),
    });
    dispose();
    loaded({ default: { mount } });
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(mount).not.toHaveBeenCalled();
  });
});
