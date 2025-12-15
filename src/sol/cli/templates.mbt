///| Sol CLI Templates - Embedded template files for project scaffolding

///|
fn template_gitignore() -> String {
  (
    #|.mooncakes
    #|target
    #|node_modules
    #|app/_gen
    #|.sol
    #|rolldown.config.mjs
  )
}

///|
fn template_moon_mod_json(package_name : String, luna_path : String?) -> String {
  match luna_path {
    Some(path) => {
      // Development mode - use local path
      let tmpl =
        #|{
        #|  "name": "{{PACKAGE_NAME}}",
        #|  "version": "0.1.0",
        #|  "deps": {
        #|    "mizchi/luna": {
        #|      "path": "{{LUNA_PATH}}"
        #|    },
        #|    "mizchi/js": "0.10.0",
        #|    "mizchi/npm_typed": "0.1.1"
        #|  },
        #|  "source": "app",
        #|  "preferred-target": "js"
        #|}
      tmpl
        .replace(old="{{PACKAGE_NAME}}", new=package_name)
        .replace(old="{{LUNA_PATH}}", new=path)
    }
    None => {
      // Production mode - use mooncakes version
      let tmpl =
        #|{
        #|  "name": "{{PACKAGE_NAME}}",
        #|  "version": "0.1.0",
        #|  "deps": {
        #|    "mizchi/luna": "0.0.1",
        #|    "mizchi/js": "0.10.0",
        #|    "mizchi/npm_typed": "0.1.1"
        #|  },
        #|  "source": "app",
        #|  "preferred-target": "js"
        #|}
      tmpl.replace(old="{{PACKAGE_NAME}}", new=package_name)
    }
  }
}

///|
fn template_package_json(project_name : String) -> String {
  let tmpl =
    #|{
    #|  "name": "{{PROJECT_NAME}}",
    #|  "version": "0.1.0",
    #|  "type": "module",
    #|  "scripts": {
    #|    "dev": "sol dev",
    #|    "build": "sol build",
    #|    "start": "node target/js/release/build/server/run/run.js"
    #|  },
    #|  "dependencies": {
    #|    "hono": "^4.0.0",
    #|    "@hono/node-server": "^1.0.0"
    #|  },
    #|  "devDependencies": {
    #|    "rolldown": "^1.0.0-beta.54"
    #|  }
    #|}
  tmpl.replace(old="{{PROJECT_NAME}}", new=project_name)
}

///|
fn template_sol_config_json() -> String {
  (
    #|{
    #|  "components": ["app/client/components/*"],
    #|  "islands": ["app/client"],
    #|  "pages": ["app/server/pages/*"],
    #|  "output": "app/_gen"
    #|}
  )
}


///|
fn template_client_moon_pkg_json(_package_name : String) -> String {
  (
    #|{
    #|  "supported-targets": ["js"],
    #|  "import": [
    #|    { "path": "mizchi/luna/platform/dom", "alias": "dom" },
    #|    { "path": "mizchi/js/core", "alias": "core" }
    #|  ]
    #|}
  )
}

///|
fn template_client_hydrate_mbt() -> String {
  (
    #|///| Client Hydration Entry
    #|
    #|///| Hydration entry point (called by loader)
    #|pub fn hydrate_counter(element : @core.Any, state : @core.Any, id : String) -> Unit {
    #|  @dom.hydrate_island(element, state, id, fn(ctx) {
    #|    let count = ctx.signal_int("count", 0)
    #|    ctx.bind_actions(fn(action) {
    #|      match action {
    #|        "increment" => count.set(count.get() + 1)
    #|        "decrement" => count.set(count.get() - 1)
    #|        _ => ()
    #|      }
    #|    })
    #|    ctx.on_update(".count-display", fn() { count.get().to_string() })
    #|  })
    #|}
  )
}

