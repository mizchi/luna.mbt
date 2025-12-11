///| E2E Test Server for MoonBit UI
///| Provides Hono app for Playwright E2E tests
///| Uses @framework module for Island Architecture support

///|
/// Create the main E2E test server app
/// Exports a Hono app that can be used from JavaScript
pub async fn create_app() -> @framework.App {
  let app = @framework.create_app()

  // Health check
  let _ = app.get(
    "/",
    async fn(c : @framework.Ctx) -> @http.Response { c.text("ok") },
  )

  // Mount loader test routes
  let loader_app = create_loader_app()
  let _ = app.route("/loader", loader_app)

  // Mount embedding test routes
  let embedding_app = create_embedding_app()
  let _ = app.route("/embedding", embedding_app)

  app
}

///|
/// Create loader test routes
async fn create_loader_app() -> @framework.App {
  let app = @framework.create_app()

  // Basic hydration test - trigger: load
  let _ = app.get(
    "/basic",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("counter-1", "/components/counter.js")
          .with_state("{\"count\":5}")
          .with_ssr_html(
            "<span data-count>5</span><button data-inc>+1</button><button data-dec>-1</button>",
          ),
      )
      let html = @framework.render_island_page(
        [island],
        title="Basic Hydration Test",
      )
      c.html(html)
    },
  )

  // Visible trigger test
  let _ = app.get(
    "/visible",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("lazy-1", "/components/lazy.js")
          .with_trigger(@framework.TriggerType::Visible)
          .with_state("{\"message\":\"Hello from state!\"}")
          .with_ssr_html("<div data-content class=\"lazy-component\">Not hydrated yet</div>"),
      )
      let html = @framework.render_island_page(
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
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("idle-1", "/components/lazy.js")
          .with_trigger(@framework.TriggerType::Idle)
          .with_state("{\"message\":\"Loaded on idle\"}")
          .with_ssr_html("<div data-content>Waiting for idle...</div>"),
      )
      let html = @framework.render_island_page(
        [island],
        title="Idle Trigger Test",
      )
      c.html(html)
    },
  )

  // Script reference state test
  let _ = app.get(
    "/script-ref",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("counter-ref", "/components/counter.js")
          .with_state_ref("kg-state-counter-ref")
          .with_ssr_html(
            "<span data-count>10</span><button data-inc>+1</button><button data-dec>-1</button>",
          ),
      )
      let state_script = @framework.generate_state_script(
        "kg-state-counter-ref",
        "{\"count\":10}",
      )
      let html = @framework.render_island_page(
        [island, state_script],
        title="Script Reference State Test",
      )
      c.html(html)
    },
  )

  // Multiple components test
  let _ = app.get(
    "/multiple",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island_a = @framework.render_island(
        @framework.IslandConfig::new("counter-a", "/components/counter.js")
          .with_state("{\"count\":1}")
          .with_ssr_html(
            "<span data-count>1</span><button data-inc>+1</button><button data-dec>-1</button>",
          ),
      )
      let island_b = @framework.render_island(
        @framework.IslandConfig::new("counter-b", "/components/counter.js")
          .with_state("{\"count\":100}")
          .with_ssr_html(
            "<span data-count>100</span><button data-inc>+1</button><button data-dec>-1</button>",
          ),
      )
      let html = @framework.render_island_page(
        [island_a, island_b],
        title="Multiple Components Test",
      )
      c.html(html)
    },
  )

  // Manual trigger test
  let _ = app.get(
    "/manual",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("manual-1", "/components/lazy.js")
          .with_trigger(@framework.TriggerType::None)
          .with_state("{\"message\":\"Manually triggered\"}")
          .with_ssr_html("<div data-content>Should not auto-hydrate</div>"),
      )
      let trigger_button =
        "<button id=\"trigger-btn\" onclick=\"window.__KG_HYDRATE__(document.querySelector('[kg\\\\:id=manual-1]'))\">Trigger Hydration</button>"
      let html = @framework.render_island_page(
        [island, trigger_button],
        title="Manual Trigger Test",
      )
      c.html(html)
    },
  )

  // URL state test
  let _ = app.get(
    "/url-state",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("user-1", "/components/user.js")
          .with_state_url("/api/state/user")
          .with_ssr_html("<div data-name>Loading...</div><div data-email></div>"),
      )
      let html = @framework.render_island_page(
        [island],
        title="URL State Test",
      )
      c.html(html)
    },
  )

  app
}

///|
/// Create embedding test routes using @framework module
async fn create_embedding_app() -> @framework.App {
  let app = @framework.create_app()

  // Minimal embed test
  let _ = app.get(
    "/minimal",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("counter-1", "/components/counter.js")
          .with_state("{\"count\":42}")
          .with_ssr_html(
            "<span data-count>42</span><button data-inc>+</button><button data-dec>-</button>",
          ),
      )
      let html = @framework.render_island_page(
        [island],
        title="Minimal Embed Test",
      )
      c.html(html)
    },
  )

  // Standalone embed test (includes loader)
  let _ = app.get(
    "/standalone",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("greeting-1", "/components/greeting.js")
          .with_state("{\"name\":\"World\"}")
          .with_ssr_html("<p>Hello, <span data-name>World</span>!</p>"),
      )
      let html = @framework.render_island_page(
        [island],
        title="Standalone Embed Test",
      )
      c.html(html)
    },
  )

  // Lazy embed test (visible trigger)
  let _ = app.get(
    "/lazy",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("lazy-counter", "/components/counter.js")
          .with_trigger(@framework.TriggerType::Visible)
          .with_state("{\"count\":100}")
          .with_ssr_html(
            "<span data-count>100</span><button data-inc>+</button><button data-dec>-</button>",
          ),
      )
      let html = @framework.render_island_page(
        [
          "<div class=\"spacer\">Scroll down to trigger hydration</div>",
          island,
        ],
        title="Lazy Embed Test",
        head="<style>.spacer { height: 150vh; background: linear-gradient(#eee, #ccc); }</style>",
      )
      c.html(html)
    },
  )

  // XSS safety test
  let _ = app.get(
    "/xss-safety",
    async fn(c : @framework.Ctx) -> @http.Response {
      let dangerous_state = "{\"message\":\"<script>alert(1)</script>\",\"html\":\"</script><script>\"}"
      let island = @framework.render_island(
        @framework.IslandConfig::new("xss-test", "/components/greeting.js")
          .with_state(dangerous_state)
          .with_ssr_html("<p data-name>Safe content</p>"),
      )
      let xss_check_script =
        "<script>window.xssTriggered = false; window.alert = () => { window.xssTriggered = true; };</script>"
      let html = @framework.render_island_page(
        [island, xss_check_script],
        title="XSS Safety Test",
      )
      c.html(html)
    },
  )

  // State script test
  let _ = app.get(
    "/state-script",
    async fn(c : @framework.Ctx) -> @http.Response {
      let island = @framework.render_island(
        @framework.IslandConfig::new("counter-script", "/components/counter.js")
          .with_state_ref("counter-state")
          .with_ssr_html(
            "<span data-count>999</span><button data-inc>+</button><button data-dec>-</button>",
          ),
      )
      let state_script = @framework.generate_state_script(
        "counter-state",
        "{\"count\":999}",
      )
      let html = @framework.render_island_page(
        [island, state_script],
        title="State Script Test",
      )
      c.html(html)
    },
  )

  app
}
