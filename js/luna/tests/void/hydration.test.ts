import { afterEach, describe, expect, it, vi } from "vitest";
import { createSignal, getOwner, onCleanup, onMount } from "../../src/index";
import { hydrate, renderToString, type VNode } from "../../src/ssr";
import { Fragment, jsx } from "../../src/ssr/jsx-runtime";
import { defineLunaIsland } from "../../src/void/hydrate";
import { initLunaIslands } from "../../src/void/scheduler";
import { lunaIsland } from "../../src/void/server";

const disposers: Array<() => void> = [];

afterEach(() => {
  for (const dispose of disposers.splice(0)) dispose();
  vi.unstubAllGlobals();
  document.body.innerHTML = "";
});

function Counter({ initial }: { initial: number }): VNode {
  const [count, setCount] = createSignal(initial);
  return jsx("div", {
    children: [
      jsx("input", { value: "server", "aria-label": "Draft" }),
      jsx("button", { onClick: () => setCount((n) => n + 1), children: () => `Luna ${count()}` }),
    ],
  });
}

describe("Void Luna hydration", () => {
  it.each(["__innerHTML", "__ref", "__future", "sol:hk", "SOL:HK"])(
    "rejects reserved JSX attribute %s before rendering or evaluating it",
    (name) => {
      const getter = vi.fn(() => '<strong data-review="benign">review</strong>');
      for (const value of ["reserved", getter]) {
        expect(() => jsx("div", { [name]: value })).toThrow(/reserved/i);
      }
      expect(getter).not.toHaveBeenCalled();
    },
  );

  it("keeps untrusted dynamic text as text through SSR and hydration", () => {
    const content = '<strong data-review="benign">review</strong>';
    const component = () => jsx("div", { children: () => content });
    document.body.innerHTML = renderToString(component);
    disposers.push(hydrate(document.body, component));
    expect(document.querySelector("div")!.textContent).toBe(content);
    expect(document.querySelector("strong")).toBeNull();
  });

  it("renders the same JSX on the server without a document and disposes its root", () => {
    const cleanup = vi.fn();
    vi.stubGlobal("document", undefined);
    const markup = renderToString(() => {
      onCleanup(cleanup);
      return jsx("button", { title: '<unsafe> & "quote"', onClick: vi.fn(), children: "<safe>" });
    });
    expect(markup).toContain("&lt;safe&gt;");
    expect(markup).toContain('title="<unsafe> &amp; &quot;quote&quot;"');
    expect(markup).toContain('sol:hk="0"');
    expect(markup).not.toMatch(/onclick/i);
    expect(cleanup).toHaveBeenCalledTimes(1);
  });

  it.each([
    [0, 1],
    [1, 0],
  ])("reuses SSR nodes and preserves input with hydration order %s, %s", (first, second) => {
    document.body.innerHTML = [0, 10]
      .map((initial) => String(lunaIsland("counter", Counter, { initial })))
      .join("");
    const elements = [...document.querySelectorAll("[data-island]")];
    const original = elements.map((element) => ({
      button: element.querySelector("button")!,
      text: element.querySelector("button")!.childNodes[1],
      input: element.querySelector("input")!,
    }));
    original[0].input.value = "typed before hydration";
    const counter = defineLunaIsland(Counter);
    for (const index of [first, second]) {
      disposers.push(counter.mount(elements[index], { initial: index * 10 }));
      original[index].button.click();
    }
    for (const [index, element] of elements.entries()) {
      expect(element.querySelector("button")).toBe(original[index].button);
      expect(element.querySelector("input")).toBe(original[index].input);
      expect(element.querySelector("button")!.childNodes[1]).toBe(original[index].text);
    }
    expect(original[0].input.value).toBe("typed before hydration");
    expect(original[0].button.textContent).toBe("Luna 1");
    expect(original[1].button.textContent).toBe("Luna 11");
  });

  it("cleans up effects and event handlers when the island is disposed", () => {
    const cleanup = vi.fn();
    const clicked = vi.fn();
    const component = () => {
      onCleanup(cleanup);
      const [count, setCount] = createSignal(0);
      return jsx("button", {
        onClick: () => {
          clicked();
          setCount((n) => n + 1);
        },
        children: () => String(count()),
      });
    };
    document.body.innerHTML = renderToString(component);
    cleanup.mockClear();
    const button = document.querySelector("button")!;
    const dispose = hydrate(document.body, component);
    button.click();
    expect(button.textContent).toBe("1");
    dispose();
    dispose();
    button.click();
    expect(clicked).toHaveBeenCalledTimes(1);
    expect(cleanup).toHaveBeenCalledTimes(1);
    expect(button.textContent).toBe("1");
  });

  it("disposes a hydrated root when Void removes its island", async () => {
    const cleanup = vi.fn();
    const clicked = vi.fn();
    const component = () => {
      onCleanup(cleanup);
      return jsx("button", { onClick: clicked, children: "Remove me" });
    };
    document.body.innerHTML = String(lunaIsland("counter", component, {}));
    cleanup.mockClear();
    disposers.push(
      initLunaIslands({ counter: async () => ({ default: defineLunaIsland(component) }) }),
    );
    const element = document.querySelector("section")!;
    const button = element.querySelector("button")!;
    await vi.waitFor(() => expect(element.getAttribute("data-luna-mounted")).toBe("true"));
    expect(element.querySelector("button")).toBe(button);
    element.remove();
    await vi.waitFor(() => expect(cleanup).toHaveBeenCalledTimes(1));
    button.click();
    expect(clicked).not.toHaveBeenCalled();
  });

  it("runs mount hooks only on the client and restores context after server errors", async () => {
    const mounted = vi.fn();
    const owner = getOwner();
    const component = () => {
      onMount(mounted);
      return jsx("p", { children: "Server" });
    };
    document.body.innerHTML = renderToString(component);
    expect(() =>
      renderToString(() => {
        throw new Error("Render failed");
      }),
    ).toThrow("Render failed");
    expect(getOwner()).toBe(owner);
    await Promise.resolve();
    expect(mounted).not.toHaveBeenCalled();
    disposers.push(hydrate(document.body, component));
    await Promise.resolve();
    expect(mounted).toHaveBeenCalledTimes(1);
  });

  it("reports a mismatch without replacing server content or leaking a root", () => {
    const cleanup = vi.fn();
    const owner = getOwner();
    document.body.innerHTML = '<input value="server"><button>Fallback</button>';
    const original = document.body.innerHTML;
    expect(() =>
      hydrate(document.body, () => {
        onCleanup(cleanup);
        return Counter({ initial: 0 });
      }),
    ).toThrow(/hydrat.*mismatch/i);
    expect(document.body.innerHTML).toBe(original);
    expect(cleanup).toHaveBeenCalledTimes(1);
    expect(getOwner()).toBe(owner);
  });

  it("hydrates fragments, nested components, reactive attributes, and refs", () => {
    const ref = vi.fn();
    const component = () => {
      const [active, setActive] = createSignal(false);
      return jsx(Fragment, {
        children: [
          jsx("span", { children: [0, false, null, "ok"] }),
          jsx(
            () =>
              jsx("button", {
                ref,
                className: () => (active() ? "active" : "idle"),
                disabled: false,
                onClick: () => setActive(true),
                children: "Go",
              }),
            {},
          ),
        ],
      });
    };
    document.body.innerHTML = renderToString(component);
    const button = document.querySelector("button")!;
    expect(ref).not.toHaveBeenCalled();
    expect(button.disabled).toBe(false);
    disposers.push(hydrate(document.body, component));
    expect(ref).toHaveBeenCalledWith(button);
    expect(document.querySelector("span")!.textContent).toBe("0ok");
    button.click();
    expect(button.className).toBe("active");
  });
});
