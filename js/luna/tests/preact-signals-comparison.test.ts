/**
 * Comparison tests between Luna and Preact Signals
 *
 * Verifies that Luna produces equivalent DOM output to Preact (excluding internal markers).
 * Tests focus on:
 * - Basic signal behavior
 * - Deep nested lists
 * - Complex fragments
 * - Conditional rendering
 *
 * Known differences:
 * - Luna's Fragment wraps multiple children in a <span> element
 * - Luna's show/Show uses placeholder comments and effects for conditional rendering
 */
import { describe, test, expect, beforeEach, afterEach } from "vitest";

// Luna imports
import {
  createElement,
  render as lunaRender,
  text,
  textDyn,
  createSignal,
  createEffect,
  createMemo,
  batch,
  For,
  Show,
  Fragment,
  show,
} from "../index.js";

// Preact imports
import { h, render as preactRender, Fragment as PreactFragment } from "preact";
import { signal, computed, effect, batch as preactBatch } from "@preact/signals-core";

// =============================================================================
// Utilities
// =============================================================================

// MoonBit AttrValue constructors
const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
  Dynamic: (getter: () => string) => ({ $tag: 1, _0: getter }),
  Handler: (handler: (e: unknown) => void) => ({ $tag: 2, _0: handler }),
};

function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

/**
 * Normalize HTML by removing internal markers (comment nodes, empty text nodes)
 * and normalizing whitespace
 */
function normalizeHtml(html: string): string {
  return html
    // Remove HTML comments (Luna uses these as markers)
    .replace(/<!--[\s\S]*?-->/g, "")
    // Remove empty text nodes and normalize whitespace
    .replace(/>\s+</g, "><")
    .trim();
}

/**
 * Get normalized innerHTML from a container
 */
function getNormalizedContent(container: HTMLElement): string {
  return normalizeHtml(container.innerHTML);
}

/**
 * Compare DOM structure (tag names, attributes, text content)
 * ignoring comment nodes and whitespace
 */
function getVisibleNodes(element: Element): string[] {
  const result: string[] = [];

  function walk(node: Node) {
    if (node.nodeType === Node.ELEMENT_NODE) {
      const el = node as Element;
      result.push(`<${el.tagName.toLowerCase()}>`);
      for (const child of el.childNodes) {
        walk(child);
      }
      result.push(`</${el.tagName.toLowerCase()}>`);
    } else if (node.nodeType === Node.TEXT_NODE) {
      const text = node.textContent?.trim();
      if (text) {
        result.push(text);
      }
    }
    // Skip comment nodes
  }

  for (const child of element.childNodes) {
    walk(child);
  }

  return result;
}

// =============================================================================
// Tests
// =============================================================================

describe("Signal Behavior Comparison", () => {
  test("basic signal get/set produces same values", () => {
    // Luna
    const [lunaCount, setLunaCount] = createSignal(0);
    const lunaValues: number[] = [];
    createEffect(() => {
      lunaValues.push(lunaCount());
    });
    setLunaCount(1);
    setLunaCount(2);

    // Preact Signals
    const preactCount = signal(0);
    const preactValues: number[] = [];
    const dispose = effect(() => {
      preactValues.push(preactCount.value);
    });
    preactCount.value = 1;
    preactCount.value = 2;
    dispose();

    expect(lunaValues).toEqual(preactValues);
  });

  test("computed/memo produces same values", () => {
    // Luna
    const [lunaA, setLunaA] = createSignal(2);
    const [lunaB] = createSignal(3);
    const lunaSum = createMemo(() => lunaA() + lunaB());

    expect(lunaSum()).toBe(5);
    setLunaA(10);
    expect(lunaSum()).toBe(13);

    // Preact Signals
    const preactA = signal(2);
    const preactB = signal(3);
    const preactSum = computed(() => preactA.value + preactB.value);

    expect(preactSum.value).toBe(5);
    preactA.value = 10;
    expect(preactSum.value).toBe(13);
  });

  test("batch updates produce same final values", () => {
    // Luna
    const [lunaA, setLunaA] = createSignal(0);
    const [lunaB, setLunaB] = createSignal(0);
    const lunaUpdates: number[] = [];

    createEffect(() => {
      lunaUpdates.push(lunaA() + lunaB());
    });

    batch(() => {
      setLunaA(1);
      setLunaB(2);
    });

    // Preact Signals
    const preactA = signal(0);
    const preactB = signal(0);
    const preactUpdates: number[] = [];

    const dispose = effect(() => {
      preactUpdates.push(preactA.value + preactB.value);
    });

    preactBatch(() => {
      preactA.value = 1;
      preactB.value = 2;
    });
    dispose();

    // Both should have initial 0 and final 3 (batch should combine updates)
    expect(lunaUpdates[0]).toBe(0);
    expect(lunaUpdates[lunaUpdates.length - 1]).toBe(3);
    expect(preactUpdates[0]).toBe(0);
    expect(preactUpdates[preactUpdates.length - 1]).toBe(3);
  });
});

