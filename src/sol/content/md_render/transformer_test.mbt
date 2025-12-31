// Tests for MDX component SSR rendering
// Ensures that component children are rendered as raw HTML, not escaped text

///|
/// Test that ComponentEmbed with HTML children renders correctly
test "Component with HTML children renders as raw HTML" {
  // Create a ComponentEmbed with HTML content
  let embed : @markdown.ComponentEmbed = {
    tag: "my-accordion",
    attrs: [],
    content: "<div data-item=\"1\">Content Here</div>",
    trigger: @luna.Load,
  }
  let node = @markdown.MdNode::Component(embed)

  // Convert to VNode
  let vnode = md_node_to_vnode(node, islands_base_path="/components/")

  // Render to HTML string
  let result = @render.render_to_string(vnode)

  // Verify the HTML content is NOT escaped
  // Should contain actual HTML tags, not &lt;div&gt;
  inspect(
    result.html.contains("<div data-item=\"1\">Content Here</div>"),
    content="true",
  )
  inspect(result.html.contains("&lt;div"), content="false")
}

///|
/// Test that ComponentEmbed with nested HTML renders correctly
test "Component with nested HTML children" {
  let embed : @markdown.ComponentEmbed = {
    tag: "accordion-demo",
    attrs: [("data-state", "open")],
    content: "<button>Click me</button><div class=\"content\"><p>Nested paragraph</p></div>",
    trigger: @luna.Visible,
  }
  let node = @markdown.MdNode::Component(embed)
  let vnode = md_node_to_vnode(node, islands_base_path="/static/")
  let result = @render.render_to_string(vnode)

  // Verify nested HTML is preserved
  inspect(result.html.contains("<button>Click me</button>"), content="true")
  inspect(result.html.contains("<p>Nested paragraph</p>"), content="true")
  // Verify luna:wc-url attribute is set
  inspect(
    result.html.contains("luna:wc-url=\"/static/accordion-demo.js\""),
    content="true",
  )
  // Verify trigger attribute
  inspect(result.html.contains("luna:wc-trigger=\"visible\""), content="true")
}

///|
/// Test that empty ComponentEmbed content produces empty element
test "Component with empty content" {
  let embed : @markdown.ComponentEmbed = {
    tag: "empty-component",
    attrs: [],
    content: "",
    trigger: @luna.Load,
  }
  let node = @markdown.MdNode::Component(embed)
  let vnode = md_node_to_vnode(node, islands_base_path="/components/")
  let result = @render.render_to_string(vnode)

  // Should produce self-closing or empty element
  inspect(
    result.html.contains("<empty-component") &&
    result.html.contains("</empty-component>"),
    content="true",
  )
}

///|
/// Test radix-style accordion structure renders correctly for SSR
test "Radix accordion SSR structure" {
  let accordion_content =
    #|<div data-accordion-item="item-1" data-state="open">
    #|  <button data-accordion-trigger>What is Luna?</button>
    #|  <div data-accordion-content>
    #|    <p>Luna is a reactive UI framework.</p>
    #|  </div>
    #|</div>
    #|<div data-accordion-item="item-2" data-state="closed">
    #|  <button data-accordion-trigger>How does it work?</button>
    #|  <div data-accordion-content>
    #|    <p>It uses signals for reactivity.</p>
    #|  </div>
    #|</div>
  let embed : @markdown.ComponentEmbed = {
    tag: "radix-accordion",
    attrs: [("collapsible", "true")],
    content: accordion_content,
    trigger: @luna.Visible,
  }
  let node = @markdown.MdNode::Component(embed)
  let vnode = md_node_to_vnode(node, islands_base_path="/components/")
  let result = @render.render_to_string(vnode)

  // Verify data attributes are preserved (critical for hydration)
  inspect(
    result.html.contains("data-accordion-item=\"item-1\""),
    content="true",
  )
  inspect(
    result.html.contains("data-accordion-item=\"item-2\""),
    content="true",
  )
  inspect(result.html.contains("data-accordion-trigger"), content="true")
  inspect(result.html.contains("data-accordion-content"), content="true")
  inspect(result.html.contains("data-state=\"open\""), content="true")
  inspect(result.html.contains("data-state=\"closed\""), content="true")
}

///|
/// Test that special characters in content are NOT double-escaped
test "Component content with special chars not double-escaped" {
  let embed : @markdown.ComponentEmbed = {
    tag: "code-demo",
    attrs: [],
    content: "<pre><code>const x = 1 &amp;&amp; 2;</code></pre>",
    trigger: @luna.Load,
  }
  let node = @markdown.MdNode::Component(embed)
  let vnode = md_node_to_vnode(node, islands_base_path="/components/")
  let result = @render.render_to_string(vnode)

  // The &amp; should be preserved as-is (already escaped in source)
  // NOT double-escaped to &amp;amp;
  inspect(result.html.contains("&amp;&amp;"), content="true")
  inspect(result.html.contains("&amp;amp;"), content="false")
}

///|
/// Test switch component SSR rendering
test "Radix switch SSR structure" {
  let switch_content =
    #|<button role="switch" aria-checked="true" data-state="checked">
    #|  <span data-thumb></span>
    #|</button>
  let embed : @markdown.ComponentEmbed = {
    tag: "radix-switch",
    attrs: [("id", "notifications")],
    content: switch_content,
    trigger: @luna.Visible,
  }
  let node = @markdown.MdNode::Component(embed)
  let vnode = md_node_to_vnode(node, islands_base_path="/components/")
  let result = @render.render_to_string(vnode)

  // Verify accessibility attributes preserved
  inspect(result.html.contains("role=\"switch\""), content="true")
  inspect(result.html.contains("aria-checked=\"true\""), content="true")
  inspect(result.html.contains("data-state=\"checked\""), content="true")
  inspect(result.html.contains("data-thumb"), content="true")
}

///|
/// Test tabs component SSR rendering
test "Radix tabs SSR structure" {
  let tabs_content =
    #|<div role="tablist">
    #|  <button role="tab" data-state="active" aria-selected="true">Tab 1</button>
    #|  <button role="tab" data-state="inactive" aria-selected="false">Tab 2</button>
    #|</div>
    #|<div role="tabpanel" data-state="active">Panel 1 content</div>
    #|<div role="tabpanel" data-state="inactive" hidden>Panel 2 content</div>
  let embed : @markdown.ComponentEmbed = {
    tag: "radix-tabs",
    attrs: [("default-value", "tab1")],
    content: tabs_content,
    trigger: @luna.Visible,
  }
  let node = @markdown.MdNode::Component(embed)
  let vnode = md_node_to_vnode(node, islands_base_path="/components/")
  let result = @render.render_to_string(vnode)

  // Verify ARIA roles preserved
  inspect(result.html.contains("role=\"tablist\""), content="true")
  inspect(result.html.contains("role=\"tab\""), content="true")
  inspect(result.html.contains("role=\"tabpanel\""), content="true")
  inspect(result.html.contains("aria-selected=\"true\""), content="true")
  inspect(result.html.contains("hidden"), content="true")
}
