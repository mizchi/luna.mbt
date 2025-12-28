/**
 * Lifecycle tests for onMount and onCleanup
 * Based on Solid.js semantics
 *
 * Expected behavior:
 * - onMount runs AFTER DOM is created and refs are bound
 * - onCleanup registered inside onMount should run when component unmounts
 * - onCleanup registered inside effects should run when effect re-runs or component unmounts
 */
import { describe, test, expect, beforeEach, afterEach } from "vitest";
import {
  createSignal,
  createEffect,
  createRenderEffect,
  createRoot,
  onMount,
  onCleanup,
  createElement,
  text,
  textDyn,
  render,
  show,
  Show,
  For,
} from "../src/index";

// MoonBit AttrValue constructors
const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
  Dynamic: (getter: () => string) => ({ $tag: 1, _0: getter }),
  Handler: (handler: (e: unknown) => void) => ({ $tag: 2, _0: handler }),
};

function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

// Helper to wait for microtasks to complete
const flushMicrotasks = () => new Promise<void>(resolve => queueMicrotask(resolve));

describe("onMount Basic Behavior", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("onMount runs after component creation", async () => {
    const log: string[] = [];

    function Component() {
      log.push("component function");
      onMount(() => {
        log.push("onMount");
      });
      log.push("before return");
      return createElement("div", [], [text("content")]);
    }

    createRoot(() => {
      render(container, Component());
    });

    // Wait for microtasks (onMount deferred execution)
    await flushMicrotasks();

    // onMount should run after component function completes
    expect(log).toContain("component function");
    expect(log).toContain("before return");
    expect(log).toContain("onMount");

    // Order: component function -> before return -> onMount
    const componentIdx = log.indexOf("component function");
    const beforeReturnIdx = log.indexOf("before return");
    const onMountIdx = log.indexOf("onMount");

    expect(componentIdx).toBeLessThan(beforeReturnIdx);
    expect(beforeReturnIdx).toBeLessThan(onMountIdx);
  });

  test("onMount has access to DOM refs", async () => {
    let refElement: HTMLElement | null = null;
    let mountElement: HTMLElement | null = null;

    function Component() {
      onMount(() => {
        mountElement = refElement;
      });
      return createElement(
        "div",
        [attr("__ref", AttrValue.Handler((el: any) => { refElement = el; }))],
        [text("content")]
      );
    }

    createRoot(() => {
      render(container, Component());
    });

    // Wait for microtasks
    await flushMicrotasks();

    // By the time onMount runs, ref should be available
    expect(refElement).not.toBeNull();
    expect(mountElement).not.toBeNull();
    expect(mountElement).toBe(refElement);
  });

  test("ref is bound before onMount runs", async () => {
    const log: string[] = [];

    function Component() {
      onMount(() => {
        log.push("onMount");
      });
      return createElement(
        "p",
        [attr("__ref", AttrValue.Handler(() => { log.push("ref"); }))],
        [text("content")]
      );
    }

    createRoot(() => {
      render(container, Component());
    });

    // Wait for microtasks
    await flushMicrotasks();

    // ref should be called before onMount
    expect(log).toEqual(["ref", "onMount"]);
  });

  test("multiple onMount calls run in order", async () => {
    const log: string[] = [];

    function Component() {
      onMount(() => log.push("first"));
      onMount(() => log.push("second"));
      onMount(() => log.push("third"));
      return createElement("div", [], [text("content")]);
    }

    createRoot(() => {
      render(container, Component());
    });

    // Wait for microtasks
    await flushMicrotasks();

    expect(log).toEqual(["first", "second", "third"]);
  });
});

