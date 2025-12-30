/**
 * CSS Performance Benchmark
 *
 * Compares zero-runtime CSS (Luna's approach) vs runtime CSS-in-JS patterns.
 *
 * Key metrics:
 * 1. Initial render with pre-generated CSS (static) vs runtime-generated CSS (dynamic)
 * 2. Style updates: class switching vs inline style mutation
 * 3. CSSOM manipulation overhead
 *
 * References:
 * - https://calendar.perfplanet.com/2019/the-unseen-performance-costs-of-css-in-js-in-react-apps/
 * - https://dev.to/srmagura/why-were-breaking-up-wiht-css-in-js-4g9b
 */

import { bench, describe } from "vitest";

// =============================================================================
// Test Helpers
// =============================================================================

function createContainer(): HTMLDivElement {
  const container = document.createElement("div");
  document.body.appendChild(container);
  return container;
}

function createStyleSheet(): { styleEl: HTMLStyleElement; sheet: CSSStyleSheet } {
  const styleEl = document.createElement("style");
  document.head.appendChild(styleEl);
  return { styleEl, sheet: styleEl.sheet! };
}

// =============================================================================
// CSS Generation Helpers
// =============================================================================

/**
 * Simulate Luna's zero-runtime approach:
 * CSS is pre-generated at SSR time, only class names are applied at runtime
 */
function generateStaticCSS(count: number): { css: string; classMap: Map<string, string> } {
  const classMap = new Map<string, string>();
  let css = "";

  const properties = [
    ["display", "flex"],
    ["align-items", "center"],
    ["justify-content", "space-between"],
    ["padding", "1rem"],
    ["margin", "0.5rem"],
    ["background", "#f5f5f5"],
    ["border-radius", "0.5rem"],
    ["font-size", "1rem"],
    ["color", "#333"],
    ["box-shadow", "0 1px 3px rgba(0,0,0,0.1)"],
  ];

  for (let i = 0; i < count; i++) {
    const [prop, val] = properties[i % properties.length];
    const decl = `${prop}:${val}`;
    if (!classMap.has(decl)) {
      const className = `_${classMap.size.toString(36)}`;
      classMap.set(decl, className);
      css += `.${className}{${decl}}`;
    }
  }

  return { css, classMap };
}

/**
 * Simulate runtime CSS-in-JS:
 * CSS is generated and inserted during component render
 */
function runtimeGenerateAndInsert(sheet: CSSStyleSheet, property: string, value: string): string {
  const className = `_r${Math.random().toString(36).slice(2, 8)}`;
  const rule = `.${className}{${property}:${value}}`;
  sheet.insertRule(rule, sheet.cssRules.length);
  return className;
}

/**
 * Simulate styled-components pattern:
 * Hash-based class generation with style injection
 */
function styledComponentsPattern(sheet: CSSStyleSheet, styles: Record<string, string>): string {
  const hash = Object.entries(styles)
    .map(([k, v]) => `${k}:${v}`)
    .join(";");
  const className = `sc-${hash.split("").reduce((a, c) => ((a << 5) - a + c.charCodeAt(0)) | 0, 0).toString(36)}`;

  const rule = `.${className}{${Object.entries(styles).map(([k, v]) => `${k}:${v}`).join(";")}}`;
  try {
    sheet.insertRule(rule, sheet.cssRules.length);
  } catch {
    // Rule might already exist
  }
  return className;
}

// =============================================================================
// Benchmark: Initial Render
// =============================================================================

describe("Initial Render: Static vs Dynamic CSS", () => {
  const ELEMENT_COUNT = 100;

  describe(`${ELEMENT_COUNT} elements`, () => {
    // Pre-generate CSS for static approach
    const { classMap } = generateStaticCSS(ELEMENT_COUNT);
    const classNames = Array.from(classMap.values());

    bench("Static CSS (Luna zero-runtime)", () => {
      const container = createContainer();
      // CSS is already in <style>, just apply class names
      const fragment = document.createDocumentFragment();
      for (let i = 0; i < ELEMENT_COUNT; i++) {
        const div = document.createElement("div");
        div.className = classNames[i % classNames.length];
        fragment.appendChild(div);
      }
      container.appendChild(fragment);
      container.remove();
    });

    bench("Runtime CSS-in-JS (insertRule per element)", () => {
      const container = createContainer();
      const { styleEl, sheet } = createStyleSheet();
      const properties = [
        ["display", "flex"],
        ["padding", "1rem"],
        ["margin", "0.5rem"],
        ["background", "#f5f5f5"],
        ["border-radius", "0.5rem"],
      ];

      const fragment = document.createDocumentFragment();
      for (let i = 0; i < ELEMENT_COUNT; i++) {
        const [prop, val] = properties[i % properties.length];
        const className = runtimeGenerateAndInsert(sheet, prop, val);
        const div = document.createElement("div");
        div.className = className;
        fragment.appendChild(div);
      }
      container.appendChild(fragment);
      container.remove();
      styleEl.remove();
    });

    bench("Inline styles (no CSS classes)", () => {
      const container = createContainer();
      const properties = [
        { display: "flex" },
        { padding: "1rem" },
        { margin: "0.5rem" },
        { background: "#f5f5f5" },
        { borderRadius: "0.5rem" },
      ];

      const fragment = document.createDocumentFragment();
      for (let i = 0; i < ELEMENT_COUNT; i++) {
        const div = document.createElement("div");
        Object.assign(div.style, properties[i % properties.length]);
        fragment.appendChild(div);
      }
      container.appendChild(fragment);
      container.remove();
    });
  });
});

