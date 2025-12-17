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

// Load static assets (use IIFE bundled version for serving)
const loaderPath = join(rootDir, "js", "loader", "dist", "loader.iife.js");
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

// Import MoonBit browser_router example module path
const browserAppModulePath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "examples",
  "browser_router",
  "browser_router.js"
);

// Import MoonBit WC example module path
const wcModulePath = join(
  rootDir,
  "target",
  "js",
  "release",
  "build",
  "examples",
  "wc",
  "wc.js"
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
  <script type="module" src="/loader.js"></script>
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
       luna:id="${componentId}"
       luna:url="/components/browser-components.js"
       luna:export="${hydrateFn}"
       luna:trigger="load"
       luna:state='${JSON.stringify(state).replace(/'/g, "&#39;")}'>${ssrHtml}</div>
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
// Serve the browser_router example HTML page that loads the MoonBit browser_router module
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
    import '/playground/browser_router/main.js';
  </script>
</body>
</html>`;

// Serve browser-app routes
// Note: Order matters - static files first, then wildcard SPA route
app.get("/playground/browser_router/main.js", (c) => {
  const code = readFileSync(browserAppModulePath, "utf-8");
  return c.body(code, 200, { "Content-Type": "application/javascript" });
});
app.get("/playground/browser_router", (c) => c.html(browserAppHtml));
app.get("/playground/browser_router/*", (c) => c.html(browserAppHtml));

// WC Example routes
const wcHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Luna WC Examples (Web Components)</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0; padding: 0; background: #fafafa;
    }
    h1 { color: #333; }
    h2 { color: #555; border-bottom: 1px solid #ddd; padding-bottom: 8px; }
    button { padding: 8px 16px; margin: 4px; border: 1px solid #ccc; border-radius: 4px; background: #fff; cursor: pointer; }
    button:hover { background: #f0f0f0; }
    input[type="text"] { padding: 8px; border: 1px solid #ccc; border-radius: 4px; margin: 4px; }
    hr { border: none; border-top: 1px solid #eee; margin: 24px 0; }
    ul { list-style: none; padding: 0; }
    li { padding: 8px; margin: 4px 0; background: #fff; border: 1px solid #eee; border-radius: 4px; display: flex; align-items: center; justify-content: space-between; }
    .app { padding: 20px; max-width: 800px; margin: 0 auto; }
  </style>
</head>
<body>
  <div class="app">
    <h1>Luna WC Examples</h1>
    <p>A collection of examples demonstrating Web Components with MoonBit.</p>
    <hr>
    <wc-counter></wc-counter>
    <hr>
    <wc-input></wc-input>
    <hr>
    <wc-effect></wc-effect>
    <hr>
    <wc-conditional></wc-conditional>
    <hr>
    <wc-style></wc-style>
    <hr>
    <wc-todo></wc-todo>
    <hr>
    <!-- Nested Components Example -->
    <wc-nested-parent></wc-nested-parent>
  </div>
  <script type="module" src="/playground/wc/main.js"></script>
</body>
</html>`;

app.get("/playground/wc", (c) => c.html(wcHtml));
app.get("/playground/wc/main.js", (c) => {
  const code = readFileSync(wcModulePath, "utf-8");
  return c.body(code, 200, { "Content-Type": "application/javascript" });
});

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

// Helper to generate island page with loader
const islandTestPage = (title: string, body: string) => `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
  <script type="module" src="/loader.js"></script>
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
    <!--luna:island:counter-1 url=/components/counter.js trigger=load-->
    <div luna:id="counter-1" luna:url="/components/counter.js" luna:state="{&quot;count&quot;:5}" luna:trigger="load">
      <span data-count>5</span>
      <button data-inc>+1</button>
      <button data-dec>-1</button>
    </div>
    <!--/luna:island:counter-1-->
  `);
  return c.html(html);
});

