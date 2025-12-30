/**
 * CSS Optimizer Transformers Tests
 *
 * Tests for pluggable output transformation strategies.
 */

import { describe, test, expect } from "vitest";
import {
  HtmlTransformer,
  JsxTransformer,
  SvelteTransformer,
  MultiTransformer,
  htmlTransformer,
  jsxTransformer,
  svelteTransformer,
} from "../src/css-optimizer/transformers.js";

describe("HtmlTransformer", () => {
  const transformer = new HtmlTransformer();

  test("should apply merge map to HTML", () => {
    const html = `<div class="_a _b other">content</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(html, mergeMap);

    expect(result).toContain("_merged");
    expect(result).toContain("other");
    expect(result).not.toContain("_a _b");
  });

  test("should return unchanged HTML for empty merge map", () => {
    const html = `<div class="_a _b">content</div>`;
    const mergeMap = new Map<string, string>();

    const result = transformer.transform(html, mergeMap);
    expect(result).toBe(html);
  });

  test("should handle multiple class attributes", () => {
    const html = `
      <div class="_a _b">first</div>
      <span class="_a _b">second</span>
    `;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(html, mergeMap);

    expect(result.match(/_merged/g)).toHaveLength(2);
  });

  test("should preserve non-prefixed classes", () => {
    const html = `<div class="_a _b regular other-class">content</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(html, mergeMap);

    expect(result).toContain("_merged");
    expect(result).toContain("regular");
    expect(result).toContain("other-class");
  });

  test("should apply longer patterns first", () => {
    const html = `<div class="_a _b _c">content</div>`;
    const mergeMap = new Map([
      ["_a _b", "_short"],
      ["_a _b _c", "_long"],
    ]);

    const result = transformer.transform(html, mergeMap);

    // Should use the longer pattern
    expect(result).toContain("_long");
    expect(result).not.toContain("_short");
  });

  test("should handle partial matches", () => {
    const html = `<div class="_a _b _c">content</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(html, mergeMap);

    expect(result).toContain("_merged");
    expect(result).toContain("_c"); // Should keep unmerged class
  });

  test("should handle custom prefix", () => {
    const html = `<div class="tw-a tw-b other">content</div>`;
    const mergeMap = new Map([["tw-a tw-b", "tw-merged"]]);

    const result = transformer.transform(html, mergeMap, { classPrefix: "tw-" });

    expect(result).toContain("tw-merged");
    expect(result).toContain("other");
  });
});

describe("JsxTransformer", () => {
  const transformer = new JsxTransformer();

  test("should apply merge map to JSX className", () => {
    const jsx = `<div className="_a _b other">content</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(jsx, mergeMap);

    expect(result).toContain('className="_merged');
    expect(result).toContain("other");
  });

  test("should handle React components", () => {
    const jsx = `
      function Component() {
        return <div className="_x _y">content</div>;
      }
    `;
    const mergeMap = new Map([["_x _y", "_merged"]]);

    const result = transformer.transform(jsx, mergeMap);

    expect(result).toContain("_merged");
  });

  test("should preserve JSX structure", () => {
    const jsx = `<Button className="_a _b" onClick={handleClick}>Click</Button>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(jsx, mergeMap);

    expect(result).toContain("onClick={handleClick}");
    expect(result).toContain('className="_merged"');
  });
});

describe("SvelteTransformer", () => {
  const transformer = new SvelteTransformer();

  test("should apply merge map to Svelte class", () => {
    const svelte = `<div class="_a _b other">content</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(svelte, mergeMap);

    expect(result).toContain("_merged");
    expect(result).toContain("other");
  });

  test("should preserve dynamic expressions", () => {
    const svelte = `<div class="_a _b {dynamic}">content</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(svelte, mergeMap);

    expect(result).toContain("_merged");
    expect(result).toContain("{dynamic}");
  });

  test("should handle complex expressions", () => {
    const svelte = `<div class="_base {isActive ? 'active' : ''} _end">content</div>`;
    const mergeMap = new Map([["_base _end", "_merged"]]);

    const result = transformer.transform(svelte, mergeMap);

    expect(result).toContain("_merged");
    expect(result).toContain("{isActive ? 'active' : ''}");
  });

  test("should preserve class:directive syntax", () => {
    const svelte = `
      <div class="_a _b" class:active={isActive}>content</div>
    `;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(svelte, mergeMap);

    expect(result).toContain("_merged");
    expect(result).toContain("class:active={isActive}");
  });
});

describe("MultiTransformer", () => {
  const transformer = new MultiTransformer();

  test("should use HTML transformer by default", () => {
    const html = `<div class="_a _b">content</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = transformer.transform(html, mergeMap);

    expect(result).toContain("_merged");
  });

  test("should select transformer by file type", () => {
    const jsx = `<div className="_x _y">content</div>`;
    const mergeMap = new Map([["_x _y", "_merged"]]);

    const result = transformer.transformWithType(jsx, mergeMap, "jsx");

    expect(result).toContain('className="_merged');
  });

  test("should transform multiple files", () => {
    const files = [
      { content: `<div class="_a _b">html</div>`, path: "index.html" },
      { content: `<div className="_a _b">jsx</div>`, path: "app.jsx" },
    ];
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const results = transformer.transformFiles(files, mergeMap);

    expect(results[0].content).toContain('class="_merged');
    expect(results[1].content).toContain('className="_merged');
  });

  test("should preserve file paths", () => {
    const files = [{ content: `<div class="_a _b">content</div>`, path: "src/page.html" }];
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const results = transformer.transformFiles(files, mergeMap);

    expect(results[0].path).toBe("src/page.html");
  });

  test("should allow registering custom transformers", () => {
    const customTransformer = new MultiTransformer();
    customTransformer.register("vue", new HtmlTransformer()); // Vue uses class=""

    const vue = `<template><div class="_vue _style">content</div></template>`;
    const mergeMap = new Map([["_vue _style", "_merged"]]);

    const result = customTransformer.transformWithType(vue, mergeMap, "vue");

    expect(result).toContain("_merged");
  });
});