///|
pub fn template_components_moon_pkg_json() -> String {
  (
    #|{
    #|  "supported-targets": ["js"],
    #|  "import": [
    #|    { "path": "mizchi/luna/core", "alias": "luna" },
    #|    "mizchi/luna/core/signal"
    #|  ]
    #|}
  )
}

///|
pub fn template_counter_mbt() -> String {
  (
    #|///| Counter Component - Shared between SSR and client
    #|
    #|///| Counter component VNode
    #|pub fn render(count : @signal.Signal[Int]) -> @luna.Node[Unit] {
    #|  @luna.h("div", [("class", @luna.attr_static("counter"))], [
    #|    @luna.h("span", [("class", @luna.attr_static("count-display"))], [
    #|      @luna.vtext_sig(count),
    #|    ]),
    #|    @luna.h("div", [("class", @luna.attr_static("buttons"))], [
    #|      @luna.h("button", [
    #|        ("class", @luna.attr_static("dec")),
    #|        ("onclick", @luna.action("decrement")),
    #|      ], [@luna.vtext("-")]),
    #|      @luna.h("button", [
    #|        ("class", @luna.attr_static("inc")),
    #|        ("onclick", @luna.action("increment")),
    #|      ], [@luna.vtext("+")]),
    #|    ]),
    #|  ])
    #|}
  )
}

///|
pub fn template_server_run_moon_pkg_json(package_name : String) -> String {
  let tmpl =
    #|{
    #|  "supported-targets": ["js"],
    #|  "is-main": true,
    #|  "import": [
    #|    { "path": "mizchi/luna/sol", "alias": "sol" },
    #|    { "path": "mizchi/js/core", "alias": "core" },
    #|    { "path": "{{PACKAGE_NAME}}/server/pages/home", "alias": "page_home" },
    #|    { "path": "{{PACKAGE_NAME}}/server/pages/about", "alias": "page_about" }
    #|  ]
    #|}
  tmpl.replace_all(old="{{PACKAGE_NAME}}", new=package_name)
}

///| Page moon.pkg.json with island support (signal + counter)
pub fn template_page_with_island_moon_pkg_json(package_name : String) -> String {
  let tmpl =
    #|{
    #|  "supported-targets": ["js"],
    #|  "import": [
    #|    { "path": "mizchi/luna/core", "alias": "luna" },
    #|    { "path": "mizchi/luna/core/signal", "alias": "signal" },
    #|    { "path": "mizchi/luna/sol", "alias": "sol" },
    #|    { "path": "{{PACKAGE_NAME}}/client/components", "alias": "counter" }
    #|  ]
    #|}
  tmpl.replace(old="{{PACKAGE_NAME}}", new=package_name)
}

///| Simple page moon.pkg.json without island dependencies
pub fn template_page_simple_moon_pkg_json() -> String {
  (
    #|{
    #|  "supported-targets": ["js"],
    #|  "import": [
    #|    { "path": "mizchi/luna/core", "alias": "luna" },
    #|    { "path": "mizchi/luna/sol", "alias": "sol" }
    #|  ]
    #|}
  )
}

///|
pub fn template_home_page_mbt() -> String {
  (
    #|///| Home Page
    #|
    #|///| Home page with counter component
    #|pub fn page(_ctx : @sol.Ctx) -> @luna.Node[Unit] {
    #|  let initial_count = 0
    #|  let state_json = "{\"count\":" + initial_count.to_string() + "}"
    #|  let count_signal = @signal.signal(initial_count)
    #|
    #|  @luna.vfragment([
    #|    @luna.h("div", [("class", @luna.attr_static("container"))], [
    #|      @luna.h("h1", [], [@luna.vtext("Welcome to Sol")]),
    #|      @luna.h("p", [], [@luna.vtext("A SSR-first web framework for MoonBit")]),
    #|      @luna.h("nav", [], [
    #|        @luna.h("a", [("href", @luna.attr_static("/"))], [@luna.vtext("Home")]),
    #|        @luna.vtext(" | "),
    #|        @luna.h("a", [("href", @luna.attr_static("/about"))], [@luna.vtext("About")]),
    #|      ]),
    #|    ]),
    #|    @sol.island(
    #|      "counter",
    #|      "/static/hydrate_counter.js",
    #|      state_json,
    #|      [@counter.render(count_signal)],
    #|    ),
    #|  ])
    #|}
  )
}

