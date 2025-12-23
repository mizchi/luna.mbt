///|
/// WC Counter Page Server Component
/// Uses wc_island() to embed a Web Components based counter.
/// Demonstrates Declarative Shadow DOM SSR with unified hydration.
/// CSS is defined in app/client/wc_counter.mbt and shared between SSR and hydration.
async fn wc_counter(_props : @router.PageProps) -> @server_dom.ServerNode {
  // Create props using WcCounterProps from client module
  let counter_props : @client.WcCounterProps = { initial_count: 0 }
  let state_json = counter_props.to_json().stringify()

  // CSS is imported from client module - shared between SSR and hydration
  let counter_styles = @client.wc_counter_css
  let content = [
    h1([text("Web Components Counter")]),
    p([text("This counter uses Declarative Shadow DOM for SSR.")]),
    p([
      text(
        "CSS is defined in app/client/wc_counter.mbt and shared between SSR and hydration.",
      ),
    ]),
    p([
      text(
        "Inspect the element to see <template shadowrootmode=\"open\"> with <style>.",
      ),
    ]),
    // WcIsland with Declarative Shadow DOM
    // Uses wc_counter.js generated from app/client/wc_counter.mbt
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js", // WC-specific component
      [
        div(class="counter", [
          span(class="count-display", [
            text(counter_props.initial_count.to_string()),
          ]),
          div(class="buttons", [
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              [text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              [text("+")],
            ),
          ]),
        ]),
      ],
      styles=counter_styles,
      state=state_json,
      trigger=@luna.Load,
    ),
    h2([text("How it works")]),
    p([
      text(
        "The WcIsland generates a custom element with Declarative Shadow DOM:",
      ),
    ]),
    div(
      class="code-block",
      style="background: #f5f5f5; padding: 1rem; border-radius: 4px; font-family: monospace; white-space: pre; overflow-x: auto;",
      [
        text("<wc-counter data-wc-url=\"...\" data-state=\"...\">\\n"),
        text("  <template shadowrootmode=\"open\">\\n"),
        text("    <style>:host { ... }</style>\\n"),
        text("    <div class=\"counter\">...</div>\\n"),
        text("  </template>\\n"),
        text("</wc-counter>"),
      ],
    ),
  ]

  // Return content only - layout is applied by SolRoutes::Layout
  @server_dom.ServerNode::sync(@luna.fragment(content))
}