// =============================================================================
// Benchmark: Style Updates
// =============================================================================

describe("Style Updates: Class Toggle vs Inline Mutation", () => {
  const UPDATE_COUNT = 1000;

  bench("Class toggle (zero-runtime pattern)", () => {
    const container = createContainer();
    const div = document.createElement("div");
    div.className = "_a";
    container.appendChild(div);

    for (let i = 0; i < UPDATE_COUNT; i++) {
      div.className = i % 2 === 0 ? "_a" : "_b";
    }

    container.remove();
  });

  bench("classList.toggle", () => {
    const container = createContainer();
    const div = document.createElement("div");
    div.className = "_a";
    container.appendChild(div);

    for (let i = 0; i < UPDATE_COUNT; i++) {
      div.classList.toggle("_active");
    }

    container.remove();
  });

  bench("Inline style mutation", () => {
    const container = createContainer();
    const div = document.createElement("div");
    container.appendChild(div);

    for (let i = 0; i < UPDATE_COUNT; i++) {
      div.style.backgroundColor = i % 2 === 0 ? "#f5f5f5" : "#e5e5e5";
    }

    container.remove();
  });

  bench("style.cssText replacement", () => {
    const container = createContainer();
    const div = document.createElement("div");
    container.appendChild(div);

    for (let i = 0; i < UPDATE_COUNT; i++) {
      div.style.cssText = i % 2 === 0 ? "background:#f5f5f5" : "background:#e5e5e5";
    }

    container.remove();
  });
});

// =============================================================================
// Benchmark: CSSOM Operations
// =============================================================================

describe("CSSOM: insertRule vs innerHTML", () => {
  const RULE_COUNT = 100;

  bench("CSSStyleSheet.insertRule (one by one)", () => {
    const style = document.createElement("style");
    document.head.appendChild(style);
    const sheet = style.sheet!;

    for (let i = 0; i < RULE_COUNT; i++) {
      sheet.insertRule(`._x${i}{color:#${i.toString(16).padStart(6, "0")}}`, sheet.cssRules.length);
    }

    style.remove();
  });

  bench("style.textContent (batch)", () => {
    const style = document.createElement("style");
    document.head.appendChild(style);

    let css = "";
    for (let i = 0; i < RULE_COUNT; i++) {
      css += `._x${i}{color:#${i.toString(16).padStart(6, "0")}}`;
    }
    style.textContent = css;

    style.remove();
  });

  bench("style.innerHTML (batch)", () => {
    const style = document.createElement("style");
    document.head.appendChild(style);

    let css = "";
    for (let i = 0; i < RULE_COUNT; i++) {
      css += `._x${i}{color:#${i.toString(16).padStart(6, "0")}}`;
    }
    style.innerHTML = css;

    style.remove();
  });
});

// =============================================================================
// Benchmark: styled-components Pattern Simulation
// =============================================================================

