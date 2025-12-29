// Test actual TSX syntax with jsxImportSource
import { describe, test, expect } from "vitest";
import "global-jsdom/register";
import { createSignal, createRoot, render, Fragment, Show, Switch, Match } from "../src/index";
import type { JSX } from "../src/jsx-runtime";

describe("TSX Syntax with jsxImportSource", () => {
  test("basic element", () => {
    const node = <div className="test">Hello</div>;
    expect(node).toBeDefined();
  });

  test("nested elements", () => {
    const node = (
      <div className="container">
        <h1>Title</h1>
        <p>Paragraph</p>
      </div>
    );
    expect(node).toBeDefined();
  });

  test("element with multiple attributes", () => {
    const node = (
      <input
        type="text"
        placeholder="Enter name"
        value="initial"
      />
    );
    expect(node).toBeDefined();
  });

  test("event handler", () => {
    let clicked = false;
    const node = (
      <button onClick={() => { clicked = true; }}>
        Click me
      </button>
    );
    expect(node).toBeDefined();
  });

  test("function component", () => {
    function Greeting(props: { name: string }): JSX.Element {
      return <span>Hello, {props.name}!</span>;
    }

    const node = <Greeting name="World" />;
    expect(node).toBeDefined();
  });

  test("component with children", () => {
    function Card(props: { title: string; children?: JSX.Element }): JSX.Element {
      return (
        <div className="card">
          <h2>{props.title}</h2>
          <div className="content">{props.children}</div>
        </div>
      );
    }

    const node = (
      <Card title="My Card">
        <p>Card content here</p>
      </Card>
    );
    expect(node).toBeDefined();
  });

  test("fragment with shorthand syntax", () => {
    const node = (
      <>
        <div>First</div>
        <div>Second</div>
      </>
    );
    // Fragment should return a DomNode (not an array)
    expect(node).toBeDefined();
    expect(Array.isArray(node)).toBe(false);
  });

  test("Fragment component with explicit JSX tag", () => {
    // This is the bug fix test: <Fragment> should work like <>
    const node = (
      <Fragment>
        <div>First</div>
        <div>Second</div>
      </Fragment>
    );
    expect(node).toBeDefined();
    expect(Array.isArray(node)).toBe(false);
  });

  test("Fragment renders correctly to DOM", () => {
    const container = document.createElement("div");

    const node = (
      <div id="wrapper">
        <Fragment>
          <span>A</span>
          <span>B</span>
        </Fragment>
      </div>
    );

    render(container, node);

    expect(container.innerHTML).toContain("A");
    expect(container.innerHTML).toContain("B");
    // Both spans should be direct children of wrapper
    const wrapper = container.querySelector("#wrapper");
    expect(wrapper?.querySelectorAll("span").length).toBe(2);
  });

  test("component returning Fragment works", () => {
    function MultipleElements(): JSX.Element {
      return (
        <Fragment>
          <div>One</div>
          <div>Two</div>
          <div>Three</div>
        </Fragment>
      );
    }

    const container = document.createElement("div");
    render(container, <MultipleElements />);

    expect(container.textContent).toContain("One");
    expect(container.textContent).toContain("Two");
    expect(container.textContent).toContain("Three");
  });

  test("render TSX to DOM", () => {
    const container = document.createElement("div");

    const node = (
      <div id="app">
        <h1 className="title">Hello TSX</h1>
        <p>This is a paragraph.</p>
      </div>
    );

    render(container, node);

    expect(container.innerHTML).toContain("app");
    expect(container.innerHTML).toContain("title");
    expect(container.innerHTML).toContain("Hello TSX");
    expect(container.innerHTML).toContain("paragraph");
  });

  test("reactive value with signal", () => {
    const [count] = createSignal(0);

    const node = (
      <div className={() => `count-${count()}`}>
        Count value
      </div>
    );

    expect(node).toBeDefined();
  });

  test("list rendering", () => {
    const items = ["Apple", "Banana", "Cherry"];

    const node = (
      <ul>
        {items.map((item) => (
          <li>{item}</li>
        ))}
      </ul>
    );

    expect(node).toBeDefined();
  });

  test("conditional rendering in component", () => {
    function Toggle(props: { show: boolean }): JSX.Element {
      return props.show ? <div>Visible</div> : <div>Hidden</div>;
    }

    const visible = <Toggle show={true} />;
    const hidden = <Toggle show={false} />;

    expect(visible).toBeDefined();
    expect(hidden).toBeDefined();
  });

  test("Show with function children returning array", () => {
    const container = document.createElement("div");

    createRoot((dispose) => {
      const [show, setShow] = createSignal(true);

      // Function children that returns multiple elements (array)
      const node = (
        <div id="show-test">
          <Show when={show}>
            {(value) => [
              <span>Shown: {String(value)}</span>,
              <span>Also shown</span>
            ]}
          </Show>
        </div>
      );

      render(container, node);

      expect(container.textContent).toContain("Shown");
      expect(container.textContent).toContain("Also shown");

      dispose();
    });
  });

  test("Switch/Match with function children", () => {
    const container = document.createElement("div");

    createRoot((dispose) => {
      const [value, setValue] = createSignal("a");

      const node = (
        <div id="switch-test">
          <Switch fallback={<span>No match</span>}>
            <Match when={() => value() === "a"}>
              {() => <span>Match A</span>}
            </Match>
            <Match when={() => value() === "b"}>
              {() => [
                <span>Match B1</span>,
                <span>Match B2</span>
              ]}
            </Match>
          </Switch>
        </div>
      );

      render(container, node);
      expect(container.textContent).toContain("Match A");

      setValue("b");
      expect(container.textContent).toContain("Match B1");
      expect(container.textContent).toContain("Match B2");

      setValue("c");
      expect(container.textContent).toContain("No match");

      dispose();
    });
  });

  test("Switch/Match with direct multiple children (no function wrapper)", () => {
    const container = document.createElement("div");

    createRoot((dispose) => {
      const [isEven, setIsEven] = createSignal(true);

      const node = (
        <div id="direct-children-test">
          <Switch fallback={<span>Odd</span>}>
            <Match when={() => isEven()}>
              <div>A</div>
              <div>B</div>
            </Match>
          </Switch>
        </div>
      );

      render(container, node);
      expect(container.textContent).toContain("A");
      expect(container.textContent).toContain("B");

      setIsEven(false);
      expect(container.textContent).toContain("Odd");
      expect(container.textContent).not.toContain("A");
      expect(container.textContent).not.toContain("B");

      dispose();
    });
  });

  // Issue #7: Reactive props (class, innerHTML)
  describe("Reactive props (Issue #7)", () => {
    test("reactive class with accessor function", () => {
      const container = document.createElement("div");

      createRoot((dispose) => {
        const [active, setActive] = createSignal(false);

        // Pass accessor function directly (not called): class={className}
        const className = () => `btn ${active() ? "active" : "inactive"}`;

        const node = (
          <button class={className}>
            Toggle
          </button>
        );

        render(container, node);
        const button = container.querySelector("button")!;

        // Initial state
        expect(button.className).toBe("btn inactive");

        // After update
        setActive(true);
        expect(button.className).toBe("btn active");

        // Toggle back
        setActive(false);
        expect(button.className).toBe("btn inactive");

        dispose();
      });
    });

    test("reactive className with accessor function", () => {
      const container = document.createElement("div");

      createRoot((dispose) => {
        const [color, setColor] = createSignal("red");

        const node = (
          <div className={() => `text-${color()}`}>
            Colored text
          </div>
        );

        render(container, node);
        const div = container.querySelector("div")!;

        expect(div.className).toBe("text-red");

        setColor("blue");
        expect(div.className).toBe("text-blue");

        dispose();
      });
    });

    test("dangerouslySetInnerHTML static", () => {
      const container = document.createElement("div");

      const node = (
        <span dangerouslySetInnerHTML={{ __html: "<b>bold</b>" }} />
      );

      render(container, node);
      const span = container.querySelector("span")!;

      expect(span.innerHTML).toBe("<b>bold</b>");
      expect(span.querySelector("b")?.textContent).toBe("bold");
    });

    test("dangerouslySetInnerHTML dynamic", () => {
      const container = document.createElement("div");

      createRoot((dispose) => {
        const [html, setHtml] = createSignal("<i>italic</i>");

        const node = (
          <span dangerouslySetInnerHTML={() => ({ __html: html() })} />
        );

        render(container, node);
        const span = container.querySelector("span")!;

        expect(span.innerHTML).toBe("<i>italic</i>");

        setHtml("<strong>strong</strong>");
        expect(span.innerHTML).toBe("<strong>strong</strong>");

        dispose();
      });
    });

    test("reactive style object", () => {
      const container = document.createElement("div");

      createRoot((dispose) => {
        const [color, setColor] = createSignal("red");

        const node = (
          <div style={() => ({ color: color(), fontWeight: "bold" })}>
            Styled text
          </div>
        );

        render(container, node);
        const div = container.querySelector("div")!;

        expect(div.getAttribute("style")).toContain("color: red");
        expect(div.getAttribute("style")).toContain("font-weight: bold");

        setColor("blue");
        expect(div.getAttribute("style")).toContain("color: blue");

        dispose();
      });
    });
  });
});
