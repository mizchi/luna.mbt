/**
 * Comprehensive tests for CSS Co-occurrence Optimizer
 */

import { describe, test, expect } from "vitest";
import {
  // Hash utilities
  djb2Hash,
  toBase36,
  hashClassName,
  hashMergedClassName,
  // Parsing
  extractClassUsages,
  parseCssRules,
  buildClassToDeclarationMap,
  extractUniqueClasses,
  // Co-occurrence
  buildCooccurrenceMatrix,
  matrixToCooccurrences,
  getTopCooccurrences,
  buildAdjacencyList,
  // Pattern mining
  findFrequentPatterns,
  removeSubsumedPatterns,
  groupByClassSet,
  // Main API
  optimizeCss,
  optimizeHtml,
} from "../src/css-optimizer/index.js";

// =============================================================================
// Hash Tests
// =============================================================================

describe("Hash utilities", () => {
  test("djb2Hash produces consistent hashes", () => {
    expect(djb2Hash("display:flex")).toBe(djb2Hash("display:flex"));
    expect(djb2Hash("display:flex")).not.toBe(djb2Hash("display:block"));
  });

  test("djb2Hash handles empty string", () => {
    expect(djb2Hash("")).toBe(5381);
  });

  test("toBase36 converts correctly", () => {
    expect(toBase36(0)).toBe("0");
    expect(toBase36(35)).toBe("z");
    expect(toBase36(36)).toBe("10");
    expect(toBase36(100)).toBe("2s");
  });

  test("hashClassName generates prefixed class names", () => {
    const cls = hashClassName("display:flex");
    expect(cls).toMatch(/^_[a-z0-9]+$/);
    expect(cls.length).toBeGreaterThan(1);
    expect(cls.length).toBeLessThanOrEqual(8);
  });

  test("hashClassName with custom prefix", () => {
    const cls = hashClassName("display:flex", "css-");
    expect(cls).toMatch(/^css-[a-z0-9]+$/);
  });

  test("hashMergedClassName generates merged class names", () => {
    const cls = hashMergedClassName(["display:flex", "color:red"]);
    expect(cls).toMatch(/^_m[a-z0-9]+$/);
  });

  test("hashMergedClassName is order-independent", () => {
    const cls1 = hashMergedClassName(["display:flex", "color:red"]);
    const cls2 = hashMergedClassName(["color:red", "display:flex"]);
    expect(cls1).toBe(cls2);
  });
});

// =============================================================================
// Parser Tests
// =============================================================================

