/**
 * Integration tests for nested components, ForEach, and provide
 * These tests document current Luna API behavior and highlight differences from SolidJS
 */
import { describe, test, expect, beforeEach } from "vitest";
import {
  // Signal API (SolidJS-style)
  createSignal,
  createEffect,
  createRoot,
  // Context API
  createContext,
  provide,
  useContext,
  // DOM API
  createElement,
  text,
  render,
  mount,
  forEach,
  show,
} from "../src/index";

// MoonBit AttrValue constructors
const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
  Dynamic: (getter: () => string) => ({ $tag: 1, _0: getter }),
};

function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

describe("Integration: Nested Components with Context", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  describe("Context across component boundaries", () => {
    test("context flows through nested function components", () => {
      const themeCtx = createContext("light");
      const values: string[] = [];

      // Simulate nested component structure
      const GrandChild = () => {
        values.push(`grandchild: ${useContext(themeCtx)}`);
        return text(useContext(themeCtx));
      };

      const Child = () => {
        values.push(`child: ${useContext(themeCtx)}`);
        return createElement("span", [], [GrandChild()]);
      };

      const Parent = () => {
        values.push(`parent: ${useContext(themeCtx)}`);
        return createElement("div", [], [Child()]);
      };

      // Provide dark theme at root
      provide(themeCtx, "dark", () => {
        render(container, Parent());
      });

      expect(values).toEqual([
        "parent: dark",
        "child: dark",
        "grandchild: dark",
      ]);
      expect(container.textContent).toBe("dark");
    });

    test("nested provide overrides parent context", () => {
      const themeCtx = createContext("light");
      const values: string[] = [];

      const Inner = () => {
        values.push(useContext(themeCtx));
        return text(useContext(themeCtx));
      };

      const Middle = () => {
        // Override context for children
        return provide(themeCtx, "blue", () => {
          values.push(`middle sees: ${useContext(themeCtx)}`);
          return createElement("div", [], [Inner()]);
        });
      };

      const Outer = () => {
        values.push(`outer sees: ${useContext(themeCtx)}`);
        return createElement("div", [], [Middle()]);
      };

      provide(themeCtx, "dark", () => {
        render(container, Outer());
      });

      expect(values).toEqual([
        "outer sees: dark",
        "middle sees: blue",
        "blue",
      ]);
    });

    test("multiple contexts work independently", () => {
      const themeCtx = createContext("light");
      const langCtx = createContext("en");
      const sizeCtx = createContext("medium");

      let capturedTheme: string;
      let capturedLang: string;
      let capturedSize: string;

      const DeepComponent = () => {
        capturedTheme = useContext(themeCtx);
        capturedLang = useContext(langCtx);
        capturedSize = useContext(sizeCtx);
        return text("deep");
      };

      provide(themeCtx, "dark", () => {
        provide(langCtx, "ja", () => {
          // sizeCtx not provided, should use default
          render(container, DeepComponent());
        });
      });

      expect(capturedTheme!).toBe("dark");
      expect(capturedLang!).toBe("ja");
      expect(capturedSize!).toBe("medium"); // default
    });
  });

  describe("ForEach with reactive updates", () => {
    test("forEach renders initial list", () => {
      const [items] = createSignal(["a", "b", "c"]);

      const List = () =>
        createElement(
          "ul",
          [],
          [
            forEach(items, (item, index) =>
              createElement(
                "li",
                [attr("data-index", AttrValue.Static(String(index)))],
                [text(item)]
              )
            ),
          ]
        );

      render(container, List());

      const lis = container.querySelectorAll("li");
      expect(lis.length).toBe(3);
      expect(lis[0].textContent).toBe("a");
      expect(lis[1].textContent).toBe("b");
      expect(lis[2].textContent).toBe("c");
    });

    test("forEach updates when signal changes", () => {
      const [items, setItems] = createSignal(["x", "y"]);

      createRoot((dispose) => {
        const List = () =>
          createElement("ul", [], [
            forEach(items, (item) => createElement("li", [], [text(item)])),
          ]);

        render(container, List());

        expect(container.querySelectorAll("li").length).toBe(2);

        // Update the list
        setItems(["x", "y", "z"]);

        expect(container.querySelectorAll("li").length).toBe(3);
        expect(container.querySelectorAll("li")[2].textContent).toBe("z");

        dispose();
      });
    });

    test("forEach with object items", () => {
      interface User {
        id: number;
        name: string;
      }

      const [users] = createSignal<User[]>([
        { id: 1, name: "Alice" },
        { id: 2, name: "Bob" },
      ]);

      createRoot((dispose) => {
        const UserList = () =>
          createElement("div", [], [
            forEach(users, (user) =>
              createElement(
                "div",
                [attr("data-id", AttrValue.Static(String(user.id)))],
                [text(user.name)]
              )
            ),
          ]);

        render(container, UserList());

        const divs = container.querySelectorAll("[data-id]");
        expect(divs.length).toBe(2);
        expect(divs[0].textContent).toBe("Alice");
        expect(divs[1].textContent).toBe("Bob");

        dispose();
      });
    });
  });

  describe("Context + ForEach integration", () => {
    test("forEach items can access context", () => {
      const prefixCtx = createContext("");
      const [items] = createSignal(["one", "two", "three"]);
      const renderedTexts: string[] = [];

      const ItemComponent = (item: string) => {
        const prefix = useContext(prefixCtx);
        const fullText = `${prefix}${item}`;
        renderedTexts.push(fullText);
        return createElement("span", [], [text(fullText)]);
      };

      provide(prefixCtx, "item-", () => {
        const List = () =>
          createElement("div", [], [
            forEach(items, (item) => ItemComponent(item)),
          ]);

        render(container, List());
      });

      expect(renderedTexts).toEqual(["item-one", "item-two", "item-three"]);
    });
  });

  describe("Show (conditional rendering)", () => {
    // NOTE: show() has a known limitation - it doesn't render initially when true
    // because the effect runs before the placeholder is in the DOM.
    // This is a design difference from SolidJS's <Show> component.

    test("show hides when condition is false", () => {
      const [visible] = createSignal(false);

      const node = show(visible, () =>
        createElement("span", [], [text("visible")])
      );

      mount(container, node);

      // When false, show renders a placeholder (comment node)
      expect(container.querySelector("span")).toBeNull();
    });

    test("show toggles from false to true", () => {
      // Start with false, then toggle to true
      const [visible, setVisible] = createSignal(false);

      const node = show(visible, () =>
        createElement("span", [], [text("content")])
      );

      mount(container, node);

      expect(container.querySelector("span")).toBeNull();

      // Toggle to true - this should work because placeholder is now in DOM
      setVisible(true);
      expect(container.querySelector("span")).not.toBeNull();

      // Toggle back to false
      setVisible(false);
      expect(container.querySelector("span")).toBeNull();
    });

    test("show renders when initial condition is true", () => {
      const [visible] = createSignal(true);

      const node = show(visible, () =>
        createElement("span", [], [text("visible")])
      );

      mount(container, node);

      expect(container.querySelector("span")).not.toBeNull();
    });
  });

  describe("Complex nested scenario", () => {
    /**
     * Luna's provide() is now Owner-based (component-tree-scoped).
     *
     * Context values are associated with Owners (reactive scopes).
     * When show() or forEach() render later, they inherit context from
     * the Owner that was active when they were created.
     *
     * This matches SolidJS's <Provider> behavior.
     */

    test("show and forEach inherit context from Owner (fixed)", () => {
      const themeCtx = createContext("light"); // default is "light"
      const [showList, setShowList] = createSignal(false);
      const [items, setItems] = createSignal(["A", "B"]);

      const ListItem = (item: string) => {
        const theme = useContext(themeCtx);
        return createElement(
          "li",
          [attr("class", AttrValue.Static(`item-${theme}`))],
          [text(item)]
        );
      };

      // Context is Owner-based: show/forEach must be created inside provide scope
      // to capture the Owner with the context value
      provide(themeCtx, "dark", () => {
        const listNode = show(showList, () =>
          createElement("ul", [], [forEach(items, (item) => ListItem(item))])
        );
        mount(container, listNode);
      });

      // Initially hidden
      expect(container.querySelector("ul")).toBeNull();

      // Toggle to visible - context should be "dark" (inherited from Owner)
      setShowList(true);
      let lis = container.querySelectorAll("li");
      expect(lis.length).toBe(2);
      // Context is "dark" because Owner-based context persists
      expect(lis[0].className).toBe("item-dark");

      // Toggle visibility
      setShowList(false);
      expect(container.querySelector("ul")).toBeNull();

      setShowList(true);
      lis = container.querySelectorAll("li");
      expect(lis.length).toBe(2);
      // Still "dark" after re-render
      expect(lis[0].className).toBe("item-dark");

      // Update items - new items should also get "dark" context
      setItems(["A", "B", "C"]);
      lis = container.querySelectorAll("li");
      expect(lis.length).toBe(3);
      expect(lis[2].className).toBe("item-dark");
    });

    test("context works with immediate rendering (non-deferred)", () => {
      const themeCtx = createContext("light");

      // Context works when rendering is synchronous
      provide(themeCtx, "dark", () => {
        const theme = useContext(themeCtx);
        const node = createElement(
          "div",
          [attr("class", AttrValue.Static(`theme-${theme}`))],
          [text(theme)]
        );
        mount(container, node);
      });

      const div = container.querySelector("div");
      expect(div?.className).toBe("theme-dark");
      expect(div?.textContent).toBe("dark");
    });

    test("forEach renders correctly without show (initial items)", () => {
      // This test shows that forEach initial render works,
      // but context is still function-scoped
      const [items, setItems] = createSignal(["A", "B"]);

      const listNode = createElement("ul", [], [
        forEach(items, (item) => createElement("li", [], [text(item)])),
      ]);

      mount(container, listNode);

      let lis = container.querySelectorAll("li");
      expect(lis.length).toBe(2);
      expect(lis[0].textContent).toBe("A");
      expect(lis[1].textContent).toBe("B");

      // Update items
      setItems(["X", "Y", "Z"]);
      lis = container.querySelectorAll("li");
      expect(lis.length).toBe(3);
      expect(lis[2].textContent).toBe("Z");
    });
  });
});
