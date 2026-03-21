/**
 * Issue #7: JSX Reactive Props Not Automatically Tracked
 *
 * Tests that reactive props (class, style, etc.) update in the DOM
 * when using accessor functions.
 *
 * Key distinction:
 * - class={className}   → passes accessor function → should be reactive (Dynamic)
 * - class={className()} → passes evaluated value → static, never updates (by design)
 */
import { describe, test, expect } from "vitest";
import "global-jsdom/register";
import { createSignal, createMemo, render } from "../src/index";
import type { JSX } from "../src/jsx-runtime";

describe("Issue #7: Reactive class prop with accessor function", () => {
  test("class updates when signal changes (accessor passed directly)", () => {
    const [active, setActive] = createSignal(false);
    const className = createMemo(() => `btn ${active() ? "active" : "inactive"}`);

    // Pass accessor function directly (NOT called)
    const node = <button class={className}>Toggle</button>;

    const container = document.createElement("div");
    render(container, node);

    const button = container.querySelector("button")!;
    expect(button.getAttribute("class")).toBe("btn inactive");

    setActive(true);
    expect(button.getAttribute("class")).toBe("btn active");

    setActive(false);
    expect(button.getAttribute("class")).toBe("btn inactive");
  });

  test("class does NOT update when signal value is passed (called accessor)", () => {
    const [active, setActive] = createSignal(false);
    const className = createMemo(() => `btn ${active() ? "active" : "inactive"}`);

    // Pass evaluated value (called accessor) - this is static by design
    const node = <button class={className()}>Toggle</button>;

    const container = document.createElement("div");
    render(container, node);

    const button = container.querySelector("button")!;
    expect(button.getAttribute("class")).toBe("btn inactive");

    setActive(true);
    // This should NOT update - value was evaluated at creation time
    expect(button.getAttribute("class")).toBe("btn inactive");
  });
});

describe("Issue #7: Reactive style prop", () => {
  test("dynamic style object updates when signal changes", () => {
    const [color, setColor] = createSignal("red");

    // Pass style as a function returning style object
    const node = (
      <div style={() => ({ color: color(), fontWeight: "bold" })}>
        Styled
      </div>
    );

    const container = document.createElement("div");
    render(container, node);

    const div = container.querySelector("div")!;
    expect(div.getAttribute("style")).toContain("color: red");

    setColor("blue");
    expect(div.getAttribute("style")).toContain("color: blue");
  });
});

describe("Issue #7: Reactive data attribute", () => {
  test("data-* attribute updates when signal changes", () => {
    const [count, setCount] = createSignal(0);

    const node = <div data-count={() => String(count())}>Content</div>;

    const container = document.createElement("div");
    render(container, node);

    const div = container.querySelector("div")!;
    expect(div.getAttribute("data-count")).toBe("0");

    setCount(42);
    expect(div.getAttribute("data-count")).toBe("42");
  });
});