// Test: Island Node with different triggers
app.get("/island-node/triggers", (c) => {
  const html = islandTestPage("Island Node Triggers", `
    <h2>Load Trigger (immediate)</h2>
    <!--luna:island:load-1 url=/components/lazy.js trigger=load-->
    <div luna:id="load-1" luna:url="/components/lazy.js" luna:state="{&quot;message&quot;:&quot;Load trigger&quot;}" luna:trigger="load">
      <div data-content>Load trigger</div>
    </div>
    <!--/luna:island:load-1-->

    <h2>Idle Trigger</h2>
    <!--luna:island:idle-1 url=/components/lazy.js trigger=idle-->
    <div luna:id="idle-1" luna:url="/components/lazy.js" luna:state="{&quot;message&quot;:&quot;Idle trigger&quot;}" luna:trigger="idle">
      <div data-content>Idle trigger</div>
    </div>
    <!--/luna:island:idle-1-->

    <h2>Visible Trigger (scroll down)</h2>
    <div style="height: 150vh; background: linear-gradient(#eee, #ccc); display: flex; align-items: center; justify-content: center;">
      Scroll down to see visible trigger
    </div>
    <!--luna:island:visible-1 url=/components/lazy.js trigger=visible-->
    <div luna:id="visible-1" luna:url="/components/lazy.js" luna:state="{&quot;message&quot;:&quot;Visible trigger&quot;}" luna:trigger="visible">
      <div data-content>Visible trigger</div>
    </div>
    <!--/luna:island:visible-1-->
  `);
  return c.html(html);
});

// Test: Nested Islands
app.get("/island-node/nested", (c) => {
  const html = islandTestPage("Nested Islands", `
    <!--luna:island:outer-1 url=/components/counter.js trigger=load-->
    <div luna:id="outer-1" luna:url="/components/counter.js" luna:state="{&quot;count&quot;:10}" luna:trigger="load">
      <h2>Outer Island</h2>
      <span data-count>10</span>
      <button data-inc>+1</button>
      <button data-dec>-1</button>
      <div style="margin-left: 20px; padding: 10px; border-left: 2px solid #ccc;">
        <!--luna:island:inner-1 url=/components/lazy.js trigger=load-->
        <div luna:id="inner-1" luna:url="/components/lazy.js" luna:state="{&quot;message&quot;:&quot;Inner island content&quot;}" luna:trigger="load">
          <h3>Inner Island</h3>
          <div data-content>Inner island content</div>
        </div>
        <!--/luna:island:inner-1-->
      </div>
    </div>
    <!--/luna:island:outer-1-->
  `);
  return c.html(html);
});

