import { test, expect, type Page } from "@playwright/test";
import { build } from "esbuild";
import { resolve } from "node:path";

let formModule: string;
test.beforeAll(async () => {
  const result = await build({
    stdin: {
      contents: `
        import { createRoot } from './js/luna/src/index.ts';
        import { useActionForm } from './js/luna/src/sol/form.ts';
        export function createForm() {
          return createRoot(dispose => ({ dispose, fields: useActionForm({ name: '', email: '' }) }));
        }
      `,
      resolveDir: resolve(import.meta.dirname, "../.."),
    },
    bundle: true,
    write: false,
    format: "esm",
    platform: "browser",
  });
  formModule = result.outputFiles[0].text;
});

async function hydrated(page: Page, host: string) {
  await expect(page.locator(host)).toHaveAttribute("data-sol-hydrated", "");
  return page.locator(host);
}

test.describe("sol_app island hydration", () => {
  let errors: string[];
  test.beforeEach(async ({ page }) => {
    errors = [];
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("console", (message) => {
      if (message.type() === "error" && message.text().includes("[sol] Hydration failed")) {
        errors.push(message.text());
      }
    });
  });
  test.afterEach(() => expect(errors).toEqual([]));

  test("home counter renders and increments after hydration", async ({ page }) => {
    await page.goto("/");
    await expect(page.getByRole("heading", { name: "Welcome to Sol" })).toBeVisible();
    const counter = await hydrated(page, "luna-counter");
    const display = counter.locator(".count-display");
    const initial = Number(await display.textContent());
    await counter.getByRole("button", { name: "+", exact: true }).click();
    await expect(display).toHaveText(String(initial + 1));
  });

  test("counter module loads and exports its hydration entry point", async ({ page }) => {
    await page.goto("/");
    await hydrated(page, "luna-counter");
    const module = await page.evaluate(async () => {
      const url = "/static/counter.js";
      const response = await fetch(url);
      return { status: response.status, hydrate: typeof (await import(url)).hydrate };
    });
    expect(module).toEqual({ status: 200, hydrate: "function" });
  });

  test("navigation unload stops effects on a detached counter", async ({ page }) => {
    await page.goto("/");
    await hydrated(page, "luna-counter");
    const result = await page.evaluate(async () => {
      const host = document.querySelector("luna-counter")!;
      const root = host.shadowRoot ?? host;
      const display = root.querySelector(".count-display")!;
      const button = [...root.querySelectorAll("button")].find((el) => el.textContent === "+")!;
      const before = display.textContent;
      const unload = (window as unknown as { __LUNA_UNLOAD_ALL__: (root: Element) => void })
        .__LUNA_UNLOAD_ALL__;
      unload(host);
      host.remove();
      button.click();
      await Promise.resolve();
      return { before, after: display.textContent };
    });
    expect(result.after).toBe(result.before);
  });

  test("API health endpoint returns JSON", async ({ request }) => {
    const response = await request.get("/api/health");
    expect(response.status()).toBe(200);
    expect(await response.json()).toHaveProperty("status", "ok");
  });

  test("counter hydrates again after CSR navigation", async ({ page }) => {
    await page.goto("/");
    await hydrated(page, "luna-counter");
    await page.getByRole("link", { name: "About", exact: true }).click();
    await expect(page).toHaveURL(/\/about$/);
    await expect(page.getByRole("heading", { name: "About" })).toBeVisible();
    await page.getByRole("link", { name: "Home", exact: true }).click();
    const counter = await hydrated(page, "luna-counter");
    const display = counter.locator(".count-display");
    const initial = Number(await display.textContent());
    await counter.getByRole("button", { name: "+", exact: true }).click();
    await expect(display).toHaveText(String(initial + 1));
  });

  test("form binds input and submits an action", async ({ page }) => {
    await page.goto("/form");
    const form = await hydrated(page, "contact-form");
    await form.getByLabel("Name").fill("Hydration Test");
    await form.getByLabel("Email").fill("hydration@example.com");
    await expect(form.locator(".preview-name")).toContainText("Hydration Test");
    await form.getByRole("button", { name: "Submit" }).click();
    await expect(form.locator(".form-result")).toContainText("Form submitted successfully!");
  });

  test("shared form posts to Sol and refreshes fragments without a document reload", async ({
    page,
  }) => {
    await page.route("**/__contract/sol-form.js", (route) =>
      route.fulfill({ contentType: "text/javascript", body: formModule }),
    );
    await page.goto("/form");
    await hydrated(page, "contact-form");
    const result = await page.evaluate(async () => {
      const action = (
        document.querySelector("contact-form")!.shadowRoot ??
        document.querySelector("contact-form")!
      )
        .querySelector("form")!
        .getAttribute("action")!;
      const moduleUrl = "/__contract/sol-form.js";
      const { createForm } = await import(moduleUrl);
      const { fields, dispose } = createForm();
      try {
        fields.setData("name", "Shared form");
        fields.setData("email", "invalid");
        await fields.post(action);
        const failed = { status: fields.error?.status, email: fields.data.email };
        fields.setData("email", "shared@example.com");
        await fields.post(action);
        return { failed, success: fields.wasSuccessful, pending: fields.pending };
      } finally {
        dispose();
      }
    });
    expect(result).toEqual({
      failed: { status: 400, email: "invalid" },
      success: true,
      pending: false,
    });
    await hydrated(page, "contact-form");
    await expect(page).toHaveURL(/\/form$/);
  });

  test("loader disposes an async renderer that finishes after DOM removal", async ({ page }) => {
    await page.route("**/__contract/async-island.js", (route) =>
      route.fulfill({
        contentType: "text/javascript",
        body: `export async function hydrate() {
        window.__lateDisposed = 0;
        await new Promise(resolve => { window.__finishLateMount = resolve; });
        return () => { window.__lateDisposed++; };
      }`,
      }),
    );
    await page.goto("/");
    await hydrated(page, "luna-counter");
    await page.evaluate(() => {
      const host = document.createElement("section");
      host.id = "late-island";
      host.setAttribute("luna:url", "/__contract/async-island.js");
      host.setAttribute("luna:trigger", "none");
      document.body.append(host);
      void (
        window as unknown as { __LUNA_HYDRATE__: (el: Element) => Promise<void> }
      ).__LUNA_HYDRATE__(host);
    });
    await page.waitForFunction(() => typeof (window as any).__finishLateMount === "function");
    await page.evaluate(() => {
      document.getElementById("late-island")!.remove();
      (window as any).__finishLateMount();
    });
    await expect.poll(() => page.evaluate(() => (window as any).__lateDisposed)).toBe(1);
  });

  test("WC counter renders and increments inside its shadow root", async ({ page }) => {
    await page.goto("/wc-counter");
    const counter = await hydrated(page, "wc-counter");
    const display = counter.locator(".count-display");
    await expect(display).toHaveText("0");
    await counter.getByRole("button", { name: "+", exact: true }).click();
    await expect(display).toHaveText("1");
  });

  test("WC modules use the native URL cache and preserve JSON escape sequences", async ({
    page,
  }) => {
    let requests = 0;
    await page.route("**/__contract/wc-cache.js?*", (route) => {
      requests++;
      return route.fulfill({
        contentType: "text/javascript",
        body: `
        window.__wcEvaluations = (window.__wcEvaluations || 0) + 1;
        export function hydrate(element, state) {
          element.textContent = state.label;
          element.setAttribute('data-version', new URL(import.meta.url).searchParams.get('v'));
          return () => { window.__wcDisposals = (window.__wcDisposals || 0) + 1; };
        }
      `,
      });
    });
    await page.goto("/wc-counter");
    await hydrated(page, "wc-counter");
    const result = await page.evaluate(async () => {
      const runtime = window as unknown as {
        __LUNA_WC_HYDRATE__: (el: Element) => Promise<void>;
        __LUNA_WC_UNLOAD__: (name: string) => boolean;
        __wcEvaluations: number;
        __wcDisposals: number;
      };
      const label = String.raw`literal \u003c and \u0026`;
      const hosts = [1, 1, 2].map((version) => {
        const el = document.createElement("wc-cache-fixture");
        el.setAttribute("luna:wc-url", `/__contract/wc-cache.js?v=${version}`);
        el.setAttribute("luna:wc-trigger", "none");
        el.setAttribute("luna:wc-state", JSON.stringify({ label }));
        document.body.append(el);
        return el;
      });
      await Promise.all(hosts.map((el) => runtime.__LUNA_WC_HYDRATE__(el)));
      const initial = hosts.map((el) => ({
        version: el.getAttribute("data-version"),
        label: el.textContent,
      }));
      const unloaded = runtime.__LUNA_WC_UNLOAD__("wc-cache-fixture");
      await runtime.__LUNA_WC_HYDRATE__(hosts[0]);
      return {
        initial,
        label,
        unloaded,
        evaluations: runtime.__wcEvaluations,
        disposals: runtime.__wcDisposals,
      };
    });
    expect(result.initial).toEqual([
      { version: "1", label: result.label },
      { version: "1", label: result.label },
      { version: "2", label: result.label },
    ]);
    expect(result.unloaded).toBe(true);
    expect(result.evaluations).toBe(2);
    expect(result.disposals).toBe(3);
    expect(requests).toBe(2);
  });
});
