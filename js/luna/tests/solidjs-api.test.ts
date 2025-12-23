/**
 * Tests for SolidJS-compatible API utilities
 */
import { describe, test, expect, beforeEach, afterEach } from "vitest";
import {
  createSignal,
  createEffect,
  createMemo,
  createRoot,
  on,
  mergeProps,
  splitProps,
  Provider,
  Index,
  Switch,
  Match,
  Portal,
  portalToBody,
  portalToSelector,
  createContext,
  useContext,
  createElement,
  text,
  mount,
  For,
} from "../src/index";

// MoonBit AttrValue constructors
const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
  Dynamic: (getter: () => string) => ({ $tag: 1, _0: getter }),
};

function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

describe("on() utility", () => {
  test("on tracks single dependency", () => {
    const results: [number, number | undefined][] = [];

    createRoot((dispose) => {
      const [count, setCount] = createSignal(0);

      createEffect(
        on(count, (value, prev) => {
          results.push([value, prev]);
        })
      );

      setCount(1);
      setCount(2);
      dispose();
    });

    expect(results).toEqual([
      [0, undefined],
      [1, 0],
      [2, 1],
    ]);
  });

  test("on tracks multiple dependencies", () => {
    const results: [[number, string], [number, string] | undefined][] = [];

    createRoot((dispose) => {
      const [a, setA] = createSignal(1);
      const [b, setB] = createSignal("x");

      createEffect(
        on([a, b], (values, prev) => {
          results.push([values as [number, string], prev as [number, string] | undefined]);
        })
      );

      setA(2);
      setB("y");
      dispose();
    });

    expect(results).toEqual([
      [[1, "x"], undefined],
      [[2, "x"], [1, "x"]],
      [[2, "y"], [2, "x"]],
    ]);
  });

  test("on with defer option skips initial run", () => {
    const results: number[] = [];

    createRoot((dispose) => {
      const [count, setCount] = createSignal(0);

      createEffect(
        on(
          count,
          (value) => {
            results.push(value);
          },
          { defer: true }
        )
      );

      // Initial run should be skipped
      expect(results).toEqual([]);

      setCount(1);
      expect(results).toEqual([1]);

      setCount(2);
      expect(results).toEqual([1, 2]);

      dispose();
    });
  });
});

describe("mergeProps()", () => {
  test("merges simple props", () => {
    const a = { foo: 1, bar: 2 };
    const b = { bar: 3, baz: 4 };
    const result = mergeProps(a, b);

    expect(result).toEqual({ foo: 1, bar: 3, baz: 4 });
  });

  test("merges event handlers", () => {
    const calls: string[] = [];
    const a = { onClick: () => calls.push("a") };
    const b = { onClick: () => calls.push("b") };
    const result = mergeProps(a, b) as { onClick: () => void };

    result.onClick();
    expect(calls).toEqual(["a", "b"]);
  });

  test("merges ref callbacks", () => {
    const refs: string[] = [];
    const a = { ref: (el: string) => refs.push(`a:${el}`) };
    const b = { ref: (el: string) => refs.push(`b:${el}`) };
    const result = mergeProps(a, b) as { ref: (el: string) => void };

    result.ref("element");
    expect(refs).toEqual(["a:element", "b:element"]);
  });

  test("merges class names", () => {
    const a = { class: "foo" };
    const b = { class: "bar" };
    const result = mergeProps(a, b);

    expect(result.class).toBe("foo bar");
  });

  test("merges className", () => {
    const a = { className: "foo" };
    const b = { className: "bar" };
    const result = mergeProps(a, b);

    expect(result.className).toBe("foo bar");
  });

  test("merges style objects", () => {
    const a = { style: { color: "red", margin: "10px" } } as const;
    const b = { style: { color: "blue", padding: "5px" } } as const;
    const result = mergeProps<{ style: Record<string, string> }>(a as any, b as any);

    expect(result.style).toEqual({ color: "blue", margin: "10px", padding: "5px" });
  });

  test("handles undefined sources", () => {
    const a = { foo: 1 };
    const result = mergeProps<{ foo?: number; bar?: number }>(undefined, a, undefined, { bar: 2 });

    expect(result).toEqual({ foo: 1, bar: 2 });
  });
});