// Test: Island with state escaping (XSS test)
app.get("/island-node/xss-safety", (c) => {
  // The state contains potentially dangerous characters, but they should be entity-escaped
  const html = islandTestPage("Island XSS Safety Test", `
    <script>window.xssTriggered = false; window.alert = () => { window.xssTriggered = true; };</script>
    <!--luna:island:xss-1 url=/components/lazy.js trigger=load-->
    <div luna:id="xss-1" luna:url="/components/lazy.js" luna:state="{&quot;message&quot;:&quot;&lt;script&gt;alert(1)&lt;/script&gt;&quot;}" luna:trigger="load">
      <div data-content>Safe content</div>
    </div>
    <!--/luna:island:xss-1-->
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
  <script type="module" src="/loader.js"></script>
</head>
<body>
  <h1>Idempotent Hydration Test</h1>
  <p>Initial count: ${count}</p>

  <!-- SSR content with kg attributes for loader -->
  <div id="counter"
       luna:id="counter-1"
       luna:url="/components/counter-mbt.js"
       luna:trigger="load"
       luna:state='${stateJson}'>${ssrHtml}</div>

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

// ============================================================================
// Sol SSR/Hydration Test Routes
// ============================================================================

// Helper to create island test pages
const solTestPage = (title: string, body: string, scripts: string = "") => `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${title}</title>
  <script>window.xssTriggered = false;</script>
  <script type="module" src="/loader.js"></script>
  ${scripts}
</head>
<body>
  <h1>${title}</h1>
  ${body}
</body>
</html>`;

// Counter component hydration script
const counterHydrateScript = `
export function hydrate(el, state, id) {
  const countSpan = el.querySelector('.count-display');
  const incBtn = el.querySelector('[data-action-click="increment"]');
  const decBtn = el.querySelector('[data-action-click="decrement"]');

  let count = state?.count ?? 0;

  const render = () => {
    if (countSpan) countSpan.textContent = count.toString();
  };

  incBtn?.addEventListener('click', () => { count++; render(); });
  decBtn?.addEventListener('click', () => { count--; render(); });

  el.setAttribute('data-hydrated', 'true');
  render();
}
export default hydrate;
`;

// State display hydration script
const stateDisplayScript = `
export function hydrate(el, state, id) {
  // Display various state types
  const intEl = el.querySelector('[data-int]');
  const floatEl = el.querySelector('[data-float]');
  const stringEl = el.querySelector('[data-string]');
  const boolEl = el.querySelector('[data-bool]');

  if (intEl && state?.int !== undefined) intEl.textContent = state.int.toString();
  if (floatEl && state?.float !== undefined) floatEl.textContent = state.float.toString();
  if (stringEl && state?.string !== undefined) stringEl.textContent = state.string;
  if (boolEl && state?.bool !== undefined) boolEl.textContent = state.bool.toString();

  el.setAttribute('data-hydrated', 'true');
}
export default hydrate;
`;

// Special chars hydration script
const specialCharsScript = `
export function hydrate(el, state, id) {
  const htmlEl = el.querySelector('[data-html]');
  const unicodeEl = el.querySelector('[data-unicode]');
  const quotesEl = el.querySelector('[data-quotes]');

  if (htmlEl && state?.html) htmlEl.textContent = state.html;
  if (unicodeEl && state?.unicode) unicodeEl.textContent = state.unicode;
  if (quotesEl && state?.quotes) quotesEl.textContent = state.quotes;

  el.setAttribute('data-hydrated', 'true');
}
export default hydrate;
`;

// Nested state hydration script
const nestedStateScript = `
export function hydrate(el, state, id) {
  const nameEl = el.querySelector('[data-user-name]');
  const emailEl = el.querySelector('[data-user-email]');
  const countEl = el.querySelector('[data-items-count]');

  if (nameEl && state?.user?.name) nameEl.textContent = state.user.name;
  if (emailEl && state?.user?.email) emailEl.textContent = state.user.email;
  if (countEl && state?.items) countEl.textContent = state.items.length.toString();

  el.setAttribute('data-hydrated', 'true');
}
export default hydrate;
`;

// Serve component scripts for sol tests
app.get("/sol-components/counter.js", (c) => {
  return c.body(counterHydrateScript, 200, { "Content-Type": "application/javascript" });
});

app.get("/sol-components/state-display.js", (c) => {
  return c.body(stateDisplayScript, 200, { "Content-Type": "application/javascript" });
});

app.get("/sol-components/special-chars.js", (c) => {
  return c.body(specialCharsScript, 200, { "Content-Type": "application/javascript" });
});

app.get("/sol-components/nested-state.js", (c) => {
  return c.body(nestedStateScript, 200, { "Content-Type": "application/javascript" });
});

// 1. SSR Output Correctness Tests
app.get("/sol-test/ssr-basic", (c) => {
  const html = solTestPage("SSR Basic Test", `
    <div id="island-container">
      <div luna:id="counter"
           luna:url="/sol-components/counter.js"
           luna:state='{"count":0}'
           luna:trigger="load">
        <span class="count-display">0</span>
        <button data-action-click="increment">+</button>
        <button data-action-click="decrement">-</button>
      </div>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/ssr-escape", (c) => {
  const html = solTestPage("SSR Escape Test", `
    <script>window.xssTriggered = false; window.alert = () => { window.xssTriggered = true; };</script>
    <div data-content>&lt;script&gt;alert('xss')&lt;/script&gt;</div>
  `);
  return c.html(html);
});

app.get("/sol-test/ssr-state-escape", (c) => {
  // JSON with dangerous content that should be escaped
  const state = JSON.stringify({ content: "</script><script>alert(1)</script>" });
  const escapedState = state.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

  const html = solTestPage("SSR State Escape Test", `
    <div luna:id="json-test"
         luna:url="/sol-components/counter.js"
         luna:state="${escapedState}"
         luna:trigger="load">
      <span>Test</span>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/ssr-fragment", (c) => {
  const html = solTestPage("SSR Fragment Test", `
    <div id="fragment-parent">
      <span>Child 1</span>
      <span>Child 2</span>
      <span>Child 3</span>
    </div>
  `);
  return c.html(html);
});

// 2. Hydration Integrity Tests
app.get("/sol-test/hydration-match", (c) => {
  const html = solTestPage("Hydration Match Test", `
    <div id="island-container">
      <div luna:id="counter"
           luna:url="/sol-components/counter.js"
           luna:state='{"count":0}'
           luna:trigger="load">
        <span class="count-display">0</span>
        <button data-action-click="increment">+</button>
        <button data-action-click="decrement">-</button>
      </div>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/hydration-state", (c) => {
  const html = solTestPage("Hydration State Test", `
    <div luna:id="counter"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":42}'
         luna:trigger="load">
      <span class="count-display">42</span>
      <button data-action-click="increment">+</button>
      <button data-action-click="decrement">-</button>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/hydration-interactive", (c) => {
  const html = solTestPage("Hydration Interactive Test", `
    <div luna:id="counter"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":0}'
         luna:trigger="load">
      <span class="count-display">0</span>
      <button data-action-click="increment">+</button>
      <button data-action-click="decrement">-</button>
    </div>
  `);
  return c.html(html);
});

// 4. Island Isolation Tests
app.get("/sol-test/multi-island", (c) => {
  const html = solTestPage("Multi Island Test", `
    <div id="counter-a"
         luna:id="counter-a"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":10}'
         luna:trigger="load">
      <h2>Counter A</h2>
      <span class="count-display">10</span>
      <button data-action-click="increment">+</button>
      <button data-action-click="decrement">-</button>
    </div>

    <div id="counter-b"
         luna:id="counter-b"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":20}'
         luna:trigger="load">
      <h2>Counter B</h2>
      <span class="count-display">20</span>
      <button data-action-click="increment">+</button>
      <button data-action-click="decrement">-</button>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/island-failure", (c) => {
  const html = solTestPage("Island Failure Test", `
    <!-- This island will fail to load -->
    <div id="broken"
         luna:id="broken"
         luna:url="/sol-components/non-existent.js"
         luna:state='{"count":0}'
         luna:trigger="load">
      <span>Broken Island</span>
    </div>

    <!-- This island should still work -->
    <div id="working"
         luna:id="working"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":5}'
         luna:trigger="load">
      <span class="count-display">5</span>
      <button data-action-click="increment">+</button>
      <button data-action-click="decrement">-</button>
    </div>
  `);
  return c.html(html);
});

// 5. State Serialization Tests
app.get("/sol-test/state-types", (c) => {
  const state = JSON.stringify({
    int: 42,
    float: 3.14,
    string: "hello",
    bool: true
  });

  const html = solTestPage("State Types Test", `
    <div luna:id="state-test"
         luna:url="/sol-components/state-display.js"
         luna:state='${state}'
         luna:trigger="load">
      <div><span data-int>42</span></div>
      <div><span data-float>3.14</span></div>
      <div><span data-string>hello</span></div>
      <div><span data-bool>true</span></div>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/state-special-chars", (c) => {
  const state = {
    html: '<script>alert("xss")</script>',
    unicode: "日本語 emoji: 🎉",
    quotes: 'say "hello"'
  };
  const stateJson = JSON.stringify(state)
    .replace(/&/g, '&amp;')
    .replace(/'/g, '&#39;');

  const html = solTestPage("State Special Chars Test", `
    <div luna:id="special"
         luna:url="/sol-components/special-chars.js"
         luna:state='${stateJson}'
         luna:trigger="load">
      <div><span data-html>${state.html.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</span></div>
      <div><span data-unicode>${state.unicode}</span></div>
      <div><span data-quotes>${state.quotes.replace(/"/g, '&quot;')}</span></div>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/state-nested", (c) => {
  const state = {
    user: { name: "Alice", email: "alice@example.com" },
    items: ["a", "b", "c"]
  };
  const stateJson = JSON.stringify(state).replace(/'/g, '&#39;');

  const html = solTestPage("State Nested Test", `
    <div luna:id="nested"
         luna:url="/sol-components/nested-state.js"
         luna:state='${stateJson}'
         luna:trigger="load">
      <div><span data-user-name>Alice</span></div>
      <div><span data-user-email>alice@example.com</span></div>
      <div><span data-items-count>3</span></div>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/state-large", (c) => {
  // Generate large state
  const largeData = Array(100).fill(null).map((_, i) => ({ id: i, name: `Item ${i}` }));
  const state = { items: largeData };
  const stateJson = JSON.stringify(state);

  const html = solTestPage("State Large Test", `
    <script type="luna/json" id="large-state-data">${stateJson}</script>
    <div luna:id="large-state"
         luna:url="/sol-components/counter.js"
         luna:state="#large-state-data"
         luna:trigger="load">
      <span>Large state test</span>
    </div>
  `);
  return c.html(html);
});

// 6. Hydration Trigger Tests
app.get("/sol-test/trigger-load", (c) => {
  const html = solTestPage("Trigger Load Test", `
    <div luna:id="load-trigger"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":0}'
         luna:trigger="load">
      <span class="count-display">0</span>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/trigger-idle", (c) => {
  const html = solTestPage("Trigger Idle Test", `
    <div luna:id="idle-trigger"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":0}'
         luna:trigger="idle">
      <span class="count-display">0</span>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/trigger-visible", (c) => {
  const html = solTestPage("Trigger Visible Test", `
    <div style="height: 200vh; background: linear-gradient(#eee, #ccc);">
      Scroll down to see the island
    </div>
    <div luna:id="visible-trigger"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":0}'
         luna:trigger="visible">
      <span class="count-display">0</span>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/trigger-media", (c) => {
  const html = solTestPage("Trigger Media Test", `
    <div luna:id="media-trigger"
         luna:url="/sol-components/counter.js"
         luna:state='{"count":0}'
         luna:trigger="media:(max-width: 600px)">
      <span class="count-display">0</span>
    </div>
  `);
  return c.html(html);
});

// Mismatch detection hydration script
const mismatchDetectScript = `
export function hydrate(el, state, id) {
  // Check for text content mismatch
  const expectedText = state?.expectedText;
  const actualText = el.textContent?.trim();

  if (expectedText !== undefined && actualText !== expectedText) {
    console.warn('[Hydration] mismatch detected: expected "' + expectedText + '", got "' + actualText + '"');
  }

  // Check for element structure
  const expectedTag = state?.expectedTag;
  if (expectedTag) {
    const firstChild = el.querySelector('*');
    if (firstChild && firstChild.tagName.toLowerCase() !== expectedTag.toLowerCase()) {
      console.warn('[Hydration] mismatch: expected <' + expectedTag + '>, got <' + firstChild.tagName.toLowerCase() + '>');
    }
  }

  // Check for attribute
  const expectedAttr = state?.expectedAttr;
  if (expectedAttr) {
    const actualAttr = el.getAttribute(expectedAttr.name);
    if (actualAttr !== expectedAttr.value) {
      console.warn('[Hydration] mismatch: attribute ' + expectedAttr.name + ' expected "' + expectedAttr.value + '", got "' + actualAttr + '"');
    }
  }

  // Check for extra elements
  const expectedChildCount = state?.expectedChildCount;
  if (expectedChildCount !== undefined) {
    const actualCount = el.children.length;
    if (actualCount !== expectedChildCount) {
      console.warn('[Hydration] mismatch: expected ' + expectedChildCount + ' children, got ' + actualCount);
    }
  }

  el.setAttribute('data-hydrated', 'true');
}
export default hydrate;
`;

app.get("/sol-components/mismatch-detect.js", (c) => {
  return c.body(mismatchDetectScript, 200, { "Content-Type": "application/javascript" });
});

// 7. Mismatch Detection Test Routes
app.get("/sol-test/mismatch-text", (c) => {
  // SSR renders "Server Text", but state expects "Client Text"
  const state = JSON.stringify({ expectedText: "Client Text" });
  const html = solTestPage("Mismatch Text Test", `
    <div luna:id="mismatch-text"
         luna:url="/sol-components/mismatch-detect.js"
         luna:state='${state}'
         luna:trigger="load">
      Server Text
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/mismatch-element", (c) => {
  // SSR renders <span>, but state expects <div>
  const state = JSON.stringify({ expectedTag: "div" });
  const html = solTestPage("Mismatch Element Test", `
    <div luna:id="mismatch-element"
         luna:url="/sol-components/mismatch-detect.js"
         luna:state='${state}'
         luna:trigger="load">
      <span>Content</span>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/mismatch-attr", (c) => {
  // SSR renders class="wrong", but state expects class="correct"
  const state = JSON.stringify({ expectedAttr: { name: "data-test", value: "correct" } });
  const html = solTestPage("Mismatch Attr Test", `
    <div luna:id="mismatch-attr"
         luna:url="/sol-components/mismatch-detect.js"
         luna:state='${state}'
         luna:trigger="load"
         data-test="wrong">
      Content
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/mismatch-extra-client", (c) => {
  // SSR renders 1 child, but state expects 2
  const state = JSON.stringify({ expectedChildCount: 2 });
  const html = solTestPage("Mismatch Extra Client Test", `
    <div luna:id="mismatch-extra"
         luna:url="/sol-components/mismatch-detect.js"
         luna:state='${state}'
         luna:trigger="load">
      <span>Only one child</span>
    </div>
  `);
  return c.html(html);
});

app.get("/sol-test/mismatch-extra-server", (c) => {
  // SSR renders 2 children, but state expects 1
  const state = JSON.stringify({ expectedChildCount: 1 });
  const html = solTestPage("Mismatch Extra Server Test", `
    <div luna:id="mismatch-extra-server"
         luna:url="/sol-components/mismatch-detect.js"
         luna:state='${state}'
         luna:trigger="load">
      <span>Child 1</span>
      <span>Child 2</span>
    </div>
  `);
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
