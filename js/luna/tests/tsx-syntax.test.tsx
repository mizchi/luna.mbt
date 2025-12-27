// Test actual TSX syntax with jsxImportSource
import { describe, test, expect } from "vitest";
import "global-jsdom/register";
import { createSignal, render } from "../src/index";
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

  test("fragment", () => {
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
});