describe("styled-components Pattern Overhead", () => {
  const COMPONENT_COUNT = 50;

  bench("Pre-computed class names (Luna)", () => {
    const container = createContainer();
    // Simulate: classes are computed at SSR, just apply them
    const classes = ["_a _b _c", "_d _e _f", "_g _h _i", "_j _k _l", "_m _n _o"];

    const fragment = document.createDocumentFragment();
    for (let i = 0; i < COMPONENT_COUNT; i++) {
      const div = document.createElement("div");
      div.className = classes[i % classes.length];
      fragment.appendChild(div);
    }
    container.appendChild(fragment);
    container.remove();
  });

  bench("Hash + insertRule per component (styled-components)", () => {
    const container = createContainer();
    const { styleEl, sheet } = createStyleSheet();
    const styleVariants = [
      { display: "flex", padding: "1rem", background: "#fff" },
      { display: "grid", padding: "0.5rem", background: "#f5f5f5" },
      { display: "block", padding: "2rem", background: "#e5e5e5" },
      { display: "inline-flex", padding: "0.25rem", background: "#ddd" },
      { display: "flex", padding: "1.5rem", background: "#ccc" },
    ];

    const fragment = document.createDocumentFragment();
    for (let i = 0; i < COMPONENT_COUNT; i++) {
      const styles = styleVariants[i % styleVariants.length];
      const className = styledComponentsPattern(sheet, styles);
      const div = document.createElement("div");
      div.className = className;
      fragment.appendChild(div);
    }
    container.appendChild(fragment);
    container.remove();
    styleEl.remove();
  });
});

// =============================================================================
// Benchmark: Large Scale Rendering
// =============================================================================

describe("Large Scale: 1000 Elements", () => {
  const ELEMENT_COUNT = 1000;

  bench("Static CSS + class names only", () => {
    const container = createContainer();
    const classes = ["_a", "_b", "_c", "_d", "_e", "_f", "_g", "_h", "_i", "_j"];

    const fragment = document.createDocumentFragment();
    for (let i = 0; i < ELEMENT_COUNT; i++) {
      const div = document.createElement("div");
      div.className = classes[i % classes.length];
      fragment.appendChild(div);
    }
    container.appendChild(fragment);
    container.remove();
  });

  bench("Runtime insertRule + class names", () => {
    const container = createContainer();
    const { styleEl, sheet } = createStyleSheet();
    const props = ["padding", "margin", "color", "background", "display"];
    const vals = ["1rem", "0.5rem", "#333", "#fff", "flex"];

    const fragment = document.createDocumentFragment();
    for (let i = 0; i < ELEMENT_COUNT; i++) {
      const className = runtimeGenerateAndInsert(
        sheet,
        props[i % props.length],
        vals[i % vals.length]
      );
      const div = document.createElement("div");
      div.className = className;
      fragment.appendChild(div);
    }
    container.appendChild(fragment);
    container.remove();
    styleEl.remove();
  });

  bench("Inline styles only", () => {
    const container = createContainer();
    const styles = [
      { padding: "1rem" },
      { margin: "0.5rem" },
      { color: "#333" },
      { background: "#fff" },
      { display: "flex" },
    ];

    const fragment = document.createDocumentFragment();
    for (let i = 0; i < ELEMENT_COUNT; i++) {
      const div = document.createElement("div");
      Object.assign(div.style, styles[i % styles.length]);
      fragment.appendChild(div);
    }
    container.appendChild(fragment);
    container.remove();
  });
});

// =============================================================================
// Benchmark: Deduplication Efficiency
// =============================================================================

describe("Deduplication: Repeated Styles", () => {
  const ELEMENT_COUNT = 200;
  const UNIQUE_STYLES = 10; // Only 10 unique styles, repeated

  bench("Luna: deduplicated (10 classes for 200 elements)", () => {
    const container = createContainer();
    // Pre-computed: same style = same class
    const classes: string[] = [];
    for (let i = 0; i < UNIQUE_STYLES; i++) {
      classes.push(`_${i.toString(36)}`);
    }

    const fragment = document.createDocumentFragment();
    for (let i = 0; i < ELEMENT_COUNT; i++) {
      const div = document.createElement("div");
      div.className = classes[i % UNIQUE_STYLES];
      fragment.appendChild(div);
    }
    container.appendChild(fragment);
    container.remove();
  });

  bench("No dedup: 200 insertRule calls", () => {
    const container = createContainer();
    const { styleEl, sheet } = createStyleSheet();
    const props = [
      "display:flex",
      "padding:1rem",
      "margin:0.5rem",
      "background:#fff",
      "color:#333",
      "border-radius:4px",
      "font-size:1rem",
      "line-height:1.5",
      "gap:0.5rem",
      "justify-content:center",
    ];

    const fragment = document.createDocumentFragment();
    for (let i = 0; i < ELEMENT_COUNT; i++) {
      const className = `_r${i}`;
      sheet.insertRule(`.${className}{${props[i % UNIQUE_STYLES]}}`, sheet.cssRules.length);
      const div = document.createElement("div");
      div.className = className;
      fragment.appendChild(div);
    }
    container.appendChild(fragment);
    container.remove();
    styleEl.remove();
  });
});
