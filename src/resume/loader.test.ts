import { describe, test, expect, beforeEach, afterEach, mock } from "bun:test";
import "global-jsdom/register";

// Load the loader script
const loaderCode = await Bun.file(
  new URL("./loader.js", import.meta.url)
).text();

describe("Resumable Loader", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
    // Reset global state
    (window as any).__STATE__ = undefined;
    (window as any).__RESUME__ = undefined;
    (window as any).__LOAD__ = undefined;
  });

  afterEach(() => {
    document.body.innerHTML = "";
  });

  function initLoader() {
    const script = document.createElement("script");
    script.textContent = loaderCode;
    document.body.appendChild(script);
    eval(loaderCode);
  }

  describe("State Extraction", () => {
    test("extracts global state (no ID)", () => {
      document.body.innerHTML = `
        <script type="application/json" data-resumable-state>[1,2,3]</script>
      `;
      initLoader();

      expect((window as any).__STATE__).toBeDefined();
      expect((window as any).__STATE__["_"]).toEqual([1, 2, 3]);
    });

    test("extracts named state", () => {
      document.body.innerHTML = `
        <script type="application/json" data-resumable-state="counter">[42]</script>
      `;
      initLoader();

      expect((window as any).__STATE__["counter"]).toEqual([42]);
    });

    test("extracts multiple named states", () => {
      document.body.innerHTML = `
        <script type="application/json" data-resumable-state="counter">[10]</script>
        <script type="application/json" data-resumable-state="form">["alice","alice@example.com"]</script>
        <script type="application/json" data-resumable-state="settings">[true,16]</script>
      `;
      initLoader();

      const state = (window as any).__STATE__;
      expect(state["counter"]).toEqual([10]);
      expect(state["form"]).toEqual(["alice", "alice@example.com"]);
      expect(state["settings"]).toEqual([true, 16]);
    });

    test("handles empty state", () => {
      document.body.innerHTML = `
        <script type="application/json" data-resumable-state="empty">[]</script>
      `;
      initLoader();

      expect((window as any).__STATE__["empty"]).toEqual([]);
    });

    test("handles complex state values", () => {
      document.body.innerHTML = `
        <script type="application/json" data-resumable-state="complex">[42,"hello",true,false,null,3.14]</script>
      `;
      initLoader();

      expect((window as any).__STATE__["complex"]).toEqual([
        42,
        "hello",
        true,
        false,
        null,
        3.14,
      ]);
    });
  });

  describe("State Context Detection", () => {
    test("finds state ID from parent element", () => {
      document.body.innerHTML = `
        <div data-state-id="counter">
          <span>0</span>
          <button id="btn" on:click="./app.js#increment">+1</button>
        </div>
        <script type="application/json" data-resumable-state="counter">[0]</script>
      `;
      initLoader();

      const btn = document.getElementById("btn")!;
      const container = btn.closest("[data-state-id]");
      expect(container).toBeDefined();
      expect(container?.getAttribute("data-state-id")).toBe("counter");
    });

    test("nested components have isolated state", () => {
      document.body.innerHTML = `
        <div data-state-id="outer">
          <div data-state-id="inner">
            <button id="inner-btn">Inner</button>
          </div>
          <button id="outer-btn">Outer</button>
        </div>
        <script type="application/json" data-resumable-state="outer">[1]</script>
        <script type="application/json" data-resumable-state="inner">[2]</script>
      `;
      initLoader();

      const innerBtn = document.getElementById("inner-btn")!;
      const outerBtn = document.getElementById("outer-btn")!;

      expect(innerBtn.closest("[data-state-id]")?.getAttribute("data-state-id")).toBe("inner");
      expect(outerBtn.closest("[data-state-id]")?.getAttribute("data-state-id")).toBe("outer");
    });
  });

  describe("Event Attributes", () => {
    test("elements can have on:click attribute", () => {
      document.body.innerHTML = `
        <button on:click="./app.js#handleClick">Click me</button>
      `;
      initLoader();

      const btn = document.querySelector("button")!;
      expect(btn.getAttribute("on:click")).toBe("./app.js#handleClick");
    });

    test("elements can have on:input attribute", () => {
      document.body.innerHTML = `
        <input on:input="./app.js#handleInput" />
      `;
      initLoader();

      const input = document.querySelector("input")!;
      expect(input.getAttribute("on:input")).toBe("./app.js#handleInput");
    });

    test("elements can have on:submit attribute", () => {
      document.body.innerHTML = `
        <form on:submit="./app.js#handleSubmit">
          <button type="submit">Submit</button>
        </form>
      `;
      initLoader();

      const form = document.querySelector("form")!;
      expect(form.getAttribute("on:submit")).toBe("./app.js#handleSubmit");
    });
  });

  describe("Portable HTML Structure", () => {
    test("complete portable HTML structure", () => {
      const html = `
        <!DOCTYPE html>
        <html>
        <body>
          <div data-state-id="counter">
            <span id="count">10</span>
            <button on:click="./app.js#increment">+1</button>
            <button on:click="./app.js#decrement">-1</button>
          </div>
          <script type="application/json" data-resumable-state="counter">[10]</script>

          <div data-state-id="todo">
            <input id="todo-input" value="Buy milk" on:input="./app.js#updateTodo" />
            <input type="checkbox" on:change="./app.js#toggleTodo" />
          </div>
          <script type="application/json" data-resumable-state="todo">["Buy milk",false]</script>
        </body>
        </html>
      `;

      document.body.innerHTML = html;
      initLoader();

      const state = (window as any).__STATE__;

      // Verify state extraction
      expect(state["counter"]).toEqual([10]);
      expect(state["todo"]).toEqual(["Buy milk", false]);

      // Verify DOM structure
      expect(document.getElementById("count")?.textContent).toBe("10");
      expect((document.getElementById("todo-input") as HTMLInputElement)?.value).toBe("Buy milk");

      // Verify event attributes
      const buttons = document.querySelectorAll("button");
      expect(buttons[0].getAttribute("on:click")).toBe("./app.js#increment");
      expect(buttons[1].getAttribute("on:click")).toBe("./app.js#decrement");
    });
  });

  describe("Lazy Loading Structure", () => {
    test("element with data-state-src attribute", () => {
      document.body.innerHTML = `
        <div data-state-id="user" data-state-src="/api/user/123">
          <span>Loading...</span>
          <button on:click="./user.js#edit">Edit</button>
        </div>
      `;
      initLoader();

      const container = document.querySelector("[data-state-id='user']")!;
      expect(container.getAttribute("data-state-src")).toBe("/api/user/123");
    });

    test("__LOAD__ function is available", () => {
      document.body.innerHTML = "";
      initLoader();

      expect(typeof (window as any).__LOAD__).toBe("function");
    });
  });

  describe("API Availability", () => {
    test("__STATE__ is available", () => {
      document.body.innerHTML = "";
      initLoader();

      expect((window as any).__STATE__).toBeDefined();
      expect(typeof (window as any).__STATE__).toBe("object");
    });

    test("__RESUME__ is available", () => {
      document.body.innerHTML = "";
      initLoader();

      expect(typeof (window as any).__RESUME__).toBe("function");
    });

    test("__LOAD__ is available", () => {
      document.body.innerHTML = "";
      initLoader();

      expect(typeof (window as any).__LOAD__).toBe("function");
    });
  });

  describe("Real World Scenarios", () => {
    test("counter component scenario", () => {
      document.body.innerHTML = `
        <div data-state-id="counter">
          <span id="display">5</span>
          <button id="inc" on:click="./counter.js#increment">+</button>
          <button id="dec" on:click="./counter.js#decrement">-</button>
        </div>
        <script type="application/json" data-resumable-state="counter">[5]</script>
      `;
      initLoader();

      const state = (window as any).__STATE__;
      expect(state["counter"][0]).toBe(5);

      // Simulate state update (what the handler would do)
      state["counter"][0]++;
      document.getElementById("display")!.textContent = String(state["counter"][0]);

      expect(state["counter"][0]).toBe(6);
      expect(document.getElementById("display")!.textContent).toBe("6");
    });

    test("form component scenario", () => {
      document.body.innerHTML = `
        <div data-state-id="form">
          <input id="name" value="Alice" on:input="./form.js#updateName" />
          <input id="email" value="alice@example.com" on:input="./form.js#updateEmail" />
          <button on:click="./form.js#submit">Submit</button>
        </div>
        <script type="application/json" data-resumable-state="form">["Alice","alice@example.com"]</script>
      `;
      initLoader();

      const state = (window as any).__STATE__;
      expect(state["form"]).toEqual(["Alice", "alice@example.com"]);

      // Simulate form update
      state["form"][0] = "Bob";
      (document.getElementById("name") as HTMLInputElement).value = state["form"][0];

      expect(state["form"][0]).toBe("Bob");
      expect((document.getElementById("name") as HTMLInputElement).value).toBe("Bob");
    });

    test("multiple independent components", () => {
      document.body.innerHTML = `
        <div data-state-id="header">
          <span id="user-name">Guest</span>
        </div>
        <script type="application/json" data-resumable-state="header">["Guest",false]</script>

        <div data-state-id="sidebar">
          <span id="item-count">3</span>
        </div>
        <script type="application/json" data-resumable-state="sidebar">[3]</script>

        <div data-state-id="main">
          <span id="page-title">Home</span>
        </div>
        <script type="application/json" data-resumable-state="main">["Home"]</script>
      `;
      initLoader();

      const state = (window as any).__STATE__;

      // Each component has independent state
      expect(state["header"]).toEqual(["Guest", false]);
      expect(state["sidebar"]).toEqual([3]);
      expect(state["main"]).toEqual(["Home"]);

      // Modifying one doesn't affect others
      state["header"][0] = "Alice";
      expect(state["header"][0]).toBe("Alice");
      expect(state["sidebar"][0]).toBe(3);
      expect(state["main"][0]).toBe("Home");
    });
  });
});
