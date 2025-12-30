/**
 * Show/For Nested Components Benchmark
 *
 * Tests performance of Show and For components with:
 * - Nested Show components
 * - Signal updates during render (ref callbacks)
 * - Multiple signal updates
 *
 * This benchmark verifies that the untracked() fix for issue #5
 * doesn't introduce performance regressions.
 */
import { bench, describe } from "vitest";
import {
  createElement,
  mount,
  createSignal,
  createMemo,
  For,
  Show,
  text,
  createRoot,
  onMount,
} from "../src/index";

// MoonBit tuple representation for attrs
function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
  Dynamic: (getter: () => string) => ({ $tag: 1, _0: getter }),
  Handler: (handler: (e: unknown) => void) => ({ $tag: 2, _0: handler }),
};

// =============================================================================
// Container helpers
// =============================================================================

function createContainer(): HTMLDivElement {
  const container = document.createElement("div");
  document.body.appendChild(container);
  return container;
}

function cleanupContainer(container: HTMLDivElement) {
  container.innerHTML = "";
  if (container.parentNode) {
    container.parentNode.removeChild(container);
  }
}

// =============================================================================
// Benchmarks - Show Mount/Unmount
// =============================================================================

describe("Show Component Performance", () => {
  let container: HTMLDivElement;

  bench(
    "Show - Simple condition toggle (1000x)",
    () => {
      const [visible, setVisible] = createSignal(false);

      const node = Show({
        when: visible,
        children: () => createElement("div", [], [text("Content")]),
      });

      mount(container, node);

      // Toggle visibility 1000 times
      for (let i = 0; i < 1000; i++) {
        setVisible(i % 2 === 0);
      }
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );

  bench(
    "Show - Nested Show (3 levels deep, 100 toggles)",
    () => {
      const [level1, setLevel1] = createSignal(true);
      const [level2, setLevel2] = createSignal(true);
      const [level3, setLevel3] = createSignal(true);

      const node = Show({
        when: level1,
        children: () =>
          Show({
            when: level2,
            children: () =>
              Show({
                when: level3,
                children: () => createElement("div", [], [text("Deep content")]),
              }),
          }),
      });

      mount(container, node);

      // Toggle each level
      for (let i = 0; i < 100; i++) {
        setLevel1(i % 3 !== 0);
        setLevel2(i % 2 !== 0);
        setLevel3(i % 4 !== 0);
      }
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );
});

// =============================================================================
// Benchmarks - For Component
// =============================================================================

describe("For Component Performance", () => {
  let container: HTMLDivElement;

  bench(
    "For - Render 1000 items",
    () => {
      const [items] = createSignal(
        Array.from({ length: 1000 }, (_, i) => i)
      );

      const node = For({
        each: items,
        children: (item: number) =>
          createElement("div", [attr("class", AttrValue.Static("item"))], [
            text(`Item ${item}`),
          ]),
      });

      mount(container, node);
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );

  bench(
    "For - Update signal 100 times (1000 items)",
    () => {
      const [items, setItems] = createSignal(
        Array.from({ length: 1000 }, (_, i) => i)
      );

      const node = For({
        each: items,
        children: (item: number) =>
          createElement("div", [attr("class", AttrValue.Static("item"))], [
            text(`Item ${item}`),
          ]),
      });

      mount(container, node);

      // Update items 100 times
      for (let i = 0; i < 100; i++) {
        setItems(Array.from({ length: 1000 }, (_, j) => j + i));
      }
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );

  bench(
    "For - Add/Remove items (grow from 100 to 1000)",
    () => {
      const [items, setItems] = createSignal(
        Array.from({ length: 100 }, (_, i) => i)
      );

      const node = For({
        each: items,
        children: (item: number) =>
          createElement("div", [], [text(`${item}`)]),
      });

      mount(container, node);

      // Grow list incrementally
      for (let size = 200; size <= 1000; size += 100) {
        setItems(Array.from({ length: size }, (_, i) => i));
      }
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );
});

// =============================================================================
// Benchmarks - Nested Show + For (Issue #5 scenario)
// =============================================================================

describe("Nested Show + For Performance (Issue #5 scenario)", () => {
  let container: HTMLDivElement;

  bench(
    "Nested Show + For - Initial render with memo",
    () => {
      const [count] = createSignal(100);
      const items = createMemo(() =>
        Array.from({ length: count() }, (_, i) => i + 1)
      );

      const node = Show({
        when: () => true,
        children: () =>
          Show({
            when: () => true,
            children: () =>
              createElement("div", [], [
                For({
                  each: items,
                  children: (item: number) =>
                    createElement("div", [], [text(`${item}`)]),
                }),
              ]),
          }),
      });

      mount(container, node);
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );

  bench(
    "Nested Show + For - Signal update in render (ref callback pattern)",
    () => {
      const [lineCount, setLineCount] = createSignal(1);
      const lines = createMemo(() =>
        Array.from({ length: lineCount() }, (_, i) => i + 1)
      );

      const setupInput = (_el: unknown) => {
        // Simulate ref callback that updates signal
        setLineCount(10);
      };

      const node = Show({
        when: () => true,
        children: () =>
          Show({
            when: () => true,
            children: () =>
              createElement("div", [], [
                For({
                  each: lines,
                  children: (num: number) =>
                    createElement("div", [], [text(`${num}`)]),
                }),
                createElement(
                  "div",
                  [attr("__ref", AttrValue.Handler(setupInput))],
                  []
                ),
              ]),
          }),
      });

      mount(container, node);
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );

  bench(
    "Nested Show + For - Deferred show with signal update",
    async () => {
      const [isReady, setIsReady] = createSignal(false);
      const [lineCount, setLineCount] = createSignal(1);
      const lines = createMemo(() =>
        Array.from({ length: lineCount() }, (_, i) => i + 1)
      );

      const setupInput = (_el: unknown) => {
        setLineCount(50);
      };

      createRoot(() => {
        onMount(() => {
          setIsReady(true);
        });

        const node = Show({
          when: isReady,
          children: () =>
            Show({
              when: () => true,
              children: () =>
                createElement("div", [], [
                  For({
                    each: lines,
                    children: (num: number) =>
                      createElement("div", [], [text(`${num}`)]),
                  }),
                  createElement(
                    "div",
                    [attr("__ref", AttrValue.Handler(setupInput))],
                    []
                  ),
                ]),
            }),
        });

        mount(container, node);
      });

      // Wait for mount and effects
      await new Promise((resolve) => setTimeout(resolve, 10));
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );
});

// =============================================================================
// Benchmarks - Stress Test
// =============================================================================

describe("Stress Test - Many Show/For Components", () => {
  let container: HTMLDivElement;

  bench(
    "100 Show components with conditional rendering",
    () => {
      const signals = Array.from({ length: 100 }, () => createSignal(true));

      const nodes = signals.map(([visible], i) =>
        Show({
          when: visible,
          children: () => createElement("div", [], [text(`Show ${i}`)]),
        })
      );

      const wrapper = createElement("div", [], nodes);
      mount(container, wrapper);

      // Toggle all signals
      signals.forEach(([, setVisible], i) => {
        setVisible(i % 2 === 0);
      });
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );

  bench(
    "10 For components with 100 items each",
    () => {
      const lists = Array.from({ length: 10 }, () =>
        createSignal(Array.from({ length: 100 }, (_, i) => i))
      );

      const nodes = lists.map(([items], listIdx) =>
        For({
          each: items,
          children: (item: number) =>
            createElement("div", [], [text(`List ${listIdx} Item ${item}`)]),
        })
      );

      const wrapper = createElement("div", [], nodes);
      mount(container, wrapper);

      // Update all lists
      lists.forEach(([, setItems]) => {
        setItems(Array.from({ length: 100 }, (_, i) => i * 2));
      });
    },
    {
      setup: () => {
        container = createContainer();
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );
});
