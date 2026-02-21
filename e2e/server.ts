/**
 * E2E Test Server for Sol - Pure TypeScript implementation
 *
 * NOTE: This is a pure TypeScript E2E server that doesn't use MoonBit Mars.
 * The Mars fetch handler has an issue with tree-shaking of async internal symbols.
 *
 * This server provides:
 * - Static file serving (loader, components)
 * - API endpoints
 * - Test routes for Playwright E2E tests
 */

import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { readFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, "..");

// Load static assets - Luna loader
// Try multiple locations: local src, luna.mbt sibling repo, mooncakes
function findLoaderPath(): string {
  const paths = [
    join(rootDir, "src", "ssg", "assets", "scripts", "loader.js"),
    join(rootDir, "..", "luna.mbt", "js", "loader", "dist", "loader.iife.js"),
    join(rootDir, ".mooncakes", "mizchi", "luna", "js", "loader", "dist", "loader.iife.js"),
  ];
  for (const p of paths) {
    if (existsSync(p)) return p;
  }
  throw new Error("Luna loader not found. Please ensure luna.mbt is available.");
}

const loaderPath = findLoaderPath();
const loaderCode = readFileSync(loaderPath, "utf-8");

// Create the main Hono app
const app = new Hono();

const counterComponentCode = `
export function hydrate(el, state, id) {
  const countSpan = el.querySelector('[data-count]');
  const incBtn = el.querySelector('[data-inc]');
  const decBtn = el.querySelector('[data-dec]');

  let count = state?.count ?? 0;

  const render = () => {
    countSpan.textContent = count;
    countSpan.setAttribute('data-hydrated', 'true');
  };

  incBtn?.addEventListener('click', () => {
    count++;
    render();
  });

  decBtn?.addEventListener('click', () => {
    count--;
    render();
  });

  el.setAttribute('data-hydrated', 'true');
  render();
}
`;

// Health check
app.get("/", (c) => c.text("ok"));

// Serve static assets (both loader.js and loader.min.js for compatibility)
app.get("/loader.js", (c) => {
  return c.body(loaderCode, 200, {
    "Content-Type": "application/javascript",
  });
});
app.get("/loader.min.js", (c) => {
  return c.body(loaderCode, 200, {
    "Content-Type": "application/javascript",
  });
});

// Component hydration scripts
app.get("/components/counter.js", (c) => {
  return c.body(counterComponentCode, 200, {
    "Content-Type": "application/javascript",
  });
});

app.get("/cors-components/counter.js", (c) => {
  return c.body(counterComponentCode, 200, {
    "Content-Type": "application/javascript",
    "Access-Control-Allow-Origin": "*",
  });
});

app.get("/components/lazy.js", (c) => {
  const code = `
export function hydrate(el, state, id) {
  el.setAttribute('data-hydrated', 'true');
  el.querySelector('[data-content]').textContent = 'Hydrated: ' + (state?.message ?? 'no message');
}
`;
  return c.body(code, 200, {
    "Content-Type": "application/javascript",
  });
});

app.get("/components/greeting.js", (c) => {
  const code = `
export function hydrate(el, state, id) {
  el.setAttribute('data-hydrated', 'true');
  const nameEl = el.querySelector('[data-name]');
  if (nameEl && state?.name) {
    nameEl.textContent = state.name;
  }
}
`;
  return c.body(code, 200, {
    "Content-Type": "application/javascript",
  });
});

app.get("/components/user.js", (c) => {
  const code = `
export function hydrate(el, state, id) {
  el.setAttribute('data-hydrated', 'true');
  el.querySelector('[data-name]').textContent = state?.name ?? 'Unknown';
  el.querySelector('[data-email]').textContent = state?.email ?? '';
}
`;
  return c.body(code, 200, {
    "Content-Type": "application/javascript",
  });
});

// API endpoints
app.get("/api/state/user", (c) => {
  return c.json({ name: "Alice", email: "alice@example.com" });
});