describe("Parser utilities", () => {
  describe("extractClassUsages", () => {
    test("extracts class combinations from HTML", () => {
      const html = `
        <div class="_a _b _c">Content</div>
        <span class="_x _y">Other</span>
      `;
      const usages = extractClassUsages(html);

      expect(usages).toHaveLength(2);
      expect(usages[0].classes).toEqual(["_a", "_b", "_c"]);
      expect(usages[1].classes).toEqual(["_x", "_y"]);
    });

    test("ignores single class elements", () => {
      const html = `<div class="_single">Content</div>`;
      const usages = extractClassUsages(html);
      expect(usages).toHaveLength(0);
    });

    test("ignores non-prefixed classes", () => {
      const html = `<div class="normal-class _luna another">Content</div>`;
      const usages = extractClassUsages(html, "html", "_");
      expect(usages).toHaveLength(0); // Only 1 _-prefixed class
    });

    test("sorts classes alphabetically", () => {
      const html = `<div class="_z _a _m">Content</div>`;
      const usages = extractClassUsages(html);
      expect(usages[0].classes).toEqual(["_a", "_m", "_z"]);
    });

    test("uses custom prefix filter", () => {
      const html = `<div class="tw-a tw-b regular">Content</div>`;
      const usages = extractClassUsages(html, "html", "tw-");
      expect(usages).toHaveLength(1);
      expect(usages[0].classes).toEqual(["tw-a", "tw-b"]);
    });

    test("includes source location", () => {
      const html = `<div class="_a _b">Content</div>`;
      const usages = extractClassUsages(html, "test.html");
      expect(usages[0].source).toContain("test.html");
    });
  });

  describe("parseCssRules", () => {
    test("parses simple CSS rules", () => {
      const css = "._a{display:flex}._b{color:red}";
      const rules = parseCssRules(css);

      expect(rules).toHaveLength(2);
      expect(rules[0]).toEqual({ selector: "_a", declarations: "display:flex" });
      expect(rules[1]).toEqual({ selector: "_b", declarations: "color:red" });
    });

    test("handles multi-declaration rules", () => {
      const css = "._a{display:flex;align-items:center;gap:10px}";
      const rules = parseCssRules(css);

      expect(rules).toHaveLength(1);
      expect(rules[0].declarations).toBe("display:flex;align-items:center;gap:10px");
    });

    test("handles whitespace in CSS", () => {
      const css = "._a { display: flex; }";
      const rules = parseCssRules(css);

      expect(rules).toHaveLength(1);
      expect(rules[0].declarations.trim()).toContain("display");
    });
  });

  describe("buildClassToDeclarationMap", () => {
    test("builds correct mapping", () => {
      const css = "._a{display:flex}._b{color:red}";
      const map = buildClassToDeclarationMap(css);

      expect(map.get("_a")).toBe("display:flex");
      expect(map.get("_b")).toBe("color:red");
    });

    test("filters by prefix", () => {
      const css = "._a{display:flex}.normal{color:red}";
      const map = buildClassToDeclarationMap(css, "_");

      expect(map.has("_a")).toBe(true);
      expect(map.has("normal")).toBe(false);
    });
  });

  describe("extractUniqueClasses", () => {
    test("extracts all unique classes", () => {
      const html = `
        <div class="_a _b _c">Content</div>
        <span class="_b _d">Other</span>
      `;
      const classes = extractUniqueClasses(html);

      expect(classes.size).toBe(4);
      expect(classes.has("_a")).toBe(true);
      expect(classes.has("_b")).toBe(true);
      expect(classes.has("_c")).toBe(true);
      expect(classes.has("_d")).toBe(true);
    });
  });
});

// =============================================================================
// Co-occurrence Tests
// =============================================================================

describe("Co-occurrence analysis", () => {
  describe("buildCooccurrenceMatrix", () => {
    test("counts pair co-occurrences", () => {
      const usages = [
        { classes: ["_a", "_b", "_c"], source: "test1" },
        { classes: ["_a", "_b"], source: "test2" },
        { classes: ["_a", "_c"], source: "test3" },
      ];

      const matrix = buildCooccurrenceMatrix(usages);

      // _a and _b appear together 2 times
      expect(matrix.get("_a")?.get("_b")).toBe(2);
      // _a and _c appear together 2 times
      expect(matrix.get("_a")?.get("_c")).toBe(2);
      // _b and _c appear together 1 time
      expect(matrix.get("_b")?.get("_c")).toBe(1);
    });

    test("maintains alphabetical order", () => {
      const usages = [{ classes: ["_z", "_a"], source: "test" }];
      const matrix = buildCooccurrenceMatrix(usages);

      // Should be stored as _a -> _z, not _z -> _a
      expect(matrix.has("_a")).toBe(true);
      expect(matrix.get("_a")?.has("_z")).toBe(true);
      expect(matrix.has("_z")).toBe(false);
    });

    test("handles empty input", () => {
      const matrix = buildCooccurrenceMatrix([]);
      expect(matrix.size).toBe(0);
    });
  });

  describe("matrixToCooccurrences", () => {
    test("converts matrix to sorted array", () => {
      const usages = [
        { classes: ["_a", "_b"], source: "1" },
        { classes: ["_a", "_b"], source: "2" },
        { classes: ["_x", "_y"], source: "3" },
      ];
      const matrix = buildCooccurrenceMatrix(usages);
      const cooccurrences = matrixToCooccurrences(matrix);

      expect(cooccurrences[0].frequency).toBeGreaterThanOrEqual(cooccurrences[1]?.frequency || 0);
      expect(cooccurrences.find((c) => c.classA === "_a" && c.classB === "_b")?.frequency).toBe(2);
    });
  });

  describe("getTopCooccurrences", () => {
    test("returns top N pairs", () => {
      const cooccurrences = [
        { classA: "_a", classB: "_b", frequency: 10 },
        { classA: "_c", classB: "_d", frequency: 5 },
        { classA: "_e", classB: "_f", frequency: 3 },
      ];

      const top2 = getTopCooccurrences(cooccurrences, 2);
      expect(top2).toHaveLength(2);
      expect(top2[0].frequency).toBe(10);
      expect(top2[1].frequency).toBe(5);
    });
  });

  describe("buildAdjacencyList", () => {
    test("builds bidirectional adjacency list", () => {
      const cooccurrences = [{ classA: "_a", classB: "_b", frequency: 5 }];
      const adj = buildAdjacencyList(cooccurrences, 1);

      expect(adj.get("_a")?.find((e) => e.target === "_b")).toBeDefined();
      expect(adj.get("_b")?.find((e) => e.target === "_a")).toBeDefined();
    });

    test("respects minFrequency filter", () => {
      const cooccurrences = [
        { classA: "_a", classB: "_b", frequency: 5 },
        { classA: "_c", classB: "_d", frequency: 1 },
      ];
      const adj = buildAdjacencyList(cooccurrences, 3);

      expect(adj.has("_a")).toBe(true);
      expect(adj.has("_c")).toBe(false);
    });
  });
});

