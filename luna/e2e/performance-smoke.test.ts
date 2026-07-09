import { test, expect } from "@playwright/test";

const LOAD_BUDGET_MS = 5000;
const HYDRATION_BUDGET_MS = 5000;
const INTERACTION_BUDGET_MS = 1000;

test.describe("performance smoke", () => {
  test("spa reaches first usable heading within budget", async ({ page }) => {
    await page.goto("/spa");
    await expect(page.getByRole("heading", { name: "Luna Examples" })).toBeVisible();

    const timing = await page.evaluate(() => {
      const nav = performance.getEntriesByType("navigation")[0] as PerformanceNavigationTiming | undefined;
      return {
        domContentLoaded: nav ? nav.domContentLoadedEventEnd - nav.startTime : 0,
        load: nav && nav.loadEventEnd > 0 ? nav.loadEventEnd - nav.startTime : 0,
      };
    });

    expect(timing.domContentLoaded).toBeGreaterThan(0);
    expect(timing.domContentLoaded).toBeLessThan(LOAD_BUDGET_MS);
    if (timing.load > 0) {
      expect(timing.load).toBeLessThan(LOAD_BUDGET_MS);
    }
  });

  test("counter first interaction commits within budget", async ({ page }) => {
    await page.goto("/spa");
    const counter = page.locator(".counter-example");
    await expect(counter).toBeVisible();
    await expect(counter.locator("p").first()).toContainText("Count: 0");

    const elapsed = await page.evaluate(async () => {
      const section = document.querySelector(".counter-example");
      if (!section) throw new Error("counter section not found");
      const button = Array.from(section.querySelectorAll("button")).find((el) =>
        el.textContent?.includes("+"),
      );
      const count = section.querySelector("p");
      if (!button || !count) throw new Error("counter controls not found");

      const start = performance.now();
      button.dispatchEvent(new MouseEvent("click", { bubbles: true, cancelable: true }));

      await new Promise<void>((resolve, reject) => {
        const deadline = window.setTimeout(() => {
          observer.disconnect();
          reject(new Error("counter update timed out"));
        }, 1000);
        const observer = new MutationObserver(() => {
          if (count.textContent?.includes("Count: 1")) {
            window.clearTimeout(deadline);
            observer.disconnect();
            resolve();
          }
        });
        observer.observe(count, { childList: true, characterData: true, subtree: true });
        if (count.textContent?.includes("Count: 1")) {
          window.clearTimeout(deadline);
          observer.disconnect();
          resolve();
        }
      });

      return performance.now() - start;
    });

    expect(elapsed).toBeLessThan(INTERACTION_BUDGET_MS);
    await expect(counter.locator("p").first()).toContainText("Count: 1");
  });

  test("hydrated browser example becomes usable within budget", async ({ page }) => {
    await page.goto("/browser/signal-effect");

    const app = page.locator("#app");
    await expect(app).toHaveAttribute("data-hydrated", "true");
    await expect(page.locator("[data-count]")).toHaveText("5");

    const hydratedAt = await page.evaluate(() => {
      const nav = performance.getEntriesByType("navigation")[0] as PerformanceNavigationTiming | undefined;
      return performance.now() - (nav?.startTime ?? 0);
    });

    expect(hydratedAt).toBeLessThan(HYDRATION_BUDGET_MS);

    await page.locator("[data-inc]").click();
    await expect(page.locator("[data-count]")).toHaveText("6");
  });
});
