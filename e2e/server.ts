/**
 * E2E Test Server - Unified server for Playwright tests
 *
 * Uses MoonBit Hono app for test routes, with JS wrapper for:
 * - Static file serving (loader, components)
 * - API endpoints
 */
import { Hono } from "hono";
import { serve } from "@hono/node-server";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const rootDir = join(__dirname, "..");

// Load static assets
const loaderPath = join(rootDir, "packages", "loader", "ln-loader-v1.js");
const loaderCode = readFileSync(loaderPath, "utf-8");

// Import MoonBit counter_component module for SSR
const counterComponentPath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "tests",
  "counter_component",
  "counter_component.js"
);

// Import MoonBit counter_client module path for client hydration
const counterClientPath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "tests",
  "counter_client",
  "counter_client.js"
);

// Import MoonBit e2e_server module
const e2eServerPath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "tests",
  "e2e_server",
  "e2e_server.js"
);

// Import MoonBit browser_components module for browser tests
const browserComponentsPath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "tests",
  "browser_components",
  "browser_components.js"
);

// Import MoonBit router_csr module for CSR router tests
const routerCsrPath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "tests",
  "router_csr",
  "router_csr.js"
);

// Import MoonBit chunked counter server module
const chunkedCounterServerPath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "examples",
  "chunked_counter",
  "server",
  "server.js"
);

// Chunked counter static files directory
const chunkedCounterStaticDir = join(
  rootDir,
  "src",
  "examples",
  "chunked_counter",
  "static"
);

// Import MoonBit SPA example module path
const spaModulePath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "examples",
  "spa",
  "spa.js"
);

// Import MoonBit browser_app example module path
const browserAppModulePath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "examples",
  "browser_app",
  "browser_app.js"
);

// Promisify MoonBit async callback
function promisifyMoonBit<T>(fn: (cont: (v: T) => void, err: (e: Error) => void) => void): Promise<T> {
  return new Promise((resolve, reject) => {
    fn(resolve, reject);
  });
}

// Create the main Hono app
const app = new Hono();

// Health check
app.get("/", (c) => c.text("ok"));

// Serve static assets
app.get("/ln-loader-v1.js", (c) => {
  return c.body(loaderCode, 200, {
    "Content-Type": "application/javascript",
  });
});

