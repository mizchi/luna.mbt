import {
  cpSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  realpathSync,
  readFileSync,
  rmSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { spawn, spawnSync } from "node:child_process";
import { randomBytes, randomUUID } from "node:crypto";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { createServer } from "node:http";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium, expect } from "@playwright/test";

const root = fileURLToPath(new URL("../", import.meta.url));
const example = join(root, "js/luna/examples-void");
const require = createRequire(join(example, "package.json"));
const viteCli = join(dirname(require.resolve("vite")), "cli.js");
const voidCli = join(dirname(require.resolve("void")), "cli/cli.mjs");
const fixture = mkdtempSync(join(tmpdir(), "luna-void-adapter-"));
const production = process.argv.includes("--production");
const origin = "http://127.0.0.1:4186";
let browser;
let server;
let redirectReceiver;
let log = "";

function run(command, args) {
  const result = spawnSync(command, args, { cwd: fixture, encoding: "utf8" });
  if (result.status !== 0) throw new Error(result.stdout + result.stderr);
}

try {
  cpSync(example, fixture, {
    recursive: true,
    filter: (path) => !/\/(node_modules|dist|\.void|\.wrangler)(\/|$)/.test(path),
  });
  const dependencies = join(fixture, "node_modules");
  mkdirSync(dependencies);
  const sourceDeps = join(example, "node_modules");
  for (const name of readdirSync(sourceDeps).filter((name) => !name.startsWith("."))) {
    if (name.startsWith("@")) {
      mkdirSync(join(dependencies, name));
      for (const pkg of readdirSync(join(sourceDeps, name))) {
        if (name === "@luna_ui" && pkg === "luna") continue;
        symlinkSync(
          realpathSync(join(sourceDeps, name, pkg)),
          join(dependencies, name, pkg),
          "dir",
        );
      }
    } else symlinkSync(realpathSync(join(sourceDeps, name)), join(dependencies, name), "dir");
  }
  symlinkSync(join(root, "node_modules/@types"), join(dependencies, "@types"), "dir");
  // Consume the same self-contained JS/type artifacts that npm packing exports.
  const luna = join(dependencies, "@luna_ui/luna");
  mkdirSync(luna, { recursive: true });
  cpSync(join(root, "js/luna/dist"), join(luna, "dist"), { recursive: true });
  cpSync(join(root, "js/luna/package.json"), join(luna, "package.json"));
  writeFileSync(join(fixture, "pnpm-workspace.yaml"), "verifyDepsBeforeRun: false\n");
  run(process.execPath, [voidCli, "prepare"]);
  run(join(root, "node_modules/.bin/tsc"), ["--noEmit"]);
  // Exercise Drizzle's TS schema loader and generate a fresh migration in this
  // isolated fixture; no checked-in or development database files are changed.
  rmSync(join(fixture, "db/migrations"), { recursive: true, force: true });
  run(process.execPath, [voidCli, "db", "generate"]);
  expect(readdirSync(join(fixture, "db/migrations")).some((name) => name.endsWith(".sql"))).toBe(
    true,
  );
  run(process.execPath, [voidCli, "db", "migrate"]);
  if (production) {
    run(process.execPath, [viteCli, "build"]);
    const path = join(fixture, "dist/ssr/wrangler.json");
    const config = JSON.parse(readFileSync(path, "utf8"));
    config.vars.BETTER_AUTH_SECRET = randomBytes(32).toString("hex");
    writeFileSync(path, JSON.stringify(config));
  }
  server = spawn(
    process.execPath,
    [
      viteCli,
      production ? "preview" : "dev",
      "--host",
      "127.0.0.1",
      "--port",
      "4186",
      "--strictPort",
    ],
    { cwd: fixture, stdio: ["ignore", "pipe", "pipe"] },
  );
  for (const stream of [server.stdout, server.stderr])
    stream.on("data", (data) => {
      log += data;
    });
  browser = await chromium.launch();
  const context = await browser.newContext({
    baseURL: origin,
    viewport: { width: 1000, height: 600 },
  });
  await expect
    .poll(
      async () => {
        if (server.exitCode !== null) throw new Error("Void server exited before startup");
        try {
          return (await context.request.get("/")).status();
        } catch {
          return 0;
        }
      },
      { timeout: 30_000 },
    )
    .toBe(401);
  const signup = await context.request.post("/api/auth/sign-up/email", {
    headers: { Origin: origin },
    data: {
      name: '<unsafe> & "user"',
      email: `void-${randomUUID()}@example.com`,
      password: "luna-void-test-password-123",
    },
  });
  expect(signup.ok(), await signup.text()).toBe(true);
  const page = await context.newPage();
  const errors = [];
  const lunaRequests = [];
  const formRequests = [];
  page.on("pageerror", (error) => errors.push(error.message));
  page.on("console", (message) => {
    if (message.type() !== "error") return;
    // Chromium reports the deliberately rejected form request in the console.
    if (message.location().url === `${origin}/?add` && /status of 422/.test(message.text())) return;
    errors.push(message.text());
  });
  page.on("request", (request) => {
    if (/counter\.luna|luna\.island/.test(request.url())) lunaRequests.push(request.url());
    if (/note-form\.luna|form\.island/.test(request.url())) formRequests.push(request.url());
  });
  await page.goto("/");
  await expect(page.locator("[data-layout=root]")).toBeVisible();
  await expect(page.getByText('Hello <unsafe> & "user"', { exact: true })).toBeVisible();
  await expect(page.locator("unsafe")).toHaveCount(0);
  await expect(page.locator("[data-island=react]")).toHaveAttribute("data-luna-mounted", "true");
  await expect(page.locator("[data-island=solid]")).toHaveAttribute("data-luna-mounted", "true");
  expect(lunaRequests).toEqual([]);
  expect(formRequests).toEqual([]);
  await page.getByRole("button", { name: "React 0", exact: true }).click();
  await expect(page.getByRole("button", { name: "React 1", exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Solid 0", exact: true }).click();
  await expect(page.getByRole("button", { name: "Solid 1", exact: true })).toBeVisible();
  const first = page.locator("[data-island=luna]").nth(0);
  const second = page.locator("[data-island=luna]").nth(1);
  await first.scrollIntoViewIfNeeded();
  await expect(first).toHaveAttribute("data-luna-mounted", "true");
  expect(lunaRequests.length).toBeGreaterThan(0);
  await first.getByRole("button", { name: "Luna 0", exact: true }).click();
  await expect(first.getByRole("button", { name: "Luna 1", exact: true })).toBeVisible();
  await expect(second).not.toHaveAttribute("data-luna-mounted");
  await second.scrollIntoViewIfNeeded();
  await expect(second).toHaveAttribute("data-luna-mounted", "true");
  await expect(second.getByRole("button", { name: "Luna 0", exact: true })).toBeVisible();
  const domReused = await page.evaluate(() =>
    window.__ssrNodes.map(
      (node, index) => node === document.querySelectorAll("[data-counter]")[index],
    ),
  );
  expect(domReused).toEqual([true, true, true, true]);
  expect(
    await page.evaluate(() =>
      window.__ssrInputs.map(
        (input, index) => input === document.querySelectorAll("[data-luna-draft]")[index],
      ),
    ),
  ).toEqual([true, true]);
  await expect(first.locator("input")).toHaveValue("typed 0");
  await expect(second.locator("input")).toHaveValue("typed 1");
  const headers = { Origin: origin, "X-VoidPages": "true" };
  const invalid = await context.request.post("/?add", { headers, data: { title: "" } });
  expect(invalid.status()).toBe(422);
  expect((await invalid.json()).errors.title).toBeTruthy();
  const saved = await context.request.post("/?add", {
    headers,
    data: { title: '<script>alert("x")</script>' },
  });
  expect(await saved.json()).toEqual({ success: true });
  await page.goto("/");
  await expect(page.getByRole("listitem")).toHaveText('<script>alert("x")</script>');
  expect((await context.request.get("/")).headers()["cache-control"]).toContain("no-store");
  await first.scrollIntoViewIfNeeded();
  await expect(first).toHaveAttribute("data-luna-mounted", "true");
  await first.getByRole("button", { name: "Luna 1", exact: true }).click();
  await expect(first.getByRole("button", { name: "Luna 2", exact: true })).toBeVisible();
  const noJs = await browser.newContext({ baseURL: origin, javaScriptEnabled: false });
  await noJs.addCookies(await context.cookies());
  const staticPage = await noJs.newPage();
  await staticPage.goto("/");
  for (const name of ["React", "Solid", "Luna"])
    await expect(
      staticPage.getByRole("button", { name: `${name} 1`, exact: true }).first(),
    ).toBeVisible();
  await page.getByRole("textbox", { name: "Title", exact: true }).fill("Native form action");
  const [formResponse] = await Promise.all([
    page.waitForNavigation(),
    page.getByRole("button", { name: "Save", exact: true }).click(),
  ]);
  expect(formResponse?.status(), await formResponse?.text()).toBe(200);
  expect(formResponse?.headers()["content-type"], await formResponse?.text()).toContain(
    "text/html",
  );
  await expect(page.getByRole("listitem")).toHaveCount(2);
  await expect(page.getByRole("button", { name: "React 2", exact: true })).toBeVisible();
  expect(formRequests).toEqual([]);
  const islandForm = page.locator("[data-island=note-form]");
  const formInput = islandForm.getByRole("textbox", { name: "Luna title", exact: true });
  // A visible island must retain a draft entered before its JS loads.
  await formInput.evaluate((input) => {
    window.__ssrFormInput = input;
    input.value = "Draft before hydration";
  });
  await islandForm.scrollIntoViewIfNeeded();
  await expect(islandForm).toHaveAttribute("data-luna-mounted", "true");
  expect(formRequests.length).toBeGreaterThan(0);
  await expect(formInput).toHaveValue("Draft before hydration");
  expect(await formInput.evaluate((input) => input === window.__ssrFormInput)).toBe(true);
  await formInput.fill("x".repeat(101));
  await islandForm.getByRole("button", { name: "Save with Luna", exact: true }).click();
  await expect(islandForm.getByRole("alert")).not.toBeEmpty();
  await expect(formInput).toHaveValue("x".repeat(101));
  await expect(
    islandForm.getByRole("button", { name: "Save with Luna", exact: true }),
  ).toBeEnabled();
  await expect(page.getByRole("listitem")).toHaveCount(2);
  // Hold the response so the real browser can observe the pending state.
  let finishAction;
  const actionGate = new Promise((resolve) => {
    finishAction = resolve;
  });
  await page.route("**/?add", async (route) => {
    const response = await route.fetch();
    await actionGate;
    await route.fulfill({ response });
  });
  await formInput.fill("Luna form action");
  await islandForm.getByRole("button", { name: "Save with Luna", exact: true }).click();
  await expect(
    islandForm.getByRole("button", { name: "Save with Luna", exact: true }),
  ).toBeDisabled();
  await expect(islandForm.locator("form")).toHaveAttribute("aria-busy", "true");
  const reloaded = page.waitForNavigation();
  finishAction();
  await reloaded;
  await page.unroute("**/?add");
  await expect(page.getByRole("listitem")).toHaveCount(3);
  await expect(page.getByRole("listitem").filter({ hasText: "Luna form action" })).toHaveCount(1);
  await expect(page.getByRole("button", { name: "React 3", exact: true })).toBeVisible();
  await islandForm.scrollIntoViewIfNeeded();
  await expect(islandForm).toHaveAttribute("data-luna-mounted", "true");
  await expect(formInput).toHaveValue("");
  await expect(islandForm.getByRole("alert")).toBeEmpty();

  // A real same-origin 303 must still refresh the page after a successful write.
  await page.route("**/?add", async (route) => {
    await route.fetch();
    await route.fulfill({ status: 303, headers: { Location: `${origin}/` } });
  });
  await formInput.fill("Redirected Luna action");
  await Promise.all([
    page.waitForNavigation(),
    islandForm.getByRole("button", { name: "Save with Luna", exact: true }).click(),
  ]);
  await page.unroute("**/?add");
  await expect(page.getByRole("listitem")).toHaveCount(4);
  expect(page.url()).toBe(`${origin}/`);

  // This loopback receiver permits CORS. The browser must reject redirects
  // before sending even a preflight or the non-sensitive test form body to it.
  const received = [];
  redirectReceiver = createServer((request, response) => {
    received.push(request.method);
    request.resume();
    response.writeHead(request.method === "OPTIONS" ? 204 : 200, {
      "Access-Control-Allow-Origin": origin,
      "Access-Control-Allow-Methods": "POST, PUT, PATCH, DELETE, OPTIONS",
      "Access-Control-Allow-Headers": "content-type",
      "Content-Type": "application/json",
    });
    response.end();
  });
  await new Promise((resolve, reject) => {
    redirectReceiver.once("error", reject);
    redirectReceiver.listen(0, "127.0.0.1", resolve);
  });
  const receiverUrl = `http://127.0.0.1:${redirectReceiver.address().port}/unexpected`;
  for (const status of [307, 308]) {
    // Separate page so expected network errors do not hide main-page errors.
    const boundaryPage = await context.newPage();
    const scriptErrors = [];
    boundaryPage.on("pageerror", (error) => scriptErrors.push(error.message));
    await boundaryPage.goto("/");
    const boundaryIsland = boundaryPage.locator("[data-island=note-form]");
    await boundaryIsland.scrollIntoViewIfNeeded();
    await expect(boundaryIsland).toHaveAttribute("data-luna-mounted", "true");
    await boundaryPage.route("**/?add", (route) =>
      route.fulfill({ status, headers: { Location: receiverUrl } }),
    );
    await boundaryIsland
      .getByRole("textbox", { name: "Luna title", exact: true })
      .fill("Blocked redirect probe");
    await boundaryIsland.getByRole("button", { name: "Save with Luna", exact: true }).click();
    await expect(boundaryIsland.getByRole("alert")).toHaveText(/fetch|network|load failed/i);
    await expect(
      boundaryIsland.getByRole("button", { name: "Save with Luna", exact: true }),
    ).toBeEnabled();
    await expect(
      boundaryIsland.getByRole("textbox", { name: "Luna title", exact: true }),
    ).toHaveValue("Blocked redirect probe");
    expect(received).toEqual([]);
    expect(boundaryPage.url()).toBe(`${origin}/`);
    expect(scriptErrors).toEqual([]);
    await boundaryPage.close();
  }
  expect(errors).toEqual([]);
  console.log(
    `Void adapter passed (${production ? "production" : "dev"}): packaged JS, auth/D1/actions, layouts, mixed React/Solid/Luna, visible scheduling, independent islands, island form validation/pending/reload, same-origin 303, blocked external 307/308, HTML escaping, no-JS fallback. DOM reused: ${JSON.stringify(domReused)}`,
  );
} catch (error) {
  console.error(log.slice(-12_000));
  throw error;
} finally {
  await browser?.close();
  if (redirectReceiver) await new Promise((resolve) => redirectReceiver.close(resolve));
  if (server && server.exitCode === null && server.signalCode === null) {
    const exited = new Promise((done) => server.once("exit", done));
    server.kill("SIGTERM");
    const force = setTimeout(() => server.kill("SIGKILL"), 3000);
    await exited;
    clearTimeout(force);
  }
  rmSync(fixture, { recursive: true, force: true });
}
