// E2E Test Server for MoonBit UI
// Provides Mars app for Playwright E2E tests
// Uses @sol module for Island Architecture support
//

///|
/// Type alias for fetch handler
pub struct FetchHandler((@mars.JsRequest) -> @js_async.Promise[@mars.JsResponse])

///|
/// Create a fetch handler from the app
/// This is the recommended way to use the app from JavaScript
pub fn create_fetch_handler() -> FetchHandler {
  let app = create_app()
  FetchHandler(app.to_fetch_handler())
}

///|
/// Create the main E2E test server app
/// Exports a Mars app that can be used from JavaScript
pub fn create_app() -> @sol.App {
  let app = @sol.create_app()

  // Health check
  app.get("/", @mars.handler(async fn(c) { c.text("ok") }))

  // Mount loader test routes
  register_loader_routes(app)

  // Mount shard test routes
  register_shard_routes(app)

  // Mount async streaming test routes
  register_async_routes(app)

  app
}

///|
/// Register loader test routes
fn register_loader_routes(app : @sol.App) -> Unit {
  // Basic hydration test - trigger: load
  app.get(
    "/loader/basic",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "counter-1", "/components/counter.js",
        )
        .with_state("{\"count\":5}")
        .with_ssr_html(
          "<span data-count>5</span><button data-inc>+1</button><button data-dec>-1</button>",
        )
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page([island], title="Basic Hydration Test")
      c.html(html)
    }),
  )

  // Visible trigger test
  app.get(
    "/loader/visible",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "lazy-1", "/components/lazy.js",
        )
        .with_trigger(@luna.TriggerType::Visible)
        .with_state("{\"message\":\"Hello from state!\"}")
        .with_ssr_html(
          "<div data-content class=\"lazy-component\">Not hydrated yet</div>",
        )
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        ["<div class=\"spacer\">Scroll down to trigger hydration</div>", island],
        title="Visible Trigger Test",
        head="<style>.spacer { height: 2000px; background: linear-gradient(#eee, #ccc); } .lazy-component { padding: 20px; background: #f0f0f0; }</style>",
      )
      c.html(html)
    }),
  )

  // Idle trigger test
  app.get(
    "/loader/idle",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "idle-1", "/components/lazy.js",
        )
        .with_trigger(@luna.TriggerType::Idle)
        .with_state("{\"message\":\"Loaded on idle\"}")
        .with_ssr_html("<div data-content>Waiting for idle...</div>")
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page([island], title="Idle Trigger Test")
      c.html(html)
    }),
  )

  // Script reference state test
  app.get(
    "/loader/script-ref",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "counter-ref", "/components/counter.js",
        )
        .with_state_ref("ln-state-counter-ref")
        .with_ssr_html(
          "<span data-count>10</span><button data-inc>+1</button><button data-dec>-1</button>",
        )
      let island : String = @sol.render_island(config)
      let state_script = @sol.generate_state_script(
        "ln-state-counter-ref", "{\"count\":10}",
      )
      let html = @sol.render_island_page(
        [island, state_script],
        title="Script Reference State Test",
      )
      c.html(html)
    }),
  )

  // Multiple components test
  app.get(
    "/loader/multiple",
    @mars.handler(async fn(c) {
      let config_a : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "counter-a", "/components/counter.js",
        )
        .with_state("{\"count\":1}")
        .with_ssr_html(
          "<span data-count>1</span><button data-inc>+1</button><button data-dec>-1</button>",
        )
      let island_a : String = @sol.render_island(config_a)
      let config_b : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "counter-b", "/components/counter.js",
        )
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
    }),
  )

  // Manual trigger test
  app.get(
    "/loader/manual",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "manual-1", "/components/lazy.js",
        )
        .with_trigger(@luna.TriggerType::None)
        .with_state("{\"message\":\"Manually triggered\"}")
        .with_ssr_html("<div data-content>Should not auto-hydrate</div>")
      let island : String = @sol.render_island(config)
      let trigger_button = "<button id=\"trigger-btn\" onclick=\"window.__LUNA_HYDRATE__(document.querySelector('[luna\\\\:id=manual-1]'))\">Trigger Hydration</button>"
      let html = @sol.render_island_page(
        [island, trigger_button],
        title="Manual Trigger Test",
      )
      c.html(html)
    }),
  )

  // URL state test
  app.get(
    "/loader/url-state",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "user-1", "/components/user.js",
        )
        .with_state_url("/api/state/user")
        .with_ssr_html("<div data-name>Loading...</div><div data-email></div>")
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page([island], title="URL State Test")
      c.html(html)
    }),
  )
}

