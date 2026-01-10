/**
 * Issue #11: Show component does not re-render when signal changes from null to truthy value
 *
 * This test reproduces the exact scenario described in the issue.
 * Now using SolidJS-compatible accessor pattern: children receives an accessor function.
 */

import { describe, test, expect, beforeEach, afterEach } from "vitest";
import {
  createSignal,
  createRoot,
  mount,
  render,
  Show,
  show,
  createElement,
  text,
} from "../src/index";

describe("Issue #11: Show with null to truthy transition", () => {
  let container: HTMLElement;

  beforeEach(() => {
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    container.remove();
  });

  test("Show updates when signal changes from null to truthy (pattern 1: direct signal)", () => {
    const [data, setData] = createSignal<string | null>(null);

    const node = Show({
      when: data,
      // SolidJS-style: children receives accessor, call with ()
      children: (value: () => string) => createElement("p", [], [text(`Data: ${value()}`)]),
    });

    mount(container, node);

    // Initial state: data is null, nothing should be visible
    expect(container.querySelector("p")).toBeNull();

    // Update signal to truthy value
    setData("loaded data");

    // After update: content should be visible
    const p = container.querySelector("p");
    expect(p).not.toBeNull();
    expect(p?.textContent).toBe("Data: loaded data");
  });

  test("Show updates when signal changes from null to truthy (pattern 2: getter function)", () => {
    const [data, setData] = createSignal<string | null>(null);

    const node = Show({
      when: () => data(),
      // SolidJS-style: children receives accessor, call with ()
      children: (value: () => string) => createElement("p", [], [text(`Data: ${value()}`)]),
    });

    mount(container, node);

    // Initial state: data is null, nothing should be visible
    expect(container.querySelector("p")).toBeNull();

    // Update signal to truthy value
    setData("loaded data");

    // After update: content should be visible
    const p = container.querySelector("p");
    expect(p).not.toBeNull();
    expect(p?.textContent).toBe("Data: loaded data");
  });

  test("Show updates with async delay (simulating real use case)", async () => {
    const [data, setData] = createSignal<string | null>(null);

    const node = Show({
      when: data,
      // SolidJS-style: children receives accessor, call with ()
      children: (value: () => string) => createElement("p", [], [text(`Data: ${value()}`)]),
    });

    mount(container, node);

    // Initial state
    expect(container.querySelector("p")).toBeNull();

    // Simulate async data loading
    await new Promise<void>((resolve) => {
      setTimeout(() => {
        setData("loaded data");
        resolve();
      }, 50);
    });

    // After async update
    const p = container.querySelector("p");
    expect(p).not.toBeNull();
    expect(p?.textContent).toBe("Data: loaded data");
  });

  test("Low-level show() works with null to truthy", () => {
    const [data, setData] = createSignal<string | null>(null);

    const node = show(
      () => data() !== null,
      () => createElement("p", [], [text(`Data: ${data()}`)]),
    );

    mount(container, node);

    // Initial state
    expect(container.querySelector("p")).toBeNull();

    // Update
    setData("loaded data");

    // After update
    const p = container.querySelector("p");
    expect(p).not.toBeNull();
    expect(p?.textContent).toBe("Data: loaded data");
  });

  test("Show inside createRoot works correctly", () => {
    const [data, setData] = createSignal<string | null>(null);
    let rootNode: unknown;

    createRoot((dispose) => {
      rootNode = Show({
        when: data,
        // SolidJS-style: children receives accessor, call with ()
        children: (value: () => string) => createElement("p", [], [text(`Data: ${value()}`)]),
      });
      mount(container, rootNode as any);
      return dispose;
    });

    // Initial state
    expect(container.querySelector("p")).toBeNull();

    // Update
    setData("loaded data");

    // After update
    const p = container.querySelector("p");
    expect(p).not.toBeNull();
    expect(p?.textContent).toBe("Data: loaded data");
  });

  test("Show with render (not mount) works correctly", () => {
    const [data, setData] = createSignal<string | null>(null);

    const node = Show({
      when: data,
      // SolidJS-style: children receives accessor, call with ()
      children: (value: () => string) => createElement("p", [], [text(`Data: ${value()}`)]),
    });

    render(container, node);

    // Initial state
    expect(container.querySelector("p")).toBeNull();

    // Update
    setData("loaded data");

    // After update
    const p = container.querySelector("p");
    expect(p).not.toBeNull();
    expect(p?.textContent).toBe("Data: loaded data");
  });
});
