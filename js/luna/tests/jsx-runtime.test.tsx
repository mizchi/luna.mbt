import { describe, test, expect } from "vitest";
import "global-jsdom/register";
import { jsx, jsxs, Fragment, type JSX } from "../src/jsx-runtime";
import { createSignal, createMemo, get, set, For, Show, render } from "../src/index";

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
    const [isActive, setIsActive] = createSignal(false);

    const node = jsx("div", {
      className: () => (isActive() ? "active" : "inactive"),
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

  test("style object is converted to CSS string", () => {
    const node = jsx("div", {
      style: { padding: "20px", backgroundColor: "red", maxWidth: "600px" },
      children: "styled",
    });

    const container = document.createElement("div");
    render(container, node);

    const div = container.querySelector("div");
    expect(div).toBeDefined();
    // Check that style is applied (camelCase converted to kebab-case)
    expect(div?.getAttribute("style")).toContain("padding: 20px");
    expect(div?.getAttribute("style")).toContain("background-color: red");
    expect(div?.getAttribute("style")).toContain("max-width: 600px");
  });

  test("style string is passed through", () => {
    const node = jsx("div", {
      style: "color: blue; margin: 10px",
      children: "styled",
    });

    const container = document.createElement("div");
    render(container, node);

    const div = container.querySelector("div");
    expect(div?.getAttribute("style")).toBe("color: blue; margin: 10px");
  });

  test("onClick handler is triggered", () => {
    let clicked = false;

    const node = jsx("button", {
      onClick: () => {
        clicked = true;
      },
      children: "Click me",
    });

    const container = document.createElement("div");
    render(container, node);

    const button = container.querySelector("button");
    expect(button).toBeDefined();

    // Simulate click
    button?.click();
    expect(clicked).toBe(true);
  });

  test("onInput handler is triggered", () => {
    let inputValue = "";

    const node = jsx("input", {
      type: "text",
      onInput: (e: Event) => {
        inputValue = (e.target as HTMLInputElement).value;
      },
    });

    const container = document.createElement("div");
    render(container, node);

    const input = container.querySelector("input") as HTMLInputElement;
    expect(input).toBeDefined();

    // Simulate input using native setter and event
    const nativeInputValueSetter = Object.getOwnPropertyDescriptor(
      window.HTMLInputElement.prototype,
      "value"
    )?.set;
    nativeInputValueSetter?.call(input, "test");
    input.dispatchEvent(new window.Event("input", { bubbles: true }));
    expect(inputValue).toBe("test");
  });

  test("signal accessor renders as dynamic text", () => {
    const [count, setCount] = createSignal(0);

    const node = jsx("div", {
      children: [
        "Count: ",
        count, // signal accessor as child
      ],
    });

    const container = document.createElement("div");
    render(container, node);

    expect(container.textContent).toContain("Count: 0");

    // Update signal
    setCount(5);
    expect(container.textContent).toContain("Count: 5");
  });

  test("memo accessor renders as dynamic text", () => {
    const [count, setCount] = createSignal(2);
    const doubled = createMemo(() => count() * 2);

    const node = jsx("div", {
      children: ["Doubled: ", doubled],
    });

    const container = document.createElement("div");
    render(container, node);

    expect(container.textContent).toContain("Doubled: 4");

    setCount(5);
    expect(container.textContent).toContain("Doubled: 10");
  });

  test("inline function renders as dynamic text", () => {
    const [isEven, setIsEven] = createSignal(true);

    const node = jsx("div", {
      children: [() => (isEven() ? "Even" : "Odd")],
    });

    const container = document.createElement("div");
    render(container, node);

    expect(container.textContent).toBe("Even");

    setIsEven(false);
    expect(container.textContent).toBe("Odd");
  });

  test("render function (with args) is passed through to For", () => {
    const [items, setItems] = createSignal(["a", "b", "c"]);

    const node = jsx(For, {
      each: items,
      children: (item: string) => jsx("li", { children: item }),
    });

    const container = document.createElement("ul");
    render(container, node);

    expect(container.querySelectorAll("li").length).toBe(3);
    expect(container.textContent).toContain("a");
    expect(container.textContent).toContain("b");
    expect(container.textContent).toContain("c");
  });

  test("Show component with JSX", () => {
    const [visible, setVisible] = createSignal(true);

    const node = jsx(Show, {
      when: visible,
      children: jsx("div", { children: "Visible content" }),
    });

    const container = document.createElement("div");
    render(container, node);

    expect(container.textContent).toContain("Visible content");

    setVisible(false);
    expect(container.textContent).not.toContain("Visible content");
  });
});

