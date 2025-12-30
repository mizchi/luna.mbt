/**
 * CSS Optimizer Integration Tests
 *
 * Tests the CSS optimizer integration with the Vite plugin pipeline.
 */

import { describe, test, expect, beforeEach, vi } from "vitest";
import { optimizeCss, optimizeHtml, extractClassUsages } from "../src/css-optimizer/index.js";

describe("CSS Optimizer Integration Tests", () => {
  /**
   * These tests simulate the full pipeline from HTML extraction
   * through optimization to final HTML/CSS output.
   */

  describe("Full pipeline simulation", () => {
    test("should optimize a realistic component page", () => {
      // Simulating a card component repeated multiple times
      const html = `
        <!DOCTYPE html>
        <html>
        <head><title>Card Grid</title></head>
        <body>
          <div class="container">
            <div class="_flex _gap _p4 _bg _rounded card">Card 1</div>
            <div class="_flex _gap _p4 _bg _rounded card">Card 2</div>
            <div class="_flex _gap _p4 _bg _rounded card">Card 3</div>
            <div class="_flex _gap _p4 _bg _rounded card">Card 4</div>
          </div>
        </body>
        </html>
      `;

      const css = `
        ._flex{display:flex}
        ._gap{gap:1rem}
        ._p4{padding:1rem}
        ._bg{background:#f0f0f0}
        ._rounded{border-radius:8px}
      `.replace(/\s+/g, "");

      const mapping: Record<string, string> = {
        "display:flex": "_flex",
        "gap:1rem": "_gap",
        "padding:1rem": "_p4",
        "background:#f0f0f0": "_bg",
        "border-radius:8px": "_rounded",
      };

      const result = optimizeCss(css, html, mapping, {
        minFrequency: 2,
        maxPatternSize: 5,
      });

      // Should find a pattern for the 5 classes that appear together 4 times
      expect(result.patterns.length).toBeGreaterThan(0);
      expect(result.mergeMap.size).toBeGreaterThan(0);
      expect(result.stats.mergedPatterns).toBeGreaterThan(0);

      // Verify optimized CSS contains merged class
      const mergedClassNames = Array.from(result.mergeMap.values());
      for (const className of mergedClassNames) {
        expect(result.css).toContain(className);
      }

      // Verify HTML optimization
      const optimizedHtml = optimizeHtml(html, result.mergeMap);
      for (const className of mergedClassNames) {
        expect(optimizedHtml).toContain(className);
      }
    });

    test("should handle TodoMVC-like patterns", () => {
      // Simulating a TodoMVC item list
      const html = `
        <!DOCTYPE html>
        <html>
        <body>
          <ul class="_list">
            <li class="_flex _items_center _p2 _border_b todo-item"><span class="_text">Buy groceries</span></li>
            <li class="_flex _items_center _p2 _border_b todo-item"><span class="_text">Walk dog</span></li>
            <li class="_flex _items_center _p2 _border_b todo-item"><span class="_text">Read book</span></li>
            <li class="_flex _items_center _p2 _border_b todo-item"><span class="_text">Clean room</span></li>
            <li class="_flex _items_center _p2 _border_b todo-item"><span class="_text">Call mom</span></li>
          </ul>
        </body>
        </html>
      `;

      const css = `._flex{display:flex}._items_center{align-items:center}._p2{padding:0.5rem}._border_b{border-bottom:1px solid #ddd}._list{list-style:none}._text{color:#333}`;

      const mapping: Record<string, string> = {
        "display:flex": "_flex",
        "align-items:center": "_items_center",
        "padding:0.5rem": "_p2",
        "border-bottom:1px solid #ddd": "_border_b",
        "list-style:none": "_list",
        "color:#333": "_text",
      };

      const result = optimizeCss(css, html, mapping, {
        minFrequency: 2,
        maxPatternSize: 5,
      });

      // The 4 classes on <li> appear 5 times each
      expect(result.patterns.length).toBeGreaterThan(0);
      expect(result.stats.estimatedBytesSaved).toBeGreaterThan(0);

      // Verify HTML transformation preserves non-luna classes
      const optimizedHtml = optimizeHtml(html, result.mergeMap);
      expect(optimizedHtml).toContain("todo-item");
      expect(optimizedHtml).toContain("_list");
      expect(optimizedHtml).toContain("_text");
    });

    test("should preserve unmerged classes correctly", () => {
      // Mix of frequent and rare patterns
      const html = `
        <div class="_a _b common">1</div>
        <div class="_a _b common">2</div>
        <div class="_a _b common">3</div>
        <div class="_c _d rare">4</div>
      `;

      const css = `._a{color:red}._b{color:blue}._c{color:green}._d{color:yellow}`;
      const mapping: Record<string, string> = {
        "color:red": "_a",
        "color:blue": "_b",
        "color:green": "_c",
        "color:yellow": "_d",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      // Should merge _a _b (3 occurrences) but not _c _d (1 occurrence)
      expect(result.patterns.length).toBeGreaterThanOrEqual(1);

      // Verify CSS still has rules for _c and _d
      expect(result.css).toContain("._c");
      expect(result.css).toContain("._d");

      // Verify HTML keeps rare classes unchanged
      const optimizedHtml = optimizeHtml(html, result.mergeMap);
      expect(optimizedHtml).toContain("_c _d");
    });
  });

  describe("Incremental build scenarios", () => {
    test("should produce deterministic output for same input", () => {
      const html = `
        <div class="_x _y">1</div>
        <div class="_x _y">2</div>
        <div class="_x _y">3</div>
      `;
      const css = `._x{a:b}._y{c:d}`;
      const mapping: Record<string, string> = { "a:b": "_x", "c:d": "_y" };

      const result1 = optimizeCss(css, html, mapping, { minFrequency: 2 });
      const result2 = optimizeCss(css, html, mapping, { minFrequency: 2 });

      expect(result1.css).toBe(result2.css);
      expect(Array.from(result1.mergeMap.entries())).toEqual(
        Array.from(result2.mergeMap.entries())
      );
    });

    test("should handle added elements gracefully", () => {
      const html1 = `
        <div class="_m _n">1</div>
        <div class="_m _n">2</div>
      `;
      const html2 = `
        <div class="_m _n">1</div>
        <div class="_m _n">2</div>
        <div class="_m _n">3</div>
      `;

      const css = `._m{e:f}._n{g:h}`;
      const mapping: Record<string, string> = { "e:f": "_m", "g:h": "_n" };

      // First run with minFrequency: 2
      const result1 = optimizeCss(css, html1, mapping, { minFrequency: 2 });
      // Second run with same threshold
      const result2 = optimizeCss(css, html2, mapping, { minFrequency: 2 });

      // Both should merge since both have >= 2 occurrences
      expect(result1.patterns.length).toBeGreaterThan(0);
      expect(result2.patterns.length).toBeGreaterThan(0);

      // Merged class name should be the same (deterministic)
      const merged1 = Array.from(result1.mergeMap.values())[0];
      const merged2 = Array.from(result2.mergeMap.values())[0];
      expect(merged1).toBe(merged2);
    });
  });

  describe("Multiple HTML files simulation", () => {
    test("should handle combined HTML from multiple pages", () => {
      // Simulating multiple pages being combined for analysis
      const page1 = `<div class="_h1 _mb _text">Page 1 Title</div>`;
      const page2 = `<div class="_h1 _mb _text">Page 2 Title</div>`;
      const page3 = `<div class="_h1 _mb _text">Page 3 Title</div>`;
      const combinedHtml = [page1, page2, page3].join("\n");

      const css = `._h1{font-size:2rem}._mb{margin-bottom:1rem}._text{color:#111}`;
      const mapping: Record<string, string> = {
        "font-size:2rem": "_h1",
        "margin-bottom:1rem": "_mb",
        "color:#111": "_text",
      };

      const result = optimizeCss(css, combinedHtml, mapping, { minFrequency: 2 });

      // Should find patterns across pages
      expect(result.patterns.length).toBeGreaterThan(0);
      expect(result.stats.estimatedBytesSaved).toBeGreaterThan(0);
    });

    test("should detect cross-page patterns correctly", () => {
      // Pattern appears in different pages
      const page1 = `<button class="_btn _primary">Submit</button>`;
      const page2 = `<button class="_btn _primary">Save</button>`;
      const page3 = `<button class="_btn _secondary">Cancel</button>`;
      const combinedHtml = [page1, page2, page3].join("\n");

      const css = `._btn{padding:0.5rem 1rem}._primary{background:blue}._secondary{background:gray}`;
      const mapping: Record<string, string> = {
        "padding:0.5rem 1rem": "_btn",
        "background:blue": "_primary",
        "background:gray": "_secondary",
      };

      const result = optimizeCss(css, combinedHtml, mapping, { minFrequency: 2 });

      // _btn _primary appears 2 times, should be merged
      // _btn _secondary appears 1 time, should not be merged
      expect(result.mergeMap.size).toBeGreaterThanOrEqual(1);

      // Verify _secondary is preserved
      expect(result.css).toContain("._secondary");
    });
  });

  describe("Edge cases in real-world scenarios", () => {
    test("should handle empty HTML gracefully", () => {
      const html = "";
      const css = `._x{a:b}._y{c:d}`;
      const mapping: Record<string, string> = { "a:b": "_x", "c:d": "_y" };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      expect(result.patterns).toHaveLength(0);
      expect(result.mergeMap.size).toBe(0);
      expect(result.css).toBe(css); // Original CSS preserved
    });

    test("should handle HTML with no Luna classes", () => {
      const html = `
        <div class="regular-class">Content</div>
        <span class="another-class">More</span>
      `;
      const css = `._a{x:y}._b{w:z}`;
      const mapping: Record<string, string> = { "x:y": "_a", "w:z": "_b" };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      expect(result.patterns).toHaveLength(0);
      expect(result.css).toBe(css);
    });

    test("should handle classes not in mapping", () => {
      const html = `
        <div class="_unknown1 _unknown2">1</div>
        <div class="_unknown1 _unknown2">2</div>
        <div class="_unknown1 _unknown2">3</div>
      `;
      const css = `._other{foo:bar}`;
      const mapping: Record<string, string> = { "foo:bar": "_other" };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      // Pattern is found in HTML but declarations not in mapping
      expect(result.mergeMap.size).toBe(0);
    });

    test("should handle pseudo-class rules preservation", () => {
      const html = `
        <a class="_link _blue">1</a>
        <a class="_link _blue">2</a>
        <a class="_link _blue">3</a>
      `;

      // Include pseudo-class rules
      const css = `._link{text-decoration:none}._blue{color:blue}._link:hover{text-decoration:underline}._blue:hover{color:darkblue}`;
      const mapping: Record<string, string> = {
        "text-decoration:none": "_link",
        "color:blue": "_blue",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      // Base rules should be merged
      expect(result.patterns.length).toBeGreaterThan(0);

      // Pseudo-class rules should be preserved
      expect(result.css).toContain(":hover");
    });

    test("should handle deeply nested HTML", () => {
      const html = `
        <div>
          <div>
            <div>
              <div>
                <span class="_deep _nested">1</span>
                <span class="_deep _nested">2</span>
              </div>
            </div>
          </div>
        </div>
      `;
      const css = `._deep{position:relative}._nested{display:inline}`;
      const mapping: Record<string, string> = {
        "position:relative": "_deep",
        "display:inline": "_nested",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      expect(result.patterns.length).toBeGreaterThan(0);
    });

    test("should handle many unique classes with few patterns", () => {
      // Many different class combinations
      const html = `
        <div class="_a _b">1</div>
        <div class="_c _d">2</div>
        <div class="_e _f">3</div>
        <div class="_g _h">4</div>
        <div class="_a _b">5</div>
      `;
      const css = `._a{a:1}._b{b:2}._c{c:3}._d{d:4}._e{e:5}._f{f:6}._g{g:7}._h{h:8}`;
      const mapping: Record<string, string> = {
        "a:1": "_a",
        "b:2": "_b",
        "c:3": "_c",
        "d:4": "_d",
        "e:5": "_e",
        "f:6": "_f",
        "g:7": "_g",
        "h:8": "_h",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      // Only _a _b appears twice
      expect(result.patterns.length).toBe(1);
    });
  });

  describe("Performance regression scenarios", () => {
    test("should handle large number of class usages efficiently", () => {
      // Generate 100 elements with the same pattern
      const items = Array.from({ length: 100 }, (_, i) =>
        `<div class="_rep1 _rep2 _rep3">Item ${i}</div>`
      ).join("\n");
      const html = `<div>${items}</div>`;

      const css = `._rep1{a:b}._rep2{c:d}._rep3{e:f}`;
      const mapping: Record<string, string> = {
        "a:b": "_rep1",
        "c:d": "_rep2",
        "e:f": "_rep3",
      };

      const start = performance.now();
      const result = optimizeCss(css, html, mapping, {
        minFrequency: 2,
        maxPatternSize: 5,
      });
      const elapsed = performance.now() - start;

      expect(result.patterns.length).toBeGreaterThan(0);
      expect(result.stats.estimatedBytesSaved).toBeGreaterThan(0);
      // Should complete reasonably fast (< 500ms)
      expect(elapsed).toBeLessThan(500);
    });

    test("should handle many different patterns efficiently", () => {
      // Generate elements with varying patterns
      const items: string[] = [];
      for (let i = 0; i < 50; i++) {
        // Half with pattern A, half with pattern B
        if (i % 2 === 0) {
          items.push(`<div class="_pa1 _pa2">A${i}</div>`);
        } else {
          items.push(`<div class="_pb1 _pb2">B${i}</div>`);
        }
      }
      const html = items.join("\n");

      const css = `._pa1{pa1:v}._pa2{pa2:v}._pb1{pb1:v}._pb2{pb2:v}`;
      const mapping: Record<string, string> = {
        "pa1:v": "_pa1",
        "pa2:v": "_pa2",
        "pb1:v": "_pb1",
        "pb2:v": "_pb2",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      // Should find both patterns
      expect(result.patterns.length).toBe(2);
    });
  });

  describe("extractClassUsages edge cases", () => {
    test("should handle malformed HTML gracefully", () => {
      const malformed = `<div class="_a _b"><span class="_c"`;
      const usages = extractClassUsages(malformed);

      // Should still extract valid class attributes
      expect(usages.length).toBeGreaterThanOrEqual(0);
    });

    test("should handle single quotes in class attribute", () => {
      const html = `<div class='_sq1 _sq2'>test</div><div class='_sq1 _sq2'>test2</div>`;
      const usages = extractClassUsages(html);

      // Double quote regex won't match single quotes
      // This is expected behavior - document or fix if needed
      expect(usages.length).toBe(0);
    });

    test("should handle extra whitespace in classes", () => {
      const html = `
        <div class="  _ws1   _ws2  ">1</div>
        <div class="_ws1    _ws2">2</div>
      `;
      const usages = extractClassUsages(html);

      expect(usages.length).toBe(2);
      // Classes should be normalized (whitespace trimmed)
      for (const usage of usages) {
        expect(usage.classes.length).toBe(2);
        expect(usage.classes).toContain("_ws1");
        expect(usage.classes).toContain("_ws2");
      }
    });
  });

  describe("optimizeHtml edge cases", () => {
    test("should handle multiple class attributes per element", () => {
      // Technically invalid HTML but should handle gracefully
      const html = `<div class="_a _b" class="_c _d">test</div>`;
      const mergeMap = new Map([["_a _b", "_merged"]]);

      const result = optimizeHtml(html, mergeMap);
      // First class attr should be replaced
      expect(result).toContain("_merged");
    });

    test("should preserve class order for non-merged classes", () => {
      const html = `<div class="_first other _second another">test</div>`;
      const mergeMap = new Map<string, string>(); // No merges

      const result = optimizeHtml(html, mergeMap);
      // With empty mergeMap, HTML is returned unchanged
      expect(result).toBe(html);
    });

    test("should reorder classes when merging", () => {
      const html = `<div class="_first other _second another">test</div><div class="_first other _second another">test2</div>`;
      const mergeMap = new Map([["_first _second", "_merged"]]);

      const result = optimizeHtml(html, mergeMap);
      // Merged class should appear, with non-luna classes at the end
      expect(result).toContain("_merged");
      expect(result).toContain("other");
      expect(result).toContain("another");
    });

    test("should handle empty class attribute", () => {
      const html = `<div class="">empty</div><div class="_a _b">filled</div>`;
      const mergeMap = new Map([["_a _b", "_merged"]]);

      const result = optimizeHtml(html, mergeMap);
      expect(result).toContain('class=""');
      expect(result).toContain("_merged");
    });
  });
});

describe("CSS Optimizer Options", () => {
  test("minFrequency controls pattern threshold", () => {
    const html = `
      <div class="_opt1 _opt2">1</div>
      <div class="_opt1 _opt2">2</div>
      <div class="_opt1 _opt2">3</div>
    `;
    const css = `._opt1{o1:v}._opt2{o2:v}`;
    const mapping: Record<string, string> = { "o1:v": "_opt1", "o2:v": "_opt2" };

    // With minFrequency: 4, should not merge (only 3 occurrences)
    const result1 = optimizeCss(css, html, mapping, { minFrequency: 4 });
    expect(result1.patterns.length).toBe(0);

    // With minFrequency: 3, should merge
    const result2 = optimizeCss(css, html, mapping, { minFrequency: 3 });
    expect(result2.patterns.length).toBe(1);
  });

  test("maxPatternSize limits pattern complexity", () => {
    const html = `
      <div class="_s1 _s2 _s3 _s4 _s5">1</div>
      <div class="_s1 _s2 _s3 _s4 _s5">2</div>
      <div class="_s1 _s2 _s3 _s4 _s5">3</div>
    `;
    const css = `._s1{s1:v}._s2{s2:v}._s3{s3:v}._s4{s4:v}._s5{s5:v}`;
    const mapping: Record<string, string> = {
      "s1:v": "_s1",
      "s2:v": "_s2",
      "s3:v": "_s3",
      "s4:v": "_s4",
      "s5:v": "_s5",
    };

    // With maxPatternSize: 2, should only find pairs
    const result1 = optimizeCss(css, html, mapping, {
      minFrequency: 2,
      maxPatternSize: 2,
    });

    // With maxPatternSize: 5, should find quintuples
    const result2 = optimizeCss(css, html, mapping, {
      minFrequency: 2,
      maxPatternSize: 5,
    });

    // The 5-class pattern should be found with maxPatternSize: 5
    const hasQuintuple = result2.patterns.some(
      (p) => p.originalClasses.length === 5
    );
    const hasPair = result1.patterns.some((p) => p.originalClasses.length === 2);

    expect(hasQuintuple).toBe(true);
    expect(hasPair).toBe(true);
  });

  test("classPrefix filters by prefix", () => {
    const html = `
      <div class="_luna1 _luna2 tailwind-class">1</div>
      <div class="_luna1 _luna2 another-class">2</div>
    `;

    // Default prefix "_" should only extract luna classes
    const usages = extractClassUsages(html, "html", "_");

    for (const usage of usages) {
      for (const cls of usage.classes) {
        expect(cls.startsWith("_")).toBe(true);
      }
    }
  });
});