// =============================================================================
// Pattern Mining Tests
// =============================================================================

describe("Pattern mining", () => {
  describe("findFrequentPatterns", () => {
    test("finds pair patterns", () => {
      const usages = [
        { classes: ["_a", "_b"], source: "1" },
        { classes: ["_a", "_b"], source: "2" },
        { classes: ["_c", "_d"], source: "3" },
      ];

      const patterns = findFrequentPatterns(usages, 2, 2);

      expect(patterns.length).toBeGreaterThanOrEqual(1);
      const abPattern = patterns.find(
        (p) => p.originalClasses.includes("_a") && p.originalClasses.includes("_b")
      );
      expect(abPattern).toBeDefined();
      expect(abPattern?.frequency).toBe(2);
    });

    test("finds triple patterns", () => {
      const usages = [
        { classes: ["_a", "_b", "_c"], source: "1" },
        { classes: ["_a", "_b", "_c"], source: "2" },
        { classes: ["_a", "_b", "_c"], source: "3" },
      ];

      const patterns = findFrequentPatterns(usages, 3, 3);

      const triplePattern = patterns.find((p) => p.originalClasses.length === 3);
      expect(triplePattern).toBeDefined();
      expect(triplePattern?.frequency).toBe(3);
    });

    test("respects minFrequency", () => {
      const usages = [
        { classes: ["_a", "_b"], source: "1" },
        { classes: ["_c", "_d"], source: "2" },
      ];

      const patterns = findFrequentPatterns(usages, 2, 2);
      expect(patterns.length).toBe(0); // Each pair appears only once
    });

    test("respects maxPatternSize", () => {
      const usages = [
        { classes: ["_a", "_b", "_c", "_d"], source: "1" },
        { classes: ["_a", "_b", "_c", "_d"], source: "2" },
      ];

      const patterns2 = findFrequentPatterns(usages, 2, 2);
      const patterns4 = findFrequentPatterns(usages, 2, 4);

      expect(patterns2.every((p) => p.originalClasses.length <= 2)).toBe(true);
      expect(patterns4.some((p) => p.originalClasses.length > 2)).toBe(true);
    });

    test("calculates bytesSaved estimate", () => {
      const usages = [
        { classes: ["_a", "_b", "_c"], source: "1" },
        { classes: ["_a", "_b", "_c"], source: "2" },
      ];

      const patterns = findFrequentPatterns(usages, 2, 3);
      const pattern = patterns.find((p) => p.originalClasses.length === 3);

      expect(pattern?.bytesSaved).toBeGreaterThan(0);
    });
  });

  describe("removeSubsumedPatterns", () => {
    test("removes subset patterns", () => {
      const patterns = [
        { originalClasses: ["_a", "_b"], frequency: 5, mergedClass: "", declarations: [], bytesSaved: 100 },
        { originalClasses: ["_a", "_b", "_c"], frequency: 5, mergedClass: "", declarations: [], bytesSaved: 200 },
      ];

      const result = removeSubsumedPatterns(patterns);

      // Should keep only the larger pattern
      expect(result.length).toBe(1);
      expect(result[0].originalClasses).toEqual(["_a", "_b", "_c"]);
    });

    test("keeps patterns with significantly different frequencies", () => {
      const patterns = [
        { originalClasses: ["_a", "_b"], frequency: 10, mergedClass: "", declarations: [], bytesSaved: 100 },
        { originalClasses: ["_a", "_b", "_c"], frequency: 2, mergedClass: "", declarations: [], bytesSaved: 50 },
      ];

      const result = removeSubsumedPatterns(patterns);

      // Should keep both because frequency difference is significant
      expect(result.length).toBe(2);
    });
  });

  describe("groupByClassSet", () => {
    test("groups usages by exact class set", () => {
      const usages = [
        { classes: ["_a", "_b"], source: "1" },
        { classes: ["_a", "_b"], source: "2" },
        { classes: ["_c", "_d"], source: "3" },
      ];

      const groups = groupByClassSet(usages);

      expect(groups.size).toBe(2);
      expect(groups.get("_a|_b")?.length).toBe(2);
      expect(groups.get("_c|_d")?.length).toBe(1);
    });
  });
});