// Helper: render island component
// Note: luna:url is the attribute used by the loader (not luna:src)
// luna:state can be inline JSON or "#id" to reference a script element
function renderIsland(opts: {
  id: string;
  src: string;
  state?: string;
  stateRef?: string;
  stateUrl?: string;
  trigger?: "load" | "visible" | "idle" | "none";
  ssrHtml: string;
}): string {
  const trigger = opts.trigger || "load";
  let stateAttr = "";
  if (opts.state) {
    stateAttr = ` luna:state="${escapeHtml(opts.state)}"`;
  } else if (opts.stateRef) {
    // Reference to script element by ID
    stateAttr = ` luna:state="#${opts.stateRef}"`;
  } else if (opts.stateUrl) {
    // TODO: URL state loading not yet implemented in loader
    stateAttr = ` luna:state-url="${opts.stateUrl}"`;
  }
  return `<div luna:id="${opts.id}" luna:url="${opts.src}" luna:trigger="${trigger}"${stateAttr}>${opts.ssrHtml}</div>`;
}

function escapeHtml(str: string): string {
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function generateStateScript(id: string, state: string): string {
  return `<script type="application/json" id="${id}">${state}</script>`;
}

function renderIslandPage(
  islands: string[],
  opts: { title?: string; head?: string } = {}
): string {
  const title = opts.title || "Test";
  const head = opts.head || "";
  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
  ${head}
  <script src="/loader.js"></script>
</head>
<body>
${islands.join("\n")}
</body>
</html>`;
}

// Loader test routes
app.get("/loader/basic", (c) => {
  const island = renderIsland({
    id: "counter-1",
    src: "/components/counter.js",
    state: '{"count":5}',
    ssrHtml: '<span data-count>5</span><button data-inc>+1</button><button data-dec>-1</button>',
  });
  return c.html(renderIslandPage([island], { title: "Basic Hydration Test" }));
});

app.get("/loader/visible", (c) => {
  const island = renderIsland({
    id: "lazy-1",
    src: "/components/lazy.js",
    trigger: "visible",
    state: '{"message":"Hello from state!"}',
    ssrHtml: '<div data-content class="lazy-component">Not hydrated yet</div>',
  });
  const html = renderIslandPage(
    ['<div class="spacer">Scroll down to trigger hydration</div>', island],
    {
      title: "Visible Trigger Test",
      head: '<style>.spacer { height: 2000px; background: linear-gradient(#eee, #ccc); } .lazy-component { padding: 20px; background: #f0f0f0; }</style>',
    }
  );
  return c.html(html);
});

app.get("/loader/idle", (c) => {
  const island = renderIsland({
    id: "idle-1",
    src: "/components/lazy.js",
    trigger: "idle",
    state: '{"message":"Loaded on idle"}',
    ssrHtml: "<div data-content>Waiting for idle...</div>",
  });
  return c.html(renderIslandPage([island], { title: "Idle Trigger Test" }));
});

app.get("/loader/script-ref", (c) => {
  const island = renderIsland({
    id: "counter-ref",
    src: "/components/counter.js",
    stateRef: "ln-state-counter-ref",
    ssrHtml: '<span data-count>10</span><button data-inc>+1</button><button data-dec>-1</button>',
  });
  const stateScript = generateStateScript("ln-state-counter-ref", '{"count":10}');
  return c.html(
    renderIslandPage([island, stateScript], { title: "Script Reference State Test" })
  );
});

app.get("/loader/multiple", (c) => {
  const islandA = renderIsland({
    id: "counter-a",
    src: "/components/counter.js",
    state: '{"count":1}',
    ssrHtml: '<span data-count>1</span><button data-inc>+1</button><button data-dec>-1</button>',
  });
  const islandB = renderIsland({
    id: "counter-b",
    src: "/components/counter.js",
    state: '{"count":100}',
    ssrHtml: '<span data-count>100</span><button data-inc>+1</button><button data-dec>-1</button>',
  });
  return c.html(renderIslandPage([islandA, islandB], { title: "Multiple Components Test" }));
});

app.get("/loader/csr-replace", (c) => {
  const initialIsland = renderIsland({
    id: "csr-counter",
    src: "/components/counter.js",
    state: '{"count":1}',
    ssrHtml:
      '<span data-count>1</span><button id="csr-inc" data-inc>+1</button><button data-dec>-1</button>',
  });
  const nextIsland = renderIsland({
    id: "csr-counter",
    src: "/components/counter.js",
    state: '{"count":10}',
    ssrHtml:
      '<span data-count>10</span><button id="csr-inc" data-inc>+1</button><button data-dec>-1</button>',
  });
  const controls = '<button id="replace-btn" type="button">Replace island</button>';
  const script = `<script>
const nextIslandHtml = ${JSON.stringify(nextIsland)};
document.getElementById("replace-btn")?.addEventListener("click", () => {
  const host = document.getElementById("csr-host");
  if (!host) return;
  host.innerHTML = nextIslandHtml;
});
</script>`;
  return c.html(
    renderIslandPage(
      [
        "<h1>CSR Replace Test</h1>",
        `<div id="csr-host">${initialIsland}</div>`,
        controls,
        script,
      ],
      { title: "CSR Replace Hydration Test" }
    )
  );
});

app.get("/loader/security-default-deny", (c) => {
  const requestUrl = new URL(c.req.url);
  const crossOriginSrc = `http://127.0.0.1:${requestUrl.port || "3456"}/cors-components/counter.js`;
  const island = renderIsland({
    id: "secure-counter",
    src: crossOriginSrc,
    state: '{"count":5}',
    ssrHtml:
      '<span data-count>5</span><button data-inc>+1</button><button data-dec>-1</button>',
  });
  return c.html(
    renderIslandPage([`<div id="secure-host">${island}</div>`], {
      title: "Security Default Deny Test",
    })
  );
});

