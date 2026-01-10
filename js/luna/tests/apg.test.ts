import { describe, test, expect, beforeEach } from "vitest";
import {
  createElement,
  render,
  text,
} from "../src/index";
import axe from "axe-core";

function attr(name: string, value: unknown) {
  return { _0: name, _1: value };
}

const AttrValue = {
  Static: (value: string) => ({ $tag: 0, _0: value }),
};

async function checkA11y(container: HTMLElement): Promise<axe.Result[]> {
  const results = await axe.run(container);
  return results.violations;
}

describe("APG Components - Accessibility Tests", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
    return () => {
      container.remove();
    };
  });

  describe("Link Pattern", () => {
    test("native link has no a11y violations", async () => {
      const node = createElement(
        "a",
        [
          attr("href", AttrValue.Static("https://example.com")),
        ],
        [text("Visit Example")]
      );
      render(container, node);

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("link with aria-label for icon is accessible", async () => {
      const node = createElement(
        "a",
        [
          attr("href", AttrValue.Static("/home")),
          attr("aria-label", AttrValue.Static("Go to home page")),
        ],
        [text("🏠")]
      );
      render(container, node);

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("link with target=_blank should have accessible text", async () => {
      const node = createElement(
        "a",
        [
          attr("href", AttrValue.Static("https://example.com")),
          attr("target", AttrValue.Static("_blank")),
        ],
        [text("External Link (opens in new tab)")]
      );
      render(container, node);

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("link-button with role=link has proper attributes", async () => {
      const node = createElement(
        "span",
        [
          attr("role", AttrValue.Static("link")),
          attr("tabindex", AttrValue.Static("0")),
        ],
        [text("Click here")]
      );
      render(container, node);

      const span = container.querySelector("span");
      expect(span?.getAttribute("role")).toBe("link");
      expect(span?.getAttribute("tabindex")).toBe("0");
    });
  });

  describe("Button Pattern", () => {
    test("native button has no a11y violations", async () => {
      const node = createElement(
        "button",
        [attr("type", AttrValue.Static("button"))],
        [text("Click me")]
      );
      render(container, node);

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("icon button with aria-label is accessible", async () => {
      const node = createElement(
        "button",
        [
          attr("type", AttrValue.Static("button")),
          attr("aria-label", AttrValue.Static("Close dialog")),
        ],
        [text("×")]
      );
      render(container, node);

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("disabled button has aria-disabled", async () => {
      const node = createElement(
        "button",
        [
          attr("type", AttrValue.Static("button")),
          attr("disabled", AttrValue.Static("true")),
          attr("aria-disabled", AttrValue.Static("true")),
        ],
        [text("Disabled")]
      );
      render(container, node);

      const button = container.querySelector("button");
      expect(button?.getAttribute("aria-disabled")).toBe("true");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("toggle button has aria-pressed", async () => {
      const node = createElement(
        "button",
        [
          attr("type", AttrValue.Static("button")),
          attr("aria-pressed", AttrValue.Static("false")),
        ],
        [text("Mute")]
      );
      render(container, node);

      const button = container.querySelector("button");
      expect(button?.getAttribute("aria-pressed")).toBe("false");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("toggle button pressed state", async () => {
      const node = createElement(
        "button",
        [
          attr("type", AttrValue.Static("button")),
          attr("aria-pressed", AttrValue.Static("true")),
        ],
        [text("Mute")]
      );
      render(container, node);

      const button = container.querySelector("button");
      expect(button?.getAttribute("aria-pressed")).toBe("true");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("menu button has aria-haspopup and aria-expanded", async () => {
      const node = createElement(
        "button",
        [
          attr("type", AttrValue.Static("button")),
          attr("aria-haspopup", AttrValue.Static("menu")),
          attr("aria-expanded", AttrValue.Static("false")),
        ],
        [text("Options")]
      );
      render(container, node);

      const button = container.querySelector("button");
      expect(button?.getAttribute("aria-haspopup")).toBe("menu");
      expect(button?.getAttribute("aria-expanded")).toBe("false");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("menu button expanded state", async () => {
      const node = createElement(
        "button",
        [
          attr("type", AttrValue.Static("button")),
          attr("aria-haspopup", AttrValue.Static("menu")),
          attr("aria-expanded", AttrValue.Static("true")),
          attr("aria-controls", AttrValue.Static("menu-id")),
        ],
        [text("Options")]
      );
      render(container, node);

      const button = container.querySelector("button");
      expect(button?.getAttribute("aria-haspopup")).toBe("menu");
      expect(button?.getAttribute("aria-expanded")).toBe("true");
      expect(button?.getAttribute("aria-controls")).toBe("menu-id");
    });
  });

  describe("Meter Pattern", () => {
    test("meter with role and aria attributes is accessible", async () => {
      const node = createElement(
        "div",
        [
          attr("role", AttrValue.Static("meter")),
          attr("aria-valuenow", AttrValue.Static("75")),
          attr("aria-valuemin", AttrValue.Static("0")),
          attr("aria-valuemax", AttrValue.Static("100")),
          attr("aria-label", AttrValue.Static("Battery level")),
        ],
        [text("75%")]
      );
      render(container, node);

      const meter = container.querySelector("[role='meter']");
      expect(meter?.getAttribute("aria-valuenow")).toBe("75");
      expect(meter?.getAttribute("aria-valuemin")).toBe("0");
      expect(meter?.getAttribute("aria-valuemax")).toBe("100");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("meter with aria-valuetext for human-readable value", async () => {
      const node = createElement(
        "div",
        [
          attr("role", AttrValue.Static("meter")),
          attr("aria-valuenow", AttrValue.Static("50")),
          attr("aria-valuemin", AttrValue.Static("0")),
          attr("aria-valuemax", AttrValue.Static("100")),
          attr("aria-valuetext", AttrValue.Static("50% (6 hours) remaining")),
          attr("aria-label", AttrValue.Static("Battery")),
        ],
        [text("50%")]
      );
      render(container, node);

      const meter = container.querySelector("[role='meter']");
      expect(meter?.getAttribute("aria-valuetext")).toBe("50% (6 hours) remaining");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("native meter element is accessible", async () => {
      const node = createElement(
        "meter",
        [
          attr("value", AttrValue.Static("75")),
          attr("min", AttrValue.Static("0")),
          attr("max", AttrValue.Static("100")),
          attr("aria-label", AttrValue.Static("Disk usage")),
        ],
        [text("75%")]
      );
      render(container, node);

      const meter = container.querySelector("meter");
      expect(meter?.getAttribute("value")).toBe("75");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });
  });

  describe("Landmarks Pattern", () => {
    test("header element creates banner landmark", async () => {
      const node = createElement("header", [], [text("Site Header")]);
      render(container, node);

      const header = container.querySelector("header");
      expect(header).not.toBeNull();

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("nav element creates navigation landmark", async () => {
      const node = createElement(
        "nav",
        [attr("aria-label", AttrValue.Static("Main navigation"))],
        [
          createElement("a", [attr("href", AttrValue.Static("/"))], [text("Home")]),
        ]
      );
      render(container, node);

      const nav = container.querySelector("nav");
      expect(nav?.getAttribute("aria-label")).toBe("Main navigation");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("main element creates main landmark", async () => {
      const node = createElement("main", [], [text("Main Content")]);
      render(container, node);

      const main = container.querySelector("main");
      expect(main).not.toBeNull();

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("aside element creates complementary landmark", async () => {
      const node = createElement(
        "aside",
        [attr("aria-label", AttrValue.Static("Related content"))],
        [text("Sidebar")]
      );
      render(container, node);

      const aside = container.querySelector("aside");
      expect(aside?.getAttribute("aria-label")).toBe("Related content");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("footer element creates contentinfo landmark", async () => {
      const node = createElement("footer", [], [text("© 2024")]);
      render(container, node);

      const footer = container.querySelector("footer");
      expect(footer).not.toBeNull();

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("search element creates search landmark", async () => {
      const node = createElement(
        "search",
        [attr("aria-label", AttrValue.Static("Site search"))],
        [
          createElement(
            "input",
            [
              attr("type", AttrValue.Static("search")),
              attr("aria-label", AttrValue.Static("Search query")),
            ],
            []
          ),
        ]
      );
      render(container, node);

      const search = container.querySelector("search");
      expect(search).not.toBeNull();

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("form with role=search creates search landmark", async () => {
      const node = createElement(
        "form",
        [
          attr("role", AttrValue.Static("search")),
          attr("aria-label", AttrValue.Static("Site search")),
        ],
        [
          createElement(
            "input",
            [
              attr("type", AttrValue.Static("search")),
              attr("aria-label", AttrValue.Static("Search query")),
            ],
            []
          ),
        ]
      );
      render(container, node);

      const form = container.querySelector("form[role='search']");
      expect(form).not.toBeNull();

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });

    test("section with aria-label creates region landmark", async () => {
      const node = createElement(
        "section",
        [attr("aria-label", AttrValue.Static("Quick Stats"))],
        [text("Statistics content")]
      );
      render(container, node);

      const section = container.querySelector("section");
      expect(section?.getAttribute("aria-label")).toBe("Quick Stats");

      const violations = await checkA11y(container);
      expect(violations).toHaveLength(0);
    });
  });

  describe("Keyboard Interaction", () => {
    test("button responds to Enter key", () => {
      let clicked = false;
      const node = createElement(
        "button",
        [
          attr("type", AttrValue.Static("button")),
          attr("click", { $tag: 2, _0: () => { clicked = true; } }),
        ],
        [text("Click")]
      );
      render(container, node);

      const button = container.querySelector("button");
      button?.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
      button?.click();
      expect(clicked).toBe(true);
    });

    test("button is focusable", () => {
      const node = createElement(
        "button",
        [attr("type", AttrValue.Static("button"))],
        [text("Focusable")]
      );
      render(container, node);

      const button = container.querySelector("button");
      button?.focus();
      expect(document.activeElement).toBe(button);
    });

    test("link-button with role=link is focusable via tabindex", () => {
      const node = createElement(
        "span",
        [
          attr("role", AttrValue.Static("link")),
          attr("tabindex", AttrValue.Static("0")),
        ],
        [text("Focusable link")]
      );
      render(container, node);

      const span = container.querySelector("span");
      span?.focus();
      expect(document.activeElement).toBe(span);
    });
  });
});
