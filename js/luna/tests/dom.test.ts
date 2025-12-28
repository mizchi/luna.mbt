import { describe, test, expect, beforeEach } from "vitest";
import {
  text,
  textDyn,
  createElement,
  createElementNs,
  svgNs,
  mathmlNs,
  render,
  mount,
  show,
  jsx,
  jsxs,
  Fragment,
  events,
  forEach,
  For,
  Show,
  createSignal,
  createRenderEffect,
} from "../src/index";
import { jsx as jsxRuntime } from "../src/jsx-runtime";

// MoonBit tuple representation for attrs: [name, value] -> { _0: name, _1: value }
// AttrValue constructors: $tag: 0 = Static, 1 = Dynamic, 2 = Handler
function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
  Dynamic: (getter: () => string) => ({ $tag: 1, _0: getter }),
  Handler: (handler: (e: unknown) => void) => ({ $tag: 2, _0: handler }),
};

describe("DOM API", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  describe("text nodes", () => {
    test("text creates a text node", () => {
      const node = text("hello");
      expect(node).toBeDefined();
    });

    test("text node renders to DOM", () => {
      const node = text("hello world");
      render(container, node);
      expect(container.textContent).toBe("hello world");
    });

    test("textDyn creates reactive text node", () => {
      const [value, setValue] = createSignal("initial");
      const node = textDyn(value);
      render(container, node);
      expect(container.textContent).toBe("initial");

      setValue("updated");
      expect(container.textContent).toBe("updated");
    });
  });

  describe("createElement", () => {
    test("createElement creates element with no attrs", () => {
      const node = createElement("div", [], []);
      expect(node).toBeDefined();
    });

    test("createElement renders to DOM", () => {
      const node = createElement("div", [], [text("content")]);
      render(container, node);
      expect(container.innerHTML).toBe("<div>content</div>");
    });

    test("createElement with static attributes", () => {
      const node = createElement(
        "div",
        [
          attr("id", AttrValue.Static("my-id")),
          attr("className", AttrValue.Static("my-class")),
        ],
        []
      );
      render(container, node);
      const div = container.querySelector("div");
      expect(div?.id).toBe("my-id");
      expect(div?.className).toBe("my-class");
    });

    test("createElement with style attribute", () => {
      const node = createElement(
        "div",
        [attr("style", AttrValue.Static("color: red; margin: 10px"))],
        []
      );
      render(container, node);
      const div = container.querySelector("div");
      expect(div?.getAttribute("style")).toBe("color: red; margin: 10px");
    });

    test("createElement with nested children", () => {
      const node = createElement("div", [], [
        createElement("span", [], [text("child1")]),
        createElement("span", [], [text("child2")]),
      ]);
      render(container, node);
      expect(container.querySelectorAll("span").length).toBe(2);
    });

    test("createElement with dynamic attribute", () => {
      const [className, setClassName] = createSignal("initial-class");
      const node = createElement(
        "div",
        [attr("className", AttrValue.Dynamic(className))],
        []
      );
      render(container, node);
      const div = container.querySelector("div");
      expect(div?.className).toBe("initial-class");

      setClassName("updated-class");
      expect(div?.className).toBe("updated-class");
    });

    test("createElement with event handler", () => {
      let clicked = false;
      const node = createElement(
        "button",
        [attr("click", AttrValue.Handler(() => { clicked = true; }))],
        [text("Click me")]
      );
      render(container, node);
      const button = container.querySelector("button");
      button?.click();
      expect(clicked).toBe(true);
    });

    test("createElement with value attribute (input)", () => {
      const node = createElement(
        "input",
        [attr("value", AttrValue.Static("test-value"))],
        []
      );
      render(container, node);
      const input = container.querySelector("input") as HTMLInputElement;
      expect(input?.value).toBe("test-value");
    });

    test("createElement with checked attribute", () => {
      const node = createElement(
        "input",
        [
          attr("type", AttrValue.Static("checkbox")),
          attr("checked", AttrValue.Static("true")),
        ],
        []
      );
      render(container, node);
      const input = container.querySelector("input") as HTMLInputElement;
      expect(input?.checked).toBe(true);
    });

    test("createElement with disabled attribute true", () => {
      const nodeDisabled = createElement(
        "button",
        [attr("disabled", AttrValue.Static("true"))],
        []
      );
      render(container, nodeDisabled);
      const btn = container.querySelector("button");
      expect(btn?.hasAttribute("disabled")).toBe(true);
    });

    test("createElement with disabled attribute false", () => {
      const nodeEnabled = createElement(
        "button",
        [attr("disabled", AttrValue.Static("false"))],
        []
      );
      render(container, nodeEnabled);
      const btn = container.querySelector("button");
      expect(btn?.hasAttribute("disabled")).toBe(false);
    });

    test("createElement with dynamic style", () => {
      const [style, setStyle] = createSignal("color: blue");
      const node = createElement(
        "div",
        [attr("style", AttrValue.Dynamic(style))],
        []
      );
      render(container, node);
      const div = container.querySelector("div");
      expect(div?.getAttribute("style")).toBe("color: blue");

      setStyle("color: green");
      expect(div?.getAttribute("style")).toBe("color: green");
    });
  });

  describe("jsx/jsxs", () => {
    test("jsx creates element", () => {
      const node = jsx("div", [], [text("jsx content")]);
      render(container, node);
      expect(container.innerHTML).toBe("<div>jsx content</div>");
    });

    test("jsxs creates element with multiple children", () => {
      const node = jsxs("div", [], [text("child1"), text("child2")]);
      render(container, node);
      expect(container.textContent).toBe("child1child2");
    });
  });

  describe("Fragment", () => {
    test("Fragment wraps multiple children", () => {
      const node = Fragment([text("a"), text("b"), text("c")]);
      render(container, node);
      expect(container.textContent).toBe("abc");
    });
  });

  describe("render and mount", () => {
    test("render clears container first", () => {
      container.innerHTML = "<p>existing</p>";
      const node = text("new content");
      render(container, node);
      expect(container.textContent).toBe("new content");
      expect(container.querySelector("p")).toBeNull();
    });

    test("mount appends without clearing", () => {
      container.innerHTML = "<p>existing</p>";
      const node = text("appended");
      mount(container, node);
      expect(container.textContent).toBe("existingappended");
    });
  });

  describe("show (conditional rendering)", () => {
    test("show creates a node", () => {
      const [visible] = createSignal(true);
      const node = show(visible, () =>
        createElement("div", [attr("id", AttrValue.Static("shown"))], [text("visible")])
      );
      expect(node).toBeDefined();
    });

    test("show with false condition creates placeholder", () => {
      const [visible] = createSignal(false);
      const node = show(visible, () =>
        createElement("div", [], [text("hidden")])
      );
      mount(container, node);
      // When false, only a comment placeholder is rendered
      expect(container.childNodes.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe("forEach (list rendering)", () => {
    test("forEach renders initial list", () => {
      const [items] = createSignal(["a", "b", "c"]);
      const node = forEach(items, (item: string, _index: number) =>
        createElement("span", [], [text(item)])
      );
      mount(container, node);
      expect(container.querySelectorAll("span").length).toBe(3);
      expect(container.textContent).toBe("abc");
    });

    test("forEach updates when items change", () => {
      const [items, setItems] = createSignal(["x", "y"]);
      const node = forEach(items, (item: string, _index: number) =>
        createElement("span", [], [text(item)])
      );
      mount(container, node);
      expect(container.textContent).toBe("xy");

      setItems(["x", "y", "z"]);
      expect(container.querySelectorAll("span").length).toBe(3);
      expect(container.textContent).toBe("xyz");
    });

    test("forEach removes items", () => {
      const [items, setItems] = createSignal(["1", "2", "3"]);
      const node = forEach(items, (item: string, _index: number) =>
        createElement("span", [], [text(item)])
      );
      mount(container, node);
      expect(container.querySelectorAll("span").length).toBe(3);

      setItems(["1"]);
      expect(container.querySelectorAll("span").length).toBe(1);
      expect(container.textContent).toBe("1");
    });

    test("forEach handles empty array", () => {
      const [items] = createSignal<string[]>([]);
      const node = forEach(items, (item: string, _index: number) =>
        createElement("span", [], [text(item)])
      );
      mount(container, node);
      expect(container.querySelectorAll("span").length).toBe(0);
    });

    test("forEach handles clear to empty", () => {
      const [items, setItems] = createSignal(["a", "b"]);
      const node = forEach(items, (item: string, _index: number) =>
        createElement("span", [], [text(item)])
      );
      mount(container, node);
      expect(container.querySelectorAll("span").length).toBe(2);

      setItems([]);
      expect(container.querySelectorAll("span").length).toBe(0);
    });
  });

  describe("events helper", () => {
    test("events returns handler map", () => {
      const handlers = events();
      expect(handlers).toBeDefined();
    });
  });

  describe("effect with DOM", () => {
    test("effect tracks signal changes", () => {
      const [count, setCount] = createSignal(0);
      const log: number[] = [];

      createRenderEffect(() => {
        log.push(count());
      });

      expect(log).toEqual([0]);
      setCount(1);
      expect(log).toEqual([0, 1]);
    });
  });

  describe("For component (SolidJS-style)", () => {
    test("For renders list with getter", () => {
      const [items] = createSignal(["a", "b", "c"]);

      const node = For({
        each: items,
        children: (item: string, index: () => number) =>
          createElement("li", [], [text(`${index()}: ${item}`)]),
      });

      mount(container, node);
      expect(container.querySelectorAll("li").length).toBe(3);
      expect(container.textContent).toBe("0: a1: b2: c");
    });

    test("For updates when signal changes", () => {
      const [items, setItems] = createSignal(["x", "y"]);

      const node = For({
        each: items,
        children: (item: string) => createElement("span", [], [text(item)]),
      });

      mount(container, node);
      expect(container.textContent).toBe("xy");

      setItems(["x", "y", "z"]);
      expect(container.querySelectorAll("span").length).toBe(3);
      expect(container.textContent).toBe("xyz");
    });

    test("For provides index as getter function", () => {
      const [items] = createSignal(["one", "two"]);
      const indices: number[] = [];

      const node = For({
        each: items,
        children: (_item: string, index: () => number) => {
          indices.push(index());
          return createElement("div", [], []);
        },
      });

      mount(container, node);
      expect(indices).toEqual([0, 1]);
    });
  });

  describe("Show component (SolidJS-style)", () => {
    test("Show hides content when condition is false", () => {
      const [visible] = createSignal(false);

      const node = Show({
        when: visible,
        children: createElement("div", [], [text("visible")]),
      });

      mount(container, node);
      expect(container.querySelector("div")).toBeNull();
    });

    test("Show toggles visibility", () => {
      const [visible, setVisible] = createSignal(false);

      const node = Show({
        when: visible,
        children: createElement("span", [], [text("content")]),
      });

      mount(container, node);
      expect(container.querySelector("span")).toBeNull();

      setVisible(true);
      expect(container.querySelector("span")).not.toBeNull();

      setVisible(false);
      expect(container.querySelector("span")).toBeNull();
    });

    test("Show accepts children as function", () => {
      const [value, setValue] = createSignal<string | null>(null);

      const node = Show({
        when: value,
        children: (v: string) => createElement("span", [], [text(v)]),
      });

      mount(container, node);
      expect(container.querySelector("span")).toBeNull();

      setValue("hello");
      expect(container.querySelector("span")?.textContent).toBe("hello");
    });
  });

  describe("ref callback (JSX style)", () => {
    test("ref callback is called with element (low-level __ref)", () => {
      let capturedElement: HTMLElement | null = null;

      const node = createElement(
        "div",
        [attr("__ref", AttrValue.Handler((el: unknown) => {
          capturedElement = el as HTMLElement;
        }))],
        [text("content")]
      );

      render(container, node);

      expect(capturedElement).not.toBeNull();
      expect(capturedElement?.tagName).toBe("DIV");
      expect(capturedElement?.textContent).toBe("content");
    });

    test("jsx-runtime converts ref prop to __ref", () => {
      let capturedElement: HTMLElement | null = null;

      // Simulates: <div ref={(el) => capturedElement = el}>content</div>
      const node = jsxRuntime("div", {
        ref: (el: HTMLElement) => { capturedElement = el; },
        children: "content",
      });

      render(container, node);

      expect(capturedElement).not.toBeNull();
      expect(capturedElement?.tagName).toBe("DIV");
      expect(capturedElement?.textContent).toBe("content");
    });

    test("jsx-runtime ref works with input elements", () => {
      let inputRef: HTMLInputElement | null = null;

      // Simulates: <input type="text" ref={(el) => inputRef = el} />
      const node = jsxRuntime("input", {
        type: "text",
        ref: (el: HTMLInputElement) => { inputRef = el; },
      });

      render(container, node);

      expect(inputRef).not.toBeNull();
      expect(inputRef?.tagName).toBe("INPUT");
      expect(inputRef?.type).toBe("text");

      // Test that we can use the ref to focus the input
      inputRef?.focus();
      expect(document.activeElement).toBe(inputRef);
    });

    test("ref callback provides access to DOM properties", () => {
      let capturedId: string | null = null;

      const node = createElement(
        "input",
        [
          attr("id", AttrValue.Static("test-input")),
          attr("type", AttrValue.Static("text")),
          attr("__ref", AttrValue.Handler((el: unknown) => {
            capturedId = (el as HTMLInputElement).id;
          })),
        ],
        []
      );

      render(container, node);

      expect(capturedId).toBe("test-input");
    });

    test("ref callback can call DOM methods", () => {
      let inputElement: HTMLInputElement | null = null;

      const node = createElement(
        "input",
        [
          attr("type", AttrValue.Static("text")),
          attr("__ref", AttrValue.Handler((el: unknown) => {
            inputElement = el as HTMLInputElement;
          })),
        ],
        []
      );

      render(container, node);

      expect(inputElement).not.toBeNull();
      // Call focus() via ref
      inputElement?.focus();
      expect(document.activeElement).toBe(inputElement);
    });

    test("ref callback with nested elements", () => {
      const refs: HTMLElement[] = [];

      const node = createElement(
        "div",
        [attr("__ref", AttrValue.Handler((el: unknown) => refs.push(el as HTMLElement)))],
        [
          createElement(
            "span",
            [attr("__ref", AttrValue.Handler((el: unknown) => refs.push(el as HTMLElement)))],
            [text("nested")]
          ),
        ]
      );

      render(container, node);

      // Both refs should be captured
      expect(refs.length).toBe(2);
      // Note: Children are processed before parent attributes, so span comes first
      const tagNames = refs.map(el => el.tagName).sort();
      expect(tagNames).toEqual(["DIV", "SPAN"]);
    });
  });

  describe("createElementNs (SVG support)", () => {
    test("svgNs returns correct namespace", () => {
      expect(svgNs()).toBe("http://www.w3.org/2000/svg");
    });

    test("mathmlNs returns correct namespace", () => {
      expect(mathmlNs()).toBe("http://www.w3.org/1998/Math/MathML");
    });

    test("createElementNs creates SVG element with correct namespace", () => {
      const node = createElementNs(svgNs(), "svg", [], []);
      render(container, node);
      const svg = container.querySelector("svg");
      expect(svg).not.toBeNull();
      expect(svg?.namespaceURI).toBe("http://www.w3.org/2000/svg");
    });

    test("createElementNs creates SVG child elements", () => {
      const rect = createElementNs(
        svgNs(),
        "rect",
        [
          attr("x", AttrValue.Static("10")),
          attr("y", AttrValue.Static("10")),
          attr("width", AttrValue.Static("100")),
          attr("height", AttrValue.Static("50")),
          attr("fill", AttrValue.Static("blue")),
        ],
        []
      );
      const svg = createElementNs(
        svgNs(),
        "svg",
        [
          attr("width", AttrValue.Static("200")),
          attr("height", AttrValue.Static("200")),
        ],
        [rect]
      );
      render(container, svg);

      const svgEl = container.querySelector("svg");
      const rectEl = container.querySelector("rect");
      expect(svgEl).not.toBeNull();
      expect(rectEl).not.toBeNull();
      expect(rectEl?.namespaceURI).toBe("http://www.w3.org/2000/svg");
      expect(rectEl?.getAttribute("fill")).toBe("blue");
    });

    test("createElementNs works with circle and path", () => {
      const circle = createElementNs(
        svgNs(),
        "circle",
        [
          attr("cx", AttrValue.Static("50")),
          attr("cy", AttrValue.Static("50")),
          attr("r", AttrValue.Static("25")),
        ],
        []
      );
      const path = createElementNs(
        svgNs(),
        "path",
        [attr("d", AttrValue.Static("M 10 10 L 50 50"))],
        []
      );
      const g = createElementNs(svgNs(), "g", [], [circle, path]);
      const svg = createElementNs(svgNs(), "svg", [], [g]);
      render(container, svg);

      expect(container.querySelector("circle")).not.toBeNull();
      expect(container.querySelector("path")).not.toBeNull();
      expect(container.querySelector("g")).not.toBeNull();
    });

    test("createElementNs with dynamic attribute", () => {
      const [fill, setFill] = createSignal("red");
      const rect = createElementNs(
        svgNs(),
        "rect",
        [
          attr("width", AttrValue.Static("100")),
          attr("height", AttrValue.Static("100")),
          attr("fill", AttrValue.Dynamic(fill)),
        ],
        []
      );
      const svg = createElementNs(svgNs(), "svg", [], [rect]);
      render(container, svg);

      const rectEl = container.querySelector("rect");
      expect(rectEl?.getAttribute("fill")).toBe("red");

      setFill("green");
      expect(rectEl?.getAttribute("fill")).toBe("green");
    });

    test("SVG can be nested inside regular HTML elements", () => {
      const circle = createElementNs(
        svgNs(),
        "circle",
        [
          attr("cx", AttrValue.Static("50")),
          attr("cy", AttrValue.Static("50")),
          attr("r", AttrValue.Static("25")),
        ],
        []
      );
      const svg = createElementNs(
        svgNs(),
        "svg",
        [
          attr("width", AttrValue.Static("100")),
          attr("height", AttrValue.Static("100")),
        ],
        [circle]
      );
      const div = createElement("div", [], [svg]);
      render(container, div);

      const divEl = container.querySelector("div");
      const svgEl = container.querySelector("svg");
      expect(divEl).not.toBeNull();
      expect(svgEl?.parentElement).toBe(divEl);
      expect(svgEl?.namespaceURI).toBe("http://www.w3.org/2000/svg");
    });
  });

  describe("forEach with SVG elements", () => {
    test("forEach renders SVG elements", () => {
      const [items, setItems] = createSignal([
        { id: "1", x: 10, y: 10 },
        { id: "2", x: 50, y: 50 },
      ]);

      const forEachNode = forEach(
        items,
        (item) =>
          createElementNs(
            svgNs(),
            "rect",
            [
              attr("data-id", AttrValue.Static(item.id)),
              attr("x", AttrValue.Static(String(item.x))),
              attr("y", AttrValue.Static(String(item.y))),
              attr("width", AttrValue.Static("20")),
              attr("height", AttrValue.Static("20")),
            ],
            []
          )
      );

      const svg = createElementNs(
        svgNs(),
        "svg",
        [
          attr("width", AttrValue.Static("200")),
          attr("height", AttrValue.Static("200")),
        ],
        [forEachNode]
      );

      render(container, svg);

      const rects = container.querySelectorAll("rect");
      expect(rects.length).toBe(2);
      expect(rects[0].getAttribute("data-id")).toBe("1");
      expect(rects[1].getAttribute("data-id")).toBe("2");
    });

    test("forEach updates SVG elements when signal changes", () => {
      const [items, setItems] = createSignal([{ id: "1", x: 10 }]);

      const forEachNode = forEach(
        items,
        (item) =>
          createElementNs(
            svgNs(),
            "circle",
            [
              attr("data-id", AttrValue.Static(item.id)),
              attr("cx", AttrValue.Static(String(item.x))),
              attr("cy", AttrValue.Static("50")),
              attr("r", AttrValue.Static("10")),
            ],
            []
          )
      );

      const svg = createElementNs(svgNs(), "svg", [], [forEachNode]);
      render(container, svg);

      expect(container.querySelectorAll("circle").length).toBe(1);

      // Add item
      setItems([
        { id: "1", x: 10 },
        { id: "2", x: 50 },
      ]);
      expect(container.querySelectorAll("circle").length).toBe(2);

      // Remove item
      setItems([{ id: "2", x: 50 }]);
      expect(container.querySelectorAll("circle").length).toBe(1);
      expect(container.querySelector("circle")?.getAttribute("data-id")).toBe("2");
    });

    test("forEach handles reordering in SVG", () => {
      const item1 = { id: "a", x: 10 };
      const item2 = { id: "b", x: 20 };
      const item3 = { id: "c", x: 30 };

      const [items, setItems] = createSignal([item1, item2, item3]);

      const forEachNode = forEach(
        items,
        (item) =>
          createElementNs(
            svgNs(),
            "rect",
            [attr("data-id", AttrValue.Static(item.id))],
            []
          )
      );

      const svg = createElementNs(svgNs(), "svg", [], [forEachNode]);
      render(container, svg);

      const getIds = () =>
        Array.from(container.querySelectorAll("rect")).map((r) =>
          r.getAttribute("data-id")
        );

      expect(getIds()).toEqual(["a", "b", "c"]);

      // Reorder
      setItems([item3, item1, item2]);
      expect(getIds()).toEqual(["c", "a", "b"]);

      // Reverse
      setItems([item2, item1, item3]);
      expect(getIds()).toEqual(["b", "a", "c"]);
    });

    test("forEach with nested SVG groups", () => {
      const [groups, setGroups] = createSignal([
        { id: "g1", items: ["a", "b"] },
        { id: "g2", items: ["c", "d"] },
      ]);

      const forEachNode = forEach(
        groups,
        (group) =>
          createElementNs(
            svgNs(),
            "g",
            [attr("data-group", AttrValue.Static(group.id))],
            group.items.map((item) =>
              createElementNs(
                svgNs(),
                "rect",
                [attr("data-item", AttrValue.Static(item))],
                []
              )
            )
          )
      );

      const svg = createElementNs(svgNs(), "svg", [], [forEachNode]);
      render(container, svg);

      const g1 = container.querySelector('[data-group="g1"]');
      const g2 = container.querySelector('[data-group="g2"]');
      expect(g1?.querySelectorAll("rect").length).toBe(2);
      expect(g2?.querySelectorAll("rect").length).toBe(2);

      // Update groups
      setGroups([{ id: "g1", items: ["a", "b", "c"] }]);
      expect(container.querySelectorAll("g").length).toBe(1);
      expect(container.querySelectorAll("rect").length).toBe(3);
    });

    test("forEach handles empty to non-empty transition in SVG", () => {
      const [items, setItems] = createSignal<{ id: string }[]>([]);

      const forEachNode = forEach(
        items,
        (item) =>
          createElementNs(
            svgNs(),
            "circle",
            [attr("data-id", AttrValue.Static(item.id))],
            []
          )
      );

      const svg = createElementNs(svgNs(), "svg", [], [forEachNode]);
      render(container, svg);

      expect(container.querySelectorAll("circle").length).toBe(0);

      // Add items
      setItems([{ id: "1" }, { id: "2" }]);
      expect(container.querySelectorAll("circle").length).toBe(2);

      // Clear again
      setItems([]);
      expect(container.querySelectorAll("circle").length).toBe(0);
    });
  });
});