describe("JSX Counter Example", () => {
  test("counter increments and decrements", () => {
    const [count, setCount] = createSignal(0);
    const doubled = createMemo(() => count() * 2);

    const Counter = () =>
      jsx("div", {
        children: [
          jsx("p", { children: ["Count: ", count] }),
          jsx("p", { children: ["Doubled: ", doubled] }),
          jsx("button", {
            id: "decrement",
            onClick: () => setCount((c) => c - 1),
            children: "-",
          }),
          jsx("button", {
            id: "increment",
            onClick: () => setCount((c) => c + 1),
            children: "+",
          }),
          jsx("button", {
            id: "reset",
            onClick: () => setCount(0),
            children: "Reset",
          }),
        ],
      });

    const container = document.createElement("div");
    render(container, jsx(Counter, {}));

    // Initial state
    expect(container.textContent).toContain("Count: 0");
    expect(container.textContent).toContain("Doubled: 0");

    // Increment
    container.querySelector<HTMLButtonElement>("#increment")?.click();
    expect(container.textContent).toContain("Count: 1");
    expect(container.textContent).toContain("Doubled: 2");

    // Increment again
    container.querySelector<HTMLButtonElement>("#increment")?.click();
    expect(container.textContent).toContain("Count: 2");
    expect(container.textContent).toContain("Doubled: 4");

    // Decrement
    container.querySelector<HTMLButtonElement>("#decrement")?.click();
    expect(container.textContent).toContain("Count: 1");
    expect(container.textContent).toContain("Doubled: 2");

    // Reset
    container.querySelector<HTMLButtonElement>("#reset")?.click();
    expect(container.textContent).toContain("Count: 0");
    expect(container.textContent).toContain("Doubled: 0");
  });
});

describe("JSX Todo Example", () => {
  test("todo list add and remove", () => {
    const [todos, setTodos] = createSignal<
      { id: number; text: string; done: boolean }[]
    >([]);
    let nextId = 1;

    const addTodo = (text: string) => {
      setTodos((t) => [...t, { id: nextId++, text, done: false }]);
    };

    const removeTodo = (id: number) => {
      setTodos((t) => t.filter((todo) => todo.id !== id));
    };

    const TodoApp = () =>
      jsxs("div", {
        children: [
          jsx("button", {
            id: "add-btn",
            onClick: () => addTodo("New todo"),
            children: "Add",
          }),
          jsx(For, {
            each: todos,
            children: (todo: { id: number; text: string; done: boolean }) =>
              jsx("div", {
                className: "todo-item",
                children: [
                  jsx("span", { children: todo.text }),
                  jsx("button", {
                    className: "remove-btn",
                    onClick: () => removeTodo(todo.id),
                    children: "x",
                  }),
                ],
              }),
          }),
        ],
      });

    const container = document.createElement("div");
    render(container, jsx(TodoApp, {}));

    // Initially empty
    expect(container.querySelectorAll(".todo-item").length).toBe(0);

    // Add first todo
    container.querySelector<HTMLButtonElement>("#add-btn")?.click();
    expect(container.querySelectorAll(".todo-item").length).toBe(1);
    expect(container.textContent).toContain("New todo");

    // Add second todo
    container.querySelector<HTMLButtonElement>("#add-btn")?.click();
    expect(container.querySelectorAll(".todo-item").length).toBe(2);

    // Remove first todo
    container.querySelector<HTMLButtonElement>(".remove-btn")?.click();
    expect(container.querySelectorAll(".todo-item").length).toBe(1);
  });
});
