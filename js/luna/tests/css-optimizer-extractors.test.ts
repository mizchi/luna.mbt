/**
 * CSS Optimizer Extractors Tests
 *
 * Tests for pluggable class extraction strategies.
 */

import { describe, test, expect } from "vitest";
import {
  HtmlExtractor,
  JsxExtractor,
  SvelteExtractor,
  MultiExtractor,
  htmlExtractor,
  jsxExtractor,
  svelteExtractor,
} from "../src/css-optimizer/extractors.js";

describe("HtmlExtractor", () => {
  const extractor = new HtmlExtractor();

  test("should extract class usages from simple HTML", () => {
    const html = `<div class="_a _b">content</div>`;
    const usages = extractor.extract(html);

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toEqual(["_a", "_b"]);
  });

  test("should filter by class prefix", () => {
    const html = `<div class="_luna other _test non-prefixed">content</div>`;
    const usages = extractor.extract(html, { classPrefix: "_" });

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toContain("_luna");
    expect(usages[0].classes).toContain("_test");
    expect(usages[0].classes).not.toContain("other");
  });

  test("should respect minClasses option", () => {
    const html = `
      <div class="_single">one class</div>
      <div class="_a _b">two classes</div>
      <div class="_x _y _z">three classes</div>
    `;

    const usages2 = extractor.extract(html, { minClasses: 2 });
    expect(usages2).toHaveLength(2);

    const usages3 = extractor.extract(html, { minClasses: 3 });
    expect(usages3).toHaveLength(1);
  });

  test("should include source information", () => {
    const html = `<div class="_a _b">content</div>`;
    const usages = extractor.extract(html, { source: "test.html" });

    expect(usages[0].source).toContain("test.html");
  });

  test("should sort classes alphabetically", () => {
    const html = `<div class="_z _a _m">content</div>`;
    const usages = extractor.extract(html);

    expect(usages[0].classes).toEqual(["_a", "_m", "_z"]);
  });

  test("should handle multiple elements", () => {
    const html = `
      <div class="_a _b">first</div>
      <span class="_c _d">second</span>
      <p class="_e _f">third</p>
    `;
    const usages = extractor.extract(html);

    expect(usages).toHaveLength(3);
  });

  test("should handle custom prefix", () => {
    const html = `<div class="tw-flex tw-gap custom">content</div>`;
    const usages = extractor.extract(html, { classPrefix: "tw-" });

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toEqual(["tw-flex", "tw-gap"]);
  });
});

describe("JsxExtractor", () => {
  const extractor = new JsxExtractor();

  test("should extract from className string literals", () => {
    const jsx = `<div className="_a _b">content</div>`;
    const usages = extractor.extract(jsx);

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toEqual(["_a", "_b"]);
  });

  test("should extract from template literals in braces", () => {
    const jsx = `<div className={"_x _y"}>content</div>`;
    const usages = extractor.extract(jsx);

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toEqual(["_x", "_y"]);
  });

  test("should handle multiple JSX elements", () => {
    const jsx = `
      function Component() {
        return (
          <div>
            <span className="_a _b">first</span>
            <button className="_c _d">second</button>
          </div>
        );
      }
    `;
    const usages = extractor.extract(jsx);

    expect(usages).toHaveLength(2);
  });

  test("should filter by prefix", () => {
    const jsx = `<div className="_luna regular _test other">content</div>`;
    const usages = extractor.extract(jsx, { classPrefix: "_" });

    expect(usages[0].classes).toContain("_luna");
    expect(usages[0].classes).toContain("_test");
    expect(usages[0].classes).not.toContain("regular");
  });
});

describe("SvelteExtractor", () => {
  const extractor = new SvelteExtractor();

  test("should extract from Svelte templates", () => {
    const svelte = `<div class="_a _b">content</div>`;
    const usages = extractor.extract(svelte);

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toEqual(["_a", "_b"]);
  });

  test("should handle dynamic expressions", () => {
    const svelte = `<div class="_static {dynamic} _another">content</div>`;
    const usages = extractor.extract(svelte);

    expect(usages).toHaveLength(1);
    // Should only extract static classes
    expect(usages[0].classes).toEqual(["_another", "_static"]);
  });

  test("should handle complex expressions", () => {
    const svelte = `<div class="_base {isActive ? '_active' : ''} _end">content</div>`;
    const usages = extractor.extract(svelte);

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toContain("_base");
    expect(usages[0].classes).toContain("_end");
  });
});

describe("MultiExtractor", () => {
  const extractor = new MultiExtractor();

  test("should use HTML extractor by default", () => {
    const html = `<div class="_a _b">content</div>`;
    const usages = extractor.extract(html);

    expect(usages).toHaveLength(1);
  });

  test("should select extractor by file type", () => {
    const jsx = `<div className="_x _y">content</div>`;
    const usages = extractor.extractWithType(jsx, "jsx");

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toEqual(["_x", "_y"]);
  });

  test("should extract from multiple files", () => {
    const files = [
      { content: `<div class="_a _b">html</div>`, path: "index.html" },
      { content: `<div className="_c _d">jsx</div>`, path: "app.jsx" },
      { content: `<div class="_e _f">svelte</div>`, path: "component.svelte" },
    ];

    const usages = extractor.extractFromFiles(files);

    expect(usages).toHaveLength(3);
  });

  test("should include file path as source", () => {
    const files = [
      { content: `<div class="_a _b">content</div>`, path: "src/page.html" },
    ];

    const usages = extractor.extractFromFiles(files);
    expect(usages[0].source).toContain("src/page.html");
  });

  test("should allow registering custom extractors", () => {
    const customExtractor = new MultiExtractor();
    customExtractor.register("vue", new HtmlExtractor()); // Vue uses class=""

    const vue = `<template><div class="_vue _style">content</div></template>`;
    const usages = customExtractor.extractWithType(vue, "vue");

    expect(usages).toHaveLength(1);
  });
});

describe("Default extractor instances", () => {
  test("htmlExtractor should be a singleton", () => {
    expect(htmlExtractor).toBeInstanceOf(HtmlExtractor);
  });

  test("jsxExtractor should be a singleton", () => {
    expect(jsxExtractor).toBeInstanceOf(JsxExtractor);
  });

  test("svelteExtractor should be a singleton", () => {
    expect(svelteExtractor).toBeInstanceOf(SvelteExtractor);
  });
});

describe("Extractor edge cases", () => {
  test("should handle empty content", () => {
    expect(htmlExtractor.extract("")).toHaveLength(0);
    expect(jsxExtractor.extract("")).toHaveLength(0);
    expect(svelteExtractor.extract("")).toHaveLength(0);
  });

  test("should handle content without matching classes", () => {
    const html = `<div class="regular classes">no prefixed classes</div>`;
    expect(htmlExtractor.extract(html)).toHaveLength(0);
  });

  test("should handle malformed HTML", () => {
    const malformed = `<div class="_a _b><span class="_c`;
    // Should not throw
    const usages = htmlExtractor.extract(malformed);
    expect(Array.isArray(usages)).toBe(true);
  });

  test("should handle nested elements", () => {
    const html = `
      <div class="_outer _wrap">
        <div class="_inner _content">
          <span class="_deep _nested">text</span>
        </div>
      </div>
    `;
    const usages = htmlExtractor.extract(html);
    expect(usages).toHaveLength(3);
  });

  test("should handle extra whitespace", () => {
    const html = `<div class="  _spacy   _classes  ">content</div>`;
    const usages = htmlExtractor.extract(html);

    expect(usages).toHaveLength(1);
    expect(usages[0].classes).toHaveLength(2);
  });
});