describe("Default transformer instances", () => {
  test("htmlTransformer should be a singleton", () => {
    expect(htmlTransformer).toBeInstanceOf(HtmlTransformer);
  });

  test("jsxTransformer should be a singleton", () => {
    expect(jsxTransformer).toBeInstanceOf(JsxTransformer);
  });

  test("svelteTransformer should be a singleton", () => {
    expect(svelteTransformer).toBeInstanceOf(SvelteTransformer);
  });
});

describe("Transformer edge cases", () => {
  test("should handle empty content", () => {
    const mergeMap = new Map([["_a _b", "_merged"]]);

    expect(htmlTransformer.transform("", mergeMap)).toBe("");
    expect(jsxTransformer.transform("", mergeMap)).toBe("");
    expect(svelteTransformer.transform("", mergeMap)).toBe("");
  });

  test("should handle content without class attributes", () => {
    const html = `<div>no classes here</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    expect(htmlTransformer.transform(html, mergeMap)).toBe(html);
  });

  test("should handle class attributes without matches", () => {
    const html = `<div class="_x _y">content</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = htmlTransformer.transform(html, mergeMap);

    // Should keep original classes
    expect(result).toContain("_x");
    expect(result).toContain("_y");
    expect(result).not.toContain("_merged");
  });

  test("should handle overlapping patterns correctly", () => {
    const html = `<div class="_a _b _c _d">content</div>`;
    const mergeMap = new Map([
      ["_a _b", "_ab"],
      ["_c _d", "_cd"],
    ]);

    const result = htmlTransformer.transform(html, mergeMap);

    expect(result).toContain("_ab");
    expect(result).toContain("_cd");
    expect(result).not.toContain("_a ");
    expect(result).not.toContain("_b ");
  });

  test("should preserve empty class attribute", () => {
    const html = `<div class="">empty</div>`;
    const mergeMap = new Map([["_a _b", "_merged"]]);

    const result = htmlTransformer.transform(html, mergeMap);
    expect(result).toContain('class=""');
  });
});