describe("onCleanup with onMount", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("onCleanup inside onMount runs on unmount", async () => {
    const log: string[] = [];
    const [visible, setVisible] = createSignal(true);

    function Child() {
      onMount(() => {
        log.push("mounted");
        onCleanup(() => {
          log.push("cleanup");
        });
      });
      return createElement("p", [], [text("I'm here")]);
    }

    createRoot(() => {
      render(
        container,
        createElement("div", [], [
          // Use function children so Child is created inside the owner scope
          Show({ when: visible, children: () => Child() }),
        ])
      );
    });

    // Wait for microtasks
    await flushMicrotasks();

    expect(log).toEqual(["mounted"]);
    expect(container.querySelector("p")).not.toBeNull();

    // Unmount the child
    setVisible(false);

    // Wait for microtasks (in case cleanup is async)
    await flushMicrotasks();

    expect(log).toEqual(["mounted", "cleanup"]);
    expect(container.querySelector("p")).toBeNull();
  });

  test("onCleanup works with show() primitive", async () => {
    const log: string[] = [];
    const [visible, setVisible] = createSignal(true);

    function Child() {
      onMount(() => {
        log.push("mounted");
        onCleanup(() => {
          log.push("cleanup");
        });
      });
      return createElement("span", [], [text("visible")]);
    }

    createRoot(() => {
      render(
        container,
        createElement("div", [], [
          show(visible, () => Child()),
        ])
      );
    });

    // Wait for microtasks
    await flushMicrotasks();

    expect(log).toEqual(["mounted"]);

    setVisible(false);
    await flushMicrotasks();
    expect(log).toEqual(["mounted", "cleanup"]);

    // Re-show should mount again
    setVisible(true);
    await flushMicrotasks();
    expect(log).toEqual(["mounted", "cleanup", "mounted"]);
  });

  test("nested cleanup order (LIFO)", async () => {
    const log: string[] = [];
    const [visible, setVisible] = createSignal(true);

    function Child() {
      onMount(() => {
        onCleanup(() => log.push("first registered"));
        onCleanup(() => log.push("second registered"));
        onCleanup(() => log.push("third registered"));
      });
      return createElement("div", [], [text("child")]);
    }

    createRoot(() => {
      render(
        container,
        // Use function children so Child is created inside the owner scope
        Show({ when: visible, children: () => Child() })
      );
    });

    // Wait for microtasks
    await flushMicrotasks();

    setVisible(false);
    await flushMicrotasks();

    // Cleanups run in reverse order (LIFO)
    expect(log).toEqual([
      "third registered",
      "second registered",
      "first registered",
    ]);
  });
});

describe("onCleanup in Effects", () => {
  test("render effect cleanup runs before re-run (synchronous)", () => {
    const log: string[] = [];
    const [count, setCount] = createSignal(0);

    createRoot(() => {
      // Use createRenderEffect for synchronous testing
      createRenderEffect(() => {
        const current = count();
        log.push(`effect run: ${current}`);
        onCleanup(() => {
          log.push(`cleanup: ${current}`);
        });
      });
    });

    expect(log).toEqual(["effect run: 0"]);

    setCount(1);
    expect(log).toEqual(["effect run: 0", "cleanup: 0", "effect run: 1"]);

    setCount(2);
    expect(log).toEqual([
      "effect run: 0",
      "cleanup: 0",
      "effect run: 1",
      "cleanup: 1",
      "effect run: 2",
    ]);
  });

  test("deferred effect: initial run is deferred, re-runs are sync", async () => {
    const log: string[] = [];
    const [count, setCount] = createSignal(0);

    createRoot(() => {
      // createEffect is deferred for initial run
      createEffect(() => {
        const current = count();
        log.push(`effect run: ${current}`);
        onCleanup(() => {
          log.push(`cleanup: ${current}`);
        });
      });
    });

    // Effect hasn't run yet (initial run is deferred)
    expect(log).toEqual([]);

    // Wait for microtask - initial run happens
    await flushMicrotasks();
    expect(log).toEqual(["effect run: 0"]);

    // Subsequent updates trigger synchronous re-runs (after effect is established)
    setCount(1);
    expect(log).toEqual(["effect run: 0", "cleanup: 0", "effect run: 1"]);

    setCount(2);
    expect(log).toEqual([
      "effect run: 0",
      "cleanup: 0",
      "effect run: 1",
      "cleanup: 1",
      "effect run: 2",
    ]);
  });
});

describe("Timer Cleanup Pattern (from docs)", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("timer is properly cleaned up on unmount", async () => {
    const [visible, setVisible] = createSignal(true);
    let intervalCleared = false;

    function Timer() {
      const [count, setCount] = createSignal(0);

      onMount(() => {
        // This is the pattern from the docs - onCleanup inside onMount
        onCleanup(() => {
          intervalCleared = true;
        });
      });

      return createElement("p", [], [textDyn(() => `Count: ${count()}`)]);
    }

    createRoot(() => {
      render(
        container,
        // Use function children so Timer is created inside the owner scope
        Show({ when: visible, children: () => Timer() })
      );
    });

    await flushMicrotasks();

    expect(intervalCleared).toBe(false);

    setVisible(false);
    await flushMicrotasks();

    expect(intervalCleared).toBe(true);
  });
});