// Component hydration scripts (legacy JS version)
app.get("/components/counter.js", (c) => {
  const code = `
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
  return c.body(code, 200, {
    "Content-Type": "application/javascript",
  });
});

// MoonBit counter client module (compiled from counter_client/hydrate.mbt)
app.get("/components/counter-mbt.js", async (c) => {
  const code = readFileSync(counterClientPath, "utf-8");
  return c.body(code, 200, {
    "Content-Type": "application/javascript",
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

// MoonBit browser_components module for browser tests
app.get("/components/browser-components.js", async (c) => {
  const code = readFileSync(browserComponentsPath, "utf-8");
  return c.body(code, 200, {
    "Content-Type": "application/javascript",
  });
});

// MoonBit router_csr module for CSR router tests
app.get("/components/router-csr.js", async (c) => {
  const code = readFileSync(routerCsrPath, "utf-8");
  return c.body(code, 200, {
    "Content-Type": "application/javascript",
  });
});

// Browser test routes
const browserTestPage = (
  title: string,
  componentId: string,
  hydrateFn: string,
  state: object,
  ssrHtml: string
) => `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
  <script type="module" src="/ln-loader-v1.js"></script>
  <style>
    .box { padding: 20px; border: 1px solid #ccc; margin: 10px 0; }
    .box.active { background-color: #e0ffe0; border-color: green; }
    .content-box { padding: 10px; background: #f0f0f0; margin: 10px 0; }
    .click-area { padding: 20px; border: 1px solid #ccc; cursor: pointer; }
    .input-row { display: flex; gap: 10px; margin-bottom: 10px; }
  </style>
</head>
<body>
  <h1>${title}</h1>
  <div id="app"
       ln:id="${componentId}"
       ln:url="/components/browser-components.js"
       ln:export="${hydrateFn}"
       ln:trigger="load"
       ln:state='${JSON.stringify(state).replace(/'/g, "&#39;")}'>${ssrHtml}</div>
</body>
</html>`;

// Signal/Effect basic test
app.get("/browser/signal-effect", (c) => {
  const html = browserTestPage(
    "Signal/Effect Test",
    "signal-effect-1",
    "hydrate_signal_effect",
    { count: 5 },
    `<div>
      <span data-count>5</span>
      <span data-double>10</span>
      <button data-inc>+1</button>
      <button data-dec>-1</button>
      <button data-reset>Reset</button>
    </div>`
  );
  return c.html(html);
});

// Dynamic attributes test
app.get("/browser/dynamic-attrs", (c) => {
  const html = browserTestPage(
    "Dynamic Attributes Test",
    "dynamic-attrs-1",
    "hydrate_dynamic_attrs",
    { active: false, color: "gray" },
    `<div>
      <div data-box class="box" style="background-color: gray; padding: 20px;">Inactive</div>
      <button data-toggle>Toggle Active</button>
      <button data-red>Red</button>
      <button data-blue>Blue</button>
    </div>`
  );
  return c.html(html);
});

// Show/hide toggle test
app.get("/browser/show-toggle", (c) => {
  const html = browserTestPage(
    "Show/Hide Toggle Test",
    "show-toggle-1",
    "hydrate_show_toggle",
    { visible: false },
    `<div>
      <button data-toggle>Show</button>
    </div>`
  );
  return c.html(html);
});

// For each list test
app.get("/browser/for-each", (c) => {
  const html = browserTestPage(
    "For Each List Test",
    "for-each-1",
    "hydrate_for_each",
    { items: ["Apple", "Banana", "Cherry"] },
    `<div>
      <div class="input-row">
        <input data-input type="text" placeholder="Enter item">
        <button data-add>Add</button>
      </div>
      <span data-count>3 items</span>
      <ul data-list>
        <li data-item="0"><span>Apple</span><button data-remove="0">x</button></li>
        <li data-item="1"><span>Banana</span><button data-remove="1">x</button></li>
        <li data-item="2"><span>Cherry</span><button data-remove="2">x</button></li>
      </ul>
    </div>`
  );
  return c.html(html);
});

// Events test
app.get("/browser/events", (c) => {
  const html = browserTestPage(
    "Events Test",
    "events-1",
    "hydrate_events",
    {},
    `<div>
      <div data-click-area class="click-area" style="padding: 20px; border: 1px solid #ccc; cursor: pointer;">Click or double-click me</div>
      <div>
        <span data-clicks>Clicks: 0</span> |
        <span data-dblclicks>Double-clicks: 0</span> |
        <span data-hover>Hover: none</span>
      </div>
    </div>`
  );
  return c.html(html);
});

// Sortable list test (for DOM reuse verification)
app.get("/browser/sortable-list", (c) => {
  const html = browserTestPage(
    "Sortable List Test",
    "sortable-list-1",
    "hydrate_sortable_list",
    { items: ["Apple", "Banana", "Cherry", "Date"] },
    `<div>
      <div class="controls">
        <button data-reverse>Reverse</button>
        <button data-move-first-to-last>Move First to Last</button>
      </div>
      <ul data-list>
        <li data-key="0" data-index="0">Apple</li>
        <li data-key="1" data-index="1">Banana</li>
        <li data-key="2" data-index="2">Cherry</li>
        <li data-key="3" data-index="3">Date</li>
      </ul>
    </div>`
  );
  return c.html(html);
});

// Input binding test
app.get("/browser/input-binding", (c) => {
  const html = browserTestPage(
    "Input Binding Test",
    "input-binding-1",
    "hydrate_input_binding",
    { text: "Initial value" },
    `<div>
      <div data-form>
        <input data-text-input type="text" value="Initial value">
        <button data-submit>Submit</button>
        <button data-clear>Clear</button>
        <button data-set-hello>Set Hello</button>
      </div>
      <div><span data-preview>Preview: Initial value</span></div>
      <div><span data-submitted>Submitted: </span></div>
    </div>`
  );
  return c.html(html);
});

// Element ref test (Solid.js style refs)
app.get("/browser/element-ref", (c) => {
  const html = browserTestPage(
    "Element Ref Test",
    "element-ref-1",
    "hydrate_element_ref",
    {},
    `<div>
      <div class="ref-demo">
        <input data-ref-input type="text" placeholder="This input has a ref">
        <button data-focus-btn>Focus Input</button>
        <button data-clear-focus-btn>Clear & Focus</button>
      </div>
      <div><span data-focus-count>Focus count: 0</span></div>
      <div><span data-ref-status>Ref captured: no</span></div>
    </div>`
  );
  return c.html(html);
});

// CSR Router test routes
// Wildcard route handler for CSR Router SPA
const csrRouterHtml = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>CSR Router Demo</title>
  <style>
    nav { margin-bottom: 20px; }
    nav a { margin-right: 10px; color: blue; text-decoration: underline; cursor: pointer; }
    [data-content] { padding: 10px; border: 1px solid #ccc; margin-top: 10px; }
  </style>
</head>
<body>
  <h1>CSR Router Demo</h1>
  <div id="app"></div>
  <script type="module">
    import { mount_router_app } from '/components/router-csr.js';
    mount_router_app();
  </script>
</body>
</html>`;

// CSR Router routes - serve the same HTML for all SPA routes
// The MoonBit router handles client-side routing
app.get("/csr-router/home", (c) => c.html(csrRouterHtml));
app.get("/csr-router/about", (c) => c.html(csrRouterHtml));
app.get("/csr-router/contact", (c) => c.html(csrRouterHtml));
app.get("/csr-router/posts/:id", (c) => c.html(csrRouterHtml));
app.get("/csr-router/unknown/*", (c) => c.html(csrRouterHtml));

// SPA Example routes
// Serve the SPA example HTML page that loads the MoonBit SPA module
const spaHtml = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Luna SPA Example</title>
  <style>
    body { font-family: system-ui, sans-serif; }
    .app { padding: 20px; max-width: 800px; margin: 0 auto; }
    .buttons { display: flex; gap: 8px; }
    button { padding: 8px 16px; cursor: pointer; }
    input[type="text"], input[type="range"] { padding: 8px; }
    hr { margin: 20px 0; }
    ul { list-style: none; padding: 0; }
    li { padding: 8px 0; }
  </style>
</head>
<body>
  <div id="app">Loading...</div>
  <script type="module">
    import '/spa/main.js';
  </script>
</body>
</html>`;

app.get("/spa", (c) => c.html(spaHtml));
app.get("/spa/main.js", (c) => {
  const code = readFileSync(spaModulePath, "utf-8");
  return c.body(code, 200, { "Content-Type": "application/javascript" });
});

// Browser App Example routes
// Serve the browser_app example HTML page that loads the MoonBit browser_app module
const browserAppHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Browser App Example</title>
  <style>
    * { box-sizing: border-box; }
    body { margin: 0; padding: 0; background: #f5f5f5; }
    nav a { color: #fff; text-decoration: none; }
    nav a:hover { text-decoration: underline; }
    .page { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #333; margin-top: 0; }
    button { background: #007bff; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; }
    button:hover { background: #0056b3; }
    ul { line-height: 1.8; }
  </style>
</head>
<body>
  <div id="app">Loading...</div>
  <script type="module">
    import '/playground/browser_app/main.js';
  </script>
</body>
</html>`;

// Serve browser-app routes
// Note: Order matters - static files first, then wildcard SPA route
app.get("/playground/browser_app/main.js", (c) => {
  const code = readFileSync(browserAppModulePath, "utf-8");
  return c.body(code, 200, { "Content-Type": "application/javascript" });
});
app.get("/playground/browser_app", (c) => c.html(browserAppHtml));
app.get("/playground/browser_app/*", (c) => c.html(browserAppHtml));

// Chunked Counter routes (for ESM import architecture tests)
// Serve static files from chunked counter static directory
// Support both /static/ and /chunked-counter/static/ paths
const serveChunkedCounterStatic = async (c: any, file: string) => {
  const filePath = join(chunkedCounterStaticDir, file);
  try {
    const code = readFileSync(filePath, "utf-8");
    const ext = file.split('.').pop();
    const contentType = ext === 'js' ? 'application/javascript' : 'text/plain';
    return c.body(code, 200, { "Content-Type": contentType });
  } catch {
    return c.notFound();
  }
};

app.get("/chunked-counter/static/:file", (c) => serveChunkedCounterStatic(c, c.req.param("file")));
app.get("/static/:file", (c) => serveChunkedCounterStatic(c, c.req.param("file")));

// Chunked counter main page (SSR)
app.get("/chunked-counter", async (c) => {
  const count = parseInt(c.req.query("count") || "5");
  const chunkedCounterServer = await import(chunkedCounterServerPath);
  const html = chunkedCounterServer.renderPage(count);
  return c.html(html);
});

// Island Node SSR test routes
// These test the visland() VNode rendering with ln:* attributes and HTML comment markers

// Helper to generate island page with ln-loader
const islandTestPage = (title: string, body: string) => `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
  <script type="module" src="/ln-loader-v1.js"></script>
</head>
<body>
  <h1>${title}</h1>
  ${body}
</body>
</html>`;

// Test: Basic Island Node SSR output format
app.get("/island-node/basic-ssr", (c) => {
  // Simulate what @luna.visland() + @ssr.render_to_string() would produce
  const html = islandTestPage("Island Node Basic SSR", `
    <!--ln:island:counter-1 url=/components/counter.js trigger=load-->
    <div ln:id="counter-1" ln:url="/components/counter.js" ln:state="{&quot;count&quot;:5}" ln:trigger="load">
      <span data-count>5</span>
      <button data-inc>+1</button>
      <button data-dec>-1</button>
    </div>
    <!--/ln:island:counter-1-->
  `);
  return c.html(html);
});

// Test: Island Node with different triggers
app.get("/island-node/triggers", (c) => {
  const html = islandTestPage("Island Node Triggers", `
    <h2>Load Trigger (immediate)</h2>
    <!--ln:island:load-1 url=/components/lazy.js trigger=load-->
    <div ln:id="load-1" ln:url="/components/lazy.js" ln:state="{&quot;message&quot;:&quot;Load trigger&quot;}" ln:trigger="load">
      <div data-content>Load trigger</div>
    </div>
    <!--/ln:island:load-1-->

    <h2>Idle Trigger</h2>
    <!--ln:island:idle-1 url=/components/lazy.js trigger=idle-->
    <div ln:id="idle-1" ln:url="/components/lazy.js" ln:state="{&quot;message&quot;:&quot;Idle trigger&quot;}" ln:trigger="idle">
      <div data-content>Idle trigger</div>
    </div>
    <!--/ln:island:idle-1-->

    <h2>Visible Trigger (scroll down)</h2>
    <div style="height: 150vh; background: linear-gradient(#eee, #ccc); display: flex; align-items: center; justify-content: center;">
      Scroll down to see visible trigger
    </div>
    <!--ln:island:visible-1 url=/components/lazy.js trigger=visible-->
    <div ln:id="visible-1" ln:url="/components/lazy.js" ln:state="{&quot;message&quot;:&quot;Visible trigger&quot;}" ln:trigger="visible">
      <div data-content>Visible trigger</div>
    </div>
    <!--/ln:island:visible-1-->
  `);
  return c.html(html);
});

// Test: Nested Islands
app.get("/island-node/nested", (c) => {
  const html = islandTestPage("Nested Islands", `
    <!--ln:island:outer-1 url=/components/counter.js trigger=load-->
    <div ln:id="outer-1" ln:url="/components/counter.js" ln:state="{&quot;count&quot;:10}" ln:trigger="load">
      <h2>Outer Island</h2>
      <span data-count>10</span>
      <button data-inc>+1</button>
      <button data-dec>-1</button>
      <div style="margin-left: 20px; padding: 10px; border-left: 2px solid #ccc;">
        <!--ln:island:inner-1 url=/components/lazy.js trigger=load-->
        <div ln:id="inner-1" ln:url="/components/lazy.js" ln:state="{&quot;message&quot;:&quot;Inner island content&quot;}" ln:trigger="load">
          <h3>Inner Island</h3>
          <div data-content>Inner island content</div>
        </div>
        <!--/ln:island:inner-1-->
      </div>
    </div>
    <!--/ln:island:outer-1-->
  `);
  return c.html(html);
});

// Test: Island with state escaping (XSS test)
app.get("/island-node/xss-safety", (c) => {
  // The state contains potentially dangerous characters, but they should be entity-escaped
  const html = islandTestPage("Island XSS Safety Test", `
    <script>window.xssTriggered = false; window.alert = () => { window.xssTriggered = true; };</script>
    <!--ln:island:xss-1 url=/components/lazy.js trigger=load-->
    <div ln:id="xss-1" ln:url="/components/lazy.js" ln:state="{&quot;message&quot;:&quot;&lt;script&gt;alert(1)&lt;/script&gt;&quot;}" ln:trigger="load">
      <div data-content>Safe content</div>
    </div>
    <!--/ln:island:xss-1-->
  `);
  return c.html(html);
});

// Idempotent hydration test route
// Uses MoonBit SSR for initial render, MoonBit hydrate for client
app.get("/test/idempotent-hydrate", async (c) => {
  const counterComponent = await import(counterComponentPath);
  const count = 5;
  const ssrHtml = counterComponent.render_counter_html(count);
  const stateJson = counterComponent.serialize_state(count);

  const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Idempotent Hydration Test</title>
  <script type="module" src="/ln-loader-v1.js"></script>
</head>
<body>
  <h1>Idempotent Hydration Test</h1>
  <p>Initial count: ${count}</p>

  <!-- SSR content with kg attributes for loader -->
  <div id="counter"
       ln:id="counter-1"
       ln:url="/components/counter-mbt.js"
       ln:trigger="load"
       ln:state='${stateJson}'>${ssrHtml}</div>

  <!-- Debug info -->
  <div id="debug">
    <h3>SSR Output (before hydration):</h3>
    <pre id="ssr-html"></pre>
    <h3>DOM after hydration:</h3>
    <pre id="hydrated-html"></pre>
  </div>

  <script type="module">
    // Capture SSR HTML before hydration
    const ssrHtml = document.getElementById('counter').innerHTML;
    document.getElementById('ssr-html').textContent = ssrHtml;

    // Wait for hydration and capture DOM after
    const checkHydration = setInterval(() => {
      const counter = document.getElementById('counter');
      if (counter.hasAttribute('data-hydrated')) {
        clearInterval(checkHydration);
        document.getElementById('hydrated-html').textContent = counter.innerHTML;
      }
    }, 50);
  </script>
</body>
</html>`;

  return c.html(html);
});

// Mount MoonBit Hono app
async function setupMoonBitRoutes() {
  const e2eServer = await import(e2eServerPath);
  const moonbitApp = await promisifyMoonBit<any>(e2eServer.create_app);

  // Mount loader routes at /loader/*
  // Mount shard routes at /shard/*
  app.route("/", moonbitApp);
}

// Start server
const port = parseInt(process.env.PORT || "3456");

async function main() {
  await setupMoonBitRoutes();

  if (process.env.E2E_SERVER_START !== "false") {
    serve({ fetch: app.fetch, port, hostname: "0.0.0.0" }, () => {
      console.log(`E2E test server running at http://localhost:${port}`);
    });
  }
}

main().catch(console.error);

export { app, port };