app.get("/loader/security-allow-host", (c) => {
  const requestUrl = new URL(c.req.url);
  const crossOriginSrc = `http://127.0.0.1:${requestUrl.port || "3456"}/cors-components/counter.js`;
  const island = renderIsland({
    id: "secure-counter",
    src: crossOriginSrc,
    state: '{"count":5}',
    ssrHtml:
      '<span data-count>5</span><button data-inc>+1</button><button data-dec>-1</button>',
  });
  return c.html(
    renderIslandPage([`<div id="secure-host">${island}</div>`], {
      title: "Security Allow Host Test",
      head: '<script>window.__LUNA_ALLOWED_HOSTS__ = ["127.0.0.1"];</script>',
    })
  );
});

app.get("/loader/manual", (c) => {
  const island = renderIsland({
    id: "manual-1",
    src: "/components/lazy.js",
    trigger: "none",
    state: '{"message":"Manually triggered"}',
    ssrHtml: "<div data-content>Should not auto-hydrate</div>",
  });
  const triggerButton =
    '<button id="trigger-btn" onclick="window.__LUNA_HYDRATE__(document.querySelector(\'[luna\\\\:id=manual-1]\'))">Trigger Hydration</button>';
  return c.html(renderIslandPage([island, triggerButton], { title: "Manual Trigger Test" }));
});

app.get("/loader/url-state", (c) => {
  const island = renderIsland({
    id: "user-1",
    src: "/components/user.js",
    stateUrl: "/api/state/user",
    ssrHtml: "<div data-name>Loading...</div><div data-email></div>",
  });
  return c.html(renderIslandPage([island], { title: "URL State Test" }));
});

// Shard test routes
app.get("/shard/minimal", (c) => {
  const island = renderIsland({
    id: "counter-1",
    src: "/components/counter.js",
    state: '{"count":42}',
    ssrHtml: '<span data-count>42</span><button data-inc>+</button><button data-dec>-</button>',
  });
  return c.html(renderIslandPage([island], { title: "Minimal Shard Test" }));
});

app.get("/shard/standalone", (c) => {
  const island = renderIsland({
    id: "greeting-1",
    src: "/components/greeting.js",
    state: '{"name":"World"}',
    ssrHtml: '<p>Hello, <span data-name>World</span>!</p>',
  });
  return c.html(renderIslandPage([island], { title: "Standalone Shard Test" }));
});

