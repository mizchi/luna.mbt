import { test, expect, type Page } from "@playwright/test";

async function hydrated(page: Page, host: string) {
  await expect(page.locator(host)).toHaveAttribute("data-sol-hydrated", "");
  return page.locator(host);
}

test.describe("sol_app island hydration", () => {
  let errors: string[];
  test.beforeEach(async ({ page }) => {
    errors = [];
    page.on("pageerror", error => errors.push(error.message));
    page.on("console", message => {
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

  test("WC counter renders and increments inside its shadow root", async ({ page }) => {
    await page.goto("/wc-counter");
    const counter = await hydrated(page, "wc-counter");
    const display = counter.locator(".count-display");
    await expect(display).toHaveText("0");
    await counter.getByRole("button", { name: "+", exact: true }).click();
    await expect(display).toHaveText("1");
  });
});