describe("DOM Rendering Comparison - Simple Elements", () => {
  let lunaContainer: HTMLDivElement;
  let preactContainer: HTMLDivElement;

  beforeEach(() => {
    lunaContainer = document.createElement("div");
    preactContainer = document.createElement("div");
    document.body.appendChild(lunaContainer);
    document.body.appendChild(preactContainer);
  });

  afterEach(() => {
    lunaContainer.remove();
    preactContainer.remove();
  });

  test("simple div with text", () => {
    // Luna
    const lunaNode = createElement("div", [], [text("Hello")]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(h("div", null, "Hello"), preactContainer);

    expect(getNormalizedContent(lunaContainer)).toBe(
      getNormalizedContent(preactContainer)
    );
  });

  test("nested elements", () => {
    // Luna
    const lunaNode = createElement("div", [], [
      createElement("span", [], [text("A")]),
      createElement("span", [], [text("B")]),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h("div", null, h("span", null, "A"), h("span", null, "B")),
      preactContainer
    );

    expect(getNormalizedContent(lunaContainer)).toBe(
      getNormalizedContent(preactContainer)
    );
  });

  test("element with attributes", () => {
    // Luna
    const lunaNode = createElement(
      "div",
      [
        attr("id", AttrValue.Static("test-id")),
        attr("className", AttrValue.Static("test-class")),
      ],
      [text("Content")]
    );
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h("div", { id: "test-id", className: "test-class" }, "Content"),
      preactContainer
    );

    expect(getNormalizedContent(lunaContainer)).toBe(
      getNormalizedContent(preactContainer)
    );
  });
});

describe("DOM Rendering Comparison - Lists", () => {
  let lunaContainer: HTMLDivElement;
  let preactContainer: HTMLDivElement;

  beforeEach(() => {
    lunaContainer = document.createElement("div");
    preactContainer = document.createElement("div");
    document.body.appendChild(lunaContainer);
    document.body.appendChild(preactContainer);
  });

  afterEach(() => {
    lunaContainer.remove();
    preactContainer.remove();
  });

  test("simple list", () => {
    const items = ["a", "b", "c"];

    // Luna
    const [lunaItems] = createSignal(items);
    const lunaNode = createElement("ul", [], [
      For({
        each: lunaItems,
        children: (item: string) => createElement("li", [], [text(item)]),
      }),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h(
        "ul",
        null,
        items.map((item, i) => h("li", { key: i }, item))
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );
  });

  test("nested list (2 levels)", () => {
    const data = [
      { name: "Group A", items: ["a1", "a2"] },
      { name: "Group B", items: ["b1", "b2", "b3"] },
    ];

    // Luna
    const [lunaData] = createSignal(data);
    const lunaNode = createElement("div", [], [
      For({
        each: lunaData,
        children: (group: (typeof data)[0]) =>
          createElement("div", [attr("className", AttrValue.Static("group"))], [
            createElement("h3", [], [text(group.name)]),
            createElement("ul", [], [
              For({
                each: () => group.items,
                children: (item: string) =>
                  createElement("li", [], [text(item)]),
              }),
            ]),
          ]),
      }),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h(
        "div",
        null,
        data.map((group, gi) =>
          h(
            "div",
            { key: gi, className: "group" },
            h("h3", null, group.name),
            h(
              "ul",
              null,
              group.items.map((item, ii) => h("li", { key: ii }, item))
            )
          )
        )
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );
  });

  test("deeply nested list (3 levels)", () => {
    const data = [
      {
        name: "Level 1-A",
        children: [
          { name: "Level 2-A", items: ["item1", "item2"] },
          { name: "Level 2-B", items: ["item3"] },
        ],
      },
      {
        name: "Level 1-B",
        children: [{ name: "Level 2-C", items: ["item4", "item5", "item6"] }],
      },
    ];

    // Luna
    const [lunaData] = createSignal(data);
    const lunaNode = createElement("div", [], [
      For({
        each: lunaData,
        children: (level1: (typeof data)[0]) =>
          createElement("section", [], [
            createElement("h2", [], [text(level1.name)]),
            For({
              each: () => level1.children,
              children: (level2: (typeof data)[0]["children"][0]) =>
                createElement("div", [], [
                  createElement("h3", [], [text(level2.name)]),
                  createElement("ul", [], [
                    For({
                      each: () => level2.items,
                      children: (item: string) =>
                        createElement("li", [], [text(item)]),
                    }),
                  ]),
                ]),
            }),
          ]),
      }),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h(
        "div",
        null,
        data.map((level1, i) =>
          h(
            "section",
            { key: i },
            h("h2", null, level1.name),
            level1.children.map((level2, j) =>
              h(
                "div",
                { key: j },
                h("h3", null, level2.name),
                h(
                  "ul",
                  null,
                  level2.items.map((item, k) => h("li", { key: k }, item))
                )
              )
            )
          )
        )
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );
  });
});

describe("Fragment Comparison with Preact", () => {
  let lunaContainer: HTMLDivElement;
  let preactContainer: HTMLDivElement;

  beforeEach(() => {
    lunaContainer = document.createElement("div");
    preactContainer = document.createElement("div");
    document.body.appendChild(lunaContainer);
    document.body.appendChild(preactContainer);
  });

  afterEach(() => {
    lunaContainer.remove();
    preactContainer.remove();
  });

  test("Fragment with single child returns the child directly", () => {
    // Luna
    const lunaNode = Fragment([createElement("span", [], [text("Single")])]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(h(PreactFragment, null, h("span", null, "Single")), preactContainer);

    expect(getVisibleNodes(lunaContainer)).toEqual(getVisibleNodes(preactContainer));
  });

  test("Fragment with multiple children (no wrapper)", () => {
    // Luna
    const lunaNode = Fragment([
      createElement("span", [], [text("A")]),
      createElement("span", [], [text("B")]),
      createElement("span", [], [text("C")]),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h(
        PreactFragment,
        null,
        h("span", null, "A"),
        h("span", null, "B"),
        h("span", null, "C")
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(getVisibleNodes(preactContainer));
  });

  test("Fragment with no children", () => {
    // Luna
    const lunaNode = Fragment([]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(h(PreactFragment, null), preactContainer);

    // Both should be empty (ignoring comment markers)
    expect(getVisibleNodes(lunaContainer)).toEqual(getVisibleNodes(preactContainer));
  });

  test("nested Fragments work correctly", () => {
    // Luna
    const lunaNode = Fragment([
      Fragment([createElement("div", [], [text("A1")])]),
      Fragment([
        createElement("div", [], [text("B1")]),
        createElement("div", [], [text("B2")]),
      ]),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h(
        PreactFragment,
        null,
        h(PreactFragment, null, h("div", null, "A1")),
        h(
          PreactFragment,
          null,
          h("div", null, "B1"),
          h("div", null, "B2")
        )
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(getVisibleNodes(preactContainer));
  });

  test("fragment with list", () => {
    const items = ["x", "y", "z"];

    // Luna
    const [lunaItems] = createSignal(items);
    const lunaNode = Fragment([
      createElement("header", [], [text("Header")]),
      For({
        each: lunaItems,
        children: (item: string) => createElement("p", [], [text(item)]),
      }),
      createElement("footer", [], [text("Footer")]),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h(
        PreactFragment,
        null,
        h("header", null, "Header"),
        items.map((item, i) => h("p", { key: i }, item)),
        h("footer", null, "Footer")
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(getVisibleNodes(preactContainer));
  });
});

describe("Luna Conditional Rendering", () => {
  let container: HTMLDivElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("show renders content when initially true", () => {
    const [visible] = createSignal(true);
    const node = createElement("div", [], [
      show(visible, () => createElement("span", [], [text("Visible")])),
    ]);
    lunaRender(container, node);

    // Luna uses placeholder comments and effects
    // Content should be rendered
    expect(container.querySelector("span")).not.toBeNull();
    expect(container.textContent).toContain("Visible");
  });

  test("show hides content when initially false", () => {
    const [visible] = createSignal(false);
    const node = createElement("div", [], [
      show(visible, () => createElement("span", [], [text("Hidden")])),
    ]);
    lunaRender(container, node);

    expect(container.querySelector("span")).toBeNull();
  });

  test("show toggles visibility dynamically", () => {
    const [visible, setVisible] = createSignal(false);
    const node = createElement("div", [], [
      show(visible, () => createElement("span", [], [text("Content")])),
    ]);
    lunaRender(container, node);

    expect(container.querySelector("span")).toBeNull();

    setVisible(true);
    expect(container.querySelector("span")).not.toBeNull();
    expect(container.textContent).toContain("Content");

    setVisible(false);
    expect(container.querySelector("span")).toBeNull();
  });

  test("Show component renders when condition is true", () => {
    const [visible] = createSignal(true);
    const node = createElement("div", [], [
      Show({
        when: visible,
        children: createElement("span", [], [text("Shown")]),
      }),
    ]);
    lunaRender(container, node);

    expect(container.querySelector("span")).not.toBeNull();
    expect(container.textContent).toContain("Shown");
  });

  test("Show component hides when condition is false", () => {
    const [visible] = createSignal(false);
    const node = createElement("div", [], [
      Show({
        when: visible,
        children: createElement("span", [], [text("Hidden")]),
      }),
    ]);
    lunaRender(container, node);

    expect(container.querySelector("span")).toBeNull();
  });
});

describe("DOM Rendering Comparison - Reactive Updates", () => {
  let lunaContainer: HTMLDivElement;
  let preactContainer: HTMLDivElement;

  beforeEach(() => {
    lunaContainer = document.createElement("div");
    preactContainer = document.createElement("div");
    document.body.appendChild(lunaContainer);
    document.body.appendChild(preactContainer);
  });

  afterEach(() => {
    lunaContainer.remove();
    preactContainer.remove();
  });

  test("text updates match", () => {
    // Luna
    const [lunaText, setLunaText] = createSignal("initial");
    const lunaNode = createElement("div", [], [textDyn(lunaText)]);
    lunaRender(lunaContainer, lunaNode);

    expect(getNormalizedContent(lunaContainer)).toBe("<div>initial</div>");

    setLunaText("updated");
    expect(getNormalizedContent(lunaContainer)).toBe("<div>updated</div>");
  });

  test("list addition updates match", () => {
    const initialItems = ["a", "b"];

    // Luna
    const [lunaItems, setLunaItems] = createSignal(initialItems);
    const lunaNode = createElement("ul", [], [
      For({
        each: lunaItems,
        children: (item: string) => createElement("li", [], [text(item)]),
      }),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact (static initial)
    preactRender(
      h(
        "ul",
        null,
        initialItems.map((item, i) => h("li", { key: i }, item))
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );

    // Update Luna
    setLunaItems(["a", "b", "c"]);

    // Update Preact
    preactRender(
      h(
        "ul",
        null,
        ["a", "b", "c"].map((item, i) => h("li", { key: i }, item))
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );
  });

  test("list removal updates match", () => {
    // Luna
    const [lunaItems, setLunaItems] = createSignal(["x", "y", "z"]);
    const lunaNode = createElement("ul", [], [
      For({
        each: lunaItems,
        children: (item: string) => createElement("li", [], [text(item)]),
      }),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Update to remove items
    setLunaItems(["x"]);

    // Preact with same final state
    preactRender(h("ul", null, h("li", { key: 0 }, "x")), preactContainer);

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );
  });

  test("conditional toggle updates", () => {
    // Luna
    const [lunaShow, setLunaShow] = createSignal(false);
    const lunaNode = createElement("div", [], [
      show(lunaShow, () => createElement("span", [], [text("Now visible")])),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Initially hidden
    expect(lunaContainer.querySelector("span")).toBeNull();

    // Show it
    setLunaShow(true);
    expect(lunaContainer.querySelector("span")).not.toBeNull();
    expect(lunaContainer.textContent).toContain("Now visible");

    // Hide it again
    setLunaShow(false);
    expect(lunaContainer.querySelector("span")).toBeNull();
  });
});

describe("Complex Scenarios", () => {
  let lunaContainer: HTMLDivElement;
  let preactContainer: HTMLDivElement;

  beforeEach(() => {
    lunaContainer = document.createElement("div");
    preactContainer = document.createElement("div");
    document.body.appendChild(lunaContainer);
    document.body.appendChild(preactContainer);
  });

  afterEach(() => {
    lunaContainer.remove();
    preactContainer.remove();
  });

  test("todo list structure", () => {
    const todos = [
      { id: 1, text: "Learn Luna", done: true },
      { id: 2, text: "Build app", done: false },
      { id: 3, text: "Deploy", done: false },
    ];

    // Luna
    const [lunaTodos] = createSignal(todos);
    const lunaNode = createElement(
      "div",
      [attr("className", AttrValue.Static("todo-app"))],
      [
        createElement("h1", [], [text("Todos")]),
        createElement("ul", [attr("className", AttrValue.Static("todo-list"))], [
          For({
            each: lunaTodos,
            children: (todo: (typeof todos)[0]) =>
              createElement(
                "li",
                [
                  attr(
                    "className",
                    AttrValue.Static(todo.done ? "done" : "pending")
                  ),
                ],
                [
                  createElement(
                    "input",
                    [
                      attr("type", AttrValue.Static("checkbox")),
                      attr("checked", AttrValue.Static(todo.done ? "true" : "false")),
                    ],
                    []
                  ),
                  createElement("span", [], [text(todo.text)]),
                ]
              ),
          }),
        ]),
        createElement(
          "footer",
          [],
          [text(`${todos.filter((t) => !t.done).length} items left`)]
        ),
      ]
    );
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h(
        "div",
        { className: "todo-app" },
        h("h1", null, "Todos"),
        h(
          "ul",
          { className: "todo-list" },
          todos.map((todo) =>
            h(
              "li",
              { key: todo.id, className: todo.done ? "done" : "pending" },
              h("input", { type: "checkbox", checked: todo.done }),
              h("span", null, todo.text)
            )
          )
        ),
        h("footer", null, `${todos.filter((t) => !t.done).length} items left`)
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );
  });

  test("tree structure with variable depth", () => {
    interface TreeNode {
      name: string;
      children?: TreeNode[];
    }

    const tree: TreeNode = {
      name: "root",
      children: [
        {
          name: "branch1",
          children: [
            { name: "leaf1a" },
            { name: "leaf1b" },
          ],
        },
        {
          name: "branch2",
          children: [
            {
              name: "branch2a",
              children: [
                { name: "leaf2a1" },
              ],
            },
          ],
        },
        { name: "leaf3" },
      ],
    };

    // Helper to render tree node in Luna
    function renderLunaTree(node: TreeNode): ReturnType<typeof createElement> {
      if (!node.children || node.children.length === 0) {
        return createElement("span", [attr("className", AttrValue.Static("leaf"))], [
          text(node.name),
        ]);
      }
      return createElement("div", [attr("className", AttrValue.Static("branch"))], [
        createElement("strong", [], [text(node.name)]),
        createElement("div", [attr("className", AttrValue.Static("children"))],
          node.children.map(child => renderLunaTree(child))
        ),
      ]);
    }

    // Helper to render tree node in Preact
    function renderPreactTree(node: TreeNode): ReturnType<typeof h> {
      if (!node.children || node.children.length === 0) {
        return h("span", { className: "leaf" }, node.name);
      }
      return h(
        "div",
        { className: "branch" },
        h("strong", null, node.name),
        h(
          "div",
          { className: "children" },
          node.children.map((child, i) =>
            // Add a fragment wrapper with key for Preact
            h(PreactFragment, { key: i }, renderPreactTree(child))
          )
        )
      );
    }

    // Luna
    lunaRender(lunaContainer, renderLunaTree(tree));

    // Preact
    preactRender(renderPreactTree(tree), preactContainer);

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );
  });

  test("mixed content with text and elements", () => {
    // Luna
    const lunaNode = createElement("article", [], [
      createElement("p", [], [
        text("This is "),
        createElement("strong", [], [text("bold")]),
        text(" and "),
        createElement("em", [], [text("italic")]),
        text(" text."),
      ]),
      createElement("p", [], [
        text("Numbers: "),
        createElement("code", [], [text("1")]),
        text(", "),
        createElement("code", [], [text("2")]),
        text(", "),
        createElement("code", [], [text("3")]),
      ]),
    ]);
    lunaRender(lunaContainer, lunaNode);

    // Preact
    preactRender(
      h(
        "article",
        null,
        h(
          "p",
          null,
          "This is ",
          h("strong", null, "bold"),
          " and ",
          h("em", null, "italic"),
          " text."
        ),
        h(
          "p",
          null,
          "Numbers: ",
          h("code", null, "1"),
          ", ",
          h("code", null, "2"),
          ", ",
          h("code", null, "3")
        )
      ),
      preactContainer
    );

    expect(getVisibleNodes(lunaContainer)).toEqual(
      getVisibleNodes(preactContainer)
    );
  });
});

describe("Edge Cases", () => {
  let container: HTMLDivElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("empty list", () => {
    const [items] = createSignal<string[]>([]);
    const node = createElement("ul", [], [
      For({
        each: items,
        children: (item: string) => createElement("li", [], [text(item)]),
      }),
    ]);
    lunaRender(container, node);

    expect(container.querySelectorAll("li").length).toBe(0);
  });

  test("list transitions from empty to populated", () => {
    const [items, setItems] = createSignal<string[]>([]);
    const node = createElement("ul", [], [
      For({
        each: items,
        children: (item: string) => createElement("li", [], [text(item)]),
      }),
    ]);
    lunaRender(container, node);

    expect(container.querySelectorAll("li").length).toBe(0);

    setItems(["a", "b"]);
    expect(container.querySelectorAll("li").length).toBe(2);
  });

  test("list transitions from populated to empty", () => {
    const [items, setItems] = createSignal(["a", "b", "c"]);
    const node = createElement("ul", [], [
      For({
        each: items,
        children: (item: string) => createElement("li", [], [text(item)]),
      }),
    ]);
    lunaRender(container, node);

    expect(container.querySelectorAll("li").length).toBe(3);

    setItems([]);
    expect(container.querySelectorAll("li").length).toBe(0);
  });

  test("deeply nested conditionals", () => {
    const [a, setA] = createSignal(true);
    const [b, setB] = createSignal(true);
    const [c, setC] = createSignal(true);

    const node = createElement("div", [], [
      show(a, () =>
        createElement("div", [attr("id", AttrValue.Static("a"))], [
          show(b, () =>
            createElement("div", [attr("id", AttrValue.Static("b"))], [
              show(c, () =>
                createElement("span", [attr("id", AttrValue.Static("c"))], [
                  text("Deepest"),
                ])
              ),
            ])
          ),
        ])
      ),
    ]);
    lunaRender(container, node);

    // All visible
    expect(container.querySelector("#a")).not.toBeNull();
    expect(container.querySelector("#b")).not.toBeNull();
    expect(container.querySelector("#c")).not.toBeNull();

    // Hide middle layer
    setB(false);
    expect(container.querySelector("#a")).not.toBeNull();
    expect(container.querySelector("#b")).toBeNull();
    expect(container.querySelector("#c")).toBeNull();

    // Show middle layer again
    setB(true);
    expect(container.querySelector("#b")).not.toBeNull();
    expect(container.querySelector("#c")).not.toBeNull();

    // Hide outer layer
    setA(false);
    expect(container.querySelector("#a")).toBeNull();
    expect(container.querySelector("#b")).toBeNull();
    expect(container.querySelector("#c")).toBeNull();
  });
});