describe("Event Listener Cleanup Pattern (from docs)", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("event listener is removed on unmount", async () => {
    const [visible, setVisible] = createSignal(true);
    const addedListeners: string[] = [];
    const removedListeners: string[] = [];

    // Mock document.addEventListener/removeEventListener
    const originalAdd = document.addEventListener;
    const originalRemove = document.removeEventListener;

    document.addEventListener = (type: string) => {
      addedListeners.push(type);
    };
    document.removeEventListener = (type: string) => {
      removedListeners.push(type);
    };

    function KeyboardHandler() {
      onMount(() => {
        const handler = (e: KeyboardEvent) => {};
        document.addEventListener("keydown", handler as any);

        onCleanup(() => {
          document.removeEventListener("keydown", handler as any);
        });
      });

      return createElement("div", [], [text("Press Escape to close")]);
    }

    createRoot(() => {
      render(
        container,
        // Use function children so KeyboardHandler is created inside the owner scope
        Show({ when: visible, children: () => KeyboardHandler() })
      );
    });

    await flushMicrotasks();

    expect(addedListeners).toEqual(["keydown"]);
    expect(removedListeners).toEqual([]);

    setVisible(false);
    await flushMicrotasks();

    expect(removedListeners).toEqual(["keydown"]);

    // Restore
    document.addEventListener = originalAdd;
    document.removeEventListener = originalRemove;
  });
});

describe("Third-Party Library Pattern (from docs)", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("library is initialized after DOM ready and cleaned up on unmount", async () => {
    const log: string[] = [];
    const [visible, setVisible] = createSignal(true);

    // Mock chart library
    class ChartLibrary {
      constructor(container: HTMLElement, options: any) {
        log.push(`init: ${container.tagName}`);
      }
      destroy() {
        log.push("destroy");
      }
    }

    function Chart() {
      let containerRef: HTMLElement | null = null;

      onMount(() => {
        if (containerRef) {
          const chart = new ChartLibrary(containerRef, {});
          onCleanup(() => {
            chart.destroy();
          });
        }
      });

      return createElement(
        "div",
        [
          attr("className", AttrValue.Static("chart-container")),
          attr("__ref", AttrValue.Handler((el: any) => { containerRef = el; })),
        ],
        []
      );
    }

    createRoot(() => {
      render(
        container,
        // Use function children so Chart is created inside the owner scope
        Show({ when: visible, children: () => Chart() })
      );
    });

    await flushMicrotasks();

    // Chart should be initialized with the container element
    expect(log).toEqual(["init: DIV"]);

    setVisible(false);
    await flushMicrotasks();

    expect(log).toEqual(["init: DIV", "destroy"]);
  });
});

describe("For loop with cleanup", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("items are cleaned up when removed from list", async () => {
    const cleanups: string[] = [];
    const [items, setItems] = createSignal(["a", "b", "c"]);

    function Item({ id }: { id: string }) {
      onMount(() => {
        onCleanup(() => {
          cleanups.push(id);
        });
      });
      return createElement("li", [], [text(id)]);
    }

    createRoot(() => {
      render(
        container,
        createElement("ul", [], [
          For({
            each: items,
            children: (item: string) => Item({ id: item }),
          }),
        ])
      );
    });

    await flushMicrotasks();

    expect(container.querySelectorAll("li").length).toBe(3);
    expect(cleanups).toEqual([]);

    // Remove one item
    setItems(["a", "c"]);
    await flushMicrotasks();

    expect(container.querySelectorAll("li").length).toBe(2);
    // "b" should be cleaned up
    expect(cleanups).toContain("b");
  });
});