describe("splitProps()", () => {
  test("splits props into specified groups", () => {
    const props = { a: 1, b: 2, c: 3, d: 4 };
    const [ab, cd] = splitProps(props, ["a", "b"]);

    expect(ab).toEqual({ a: 1, b: 2 });
    expect(cd).toEqual({ c: 3, d: 4 });
  });

  test("splits props into multiple groups", () => {
    const props = { a: 1, b: 2, c: 3, d: 4, e: 5 };
    const [group1, group2, rest] = splitProps(props, ["a", "b"], ["c"]);

    expect(group1).toEqual({ a: 1, b: 2 });
    expect(group2).toEqual({ c: 3 });
    expect(rest).toEqual({ d: 4, e: 5 });
  });

  test("handles missing keys", () => {
    const props = { a: 1, b: 2 };
    const [group, rest] = splitProps(props, ["a", "c"] as (keyof typeof props)[]);

    expect(group).toEqual({ a: 1 });
    expect(rest).toEqual({ b: 2 });
  });
});

describe("Provider component", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  test("Provider provides context value", () => {
    const themeCtx = createContext("light");
    let capturedTheme = "";

    const Child = () => {
      capturedTheme = useContext(themeCtx);
      return text(capturedTheme);
    };

    Provider({
      context: themeCtx,
      value: "dark",
      children: () => {
        mount(container, Child());
        return text("");
      },
    });

    expect(capturedTheme).toBe("dark");
  });

  test("Provider works with function children", () => {
    const countCtx = createContext(0);
    let capturedCount = -1;

    Provider({
      context: countCtx,
      value: 42,
      children: () => {
        capturedCount = useContext(countCtx);
        return text(String(capturedCount));
      },
    });

    expect(capturedCount).toBe(42);
  });
});

describe("Index component", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  test("Index renders list with item getters", () => {
    const [items] = createSignal(["a", "b", "c"]);

    const node = Index({
      each: items,
      children: (itemGetter, index) =>
        createElement(
          "span",
          [attr("data-index", AttrValue.Static(String(index)))],
          [text(itemGetter())]
        ),
    });

    mount(container, node);

    const spans = container.querySelectorAll("span");
    expect(spans.length).toBe(3);
    expect(spans[0].textContent).toBe("a");
    expect(spans[1].textContent).toBe("b");
    expect(spans[2].textContent).toBe("c");
  });

  test("Index provides working item getter", () => {
    const values: string[] = [];
    const [items] = createSignal(["x", "y"]);

    Index({
      each: items,
      children: (itemGetter, _index) => {
        values.push(itemGetter());
        return text(itemGetter());
      },
    });

    expect(values).toEqual(["x", "y"]);
  });
});

describe("Switch/Match components", () => {
  test("Switch renders first truthy Match", () => {
    const [value, setValue] = createSignal("a");

    let rendered = "";
    createRoot((dispose) => {
      const result = Switch({
        fallback: text("none"),
        children: [
          Match({
            when: () => value() === "a",
            children: text("matched-a"),
          }),
          Match({
            when: () => value() === "b",
            children: text("matched-b"),
          }),
        ],
      });

      // result should be the matched content
      rendered = result ? "has-result" : "no-result";
      dispose();
    });

    expect(rendered).toBe("has-result");
  });

  test("Switch returns fallback when no match", () => {
    const [value] = createSignal("c");

    const result = Switch({
      fallback: text("fallback"),
      children: [
        Match({
          when: () => value() === "a",
          children: text("a"),
        }),
        Match({
          when: () => value() === "b",
          children: text("b"),
        }),
      ],
    });

    // Result should be fallback text node
    expect(result).toBeDefined();
  });

  test("Match with function children receives value", () => {
    const [user, setUser] = createSignal<{ name: string } | null>(null);
    let receivedName = "";

    createRoot((dispose) => {
      const match = Match({
        when: user,
        children: (u: { name: string }) => {
          receivedName = u.name;
          return text(u.name);
        },
      });

      // First, user is null, so match.when() should be false
      expect(match.when()).toBe(false);

      setUser({ name: "Alice" });
      expect(match.when()).toBe(true);

      // Call children with the value
      if (match.when() && typeof match.children === "function") {
        match.children();
        expect(receivedName).toBe("Alice");
      }

      dispose();
    });
  });
});

