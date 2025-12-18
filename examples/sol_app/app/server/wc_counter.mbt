///| WC Counter Page Server Component
///|
///| Uses wc_island() to embed a Web Components based counter.
///| Demonstrates Declarative Shadow DOM SSR with unified hydration.
///|
///| CSS is defined in app/client/wc_counter.mbt and shared between SSR and hydration.

///| WC Counter page - Web Components based island (sync server component)
pub fn wc_counter(props : @router.PageProps) -> @server_dom.ServerNode {
  // Create props using WcCounterProps from client module
  let counter_props : @client.WcCounterProps = { initial_count: 0 }
  let state_json = counter_props.to_json().stringify()

  // CSS is imported from client module - shared between SSR and hydration
  let counter_styles = @client.wc_counter_css

  let content = [
    h1(children=[text("Web Components Counter")]),
    p(children=[
      text("This counter uses Declarative Shadow DOM for SSR."),
    ]),
    p(children=[
      text("CSS is defined in app/client/wc_counter.mbt and shared between SSR and hydration."),
    ]),
    p(children=[
      text("Inspect the element to see <template shadowrootmode=\"open\"> with <style>."),
    ]),
    // WcIsland with Declarative Shadow DOM
    // Uses wc_counter.js generated from app/client/wc_counter.mbt
    @server_dom.wc_island(
      "wc-counter",
      "/static/wc_counter.js", // WC-specific component
      styles=counter_styles,
      state=state_json,
      trigger=@luna.Load,
      children=[
        div(class="counter", children=[
          span(class="count-display", children=[
            text(counter_props.initial_count.to_string()),
          ]),
          div(class="buttons", children=[
            button(
              class="dec",
              attrs=[("data-on-click", @luna.attr_static("decrement"))],
              children=[text("-")],
            ),
            button(
              class="inc",
              attrs=[("data-on-click", @luna.attr_static("increment"))],
              children=[text("+")],
            ),
          ]),
        ]),
      ],
    ),
    h2(children=[text("How it works")]),
    p(children=[
      text("The WcIsland generates a custom element with Declarative Shadow DOM:"),
    ]),
    div(class="code-block", style="background: #f5f5f5; padding: 1rem; border-radius: 4px; font-family: monospace; white-space: pre; overflow-x: auto;", children=[
      text("<wc-counter data-wc-url=\"...\" data-state=\"...\">\\n"),
      text("  <template shadowrootmode=\"open\">\\n"),
      text("    <style>:host { ... }</style>\\n"),
      text("    <div class=\"counter\">...</div>\\n"),
      text("  </template>\\n"),
      text("</wc-counter>"),
    ]),
  ]

  // Fragment request: return content only (no layout)
  // Full page request: wrap with layout
  let node = if props.params.is_fragment {
    @luna.fragment(content)
  } else {
    layout(content)
  }
  @server_dom.ServerNode::sync(node)
}
