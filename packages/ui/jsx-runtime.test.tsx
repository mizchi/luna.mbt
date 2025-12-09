import { describe, test, expect } from "bun:test";
import "global-jsdom/register";
import { jsx, jsxs, Fragment, type JSX } from "./jsx-runtime.js";
import { createSignal, get, set } from "./index.js";
import { render } from "./dom.js";

describe("JSX Runtime", () => {
  test("jsx creates element", () => {
    const node = jsx("div", { className: "test" });
    expect(node).toBeDefined();
  });

  test("jsx with children", () => {
    const node = jsx("div", {
      children: jsx("span", { children: "hello" }),
    });
    expect(node).toBeDefined();
  });

  test("jsxs with multiple children", () => {
    const node = jsxs("div", {
      children: [
        jsx("span", { children: "first" }),
        jsx("span", { children: "second" }),
      ],
    });
    expect(node).toBeDefined();
  });

  test("Fragment returns children array", () => {
    const nodes = Fragment({
      children: [
        jsx("div", { children: "a" }),
        jsx("div", { children: "b" }),
      ],
    });
    expect(Array.isArray(nodes)).toBe(true);
    expect(nodes.length).toBe(2);
  });

  test("function component", () => {
    function MyComponent(props: { name: string }) {
      return jsx("div", { children: `Hello, ${props.name}!` });
    }

    const node = jsx(MyComponent, { name: "World" });
    expect(node).toBeDefined();
  });

  test("renders to DOM", () => {
    const node = jsx("div", {
      id: "test-root",
      className: "container",
      children: jsxs("p", {
        children: ["Hello ", "World"],
      }),
    });

    const container = document.createElement("div");
    render(container, node);

    expect(container.innerHTML).toContain("test-root");
    expect(container.innerHTML).toContain("container");
    expect(container.innerHTML).toContain("Hello");
    expect(container.innerHTML).toContain("World");
  });

  test("reactive className", () => {
    const [active, setActive] = [
      createSignal(false),
      (v: boolean) => set(createSignal(false), v),
    ];

    const isActive = createSignal(false);

    const node = jsx("div", {
      className: () => (get(isActive) ? "active" : "inactive"),
    });

    expect(node).toBeDefined();
  });

  test("event handlers", () => {
    let clicked = false;

    const node = jsx("button", {
      onClick: () => {
        clicked = true;
      },
      children: "Click me",
    });

    expect(node).toBeDefined();
  });

  test("input with value", () => {
    const node = jsx("input", {
      type: "text",
      placeholder: "Enter text",
      value: "initial",
    });

    expect(node).toBeDefined();
  });

  test("self-closing elements", () => {
    const br = jsx("br", {});
    const hr = jsx("hr", {});
    const img = jsx("img", { src: "test.png", alt: "Test" });

    expect(br).toBeDefined();
    expect(hr).toBeDefined();
    expect(img).toBeDefined();
  });
});
