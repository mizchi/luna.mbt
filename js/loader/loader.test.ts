import { describe, test, expect, beforeEach, afterEach } from "vitest";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load the loader script from dist/ (IIFE bundled version for eval)
const loaderCode = readFileSync(join(__dirname, "dist", "loader.iife.js"), "utf-8");

describe("Luna Loader", () => {
  let originalMutationObserver: typeof MutationObserver;

  beforeEach(() => {
    document.body.innerHTML = "";
    // Reset global state
    (window as any).__LN_STATE__ = undefined;
    (window as any).__LN_HYDRATE__ = undefined;
    (window as any).__LN_SCAN__ = undefined;

    // Mock MutationObserver to prevent interference
    originalMutationObserver = window.MutationObserver;
    window.MutationObserver = class MockMutationObserver {
      observe() {}
      disconnect() {}
      takeRecords() { return []; }
    } as any;
  });

  afterEach(() => {
    document.body.innerHTML = "";
    window.MutationObserver = originalMutationObserver;
  });

  function initLoader() {
    eval(loaderCode);
  }

  // Helper to find elements with ln:id attribute (jsdom has issues with querySelector for namespaced attrs)
  function findIslandById(id: string): Element | null {
    const divs = document.querySelectorAll("div");
    for (const div of divs) {
      if (div.getAttribute("ln:id") === id) return div;
    }
    return null;
  }

  describe("State Extraction from ln/json scripts", () => {
    test("extracts state from script with id", () => {
      document.body.innerHTML = `
        <script type="ln/json" id="counter">[1,2,3]</script>
      `;
      initLoader();

      expect((window as any).__LN_STATE__).toBeDefined();
      expect((window as any).__LN_STATE__["counter"]).toEqual([1, 2, 3]);
    });

    test("extracts multiple named states", () => {
      document.body.innerHTML = `
        <script type="ln/json" id="counter">[10]</script>
        <script type="ln/json" id="form">["alice","alice@example.com"]</script>
        <script type="ln/json" id="settings">[true,16]</script>
      `;
      initLoader();

      const state = (window as any).__LN_STATE__;
      expect(state["counter"]).toEqual([10]);
      expect(state["form"]).toEqual(["alice", "alice@example.com"]);
      expect(state["settings"]).toEqual([true, 16]);
    });

    test("handles empty state", () => {
      document.body.innerHTML = `
        <script type="ln/json" id="empty">[]</script>
      `;
      initLoader();

      expect((window as any).__LN_STATE__["empty"]).toEqual([]);
    });

    test("handles complex state values", () => {
      document.body.innerHTML = `
        <script type="ln/json" id="complex">[42,"hello",true,false,null,3.14]</script>
      `;
      initLoader();

      expect((window as any).__LN_STATE__["complex"]).toEqual([
        42,
        "hello",
        true,
        false,
        null,
        3.14,
      ]);
    });

    test("handles object state", () => {
      document.body.innerHTML = `
        <script type="ln/json" id="obj">{"count":5,"name":"test"}</script>
      `;
      initLoader();

      expect((window as any).__LN_STATE__["obj"]).toEqual({ count: 5, name: "test" });
    });
  });

  describe("API Availability", () => {
    test("__LN_STATE__ is available", () => {
      document.body.innerHTML = "";
      initLoader();

      expect((window as any).__LN_STATE__).toBeDefined();
      expect(typeof (window as any).__LN_STATE__).toBe("object");
    });

    test("__LN_HYDRATE__ is available", () => {
      document.body.innerHTML = "";
      initLoader();

      expect(typeof (window as any).__LN_HYDRATE__).toBe("function");
    });

    test("__LN_SCAN__ is available", () => {
      document.body.innerHTML = "";
      initLoader();

      expect(typeof (window as any).__LN_SCAN__).toBe("function");
    });
  });

  describe("Island Attributes", () => {
    test("elements can have ln:id attribute", () => {
      document.body.innerHTML = `<div ln:id="counter">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:id")).toBe("counter");
    });

    test("elements can have ln:url attribute", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:url")).toBe("./counter.js");
    });

    test("elements can have ln:trigger attribute", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js" ln:trigger="idle">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:trigger")).toBe("idle");
    });

    test("elements can have ln:state attribute with inline JSON", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js" ln:state='{"count":5}'>Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:state")).toBe('{"count":5}');
    });

    test("elements can have ln:state attribute with script reference", () => {
      document.body.innerHTML = `
        <script type="ln/json" id="counter-state">{"count":10}</script>
        <div ln:id="counter" ln:url="./counter.js" ln:state="#counter-state">Counter</div>
      `;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:state")).toBe("#counter-state");
    });

    test("elements can have ln:export attribute", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js" ln:export="hydrateCounter">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:export")).toBe("hydrateCounter");
    });
  });

  describe("Island HTML Structure", () => {
    test("complete island HTML structure", () => {
      const html = `
        <script type="ln/json" id="counter-state">{"count":10}</script>
        <div ln:id="counter" ln:url="./counter.js" ln:state="#counter-state" ln:trigger="load">
          <span id="count">10</span>
          <button class="inc">+1</button>
          <button class="dec">-1</button>
        </div>

        <script type="ln/json" id="todo-state">{"text":"Buy milk","done":false}</script>
        <div ln:id="todo" ln:url="./todo.js" ln:state="#todo-state" ln:trigger="visible">
          <input id="todo-input" value="Buy milk" />
          <input type="checkbox" />
        </div>
      `;

      document.body.innerHTML = html;
      initLoader();

      const state = (window as any).__LN_STATE__;

      // Verify state extraction
      expect(state["counter-state"]).toEqual({ count: 10 });
      expect(state["todo-state"]).toEqual({ text: "Buy milk", done: false });

      // Verify DOM structure
      expect(document.getElementById("count")?.textContent).toBe("10");
      expect((document.getElementById("todo-input") as HTMLInputElement)?.value).toBe("Buy milk");

      // Verify island attributes
      const counterEl = findIslandById("counter");
      expect(counterEl).not.toBeNull();
      expect(counterEl!.getAttribute("ln:url")).toBe("./counter.js");
      expect(counterEl!.getAttribute("ln:trigger")).toBe("load");

      const todoEl = findIslandById("todo");
      expect(todoEl).not.toBeNull();
      expect(todoEl!.getAttribute("ln:url")).toBe("./todo.js");
      expect(todoEl!.getAttribute("ln:trigger")).toBe("visible");
    });
  });

  describe("Trigger Types", () => {
    test("default trigger is load (not explicitly set)", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:trigger")).toBeNull();
    });

    test("idle trigger", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js" ln:trigger="idle">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:trigger")).toBe("idle");
    });

    test("visible trigger", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js" ln:trigger="visible">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:trigger")).toBe("visible");
    });

    test("media trigger", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js" ln:trigger="media:(min-width: 768px)">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:trigger")).toBe("media:(min-width: 768px)");
    });

    test("none trigger", () => {
      document.body.innerHTML = `<div ln:id="counter" ln:url="./counter.js" ln:trigger="none">Counter</div>`;
      initLoader();

      const el = findIslandById("counter");
      expect(el).not.toBeNull();
      expect(el!.getAttribute("ln:trigger")).toBe("none");
    });
  });

  describe("State Management", () => {
    test("state can be updated after initialization", () => {
      document.body.innerHTML = `
        <script type="ln/json" id="counter">{"count":5}</script>
      `;
      initLoader();

      const state = (window as any).__LN_STATE__;
      expect(state["counter"].count).toBe(5);

      // Update state
      state["counter"].count = 10;
      expect(state["counter"].count).toBe(10);
    });

    test("multiple islands have independent state", () => {
      document.body.innerHTML = `
        <script type="ln/json" id="header">{"user":"Guest","loggedIn":false}</script>
        <script type="ln/json" id="sidebar">{"itemCount":3}</script>
        <script type="ln/json" id="main">{"page":"Home"}</script>
      `;
      initLoader();

      const state = (window as any).__LN_STATE__;

      // Each island has independent state
      expect(state["header"]).toEqual({ user: "Guest", loggedIn: false });
      expect(state["sidebar"]).toEqual({ itemCount: 3 });
      expect(state["main"]).toEqual({ page: "Home" });

      // Modifying one doesn't affect others
      state["header"].user = "Alice";
      expect(state["header"].user).toBe("Alice");
      expect(state["sidebar"].itemCount).toBe(3);
      expect(state["main"].page).toBe("Home");
    });
  });
});