///|
/// Register shard test routes using @sol module
fn register_shard_routes(app : @sol.App) -> Unit {
  // Minimal shard test
  app.get(
    "/shard/minimal",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "counter-1", "/components/counter.js",
        )
        .with_state("{\"count\":42}")
        .with_ssr_html(
          "<span data-count>42</span><button data-inc>+</button><button data-dec>-</button>",
        )
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page([island], title="Minimal Shard Test")
      c.html(html)
    }),
  )

  // Standalone shard test (includes loader)
  app.get(
    "/shard/standalone",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "greeting-1", "/components/greeting.js",
        )
        .with_state("{\"name\":\"World\"}")
        .with_ssr_html("<p>Hello, <span data-name>World</span>!</p>")
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page([island], title="Standalone Shard Test")
      c.html(html)
    }),
  )

  // Lazy shard test (visible trigger)
  app.get(
    "/shard/lazy",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "lazy-counter", "/components/counter.js",
        )
        .with_trigger(@luna.TriggerType::Visible)
        .with_state("{\"count\":100}")
        .with_ssr_html(
          "<span data-count>100</span><button data-inc>+</button><button data-dec>-</button>",
        )
      let island : String = @sol.render_island(config)
      let html = @sol.render_island_page(
        ["<div class=\"spacer\">Scroll down to trigger hydration</div>", island],
        title="Lazy Shard Test",
        head="<style>.spacer { height: 150vh; background: linear-gradient(#eee, #ccc); }</style>",
      )
      c.html(html)
    }),
  )

  // XSS safety test
  app.get(
    "/shard/xss-safety",
    @mars.handler(async fn(c) {
      let dangerous_state = "{\"message\":\"<script>alert(1)</script>\",\"html\":\"</script><script>\"}"
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "xss-test", "/components/greeting.js",
        )
        .with_state(dangerous_state)
        .with_ssr_html("<p data-name>Safe content</p>")
      let island : String = @sol.render_island(config)
      let xss_check_script = "<script>window.xssTriggered = false; window.alert = () => { window.xssTriggered = true; };</script>"
      let html = @sol.render_island_page(
        [island, xss_check_script],
        title="XSS Safety Test",
      )
      c.html(html)
    }),
  )

  // State script test
  app.get(
    "/shard/state-script",
    @mars.handler(async fn(c) {
      let config : @sol.IslandConfig[Unit] = @sol.IslandConfig::new(
          "counter-script", "/components/counter.js",
        )
        .with_state_ref("counter-state")
        .with_ssr_html(
          "<span data-count>999</span><button data-inc>+</button><button data-dec>-</button>",
        )
      let island : String = @sol.render_island(config)
      let state_script = @sol.generate_state_script(
        "counter-state", "{\"count\":999}",
      )
      let html = @sol.render_island_page(
        [island, state_script],
        title="State Script Test",
      )
      c.html(html)
    }),
  )
}

