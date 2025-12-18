import { test, expect } from "@playwright/test";

/**
 * E2E tests for Web Components CSS isolation
 *
 * Tests that CSS injected via use_style() is correctly placed inside
 * the ShadowRoot, not leaked to document.head.
 *
 * Bug reproduction:
 * / -> /wc-counter -> / navigation causes WC CSS to leak to document.head,
 * affecting elements with same class names on other pages.
 */
test.describe("WC CSS Isolation", () => {
  test.describe("CSS leak on navigation", () => {
    /**
     * CRITICAL TEST: Reproduces the CSS leak bug
     *
     * Scenario:
     * 1. Navigate to / (home page with .count-display that has NO special styling)
     * 2. Navigate to /wc-counter (WC with .count-display that has font-size: 2rem, font-weight: bold)
     * 3. Navigate back to / (home page)
     * 4. Check if .count-display on home page is affected by WC CSS leak
     *
     * Expected: Home page .count-display should NOT have WC CSS styles
     * Bug: If use_style leaks to document.head, home page gets WC styles
     */
    test("navigating / -> /wc-counter -> / should NOT leak WC CSS to home page", async ({ page }) => {
      // Step 1: Go to home page first and check initial .count-display styles
      await page.goto("/");
      await page.waitForTimeout(500);

      const initialStyles = await page.evaluate(() => {
        const countDisplay = document.querySelector(".count-display");
        if (!countDisplay) {
          return { error: "No .count-display on home page" };
        }
        const styles = window.getComputedStyle(countDisplay);
        return {
          fontSize: styles.fontSize,
          fontWeight: styles.fontWeight,
        };
      });

      // Home page .count-display should have default browser styles (not WC styles)
      // WC CSS has: font-size: 2rem (32px), font-weight: bold (700)
      console.log("Initial home page styles:", initialStyles);

      // Step 2: Navigate to /wc-counter (triggers WC hydration with use_style)
      await page.click('a[href="/wc-counter"]');
      await page.waitForTimeout(1000);

      // Verify we're on wc-counter page and WC is hydrated
      const wcCounterStyles = await page.evaluate(() => {
        const wcCounter = document.querySelector("wc-counter");
        if (!wcCounter || !wcCounter.shadowRoot) {
          return { error: "No wc-counter or shadowRoot" };
        }
        const countDisplay = wcCounter.shadowRoot.querySelector(".count-display");
        if (!countDisplay) {
          return { error: "No .count-display in WC shadowRoot" };
        }
        const styles = window.getComputedStyle(countDisplay);
        return {
          fontSize: styles.fontSize,
          fontWeight: styles.fontWeight,
        };
      });

      console.log("WC counter styles:", wcCounterStyles);

      // WC .count-display should have WC CSS styles
      expect(wcCounterStyles).not.toHaveProperty("error");
      expect(wcCounterStyles.fontSize).toBe("32px"); // 2rem
      expect(wcCounterStyles.fontWeight).toBe("700"); // bold

      // Step 3: Check if CSS leaked to document.head
      const headLeakCheck = await page.evaluate(() => {
        const styles = document.head.querySelectorAll("style");
        const leakedStyles: Array<{ id: string; content: string }> = [];

        styles.forEach(style => {
          const content = style.textContent || "";
          // WC-specific patterns that should ONLY be in shadowRoot
          if (content.includes(".count-display") && content.includes("font-size")) {
            leakedStyles.push({
              id: style.id || "(no id)",
              content: content.substring(0, 200),
            });
          }
        });

        return {
          totalStylesInHead: styles.length,
          leakedCount: leakedStyles.length,
          leakedStyles,
        };
      });

      console.log("Head leak check:", headLeakCheck);

      // CRITICAL: WC CSS should NOT be in document.head
      expect(headLeakCheck.leakedCount).toBe(0);

      // Step 4: Navigate back to home
      await page.click('a[href="/"]');
      await page.waitForTimeout(500);

      // Step 5: Check home page .count-display styles after navigation
      const afterNavStyles = await page.evaluate(() => {
        const countDisplay = document.querySelector(".count-display");
        if (!countDisplay) {
          return { error: "No .count-display on home page after nav" };
        }
        const styles = window.getComputedStyle(countDisplay);
        return {
          fontSize: styles.fontSize,
          fontWeight: styles.fontWeight,
        };
      });

      console.log("After navigation home page styles:", afterNavStyles);

      // Home page .count-display should NOT have WC CSS styles
      // If it has font-size: 32px and font-weight: 700, CSS leaked!
      if (!("error" in afterNavStyles)) {
        expect(afterNavStyles.fontSize).not.toBe("32px");
        expect(afterNavStyles.fontWeight).not.toBe("700");
      }
    });

    test("WC CSS should stay inside shadowRoot, not leak to document.head", async ({ page }) => {
      // Capture console logs for debugging
      page.on("console", msg => {
        if (msg.text().includes("[use_style]")) {
          console.log(`[Browser] ${msg.text()}`);
        }
      });

      await page.goto("/wc-counter");
      await page.waitForTimeout(1000);

      const result = await page.evaluate(() => {
        const wcCounter = document.querySelector("wc-counter");
        if (!wcCounter || !wcCounter.shadowRoot) {
          return { error: "No wc-counter or shadowRoot" };
        }

        // Check shadowRoot has style
        const styleInShadow = wcCounter.shadowRoot.querySelector("style");
        const shadowStyleContent = styleInShadow?.textContent || "";

        // Check document.head for leaked WC styles
        const headStyles = document.head.querySelectorAll("style");
        let leakedToHead = false;
        let leakedContent = "";

        headStyles.forEach(style => {
          const content = style.textContent || "";
          if (content.includes(":host") || content.includes(".count-display")) {
            leakedToHead = true;
            leakedContent = content.substring(0, 100);
          }
        });

        return {
          hasStyleInShadow: !!styleInShadow,
          shadowHasCountDisplay: shadowStyleContent.includes(".count-display"),
          shadowHasHost: shadowStyleContent.includes(":host"),
          leakedToHead,
          leakedContent,
        };
      });

      expect(result).not.toHaveProperty("error");
      expect(result.hasStyleInShadow).toBe(true);
      expect(result.shadowHasCountDisplay).toBe(true);
      expect(result.shadowHasHost).toBe(true);
      // CRITICAL: Should NOT leak to document.head
      expect(result.leakedToHead).toBe(false);
    });
  });

  test.describe("CSS isolation verification", () => {
    test("external element with same class should NOT get WC styles", async ({ page }) => {
      await page.goto("/wc-counter");
      await page.waitForTimeout(1000);

      const result = await page.evaluate(() => {
        // Create external element with same class as WC internal element
        const externalDiv = document.createElement("div");
        externalDiv.className = "count-display";
        externalDiv.textContent = "External Count Display";
        document.body.appendChild(externalDiv);

        const styles = window.getComputedStyle(externalDiv);

        // Cleanup
        externalDiv.remove();

        return {
          fontSize: styles.fontSize,
          fontWeight: styles.fontWeight,
        };
      });

      // External .count-display should NOT have WC CSS
      // WC CSS: font-size: 2rem (32px), font-weight: bold (700)
      expect(result.fontSize).not.toBe("32px");
      expect(result.fontWeight).not.toBe("700");
    });
  });
});