// =============================================================================
// Main API Tests
// =============================================================================

describe("Main API", () => {
  describe("optimizeCss", () => {
    test("merges frequently co-occurring classes", () => {
      const css = "._a{display:flex}._b{align-items:center}._c{color:red}";
      const html = `
        <div class="_a _b">Content</div>
        <div class="_a _b">More</div>
        <span class="_c">Other</span>
      `;
      const mapping = {
        "display:flex": "_a",
        "align-items:center": "_b",
        "color:red": "_c",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      expect(result.patterns.length).toBeGreaterThanOrEqual(1);
      expect(result.mergeMap.size).toBeGreaterThanOrEqual(1);
      expect(result.stats.mergedPatterns).toBeGreaterThanOrEqual(1);
    });

    test("generates valid merged CSS", () => {
      const css = "._a{display:flex}._b{align-items:center}";
      const html = `
        <div class="_a _b">1</div>
        <div class="_a _b">2</div>
      `;
      const mapping = {
        "display:flex": "_a",
        "align-items:center": "_b",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      // Check that merged class rule is generated
      if (result.patterns.length > 0) {
        const mergedClass = result.patterns[0].mergedClass;
        expect(result.css).toContain(`.${mergedClass}{`);
        expect(result.css).toContain("display:flex");
        expect(result.css).toContain("align-items:center");
      }
    });

    test("removes merged classes from original CSS", () => {
      const css = "._a{display:flex}._b{align-items:center}._c{color:red}";
      const html = `
        <div class="_a _b">1</div>
        <div class="_a _b">2</div>
      `;
      const mapping = {
        "display:flex": "_a",
        "align-items:center": "_b",
        "color:red": "_c",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      if (result.patterns.length > 0) {
        // Merged classes should be removed
        expect(result.css).not.toMatch(/\._a\{display:flex\}/);
        expect(result.css).not.toMatch(/\._b\{align-items:center\}/);
        // Unmerged class should remain
        expect(result.css).toContain("._c{color:red}");
      }
    });

    test("handles no patterns found", () => {
      const css = "._a{display:flex}._b{color:red}";
      const html = `
        <div class="_a">Single</div>
        <span class="_b">Other</span>
      `;
      const mapping = {
        "display:flex": "_a",
        "color:red": "_b",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      expect(result.patterns).toHaveLength(0);
      expect(result.css).toBe(css); // Unchanged
    });

    test("preserves pseudo-class rules", () => {
      const css = "._a{color:blue}._a:hover{color:red}";
      const html = `<div class="_a _b">1</div><div class="_a _b">2</div>`;
      const mapping = {
        "color:blue": "_a",
        "display:flex": "_b",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2 });

      expect(result.css).toContain(":hover");
    });

    test("respects pretty option", () => {
      const css = "._a{display:flex}._b{color:red}";
      const html = `<div class="_a _b">1</div><div class="_a _b">2</div>`;
      const mapping = {
        "display:flex": "_a",
        "color:red": "_b",
      };

      const result = optimizeCss(css, html, mapping, { minFrequency: 2, pretty: true });

      if (result.patterns.length > 0) {
        expect(result.css).toContain(" { ");
        expect(result.css).toContain(" }");
      }
    });
  });

  describe("optimizeHtml", () => {
    test("replaces class combinations with merged class", () => {
      const html = `<div class="_a _b _c">Content</div>`;
      const mergeMap = new Map([["_a _b", "_merged"]]);

      const result = optimizeHtml(html, mergeMap);

      expect(result).toContain("_merged");
      expect(result).toContain("_c"); // Remaining class
      expect(result).not.toContain('"_a _b _c"');
    });

    test("handles multiple elements", () => {
      const html = `
        <div class="_a _b">First</div>
        <span class="_a _b">Second</span>
        <p class="_c _d">Third</p>
      `;
      const mergeMap = new Map([["_a _b", "_merged"]]);

      const result = optimizeHtml(html, mergeMap);

      expect((result.match(/_merged/g) || []).length).toBe(2);
      expect(result).toContain("_c _d"); // Unchanged
    });

    test("handles non-prefixed classes", () => {
      const html = `<div class="_a _b regular-class">Content</div>`;
      const mergeMap = new Map([["_a _b", "_merged"]]);

      const result = optimizeHtml(html, mergeMap);

      expect(result).toContain("_merged");
      expect(result).toContain("regular-class");
    });

    test("applies longer patterns first", () => {
      const html = `<div class="_a _b _c">Content</div>`;
      const mergeMap = new Map([
        ["_a _b", "_m1"],
        ["_a _b _c", "_m2"],
      ]);

      const result = optimizeHtml(html, mergeMap);

      expect(result).toContain("_m2");
      expect(result).not.toContain("_m1");
    });

    test("returns unchanged HTML when no patterns match", () => {
      const html = `<div class="_x _y">Content</div>`;
      const mergeMap = new Map([["_a _b", "_merged"]]);

      const result = optimizeHtml(html, mergeMap);

      expect(result).toBe(html);
    });

    test("returns unchanged HTML with empty mergeMap", () => {
      const html = `<div class="_a _b">Content</div>`;
      const mergeMap = new Map<string, string>();

      const result = optimizeHtml(html, mergeMap);

      expect(result).toBe(html);
    });
  });
});

// =============================================================================
// Edge Cases and Integration Tests
// =============================================================================

describe("Edge cases", () => {
  test("handles empty HTML", () => {
    const result = optimizeCss("._a{display:flex}", "", { "display:flex": "_a" });
    expect(result.patterns).toHaveLength(0);
  });

  test("handles empty CSS", () => {
    const result = optimizeCss("", '<div class="_a _b">Test</div>', {});
    expect(result.css).toBe("");
  });

  test("handles special characters in class names", () => {
    const html = `<div class="_a-1 _b_2">Content</div>`;
    const usages = extractClassUsages(html);
    expect(usages[0].classes).toContain("_a-1");
    expect(usages[0].classes).toContain("_b_2");
  });

  test("handles very long class lists", () => {
    const classes = Array.from({ length: 20 }, (_, i) => `_c${i}`);
    const html = `<div class="${classes.join(" ")}">Content</div>`;
    const usages = extractClassUsages(html);

    expect(usages[0].classes.length).toBe(20);
  });

  test("handles duplicate classes in single element", () => {
    const html = `<div class="_a _b _a">Content</div>`;
    const usages = extractClassUsages(html);

    // Should contain 3 total classes but sorted
    expect(usages[0].classes).toContain("_a");
    expect(usages[0].classes).toContain("_b");
  });

  test("conflicting patterns are handled correctly", () => {
    // When _a, _b, _c all appear together multiple times
    // AND _a, _b appear together multiple times
    // Only one should be used (no overlap)
    const html = `
      <div class="_a _b _c">1</div>
      <div class="_a _b _c">2</div>
      <div class="_a _b">3</div>
      <div class="_a _b">4</div>
    `;
    const css = "._a{a:1}._b{b:2}._c{c:3}";
    const mapping = { "a:1": "_a", "b:2": "_b", "c:3": "_c" };

    const result = optimizeCss(css, html, mapping, { minFrequency: 2, maxPatternSize: 3 });

    // Each class should only be used in at most one pattern
    const usedClasses = new Set<string>();
    for (const pattern of result.patterns) {
      for (const cls of pattern.originalClasses) {
        expect(usedClasses.has(cls)).toBe(false);
        usedClasses.add(cls);
      }
    }
  });
});