app.get("/shard/lazy", (c) => {
  const island = renderIsland({
    id: "lazy-counter",
    src: "/components/counter.js",
    trigger: "visible",
    state: '{"count":100}',
    ssrHtml: '<span data-count>100</span><button data-inc>+</button><button data-dec>-</button>',
  });
  const html = renderIslandPage(
    ['<div class="spacer">Scroll down to trigger hydration</div>', island],
    {
      title: "Lazy Shard Test",
      head: '<style>.spacer { height: 150vh; background: linear-gradient(#eee, #ccc); }</style>',
    }
  );
  return c.html(html);
});

app.get("/shard/xss-safety", (c) => {
  const dangerousState = '{"message":"<script>alert(1)</script>","html":"</script><script>"}';
  const island = renderIsland({
    id: "xss-test",
    src: "/components/greeting.js",
    state: dangerousState,
    ssrHtml: "<p data-name>Safe content</p>",
  });
  const xssCheckScript =
    '<script>window.xssTriggered = false; window.alert = () => { window.xssTriggered = true; };</script>';
  return c.html(renderIslandPage([island, xssCheckScript], { title: "XSS Safety Test" }));
});

app.get("/shard/state-script", (c) => {
  const island = renderIsland({
    id: "counter-script",
    src: "/components/counter.js",
    stateRef: "counter-state",
    ssrHtml: '<span data-count>999</span><button data-inc>+</button><button data-dec>-</button>',
  });
  const stateScript = generateStateScript("counter-state", '{"count":999}');
  return c.html(renderIslandPage([island, stateScript], { title: "State Script Test" }));
});

// Async streaming test routes
app.get("/async/basic", (c) => {
  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Async Streaming Test</title></head><body>
<h1>Async Streaming Test</h1>
<div id="static-content">This is static content</div>
<div id="A:1" class="loading">Loading...</div>
<template id="T:1"><div class="resolved">Async content loaded!</div></template>
<script>(function(){var t=document.getElementById('T:1'),p=document.getElementById('A:1');if(t&&p){p.replaceWith(t.content);t.remove();}})()</script>
</body></html>`;
  return c.html(html);
});

app.get("/async/multiple", (c) => {
  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Multiple Async Test</title></head><body>
<h1>Multiple Async Test</h1>
<div id="A:1" class="loading">First loading...</div>
<div id="middle">Static middle content</div>
<div id="A:2" class="loading">Second loading...</div>
<template id="T:1"><div id="first-resolved">First resolved</div></template>
<script>(function(){var t=document.getElementById('T:1'),p=document.getElementById('A:1');if(t&&p){p.replaceWith(t.content);t.remove();}})()</script>
<template id="T:2"><div id="second-resolved">Second resolved</div></template>
<script>(function(){var t=document.getElementById('T:2'),p=document.getElementById('A:2');if(t&&p){p.replaceWith(t.content);t.remove();}})()</script>
</body></html>`;
  return c.html(html);
});

app.get("/async/nested", (c) => {
  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Nested Async Test</title></head><body>
<div id="container">
<header>Header</header>
<div id="A:1" class="skeleton">Loading main content...</div>
<footer>Footer</footer>
</div>
<template id="T:1"><main id="main-content"><p>Main content loaded</p><ul><li>Item 1</li><li>Item 2</li></ul></main></template>
<script>(function(){var t=document.getElementById('T:1'),p=document.getElementById('A:1');if(t&&p){p.replaceWith(t.content);t.remove();}})()</script>
</body></html>`;
  return c.html(html);
});

app.get("/async/fallback-only", (c) => {
  const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Fallback Only Test</title></head><body>
<h1>Fallback Only Test</h1>
<div id="A:1"><div id="fallback-visible">Fallback is visible</div></div>
</body></html>`;
  return c.html(html);
});

// Start server
const port = parseInt(process.env.PORT || "3456");
const debug = process.env.DEBUG === "1";

if (process.env.E2E_SERVER_START !== "false") {
  serve({ fetch: app.fetch, port, hostname: "0.0.0.0" }, () => {
    if (debug) {
      console.log(`E2E test server running at http://localhost:${port}`);
    }
  });
}

export { app, port };