///|
/// Register async streaming test routes
fn register_async_routes(app : @sol.App) -> Unit {
  // Basic async streaming test - simulates streaming SSR with template replacement
  app.get(
    "/async/basic",
    @mars.handler(async fn(c) {
      // Build page with VAsync nodes
      let node : @luna.Node[Unit, String] = @luna.fragment([
        @luna.h("h1", [], [@luna.text("Async Streaming Test")]),
        @luna.h("div", [("id", @luna.attr_static("static-content"))], [
          @luna.text("This is static content"),
        ]),
        @luna.async_(
          render=async fn() {
            @luna.h("div", [("class", @luna.attr_static("resolved"))], [
              @luna.text("Async content loaded!"),
            ])
          },
          fallback=fn() {
            @luna.h("div", [("class", @luna.attr_static("loading"))], [
              @luna.text("Loading..."),
            ])
          },
        ),
      ])

      // Render with async boundaries collected
      let chunks : Array[String] = []
      let writer = @stream_renderer.StreamWriter::from_callback(fn(chunk) {
        chunks.push(chunk)
      })
      let boundaries = @stream_renderer.render_to_stream_collecting_async(
        node, writer,
      )

      // Build the HTML with template replacement
      let sb = StringBuilder::new()
      sb.write_string(
        "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Async Streaming Test</title></head><body>",
      )
      for chunk in chunks {
        sb.write_string(chunk)
      }

      // Add template and script for each boundary (simulating resolved async)
      for boundary in boundaries {
        let id = boundary.id
        sb.write_string("<template id=\"T:")
        sb.write_string(id.to_string())
        sb.write_string(
          "\"><div class=\"resolved\">Async content loaded!</div></template>",
        )
        sb.write_string("<script>(function(){var t=document.getElementById('T:")
        sb.write_string(id.to_string())
        sb.write_string("'),p=document.getElementById('A:")
        sb.write_string(id.to_string())
        sb.write_string(
          "');if(t&&p){p.replaceWith(t.content);t.remove();}})()</script>",
        )
      }
      sb.write_string("</body></html>")
      c.html(sb.to_string())
    }),
  )

  // Multiple async boundaries test
  app.get(
    "/async/multiple",
    @mars.handler(async fn(c) {
      let node : @luna.Node[Unit, String] = @luna.fragment([
        @luna.h("h1", [], [@luna.text("Multiple Async Test")]),
        @luna.async_(
          render=async fn() {
            @luna.h("div", [("id", @luna.attr_static("first-resolved"))], [
              @luna.text("First resolved"),
            ])
          },
          fallback=fn() {
            @luna.h("div", [("id", @luna.attr_static("first-loading"))], [
              @luna.text("First loading..."),
            ])
          },
        ),
        @luna.h("div", [("id", @luna.attr_static("middle"))], [
          @luna.text("Static middle content"),
        ]),
        @luna.async_(
          render=async fn() {
            @luna.h("div", [("id", @luna.attr_static("second-resolved"))], [
              @luna.text("Second resolved"),
            ])
          },
          fallback=fn() {
            @luna.h("div", [("id", @luna.attr_static("second-loading"))], [
              @luna.text("Second loading..."),
            ])
          },
        ),
      ])
      let chunks : Array[String] = []
      let writer = @stream_renderer.StreamWriter::from_callback(fn(chunk) {
        chunks.push(chunk)
      })
      let boundaries = @stream_renderer.render_to_stream_collecting_async(
        node, writer,
      )
      let sb = StringBuilder::new()
      sb.write_string(
        "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Multiple Async Test</title></head><body>",
      )
      for chunk in chunks {
        sb.write_string(chunk)
      }

      // Add templates - first one with content, second with different content
      for i, boundary in boundaries {
        let id = boundary.id
        let content = if i == 0 { "First resolved" } else { "Second resolved" }
        let resolved_id = if i == 0 {
          "first-resolved"
        } else {
          "second-resolved"
        }
        sb.write_string("<template id=\"T:")
        sb.write_string(id.to_string())
        sb.write_string("\"><div id=\"")
        sb.write_string(resolved_id)
        sb.write_string("\">")
        sb.write_string(content)
        sb.write_string("</div></template>")
        sb.write_string("<script>(function(){var t=document.getElementById('T:")
        sb.write_string(id.to_string())
        sb.write_string("'),p=document.getElementById('A:")
        sb.write_string(id.to_string())
        sb.write_string(
          "');if(t&&p){p.replaceWith(t.content);t.remove();}})()</script>",
        )
      }
      sb.write_string("</body></html>")
      c.html(sb.to_string())
    }),
  )

  // Nested content test
  app.get(
    "/async/nested",
    @mars.handler(async fn(c) {
      let node : @luna.Node[Unit, String] = @luna.h(
        "div",
        [("id", @luna.attr_static("container"))],
        [
          @luna.h("header", [], [@luna.text("Header")]),
          @luna.async_(
            render=async fn() {
              @luna.h("main", [("id", @luna.attr_static("main-content"))], [
                @luna.h("p", [], [@luna.text("Main content loaded")]),
                @luna.h("ul", [], [
                  @luna.h("li", [], [@luna.text("Item 1")]),
                  @luna.h("li", [], [@luna.text("Item 2")]),
                ]),
              ])
            },
            fallback=fn() {
              @luna.h("main", [("class", @luna.attr_static("skeleton"))], [
                @luna.text("Loading main content..."),
              ])
            },
          ),
          @luna.h("footer", [], [@luna.text("Footer")]),
        ],
      )
      let chunks : Array[String] = []
      let writer = @stream_renderer.StreamWriter::from_callback(fn(chunk) {
        chunks.push(chunk)
      })
      let boundaries = @stream_renderer.render_to_stream_collecting_async(
        node, writer,
      )
      let sb = StringBuilder::new()
      sb.write_string(
        "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Nested Async Test</title></head><body>",
      )
      for chunk in chunks {
        sb.write_string(chunk)
      }
      for boundary in boundaries {
        let id = boundary.id
        sb.write_string("<template id=\"T:")
        sb.write_string(id.to_string())
        sb.write_string(
          "\"><main id=\"main-content\"><p>Main content loaded</p><ul><li>Item 1</li><li>Item 2</li></ul></main></template>",
        )
        sb.write_string("<script>(function(){var t=document.getElementById('T:")
        sb.write_string(id.to_string())
        sb.write_string("'),p=document.getElementById('A:")
        sb.write_string(id.to_string())
        sb.write_string(
          "');if(t&&p){p.replaceWith(t.content);t.remove();}})()</script>",
        )
      }
      sb.write_string("</body></html>")
      c.html(sb.to_string())
    }),
  )

  // Fallback only test (no replacement scripts - for testing initial state)
  app.get(
    "/async/fallback-only",
    @mars.handler(async fn(c) {
      let node : @luna.Node[Unit, String] = @luna.fragment([
        @luna.h("h1", [], [@luna.text("Fallback Only Test")]),
        @luna.async_(
          render=async fn() {
            @luna.h("div", [("id", @luna.attr_static("never-seen"))], [
              @luna.text("This should not appear"),
            ])
          },
          fallback=fn() {
            @luna.h("div", [("id", @luna.attr_static("fallback-visible"))], [
              @luna.text("Fallback is visible"),
            ])
          },
        ),
      ])
      let chunks : Array[String] = []
      let writer = @stream_renderer.StreamWriter::from_callback(fn(chunk) {
        chunks.push(chunk)
      })
      let _ = @stream_renderer.render_to_stream_collecting_async(node, writer)
      let sb = StringBuilder::new()
      sb.write_string(
        "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>Fallback Only Test</title></head><body>",
      )
      for chunk in chunks {
        sb.write_string(chunk)
      }
      // No template/script - just the fallback
      sb.write_string("</body></html>")
      c.html(sb.to_string())
    }),
  )
}
