/**
 * Grid Rendering Benchmark
 *
 * Compares Luna, Preact, and React performance for heavy DOM rendering.
 * Based on src/examples/game/main.mbt stress test pattern.
 */
import { bench, describe } from "vitest";
import {
  createElement,
  render as lunaRender,
  createSignal,
  For,
} from "../index.js";

// Preact
import { h, render as preactRender } from "preact";
import { useState } from "preact/hooks";

// React
import React from "react";
import ReactDOM from "react-dom/client";
import { flushSync } from "react-dom";

// =============================================================================
// Configuration
// =============================================================================

const GRID_SIZE = 50; // 50x50 = 2,500 cells
const TOTAL_CELLS = GRID_SIZE * GRID_SIZE;

// Generate indices array once
const indices = Array.from({ length: TOTAL_CELLS }, (_, i) => i);

// Cell types for game simulation
type CellType = 0 | 1 | 2 | 3 | 4; // empty, player, player_bullet, enemy_bullet, enemy

function randomCellType(): CellType {
  const r = Math.random();
  if (r < 0.9) return 0; // 90% empty
  if (r < 0.92) return 1; // 2% player
  if (r < 0.95) return 2; // 3% player_bullet
  if (r < 0.98) return 3; // 3% enemy_bullet
  return 4; // 2% enemy
}

function generateCellTypes(size: number = TOTAL_CELLS): CellType[] {
  return Array.from({ length: size }, () => randomCellType());
}

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
// Luna Implementation
// =============================================================================

// MoonBit tuple representation for attrs
function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
  Dynamic: (getter: () => string) => ({ $tag: 1, _0: getter }),
};

function lunaGridStatic(cellTypes: CellType[]) {
  return createElement(
    "div",
    [attr("className", AttrValue.Static("grid"))],
    cellTypes.map((type) =>
      createElement(
        "div",
        [attr("className", AttrValue.Static(`cell c${type}`))],
        []
      )
    )
  );
}

function lunaGridReactive(initialCellTypes: CellType[]) {
  const [cellTypes, setCellTypes] = createSignal(initialCellTypes);

  const grid = createElement(
    "div",
    [attr("className", AttrValue.Static("grid"))],
    [
      For({
        each: () => Array.from({ length: initialCellTypes.length }, (_, i) => i),
        children: (idx: number) => {
          return createElement(
            "div",
            [
              attr(
                "className",
                AttrValue.Dynamic(() => `cell c${cellTypes()[idx]}`)
              ),
            ],
            []
          );
        },
      }),
    ]
  );

  return { grid, setCellTypes };
}

// =============================================================================
// Preact Implementation
// =============================================================================

function PreactGrid({ cellTypes }: { cellTypes: CellType[] }) {
  return h(
    "div",
    { className: "grid" },
    cellTypes.map((type, i) => h("div", { key: i, className: `cell c${type}` }))
  );
}

// =============================================================================
// React Implementation
// =============================================================================

function ReactGrid({ cellTypes }: { cellTypes: CellType[] }) {
  return React.createElement(
    "div",
    { className: "grid" },
    cellTypes.map((type, i) =>
      React.createElement("div", { key: i, className: `cell c${type}` })
    )
  );
}

// =============================================================================
// Benchmarks - Initial Mount (2,500 cells)
// =============================================================================