// ============================================================================
// Solid.js Style: onCleanup in Component Body (not inside onMount)
// ============================================================================
describe("onCleanup in Component Body (Solid.js style)", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("onCleanup in component body runs on unmount", async () => {
    const log: string[] = [];
    const [visible, setVisible] = createSignal(true);

    // Solid.js style: onCleanup directly in component body
    function Child() {
      log.push("component created");

      // This is the Solid.js pattern - cleanup in component body, not in onMount
      onCleanup(() => {
        log.push("cleanup");
      });

      return createElement("p", [], [text("I'm here")]);
    }

    createRoot(() => {
      render(
        container,
        Show({ when: visible, children: () => Child() })
      );
    });

    // No microtask wait needed - component body runs synchronously
    expect(log).toEqual(["component created"]);
    expect(container.querySelector("p")).not.toBeNull();

    // Unmount the child
    setVisible(false);

    expect(log).toEqual(["component created", "cleanup"]);
    expect(container.querySelector("p")).toBeNull();
  });

  test("timer cleanup pattern (Solid.js style)", async () => {
    const [visible, setVisible] = createSignal(true);
    let timerCleared = false;

    // Solid.js docs example pattern
    function Timer() {
      const [count, setCount] = createSignal(0);

      // Setup side effect directly in component
      const interval = setInterval(() => {
        setCount(c => c + 1);
      }, 1000);

      // Cleanup registered directly in component body
      onCleanup(() => {
        clearInterval(interval);
        timerCleared = true;
      });

      return createElement("p", [], [textDyn(() => `Count: ${count()}`)]);
    }

    createRoot(() => {
      render(
        container,
        Show({ when: visible, children: () => Timer() })
      );
    });

    expect(timerCleared).toBe(false);

    setVisible(false);

    expect(timerCleared).toBe(true);
  });

  test("event listener pattern (Solid.js docs example)", async () => {
    const [visible, setVisible] = createSignal(true);
    const addedListeners: string[] = [];
    const removedListeners: string[] = [];

    // Mock document.addEventListener/removeEventListener
    const originalAdd = document.addEventListener;
    const originalRemove = document.removeEventListener;

    document.addEventListener = (type: string) => {
      addedListeners.push(type);
    };
    document.removeEventListener = (type: string) => {
      removedListeners.push(type);
    };

    // Exact pattern from Solid.js docs
    function ClickCounter() {
      const [count, setCount] = createSignal(0);
      const handleClick = () => setCount(value => value + 1);

      document.addEventListener("click", handleClick as any);

      onCleanup(() => {
        document.removeEventListener("click", handleClick as any);
      });

      return createElement("main", [], [
        textDyn(() => `Document has been clicked ${count()} times`)
      ]);
    }

    createRoot(() => {
      render(
        container,
        Show({ when: visible, children: () => ClickCounter() })
      );
    });

    expect(addedListeners).toEqual(["click"]);
    expect(removedListeners).toEqual([]);

    setVisible(false);

    expect(removedListeners).toEqual(["click"]);

    // Restore
    document.addEventListener = originalAdd;
    document.removeEventListener = originalRemove;
  });

  test("multiple cleanups in component body (LIFO order)", async () => {
    const log: string[] = [];
    const [visible, setVisible] = createSignal(true);

    function Child() {
      onCleanup(() => log.push("first registered"));
      onCleanup(() => log.push("second registered"));
      onCleanup(() => log.push("third registered"));

      return createElement("div", [], [text("child")]);
    }

    createRoot(() => {
      render(
        container,
        Show({ when: visible, children: () => Child() })
      );
    });

    setVisible(false);

    // Cleanups run in reverse order (LIFO)
    expect(log).toEqual([
      "third registered",
      "second registered",
      "first registered",
    ]);
  });

  test("onCleanup works with For loop items (component body style)", async () => {
    const cleanups: string[] = [];
    const [items, setItems] = createSignal(["a", "b", "c"]);

    function Item({ id }: { id: string }) {
      // Solid.js style - cleanup in component body
      onCleanup(() => {
        cleanups.push(id);
      });
      return createElement("li", [], [text(id)]);
    }

    createRoot(() => {
      render(
        container,
        createElement("ul", [], [
          For({
            each: items,
            children: (item: string) => Item({ id: item }),
          }),
        ])
      );
    });

    expect(container.querySelectorAll("li").length).toBe(3);
    expect(cleanups).toEqual([]);

    // Remove one item
    setItems(["a", "c"]);

    expect(container.querySelectorAll("li").length).toBe(2);
    expect(cleanups).toContain("b");
  });

  test("combining onMount and onCleanup in component body", async () => {
    const log: string[] = [];
    const [visible, setVisible] = createSignal(true);

    function Child() {
      log.push("component body start");

      // Cleanup in component body (runs on unmount)
      onCleanup(() => {
        log.push("body cleanup");
      });

      // onMount for DOM-dependent setup
      onMount(() => {
        log.push("mounted");
        // Cleanup inside onMount (also runs on unmount)
        onCleanup(() => {
          log.push("mount cleanup");
        });
      });

      log.push("component body end");
      return createElement("div", [], [text("content")]);
    }

    createRoot(() => {
      render(
        container,
        Show({ when: visible, children: () => Child() })
      );
    });

    await flushMicrotasks();

    expect(log).toEqual([
      "component body start",
      "component body end",
      "mounted"
    ]);

    setVisible(false);
    await flushMicrotasks();

    // Both cleanups should run
    expect(log).toContain("body cleanup");
    expect(log).toContain("mount cleanup");
  });
});