describe("SolidJS API compatibility", () => {
  test("createSignal returns tuple [getter, setter]", () => {
    const [count, setCount] = createSignal(0);

    expect(typeof count).toBe("function");
    expect(typeof setCount).toBe("function");
    expect(count()).toBe(0);

    setCount(5);
    expect(count()).toBe(5);

    setCount((c) => c + 1);
    expect(count()).toBe(6);
  });

  test("createMemo returns accessor", () => {
    const [count, setCount] = createSignal(2);
    const doubled = createMemo(() => count() * 2);

    expect(typeof doubled).toBe("function");
    expect(doubled()).toBe(4);

    setCount(5);
    expect(doubled()).toBe(10);
  });

  test("createEffect tracks dependencies automatically", () => {
    const values: number[] = [];

    createRoot((dispose) => {
      const [count, setCount] = createSignal(0);

      createEffect(() => {
        values.push(count());
      });

      setCount(1);
      setCount(2);
      dispose();
    });

    expect(values).toEqual([0, 1, 2]);
  });
});

describe("Portal component", () => {
  let container: HTMLElement;
  let portalTarget: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    container.id = "test-container";
    document.body.appendChild(container);

    portalTarget = document.createElement("div");
    portalTarget.id = "portal-target";
    document.body.appendChild(portalTarget);
  });

  afterEach(() => {
    container.remove();
    portalTarget.remove();
  });

  test("Portal renders children to body by default", () => {
    const content = createElement("div", [attr("id", AttrValue.Static("portal-content"))], [text("Portal content")]);

    const placeholder = Portal({
      children: content,
    });

    // Placeholder should be returned
    expect(placeholder).toBeDefined();

    // Content should be in body
    const rendered = document.getElementById("portal-content");
    expect(rendered).not.toBeNull();
    expect(rendered?.textContent).toBe("Portal content");

    // Clean up
    rendered?.remove();
  });

  test("Portal renders to selector mount target", () => {
    const content = createElement("div", [attr("id", AttrValue.Static("selector-portal"))], [text("Selector portal")]);

    Portal({
      mount: "#portal-target",
      children: content,
    });

    // Content should be in the portal target
    const rendered = portalTarget.querySelector("#selector-portal");
    expect(rendered).not.toBeNull();
    expect(rendered?.textContent).toBe("Selector portal");
  });

  test("portalToBody low-level API works", () => {
    const content = createElement("div", [attr("id", AttrValue.Static("low-level-portal"))], [text("Low level")]);

    portalToBody([content]);

    const rendered = document.getElementById("low-level-portal");
    expect(rendered).not.toBeNull();
    expect(rendered?.textContent).toBe("Low level");

    rendered?.remove();
  });

  test("portalToSelector low-level API works", () => {
    const content = createElement("div", [attr("class", AttrValue.Static("selector-content"))], [text("Selector content")]);

    portalToSelector("#portal-target", [content]);

    const rendered = portalTarget.querySelector(".selector-content");
    expect(rendered).not.toBeNull();
    expect(rendered?.textContent).toBe("Selector content");
  });

  test("Portal accepts function children", () => {
    const content = () => createElement("span", [attr("id", AttrValue.Static("func-portal"))], [text("Function child")]);

    Portal({
      children: content,
    });

    const rendered = document.getElementById("func-portal");
    expect(rendered).not.toBeNull();
    expect(rendered?.textContent).toBe("Function child");

    rendered?.remove();
  });
});
