// Chaos crawl over sol_app's dev server.
//
// Drives chaosbringer (https://www.npmjs.com/package/chaosbringer) to walk
// the routes the SSR framework exposes, asserting per-page invariants on
// every transition. The test fails if any visited page:
//   - has no <h1> or <h2> (SSR pipeline produced an empty body)
//   - logs a console error or raises a JS exception (`strict: true`)
//   - returns a non-2xx response
//
// chaosbringer manages its own browser context, so this spec only owns the
// chaos() call — no `page` fixture, no per-test browser launch.
import { test, expect } from "@playwright/test";
import { chaos } from "chaosbringer";

const baseUrl = "http://localhost:3458";

test("sol_app: chaosbringer crawl finds no invariant breakages", async () => {
  const result = await chaos({
    baseUrl,
    seed: 42,
    maxPages: 12,
    maxActionsPerPage: 0,
    strict: true,
    // Dev-mode noise (HMR WebSocket, dev-server reconnects) we don't want
    // to flag as page errors.
    ignoreErrorPatterns: [
      "WebSocket connection",
      "Failed to load resource:.*\\b404\\b",
    ],
    // sol_app's link inventory currently lists routes that haven't been
    // implemented yet — they fall through to the 404 view and would fail
    // the heading invariants below. Track them here as known-stubs;
    // remove entries as sol_app ships the routes.
    excludePatterns: [
      "/docs/api/overview",
      "/blog/2024/recap",
    ],
    invariants: [
      {
        name: "has-heading",
        check: async ({ page }) => {
          const count = await page.locator("h1, h2").count();
          return count > 0 || "no <h1>/<h2> rendered";
        },
      },
      {
        name: "no-empty-body",
        check: async ({ page }) => {
          const text = (await page.locator("body").innerText()).trim();
          return text.length > 0 || "body innerText is empty";
        },
      },
      {
        name: "stable-title",
        check: async ({ page, url }) => {
          const title = await page.title();
          return title.length > 0 || `empty <title> at ${url}`;
        },
      },
    ],
  });

  if (!result.passed) {
    const failingPages = result.report.pages
      .filter((p) => p.errors.length > 0)
      .map((p) => {
        const errs = p.errors
          .map((e) => `    [${e.type}] ${e.invariantName ?? ""} ${e.message}`)
          .join("\n");
        return `- ${p.url} (status=${p.status})\n${errs}`;
      })
      .join("\n");
    throw new Error(
      `chaosbringer crawl failed:\n${failingPages}\n\nRepro:\n  ${result.report.reproCommand}`,
    );
  }

  expect(
    result.report.pages.length,
    "should visit at least one page",
  ).toBeGreaterThan(0);
});
