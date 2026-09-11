/**
 * Tests for CLI scaffold templates (Issue #12)
 * Verifies that generated templates use correct API signatures and dependencies.
 */
import { describe, test, expect } from "vitest";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";

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
  test("scaffolds current MoonBit manifest filenames", () => {
    const stage = fs.mkdtempSync(path.join(tmpdir(), "luna-mbt-template-"));
    try {
      const result = spawnSync(
        path.resolve(__dirname, "../../../sol/node_modules/.bin/tsx"),
        [cliPath, "new", "sample", "--mbt"],
        { cwd: stage, encoding: "utf8" }
      );
      expect(result.status, result.stderr).toBe(0);
      const project = path.join(stage, "sample");
      expect(fs.readFileSync(path.join(project, "moon.mod"), "utf8")).toContain('name = "internal/sample"');
      expect(fs.readFileSync(path.join(project, "src/moon.pkg"), "utf8")).toContain('"mizchi/signals" @signal');
      expect(fs.existsSync(path.join(project, "moon.mod.json"))).toBe(false);
      expect(fs.existsSync(path.join(project, "src/moon.pkg.json"))).toBe(false);
    } finally {
      fs.rmSync(stage, { recursive: true, force: true });
    }
  });

  test("moon.mod should include mizchi/signals dependency", () => {
    expect(cliSource).toMatch(/"mizchi\/signals@\d+\.\d+\.\d+"/);
  });

  test("moon.mod should use up-to-date mizchi/luna version (>= 0.16.0)", () => {
    // Should NOT contain the old version "0.1.3"
    expect(cliSource).not.toContain('"mizchi/luna@0.1.3"');
  });

  test("moon.mod should use up-to-date mizchi/js version (>= 0.10.14)", () => {
    expect(cliSource).not.toContain('"mizchi/js@0.10.6"');
  });
});

describe("Issue #12: CLI MoonBit template - import paths", () => {
  test("moon.pkg should import mizchi/signals, not mizchi/luna/signal", () => {
    // Old: "mizchi/luna/signal"
    // New: "mizchi/signals" @signal
    expect(cliSource).not.toMatch(/"mizchi\/luna\/signal"/);
  });

  test("moon.pkg should import mizchi/luna/dom, not mizchi/luna/platform/dom/element", () => {
    expect(cliSource).not.toContain("mizchi/luna/platform/dom/element");
  });
});

describe("Issue #12: CLI MoonBit template - lib.mbt API", () => {
  test("lib.mbt should use DomElement::from_dom, not from_jsdom", () => {
    expect(cliSource).not.toContain("from_jsdom");
    expect(cliSource).toContain("from_dom");
  });
});

describe("CLI MoonBit template - buildable out of the box", () => {
  // 0.23.0's _bench subpackage imports mizchi/js/browser/dom, which the
  // pinned mizchi/js@0.12.1 does not export, so `moon build` fails with
  // "Cannot find import 'mizchi/js/browser/dom' in mizchi/luna/_bench@0.23.0".
  test("moon.mod must not pin the broken mizchi/luna 0.23.0", () => {
    expect(cliSource).not.toContain('"mizchi/luna@0.23.0"');
  });

  // vite-plugin-moonbit resolves `mbt:` imports to the RELEASE artifact
  // (_build/js/release/build/<name>.js). A plain `moon build` writes debug/,
  // so vite dies with "failed to resolve import 'mbt:internal/<name>'".
  // Both the build script and the printed getting-started must use --release.
  test("build script must build release, not debug", () => {
    expect(cliSource).not.toContain('"moon build && vite build"');
    expect(cliSource).toContain("moon build --target js --release && vite build");
  });

  test("printed getting-started must instruct a release build", () => {
    expect(cliSource).toContain("moon build --target js --release`");
    expect(cliSource).not.toMatch(/console\.log\(`\s*moon build`\)/);
  });
});
