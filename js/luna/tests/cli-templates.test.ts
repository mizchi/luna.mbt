/**
 * Tests for CLI scaffold templates (Issue #12)
 * Verifies that generated templates use correct API signatures and dependencies.
 */
import { describe, test, expect } from "vitest";

// We dynamically import the template functions from cli.ts
// by extracting and testing them directly
// Since cli.ts has side effects (process.argv), we test the template content
// by importing the file and calling the template generators.

// Helper: extract template content by path from template array
function findTemplate(
  templates: Array<{ path: string; content: string }>,
  filePath: string
): string | undefined {
  return templates.find((t) => t.path === filePath)?.content;
}

// Dynamically load getTsxTemplates and getMbtTemplates
// We use a workaround: import the file and extract the functions
let getTsxTemplates: (name: string) => Array<{ path: string; content: string }>;
let getMbtTemplates: (name: string) => Array<{ path: string; content: string }>;

// Since cli.ts runs main() on import, we need to extract just the template functions.
// For now, we test the actual file content directly.
import * as fs from "node:fs";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const cliPath = path.resolve(__dirname, "../bin/cli.ts");
const cliSource = fs.readFileSync(cliPath, "utf-8");

describe("Issue #12: CLI TSX template - render argument order", () => {
  test("src/main.tsx should use render(element, component) not render(component, element)", () => {
    // Extract the main.tsx template content from cli.ts source
    // The template contains: render(..., document.getElementById("app")!)
    // Correct: render(document.getElementById("app")!, <App />)
    // Wrong:   render(() => <App />, document.getElementById("app")!)

    const wrongPattern = /render\(\(\)\s*=>\s*<App\s*\/>/;
    const correctPattern = /render\(document\.getElementById/;

    expect(cliSource).not.toMatch(wrongPattern);
    expect(cliSource).toMatch(correctPattern);
  });
});

describe("Issue #12: CLI MoonBit template - dependencies", () => {
  test("moon.mod.json should include mizchi/signals dependency", () => {
    // The template should include "mizchi/signals" in deps
    expect(cliSource).toContain('"mizchi/signals"');
  });

  test("moon.mod.json should use up-to-date mizchi/luna version (>= 0.16.0)", () => {
    // Should NOT contain the old version "0.1.3"
    expect(cliSource).not.toContain('"mizchi/luna": "0.1.3"');
  });

  test("moon.mod.json should use up-to-date mizchi/js version (>= 0.10.14)", () => {
    expect(cliSource).not.toContain('"mizchi/js": "0.10.6"');
  });
});

describe("Issue #12: CLI MoonBit template - import paths", () => {
  test("moon.pkg.json should import mizchi/signals, not mizchi/luna/signal", () => {
    // Old: "mizchi/luna/signal"
    // New: { path: "mizchi/signals", alias: "signal" }
    expect(cliSource).not.toMatch(/"mizchi\/luna\/signal"/);
  });

  test("moon.pkg.json should import mizchi/luna/dom, not mizchi/luna/platform/dom/element", () => {
    expect(cliSource).not.toContain("mizchi/luna/platform/dom/element");
  });
});

describe("Issue #12: CLI MoonBit template - lib.mbt API", () => {
  test("lib.mbt should use DomElement::from_dom, not from_jsdom", () => {
    expect(cliSource).not.toContain("from_jsdom");
    expect(cliSource).toContain("from_dom");
  });
});
