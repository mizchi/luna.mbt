import { test, expect, type Page } from "@playwright/test";

/**
 * E2E tests for CSS Utilities with Web Components
 *
 * Tests that:
 * 1. CSS utility classes work correctly within ShadowDOM boundaries
 * 2. Each component instance has isolated CSS (no leaking between components)
 * 3. Hydration preserves CSS utility styles
 * 4. Multiple WC instances with same utility classes don't interfere
 *
 * Run with: cd examples/sol_app && pnpm test:e2e
 */

// Helper to wait for WC to be ready
async function waitForWcCounter(page: Page) {
  await page.waitForSelector("wc-counter");
  await page.waitForFunction(() => {
    const wc = document.querySelector("wc-counter");
    return wc && wc.shadowRoot;
  }, { timeout: 10000 });
}

test.describe("CSS Utilities + WebComponent Boundary", () => {
  test.describe("ShadowDOM CSS Isolation", () => {
    test("CSS styles inside ShadowDOM do not affect elements outside", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      // Add an element outside the WC with the same class name
      const result = await page.evaluate(() => {
        // Create element outside WC with same class
        const outsideEl = document.createElement("span");
        outsideEl.className = "count-display";
        outsideEl.textContent = "Outside WC";
        outsideEl.id = "outside-count";
        document.body.appendChild(outsideEl);

        // Get styles of both elements
        const outsideStyles = window.getComputedStyle(outsideEl);

        const wcCounter = document.querySelector("wc-counter");
        const insideEl = wcCounter?.shadowRoot?.querySelector(".count-display");
        const insideStyles = insideEl ? window.getComputedStyle(insideEl) : null;

        const result = {
          outsideFontSize: outsideStyles.fontSize,
          outsideFontWeight: outsideStyles.fontWeight,
          insideFontSize: insideStyles?.fontSize || "N/A",
          insideFontWeight: insideStyles?.fontWeight || "N/A",
        };

        // Cleanup
        outsideEl.remove();

        return result;
      });

      // Outside element should NOT have WC styles (32px, 700)
      expect(result.outsideFontSize).not.toBe("32px");
      expect(result.outsideFontWeight).not.toBe("700");

      // Inside element SHOULD have WC styles
      expect(result.insideFontSize).toBe("32px");
      expect(result.insideFontWeight).toBe("700");
    });

    test("ShadowDOM boundary isolates CSS even with same class names", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const result = await page.evaluate(() => {
        // Get WC's shadowRoot
        const wc = document.querySelector("wc-counter");
        if (!wc?.shadowRoot) return { error: "No shadowRoot" };

        // Query from document level - should NOT find ShadowDOM elements
        const docLevelQuery = document.querySelector(".count-display");

        // Query from shadowRoot - SHOULD find the element
        const shadowQuery = wc.shadowRoot.querySelector(".count-display");

        return {
          docLevelFound: !!docLevelQuery,
          shadowQueryFound: !!shadowQuery,
          shadowQueryText: shadowQuery?.textContent?.trim() || "",
        };
      });

      // Document-level query should NOT pierce ShadowDOM
      expect(result.docLevelFound).toBe(false);
      // ShadowRoot query should find the element
      expect(result.shadowQueryFound).toBe(true);
      expect(result.shadowQueryText).toBe("0");
    });
  });

  test.describe("Hydration Boundary Preservation", () => {
    test("CSS is preserved after hydration completes", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      // Check CSS immediately after hydration
      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");

      await expect(countDisplay).toHaveCSS("font-size", "32px");
      await expect(countDisplay).toHaveCSS("font-weight", "700");
    });

    test("CSS remains correct after state changes via hydrated handlers", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const incButton = wcCounter.locator("button.inc");

      // Initial CSS check
      await expect(countDisplay).toHaveCSS("font-size", "32px");

      // Click to trigger state change (via hydrated event handler)
      await incButton.click();
      await incButton.click();
      await incButton.click();

      // Verify state changed
      await expect(countDisplay).toContainText("3");

      // CSS should still be correct after state changes
      await expect(countDisplay).toHaveCSS("font-size", "32px");
      await expect(countDisplay).toHaveCSS("font-weight", "700");
    });

    test("Each WC instance hydrates independently", async ({ page }) => {
      await page.goto("/wc-multiple");

      // Wait for all WC instances
      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const wcCounters = page.locator("wc-counter");

      // Each counter should have independent state
      const counter1 = wcCounters.nth(0);
      const counter2 = wcCounters.nth(1);
      const counter3 = wcCounters.nth(2);

      // Increment only counter 1
      await counter1.locator("button.inc").click();

      // Check states are independent
      await expect(counter1.locator(".count-display")).toContainText("1");
      await expect(counter2.locator(".count-display")).toContainText("10");
      await expect(counter3.locator(".count-display")).toContainText("100");

      // All should have correct CSS
      await expect(counter1.locator(".count-display")).toHaveCSS("font-size", "32px");
      await expect(counter2.locator(".count-display")).toHaveCSS("font-size", "32px");
      await expect(counter3.locator(".count-display")).toHaveCSS("font-size", "32px");
    });
  });

  test.describe("Multiple Component CSS Isolation", () => {
    test("Each WC instance has its own style element in ShadowDOM", async ({ page }) => {
      await page.goto("/wc-multiple");

      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const result = await page.evaluate(() => {
        const counters = document.querySelectorAll("wc-counter");
        const styleInfo: { index: number; hasStyle: boolean; styleCount: number }[] = [];

        counters.forEach((wc, index) => {
          const shadow = wc.shadowRoot;
          if (shadow) {
            const styles = shadow.querySelectorAll("style");
            styleInfo.push({
              index,
              hasStyle: styles.length > 0,
              styleCount: styles.length,
            });
          }
        });

        return { count: counters.length, styleInfo };
      });

      expect(result.count).toBe(3);

      // Each WC should have its own style element
      for (const info of result.styleInfo) {
        expect(info.hasStyle).toBe(true);
        expect(info.styleCount).toBeGreaterThanOrEqual(1);
      }
    });

    test("Modifying one WC does not affect CSS of others", async ({ page }) => {
      await page.goto("/wc-multiple");

      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const wcCounters = page.locator("wc-counter");

      // Interact with counter 1 extensively
      const counter1 = wcCounters.nth(0);
      for (let i = 0; i < 10; i++) {
        await counter1.locator("button.inc").click();
      }

      // All counters should still have correct CSS
      for (let i = 0; i < 3; i++) {
        const counter = wcCounters.nth(i);
        await expect(counter.locator(".count-display")).toHaveCSS("font-size", "32px");
        await expect(counter.locator(".count-display")).toHaveCSS("font-weight", "700");
      }
    });
  });

  test.describe("Navigation and CSS Persistence", () => {
    test("CSS is correctly applied after navigation to WC page", async ({ page }) => {
      // Start at home page
      await page.goto("/");
      await page.waitForTimeout(300);

      // Navigate to wc-counter
      const link = page.locator('a[href="/wc-counter"]');
      if (await link.count() > 0) {
        await link.click();
        await waitForWcCounter(page);

        // CSS should be applied
        const wcCounter = page.locator("wc-counter");
        await expect(wcCounter.locator(".count-display")).toHaveCSS("font-size", "32px");
      }
    });

    test("CSS does not leak to document after navigating away from WC page", async ({ page }) => {
      // Start at wc-counter
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      // Navigate away
      const homeLink = page.locator('a[href="/"]');
      if (await homeLink.count() > 0) {
        await homeLink.click();
        await page.waitForTimeout(500);

        // Check that no WC CSS leaked to document.head
        const leakCheck = await page.evaluate(() => {
          const headStyles = document.head.querySelectorAll("style");
          let wcStylesInHead = 0;

          headStyles.forEach(style => {
            const content = style.textContent || "";
            // WC-specific CSS patterns
            if (content.includes(":host") && content.includes(".count-display")) {
              wcStylesInHead++;
            }
          });

          return { wcStylesInHead };
        });

        expect(leakCheck.wcStylesInHead).toBe(0);
      }
    });

    test("Re-navigating to WC page reapplies CSS correctly", async ({ page }) => {
      // Navigate: / -> /wc-counter -> / -> /wc-counter
      await page.goto("/");
      await page.waitForTimeout(200);

      // First navigation to wc-counter
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      await expect(wcCounter.locator(".count-display")).toHaveCSS("font-size", "32px");

      // Navigate away
      await page.goto("/");
      await page.waitForTimeout(200);

      // Second navigation to wc-counter
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      // CSS should still be correct
      await expect(wcCounter.locator(".count-display")).toHaveCSS("font-size", "32px");
      await expect(wcCounter.locator(".count-display")).toHaveCSS("font-weight", "700");
    });
  });

  test.describe("SSR CSS Embedding", () => {
    test("SSR generates style tag inside Declarative Shadow DOM template", async ({ page, baseURL }) => {
      // Fetch raw HTML without JS execution
      const response = await page.request.get(`${baseURL}/wc-counter`);
      const html = await response.text();

      // Verify structure: <template shadowrootmode="open"> contains <style>
      expect(html).toContain('<template shadowrootmode="open">');
      expect(html).toMatch(/<style id="style-\d+">/);
      expect(html).toContain(":host");
    });

    test("SSR CSS includes all required selectors for component", async ({ page, baseURL }) => {
      const response = await page.request.get(`${baseURL}/wc-counter`);
      const html = await response.text();

      // Extract CSS from inside the Shadow DOM template (not global styles)
      // Match: <template shadowrootmode="open">...<style>...</style>...</template>
      const templateMatch = html.match(/<template shadowrootmode="open">([\s\S]*?)<\/template>/);
      expect(templateMatch).not.toBeNull();

      const templateContent = templateMatch![1];
      const styleMatch = templateContent.match(/<style[^>]*>([\s\S]*?)<\/style>/);
      expect(styleMatch).not.toBeNull();

      const cssContent = styleMatch![1];

      // Verify key selectors are present
      expect(cssContent).toContain(":host");
      expect(cssContent).toContain(".counter");
      expect(cssContent).toContain(".count-display");
      expect(cssContent).toContain(".buttons");
    });

    test("Multiple WC instances each have their own SSR style tag", async ({ page, baseURL }) => {
      const response = await page.request.get(`${baseURL}/wc-multiple`);
      const html = await response.text();

      // Count style tags with hash IDs (SSR-generated)
      const styleMatches = html.match(/<style id="style-\d+">/g) || [];

      // Should have 3 style tags (one per WC instance)
      expect(styleMatches.length).toBe(3);
    });
  });

  test.describe("CSS Deduplication in Multiple Instances", () => {
    test("Same CSS rules are applied to all instances from separate style tags", async ({ page }) => {
      await page.goto("/wc-multiple");

      await page.waitForFunction(() => {
        const counters = document.querySelectorAll("wc-counter");
        return counters.length === 3 && Array.from(counters).every(wc => wc.shadowRoot);
      }, { timeout: 10000 });

      const result = await page.evaluate(() => {
        const counters = document.querySelectorAll("wc-counter");
        const cssInfo: { hostDisplay: string; countDisplayFontSize: string }[] = [];

        counters.forEach(wc => {
          const shadow = wc.shadowRoot;
          if (shadow) {
            // Get computed styles to verify CSS is applied
            const host = wc as HTMLElement;
            const countDisplay = shadow.querySelector(".count-display") as HTMLElement;

            cssInfo.push({
              hostDisplay: window.getComputedStyle(host).display,
              countDisplayFontSize: countDisplay ? window.getComputedStyle(countDisplay).fontSize : "N/A",
            });
          }
        });

        return cssInfo;
      });

      // All instances should have same CSS applied
      for (const info of result) {
        expect(info.hostDisplay).toBe("block"); // :host { display: block }
        expect(info.countDisplayFontSize).toBe("32px"); // .count-display { font-size: 2rem }
      }
    });
  });

  test.describe("Error Resilience", () => {
    test("No console errors related to CSS during hydration", async ({ page }) => {
      const cssErrors: string[] = [];
      page.on("console", msg => {
        const text = msg.text();
        if (msg.type() === "error" && (text.includes("CSS") || text.includes("style"))) {
          cssErrors.push(text);
        }
      });

      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      // Interact with component
      const wcCounter = page.locator("wc-counter");
      await wcCounter.locator("button.inc").click();
      await wcCounter.locator("button.inc").click();

      await page.waitForTimeout(300);

      expect(cssErrors).toEqual([]);
    });

    test("CSS remains functional after rapid interactions", async ({ page }) => {
      await page.goto("/wc-counter");
      await waitForWcCounter(page);

      const wcCounter = page.locator("wc-counter");
      const countDisplay = wcCounter.locator(".count-display");
      const incButton = wcCounter.locator("button.inc");

      // Rapid clicks
      for (let i = 0; i < 20; i++) {
        await incButton.click();
      }

      // CSS should still be intact
      await expect(countDisplay).toContainText("20");
      await expect(countDisplay).toHaveCSS("font-size", "32px");
      await expect(countDisplay).toHaveCSS("font-weight", "700");
    });
  });
});
