///| E2E Test Server for MoonBit UI
///| Provides Hono app for Playwright E2E tests
///| Uses @sol module for Island Architecture support

///|
/// Create the main E2E test server app
/// Exports a Hono app that can be used from JavaScript
pub async fn create_app() -> @sol.App {
  let app = @sol.create_app()

  // Health check
  let _ = app.get(
    "/",
    async fn(c : @sol.Ctx) -> @http.Response { c.text("ok") },
  )

  // Mount loader test routes
  let loader_app = create_loader_app()
  let _ = app.route("/loader", loader_app)

  // Mount shard test routes
  let shard_app = create_shard_app()
  let _ = app.route("/shard", shard_app)

  app
}

///|
/// Create loader test routes
async fn create_loader_app() -> @sol.App {
  let app = @sol.create_app()

  // Basic hydration test - trigger: load
  let _ = app.get(
    "/basic",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("counter-1", "/components/counter.js")
        .with_state("{\"count\":5}")
        .with_ssr_html(
          "<span data-count>5</span><button data-inc>+1</button><button data-dec>-1</button>",
        )
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        [island],
        title="Basic Hydration Test",
      )
      c.html(html)
    },
  )

  // Visible trigger test
  let _ = app.get(
    "/visible",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("lazy-1", "/components/lazy.js")
        .with_trigger(@sol.TriggerType::Visible)
        .with_state("{\"message\":\"Hello from state!\"}")
        .with_ssr_html("<div data-content class=\"lazy-component\">Not hydrated yet</div>")
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        [
          "<div class=\"spacer\">Scroll down to trigger hydration</div>",
          island,
        ],
        title="Visible Trigger Test",
        head="<style>.spacer { height: 150vh; background: linear-gradient(#eee, #ccc); } .lazy-component { padding: 20px; background: #f0f0f0; }</style>",
      )
      c.html(html)
    },
  )

  // Idle trigger test
  let _ = app.get(
    "/idle",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("idle-1", "/components/lazy.js")
        .with_trigger(@sol.TriggerType::Idle)
        .with_state("{\"message\":\"Loaded on idle\"}")
        .with_ssr_html("<div data-content>Waiting for idle...</div>")
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        [island],
        title="Idle Trigger Test",
      )
      c.html(html)
    },
  )

  // Script reference state test
  let _ = app.get(
    "/script-ref",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("counter-ref", "/components/counter.js")
        .with_state_ref("ln-state-counter-ref")
        .with_ssr_html(
          "<span data-count>10</span><button data-inc>+1</button><button data-dec>-1</button>",
        )
      let island : String = @sol.render_island(config)
      let state_script = @sol.generate_state_script(
        "ln-state-counter-ref",
        "{\"count\":10}",
      )
      let html = @sol.render_island_page(
        [island, state_script],
        title="Script Reference State Test",
      )
      c.html(html)
    },
  )

  // Multiple components test
  let _ = app.get(
    "/multiple",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config_a : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("counter-a", "/components/counter.js")
        .with_state("{\"count\":1}")
        .with_ssr_html(
          "<span data-count>1</span><button data-inc>+1</button><button data-dec>-1</button>",
        )
      let island_a : String = @sol.render_island(config_a)
      let config_b : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("counter-b", "/components/counter.js")
        .with_state("{\"count\":100}")
        .with_ssr_html(
          "<span data-count>100</span><button data-inc>+1</button><button data-dec>-1</button>",
        )
      let island_b : String = @sol.render_island(config_b)
      let html = @sol.render_island_page(
        [island_a, island_b],
        title="Multiple Components Test",
      )
      c.html(html)
    },
  )

  // Manual trigger test
  let _ = app.get(
    "/manual",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("manual-1", "/components/lazy.js")
        .with_trigger(@sol.TriggerType::None)
        .with_state("{\"message\":\"Manually triggered\"}")
        .with_ssr_html("<div data-content>Should not auto-hydrate</div>")
      let island : String = @sol.render_island(config)
      let trigger_button =
        "<button id=\"trigger-btn\" onclick=\"window.__LN_HYDRATE__(document.querySelector('[ln\\\\:id=manual-1]'))\">Trigger Hydration</button>"
      let html = @sol.render_island_page(
        [island, trigger_button],
        title="Manual Trigger Test",
      )
      c.html(html)
    },
  )

  // URL state test
  let _ = app.get(
    "/url-state",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("user-1", "/components/user.js")
        .with_state_url("/api/state/user")
        .with_ssr_html("<div data-name>Loading...</div><div data-email></div>")
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        [island],
        title="URL State Test",
      )
      c.html(html)
    },
  )

  app
}

///|
/// Create shard test routes using @sol module
async fn create_shard_app() -> @sol.App {
  let app = @sol.create_app()

  // Minimal shard test
  let _ = app.get(
    "/minimal",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("counter-1", "/components/counter.js")
        .with_state("{\"count\":42}")
        .with_ssr_html(
          "<span data-count>42</span><button data-inc>+</button><button data-dec>-</button>",
        )
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        [island],
        title="Minimal Shard Test",
      )
      c.html(html)
    },
  )

  // Standalone shard test (includes loader)
  let _ = app.get(
    "/standalone",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("greeting-1", "/components/greeting.js")
        .with_state("{\"name\":\"World\"}")
        .with_ssr_html("<p>Hello, <span data-name>World</span>!</p>")
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        [island],
        title="Standalone Shard Test",
      )
      c.html(html)
    },
  )

  // Lazy shard test (visible trigger)
  let _ = app.get(
    "/lazy",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("lazy-counter", "/components/counter.js")
        .with_trigger(@sol.TriggerType::Visible)
        .with_state("{\"count\":100}")
        .with_ssr_html(
          "<span data-count>100</span><button data-inc>+</button><button data-dec>-</button>",
        )
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        [
          "<div class=\"spacer\">Scroll down to trigger hydration</div>",
          island,
        ],
        title="Lazy Shard Test",
        head="<style>.spacer { height: 150vh; background: linear-gradient(#eee, #ccc); }</style>",
      )
      c.html(html)
    },
  )

  // XSS safety test
  let _ = app.get(
    "/xss-safety",
    async fn(c : @sol.Ctx) -> @http.Response {
      let dangerous_state = "{\"message\":\"<script>alert(1)</script>\",\"html\":\"</script><script>\"}"
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("xss-test", "/components/greeting.js")
        .with_state(dangerous_state)
        .with_ssr_html("<p data-name>Safe content</p>")
      let island : String = @sol.render_island(config)
      let xss_check_script =
        "<script>window.xssTriggered = false; window.alert = () => { window.xssTriggered = true; };</script>"
      let html = @sol.render_island_page(
        [island, xss_check_script],
        title="XSS Safety Test",
      )
      c.html(html)
    },
  )

  // State script test
  let _ = app.get(
    "/state-script",
    async fn(c : @sol.Ctx) -> @http.Response {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new("counter-script", "/components/counter.js")
        .with_state_ref("counter-state")
        .with_ssr_html(
          "<span data-count>999</span><button data-inc>+</button><button data-dec>-</button>",
        )
      let island : String = @sol.render_island(config)
      let state_script = @sol.generate_state_script(
        "counter-state",
        "{\"count\":999}",
      )
      let html = @sol.render_island_page(
        [island, state_script],
        title="State Script Test",
      )
      c.html(html)
    },
  )

  app
}
