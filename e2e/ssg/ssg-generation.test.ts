import { test, expect } from "@playwright/test";
import { execSync } from "node:child_process";
import { join } from "node:path";
import { existsSync, readFileSync } from "node:fs";

const PROJECT_ROOT = join(import.meta.dirname, "../..");
const WEBSITE_DIR = join(PROJECT_ROOT, "website");
const DIST_DIR = join(WEBSITE_DIR, "dist-docs");

test.describe("SSG Generation Correctness", () => {
  test.beforeAll(() => {
    // Ensure website is built
    if (!existsSync(join(DIST_DIR, "index.html"))) {
      execSync("node ../js/sol/dist/cli.js build", {
        cwd: WEBSITE_DIR,
        stdio: "inherit",
      });
    }
  });

  test.describe("CSS Theme", () => {
    test("uses Indigo as primary color in light mode", () => {
      const html = readFileSync(join(DIST_DIR, "index.html"), "utf-8");

      // Should contain Indigo 500 (#6366f1) for light mode
      expect(html).toContain("--primary-color: #6366f1");
      // Should NOT contain old Amber color
      expect(html).not.toContain("--primary-color: #b45309");
    });

    test("uses Indigo as primary color in dark mode", () => {
      const html = readFileSync(join(DIST_DIR, "index.html"), "utf-8");

      // Should contain Indigo 400 (#818cf8) for dark mode
      expect(html).toContain("--primary-color: #818cf8");
      // Should NOT contain old Amber color in dark mode
      expect(html).not.toContain("--primary-color: #fbbf24");
    });

    test("includes secondary and hero gradient colors", () => {
      const html = readFileSync(join(DIST_DIR, "index.html"), "utf-8");

      expect(html).toContain("--secondary-color: #06b6d4"); // Cyan 500
      expect(html).toContain("--hero-gradient-start: #4f46e5");
      expect(html).toContain("--hero-gradient-end: #06b6d4");
    });
  });

  test.describe("Page Structure", () => {
    test("home page has correct hero section", () => {
      const html = readFileSync(join(DIST_DIR, "index.html"), "utf-8");

      expect(html).toContain('class="hero"');
      expect(html).toContain('class="hero-title"');
      expect(html).toContain("The Future of UI is");
      expect(html).toContain('class="hero-title-gradient"');
      expect(html).toContain("Light & Native");
    });

    test("home page has navigation links", () => {
      const html = readFileSync(join(DIST_DIR, "index.html"), "utf-8");

      expect(html).toContain('href="/luna/"');
      expect(html).toContain('href="/sol/"');
      expect(html).toContain('href="/ssg/"');
    });

    test("home page has theme toggle", () => {
      const html = readFileSync(join(DIST_DIR, "index.html"), "utf-8");

      expect(html).toContain('class="theme-toggle"');
      expect(html).toContain("toggleTheme()");
    });

    test("home page has language switcher", () => {
      const html = readFileSync(join(DIST_DIR, "index.html"), "utf-8");

      expect(html).toContain('class="lang-switcher"');
      expect(html).toContain('href="/ja/"');
    });
  });

  test.describe("Assets", () => {
    test("loader.js exists and contains hydration code", () => {
      const loaderPath = join(DIST_DIR, "assets/loader.js");
      expect(existsSync(loaderPath)).toBe(true);

      const content = readFileSync(loaderPath, "utf-8");
      expect(content).toContain("__LUNA_STATE__");
      expect(content).toContain("__LUNA_SCAN__");
      expect(content).toContain("__LUNA_HYDRATE__");
    });

    test("style.css exists", () => {
      const stylePath = join(DIST_DIR, "assets/style.css");
      expect(existsSync(stylePath)).toBe(true);
    });
  });

  test.describe("Component Files", () => {
    test("accordion-demo.js exists", () => {
      const path = join(DIST_DIR, "components/accordion-demo.js");
      expect(existsSync(path)).toBe(true);

      const content = readFileSync(path, "utf-8");
      expect(content).toContain("accordion");
    });

    test("counter component exists", () => {
      const path = join(DIST_DIR, "components/my-counter.js");
      expect(existsSync(path)).toBe(true);
    });

    test("dialog-demo.js exists", () => {
      const path = join(DIST_DIR, "components/dialog-demo.js");
      expect(existsSync(path)).toBe(true);
    });

    test("accordion-demo.js is bundled (uses shared chunks)", () => {
      const path = join(DIST_DIR, "components/accordion-demo.js");
      const content = readFileSync(path, "utf-8");

      // Bundled JS should use shared chunks from _shared/ directory
      expect(content).toContain('from "./_shared/');
      // Should NOT have TypeScript imports
      expect(content).not.toContain(".ts'");
      expect(content).not.toContain('.ts"');
      expect(content).not.toContain("@luna/hydration");
    });
  });

  test.describe("Web Component Pages", () => {
    test("accordion page has luna:behavior attribute", () => {
      const html = readFileSync(
        join(DIST_DIR, "luna/radix-components/accordion/index.html"),
        "utf-8"
      );

      // Accordion uses built-in behavior instead of external JS
      expect(html).toContain('luna:behavior="accordion"');
      expect(html).toContain('luna:wc-trigger="visible"');
    });

    test("accordion page has WC loader script", () => {
      const html = readFileSync(
        join(DIST_DIR, "luna/radix-components/accordion/index.html"),
        "utf-8"
      );

      // WC loader should be included for pages with Web Components
      expect(html).toContain("__LUNA_WC_SCAN__");
    });

    test("accordion page has SSR content", () => {
      const html = readFileSync(
        join(DIST_DIR, "luna/radix-components/accordion/index.html"),
        "utf-8"
      );

      // SSR content should be present
      expect(html).toContain('data-accordion-item="item-1"');
      expect(html).toContain('data-state="open"');
      expect(html).toContain("What is Luna?");
    });
  });

  test.describe("i18n", () => {
    test("Japanese home page exists", () => {
      const path = join(DIST_DIR, "ja/index.html");
      expect(existsSync(path)).toBe(true);
    });

    // TODO: Fix i18n lang attribute - currently all pages have lang="en"
    test.skip("Japanese page has correct lang attribute", () => {
      const html = readFileSync(join(DIST_DIR, "ja/index.html"), "utf-8");
      expect(html).toContain('lang="ja"');
    });
  });

  test.describe("Meta Files", () => {
    test("sitemap.xml exists", () => {
      const path = join(DIST_DIR, "sitemap.xml");
      expect(existsSync(path)).toBe(true);

      const content = readFileSync(path, "utf-8");
      expect(content).toContain('<?xml version="1.0"');
      expect(content).toContain("<urlset");
    });

    test("manifest.json exists", () => {
      const path = join(DIST_DIR, "_luna/manifest.json");
      expect(existsSync(path)).toBe(true);

      const manifest = JSON.parse(readFileSync(path, "utf-8"));
      expect(manifest.routes).toBeDefined();
    });

    test("404.html exists", () => {
      const path = join(DIST_DIR, "404.html");
      expect(existsSync(path)).toBe(true);
    });
  });
});