///|
pub fn template_about_page_mbt() -> String {
  (
    #|///| About Page
    #|
    #|///| About page
    #|pub fn page(_ctx : @sol.Ctx) -> @luna.Node[Unit] {
    #|  @luna.h("div", [("class", @luna.attr_static("container"))], [
    #|    @luna.h("h1", [], [@luna.vtext("About")]),
    #|    @luna.h("p", [], [@luna.vtext("Built with MoonBit and Sol framework.")]),
    #|    @luna.h("a", [("href", @luna.attr_static("/"))], [@luna.vtext("← Back")]),
    #|  ])
    #|}
  )
}

///|
pub fn template_server_main_mbt() -> String {
  (
    #|///| Sol App - Server Entry Point
    #|
    #|///| Configure the application
    #|fn configure_app(app : @sol.App) -> @sol.App {
    #|  let style = "<style>body { font-family: system-ui; max-width: 800px; margin: 0 auto; padding: 2rem; } .counter { margin: 2rem 0; padding: 1rem; border: 1px solid #ccc; border-radius: 8px; } .buttons { margin-top: 1rem; } .buttons button { font-size: 1.5rem; padding: 0.5rem 1rem; margin: 0 0.5rem; cursor: pointer; }</style>"
    #|
    #|  let app = @sol.page(app, "/", @page_home.page, title="Home", head=style, hydration=true, loader_url="/static/loader.min.js")
    #|  let app = @sol.page(app, "/about", @page_about.page, title="About", head=style)
    #|  let app = @sol.api(app, "/api/health", fn(_c) { @sol.json_obj([("status", @core.any("ok"))]) })
    #|  let app = @sol.serve_static(app)
    #|  app
    #|}
    #|
    #|///|
    #|fn main {
    #|  @sol.run(configure_app)
    #|}
  )
}