describe("Grid Rendering - Initial Mount (2,500 cells)", () => {
  let container: HTMLDivElement;
  let reactRoot: ReactDOM.Root | null = null;

  bench(
    "Luna - Static Grid",
    () => {
      const cellTypes = generateCellTypes();
      const grid = lunaGridStatic(cellTypes);
      container.innerHTML = "";
      lunaRender(container, grid);
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
    "Preact - Static Grid",
    () => {
      const cellTypes = generateCellTypes();
      container.innerHTML = "";
      preactRender(PreactGrid({ cellTypes }), container);
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
    "React - Static Grid",
    () => {
      const cellTypes = generateCellTypes();
      if (reactRoot) {
        flushSync(() => {
          reactRoot!.render(ReactGrid({ cellTypes }));
        });
      }
    },
    {
      setup: () => {
        container = createContainer();
        reactRoot = ReactDOM.createRoot(container);
      },
      teardown: () => {
        if (reactRoot) {
          reactRoot.unmount();
          reactRoot = null;
        }
        cleanupContainer(container);
      },
    }
  );
});

// =============================================================================
// Benchmarks - Reactive State Mount
// =============================================================================

describe("Grid Rendering - With Reactive State (2,500 cells)", () => {
  let container: HTMLDivElement;
  let reactRoot: ReactDOM.Root | null = null;

  bench(
    "Luna - Reactive Grid Mount",
    () => {
      const cellTypes = generateCellTypes();
      container.innerHTML = "";
      const { grid } = lunaGridReactive(cellTypes);
      lunaRender(container, grid);
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
    "Preact - Reactive Grid Mount",
    () => {
      const PreactStatefulGrid = () => {
        const [cellTypes] = useState(generateCellTypes);
        return h(
          "div",
          { className: "grid" },
          cellTypes.map((type, i) =>
            h("div", { key: i, className: `cell c${type}` })
          )
        );
      };
      container.innerHTML = "";
      preactRender(h(PreactStatefulGrid, null), container);
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
    "React - Reactive Grid Mount",
    () => {
      const ReactStatefulGrid = () => {
        const [cellTypes] = React.useState(generateCellTypes);
        return React.createElement(
          "div",
          { className: "grid" },
          cellTypes.map((type, i) =>
            React.createElement("div", { key: i, className: `cell c${type}` })
          )
        );
      };
      if (reactRoot) {
        flushSync(() => {
          reactRoot!.render(React.createElement(ReactStatefulGrid));
        });
      }
    },
    {
      setup: () => {
        container = createContainer();
        reactRoot = ReactDOM.createRoot(container);
      },
      teardown: () => {
        if (reactRoot) {
          reactRoot.unmount();
          reactRoot = null;
        }
        cleanupContainer(container);
      },
    }
  );
});

// =============================================================================
// Benchmarks - State Update
// =============================================================================

describe("Grid Rendering - State Update (2,500 cells)", () => {
  // Luna state
  let lunaContainer: HTMLDivElement;
  let lunaSetCellTypes: ((types: CellType[]) => void) | null = null;

  // Preact state
  let preactContainer: HTMLDivElement;
  let preactSetCellTypes: ((fn: (prev: CellType[]) => CellType[]) => void) | null = null;

  // React state
  let reactContainer: HTMLDivElement;
  let reactRoot: ReactDOM.Root | null = null;
  let reactSetCellTypes: ((types: CellType[]) => void) | null = null;

  bench(
    "Luna - Update All Cells",
    () => {
      if (lunaSetCellTypes) {
        lunaSetCellTypes(generateCellTypes());
      }
    },
    {
      setup: () => {
        lunaContainer = createContainer();
        const { grid, setCellTypes } = lunaGridReactive(generateCellTypes());
        lunaSetCellTypes = setCellTypes;
        lunaRender(lunaContainer, grid);
      },
      teardown: () => {
        cleanupContainer(lunaContainer);
        lunaSetCellTypes = null;
      },
    }
  );

  bench(
    "Preact - Update All Cells",
    () => {
      if (preactSetCellTypes) {
        preactSetCellTypes(() => generateCellTypes());
      }
    },
    {
      setup: () => {
        preactContainer = createContainer();
        const PreactStatefulGrid = () => {
          const [cellTypes, setCellTypes] = useState<CellType[]>(generateCellTypes);
          preactSetCellTypes = setCellTypes;
          return h(
            "div",
            { className: "grid" },
            cellTypes.map((type, i) =>
              h("div", { key: i, className: `cell c${type}` })
            )
          );
        };
        preactRender(h(PreactStatefulGrid, null), preactContainer);
      },
      teardown: () => {
        cleanupContainer(preactContainer);
        preactSetCellTypes = null;
      },
    }
  );

  bench(
    "React - Update All Cells",
    () => {
      if (reactSetCellTypes) {
        flushSync(() => {
          reactSetCellTypes!(generateCellTypes());
        });
      }
    },
    {
      setup: () => {
        reactContainer = createContainer();
        const ReactStatefulGrid = () => {
          const [cellTypes, setCellTypes] = React.useState<CellType[]>(generateCellTypes);
          reactSetCellTypes = setCellTypes;
          return React.createElement(
            "div",
            { className: "grid" },
            cellTypes.map((type, i) =>
              React.createElement("div", { key: i, className: `cell c${type}` })
            )
          );
        };
        reactRoot = ReactDOM.createRoot(reactContainer);
        flushSync(() => {
          reactRoot!.render(React.createElement(ReactStatefulGrid));
        });
      },
      teardown: () => {
        if (reactRoot) {
          reactRoot.unmount();
        }
        cleanupContainer(reactContainer);
        reactSetCellTypes = null;
        reactRoot = null;
      },
    }
  );
});

// =============================================================================
// Benchmarks - Larger Grid (5,000 cells - reduced from 10,000 for stability)
// =============================================================================

describe("Grid Rendering - Large Grid (5,000 cells)", () => {
  const LARGE_SIZE = 5000;

  let container: HTMLDivElement;
  let reactRoot: ReactDOM.Root | null = null;

  bench(
    "Luna - 5,000 cells",
    () => {
      const cellTypes = generateCellTypes(LARGE_SIZE);
      const grid = createElement(
        "div",
        [attr("className", AttrValue.Static("grid"))],
        cellTypes.map((type) =>
          createElement(
            "div",
            [attr("className", AttrValue.Static(`cell c${type}`))],
            []
          )
        )
      );
      container.innerHTML = "";
      lunaRender(container, grid);
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
    "Preact - 5,000 cells",
    () => {
      const cellTypes = generateCellTypes(LARGE_SIZE);
      container.innerHTML = "";
      preactRender(
        h(
          "div",
          { className: "grid" },
          cellTypes.map((type, i) =>
            h("div", { key: i, className: `cell c${type}` })
          )
        ),
        container
      );
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
    "React - 5,000 cells",
    () => {
      const cellTypes = generateCellTypes(LARGE_SIZE);
      if (reactRoot) {
        flushSync(() => {
          reactRoot!.render(
            React.createElement(
              "div",
              { className: "grid" },
              cellTypes.map((type, i) =>
                React.createElement("div", { key: i, className: `cell c${type}` })
              )
            )
          );
        });
      }
    },
    {
      setup: () => {
        container = createContainer();
        reactRoot = ReactDOM.createRoot(container);
      },
      teardown: () => {
        if (reactRoot) {
          reactRoot.unmount();
          reactRoot = null;
        }
        cleanupContainer(container);
      },
    }
  );
});

// =============================================================================
// Benchmarks - List Operations
// =============================================================================

describe("List Operations - Add/Remove Items", () => {
  let container: HTMLDivElement;
  const ITEMS_COUNT = 1000;

  // Luna list operations
  let lunaItems: ReturnType<typeof createSignal<number[]>>;

  bench(
    "Luna - Add 100 items to list",
    () => {
      const [, setItems] = lunaItems;
      setItems((prev) => [...prev, ...Array.from({ length: 100 }, (_, i) => prev.length + i)]);
    },
    {
      setup: () => {
        container = createContainer();
        lunaItems = createSignal<number[]>(Array.from({ length: ITEMS_COUNT }, (_, i) => i));
        const [items] = lunaItems;
        const list = createElement(
          "ul",
          [],
          [
            For({
              each: items,
              children: (item: number) =>
                createElement("li", [], [
                  createElement("span", [], []),
                ]),
            }),
          ]
        );
        lunaRender(container, list);
      },
      teardown: () => {
        cleanupContainer(container);
      },
    }
  );

  // Preact list operations
  let preactSetItems: ((fn: (prev: number[]) => number[]) => void) | null = null;

  bench(
    "Preact - Add 100 items to list",
    () => {
      if (preactSetItems) {
        preactSetItems((prev) => [...prev, ...Array.from({ length: 100 }, (_, i) => prev.length + i)]);
      }
    },
    {
      setup: () => {
        container = createContainer();
        const PreactList = () => {
          const [items, setItems] = useState<number[]>(
            Array.from({ length: ITEMS_COUNT }, (_, i) => i)
          );
          preactSetItems = setItems;
          return h(
            "ul",
            null,
            items.map((item) => h("li", { key: item }, h("span", null)))
          );
        };
        preactRender(h(PreactList, null), container);
      },
      teardown: () => {
        cleanupContainer(container);
        preactSetItems = null;
      },
    }
  );

  // React list operations
  let reactSetItems: ((fn: (prev: number[]) => number[]) => void) | null = null;
  let reactRoot: ReactDOM.Root | null = null;

  bench(
    "React - Add 100 items to list",
    () => {
      if (reactSetItems) {
        flushSync(() => {
          reactSetItems!((prev) => [...prev, ...Array.from({ length: 100 }, (_, i) => prev.length + i)]);
        });
      }
    },
    {
      setup: () => {
        container = createContainer();
        const ReactList = () => {
          const [items, setItems] = React.useState<number[]>(
            Array.from({ length: ITEMS_COUNT }, (_, i) => i)
          );
          reactSetItems = setItems;
          return React.createElement(
            "ul",
            null,
            items.map((item) =>
              React.createElement("li", { key: item }, React.createElement("span", null))
            )
          );
        };
        reactRoot = ReactDOM.createRoot(container);
        flushSync(() => {
          reactRoot!.render(React.createElement(ReactList));
        });
      },
      teardown: () => {
        if (reactRoot) {
          reactRoot.unmount();
        }
        cleanupContainer(container);
        reactSetItems = null;
        reactRoot = null;
      },
    }
  );
});