///|
pub fn template_ln_loader_js() -> String {
  (
    #|/*! luna loader v1 - MIT License */
    #|((d, w) => {
    #|  const S = {};
    #|  const loaded = new Set();
    #|
    #|  const parseState = async (el) => {
    #|    const attr = el.getAttribute('ln:state');
    #|    if (!attr) return null;
    #|    if (attr.startsWith('#')) {
    #|      const script = d.getElementById(attr.slice(1));
    #|      return script ? JSON.parse(script.textContent) : null;
    #|    }
    #|    try { return JSON.parse(attr); } catch { return null; }
    #|  };
    #|
    #|  const hydrate = async (el) => {
    #|    const id = el.getAttribute('ln:id');
    #|    if (!id || loaded.has(id)) return;
    #|    loaded.add(id);
    #|    const url = el.getAttribute('ln:url');
    #|    if (!url) return;
    #|    const state = await parseState(el);
    #|    S[id] = state;
    #|    try {
    #|      const mod = await import(url);
    #|      const exportName = el.getAttribute('ln:export');
    #|      const fn = exportName ? mod[exportName] : (mod.hydrate || mod.default);
    #|      if (fn) fn(el, state, id);
    #|    } catch (e) {
    #|      console.error(`[ln-loader] Failed to hydrate ${id}:`, e);
    #|    }
    #|  };
    #|
    #|  const setupTrigger = (el) => {
    #|    const trigger = el.getAttribute('ln:trigger') || 'load';
    #|    if (trigger === 'load') {
    #|      if (d.readyState === 'loading') {
    #|        d.addEventListener('DOMContentLoaded', () => hydrate(el), { once: true });
    #|      } else { hydrate(el); }
    #|    } else if (trigger === 'idle') {
    #|      if ('requestIdleCallback' in w) { requestIdleCallback(() => hydrate(el)); }
    #|      else { setTimeout(() => hydrate(el), 200); }
    #|    } else if (trigger === 'visible') {
    #|      const observer = new IntersectionObserver((entries) => {
    #|        entries.forEach(entry => { if (entry.isIntersecting) { observer.disconnect(); hydrate(el); } });
    #|      }, { rootMargin: '50px' });
    #|      observer.observe(el);
    #|    } else if (trigger.startsWith('media:')) {
    #|      const query = trigger.slice(6);
    #|      const mql = w.matchMedia(query);
    #|      const check = () => { if (mql.matches) { mql.removeEventListener('change', check); hydrate(el); } };
    #|      if (mql.matches) { hydrate(el); } else { mql.addEventListener('change', check); }
    #|    }
    #|  };
    #|
    #|  const scan = () => { d.querySelectorAll('[ln\\:id]').forEach(setupTrigger); };
    #|
    #|  d.querySelectorAll('script[type="ln/json"]').forEach(s => { if (s.id) S[s.id] = JSON.parse(s.textContent); });
    #|
    #|  if (d.readyState === 'loading') { d.addEventListener('DOMContentLoaded', scan, { once: true }); }
    #|  else { scan(); }
    #|
    #|  const mo = new MutationObserver((mutations) => {
    #|    mutations.forEach(m => { m.addedNodes.forEach(node => { if (node.nodeType === 1 && node.hasAttribute('ln:id')) setupTrigger(node); }); });
    #|  });
    #|  mo.observe(d.body || d.documentElement, { childList: true, subtree: true });
    #|
    #|  w.__LN_STATE__ = S;
    #|  w.__LN_HYDRATE__ = hydrate;
    #|  w.__LN_SCAN__ = scan;
    #|})(document, window);
  )
}

///|
/// Template file structure for generating project
pub struct TemplateFile {
  path : String
  content : String
}

///|
/// Generate all template files for a new project
/// package_name: Full name with namespace (e.g. "mizchi/mysun") for moon.mod.json
/// project_name: Short name without namespace (e.g. "mysun") for package.json and directory
/// luna_path: Optional local path to luna (for dev mode)
pub fn generate_templates(
  package_name : String,
  project_name : String,
  luna_path : String?
) -> Array[TemplateFile] {
  [
    // Root config files
    { path: ".gitignore", content: template_gitignore() },
    {
      path: "moon.mod.json",
      content: template_moon_mod_json(package_name, luna_path),
    },
    { path: "package.json", content: template_package_json(project_name) },
    { path: "sol.config.json", content: template_sol_config_json() },
    // Client - components (shared SSR/client)
    {
      path: "app/client/components/moon.pkg.json",
      content: template_components_moon_pkg_json(),
    },
    {
      path: "app/client/components/counter.mbt",
      content: template_counter_mbt(),
    },
    // Client - hydration entry
    {
      path: "app/client/moon.pkg.json",
      content: template_client_moon_pkg_json(package_name),
    },
    { path: "app/client/hydrate.mbt", content: template_client_hydrate_mbt() },
    // Server - pages (each page in its own package)
    {
      path: "app/server/pages/home/moon.pkg.json",
      content: template_page_with_island_moon_pkg_json(package_name),
    },
    {
      path: "app/server/pages/home/home.mbt",
      content: template_home_page_mbt(),
    },
    {
      path: "app/server/pages/about/moon.pkg.json",
      content: template_page_simple_moon_pkg_json(),
    },
    {
      path: "app/server/pages/about/about.mbt",
      content: template_about_page_mbt(),
    },
    // Server - entry point
    {
      path: "app/server/run/moon.pkg.json",
      content: template_server_run_moon_pkg_json(package_name),
    },
    { path: "app/server/run/main.mbt", content: template_server_main_mbt() },
    // Static assets
    { path: "static/loader.min.js", content: template_ln_loader_js() },
  ]
}
