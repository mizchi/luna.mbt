// Static Content SSR Integration Tests
//
// Verifies that static content works correctly with SSR:
// - Server: render_to_string() produces HTML
// - Client: inject_static() produces identical DOM
// - Content is truly static (no hydration needed)
//
// Note: get_inner_html helper is defined in hydrate_test.mbt

///|
test "static_content: SSR and CSR produce identical output" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Create a VNode that would be rendered on server
  let vnode : @luna.Node[Unit, String] = @luna.h(
    "div",
    [("class", @luna.attr_static("container"))],
    [
      @luna.h("h1", [], [@luna.text("Hello SSR")]),
      @luna.h("p", [], [@luna.text("This is static content")]),
    ],
  )

  // SSR: What server would produce
  let ssr_html = @render.render_to_string(vnode).html

  // CSR: What inject_static produces
  let container = doc.createElement("div")
  inject_static(container, vnode)
  let csr_html = get_inner_html(container)

  // They should be identical
  assert_eq(ssr_html, csr_html)
}

///|
test "static_content: nested elements render correctly" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let vnode : @luna.Node[Unit, String] = @luna.h("nav", [], [
    @luna.h("ul", [], [
      @luna.h("li", [], [
        @luna.h("a", [("href", @luna.attr_static("/"))], [@luna.text("Home")]),
      ]),
      @luna.h("li", [], [
        @luna.h("a", [("href", @luna.attr_static("/about"))], [
          @luna.text("About"),
        ]),
      ]),
      @luna.h("li", [], [
        @luna.h("a", [("href", @luna.attr_static("/contact"))], [
          @luna.text("Contact"),
        ]),
      ]),
    ]),
  ])
  let ssr_html = @render.render_to_string(vnode).html
  let container = doc.createElement("div")
  inject_static(container, vnode)
  assert_eq(ssr_html, get_inner_html(container))
}

///|
test "static_content: void elements handled correctly" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let vnode : @luna.Node[Unit, String] = @luna.h("div", [], [
    @luna.h(
      "img",
      [
        ("src", @luna.attr_static("/image.png")),
        ("alt", @luna.attr_static("Test image")),
      ],
      [],
    ),
    @luna.h("br", [], []),
    @luna.h(
      "input",
      [
        ("type", @luna.attr_static("text")),
        ("placeholder", @luna.attr_static("Enter text")),
      ],
      [],
    ),
  ])
  let ssr_html = @render.render_to_string(vnode).html
  let container = doc.createElement("div")
  inject_static(container, vnode)

  // Both should contain self-closing void elements
  assert_true(ssr_html.contains("<img "))
  assert_true(ssr_html.contains("<br />"))
  assert_true(ssr_html.contains("<input "))
}

///|
test "static_content: special characters escaped correctly" {
  @global_jsdom.register()
  let vnode : @luna.Node[Unit, String] = @luna.h("div", [], [
    @luna.text("Hello <script>alert('xss')</script>"),
    @luna.h("span", [], [@luna.text("A & B")]),
  ])
  let ssr_html = @render.render_to_string(vnode).html

  // XSS should be escaped
  assert_true(ssr_html.contains("&lt;script&gt;"))
  assert_true(ssr_html.contains("&amp;"))
  assert_false(ssr_html.contains("<script>"))
}

///|
test "static_block: creates wrapper with innerHTML" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let vnode : @luna.Node[Unit, String] = @luna.h("ul", [], [
    @luna.h("li", [], [@luna.text("Item 1")]),
    @luna.h("li", [], [@luna.text("Item 2")]),
  ])
  let block = static_block("section", vnode)
  let dom_node = block.to_dom()

  // Should create a section wrapper
  assert_eq(dom_node.nodeName(), "SECTION")

  // Content should be inside
  let container = doc.createElement("div")
  container.as_node().appendChild(dom_node) |> ignore
  assert_true(get_inner_html(container).contains("<ul>"))
  assert_true(get_inner_html(container).contains("Item 1"))
}

///|
test "static_div: convenience wrapper works" {
  @global_jsdom.register()
  let vnode : @luna.Node[Unit, String] = @luna.text("Hello")
  let block = static_div(vnode)
  assert_eq(block.to_dom().nodeName(), "DIV")
}

///|
test "static_span: convenience wrapper works" {
  @global_jsdom.register()
  let vnode : @luna.Node[Unit, String] = @luna.text("Hello")
  let block = static_span(vnode)
  assert_eq(block.to_dom().nodeName(), "SPAN")
}

///|
test "inject_static_html: raw HTML injection" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Simulating pre-rendered HTML from SSR
  let ssr_html = "<div class=\"header\"><h1>Welcome</h1></div>"
  let container = doc.createElement("div")
  inject_static_html(container, ssr_html)
  assert_eq(get_inner_html(container), ssr_html)
}

///|
test "static_content: Fragment renders correctly" {
  @global_jsdom.register()
  let doc = @js_dom.document()
  let vnode : @luna.Node[Unit, String] = @luna.fragment([
    @luna.h("span", [], [@luna.text("First")]),
    @luna.h("span", [], [@luna.text("Second")]),
  ])
  let ssr_html = @render.render_to_string(vnode).html
  let container = doc.createElement("div")
  inject_static(container, vnode)

  // Fragment should render children directly
  assert_eq(ssr_html, "<span>First</span><span>Second</span>")
  assert_eq(get_inner_html(container), ssr_html)
}

///|
test "static_content: large list renders efficiently" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Create a large list (simulating real-world static content)
  let items : Array[@luna.Node[Unit, String]] = []
  for i = 0; i < 100; i = i + 1 {
    items.push(@luna.h("li", [], [@luna.text("Item " + i.to_string())]))
  }
  let vnode : @luna.Node[Unit, String] = @luna.h("ul", [], items)
  let ssr_html = @render.render_to_string(vnode).html
  let container = doc.createElement("div")
  inject_static(container, vnode)

  // Verify content matches
  assert_eq(ssr_html, get_inner_html(container))

  // Verify structure
  assert_true(ssr_html.contains("<li>Item 0</li>"))
  assert_true(ssr_html.contains("<li>Item 99</li>"))
}

// =============================================================================
// Sol Integration Tests
// =============================================================================

///|
test "sol_pattern: static header with Island placeholder" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Sol pattern: static header followed by dynamic island marker
  // The Island would be hydrated separately
  let header : @luna.Node[Unit, String] = @luna.h(
    "header",
    [("class", @luna.attr_static("site-header"))],
    [
      @luna.h("h1", [], [@luna.text("My Site")]),
      @luna.h("nav", [], [
        @luna.h("a", [("href", @luna.attr_static("/"))], [@luna.text("Home")]),
        @luna.h("a", [("href", @luna.attr_static("/about"))], [
          @luna.text("About"),
        ]),
      ]),
    ],
  )

  // Server renders header
  let ssr_html = @render.render_to_string(header).html

  // Client injects static header
  let header_container = doc.createElement("div")
  inject_static(header_container, header)

  // Verify identical
  assert_eq(ssr_html, get_inner_html(header_container))

  // Verify structure
  assert_true(ssr_html.contains("site-header"))
  assert_true(ssr_html.contains("My Site"))
}

///|
test "sol_pattern: sol-link navigation (static content)" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Sol CSR navigation links
  let nav : @luna.Node[Unit, String] = @luna.h("nav", [], [
    @luna.h(
      "a",
      [
        ("href", @luna.attr_static("/about")),
        ("sol-link", @luna.attr_static("")),
      ],
      [@luna.text("About")],
    ),
    @luna.h(
      "a",
      [
        ("href", @luna.attr_static("/contact")),
        ("sol-link", @luna.attr_static("")),
      ],
      [@luna.text("Contact")],
    ),
  ])
  let ssr_html = @render.render_to_string(nav).html
  let container = doc.createElement("div")
  inject_static(container, nav)

  // sol-link attribute should be preserved
  // Note: SSR outputs `sol-link` (no value), browser innerHTML outputs `sol-link=""`
  // Both are semantically equivalent for boolean attributes
  assert_true(ssr_html.contains("sol-link"))
  assert_true(get_inner_html(container).contains("sol-link"))
  assert_true(get_inner_html(container).contains("/about"))
  assert_true(get_inner_html(container).contains("/contact"))
}

///|
test "sol_pattern: pre-cached SSR fragment injection" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Simulating Sol's fragment caching
  // Server pre-renders and caches this fragment
  let cached_fragment : @luna.Node[Unit, String] = @luna.h(
    "section",
    [("class", @luna.attr_static("cached-content"))],
    [
      @luna.h("h2", [], [@luna.text("Cached Section")]),
      @luna.h("p", [], [
        @luna.text("This content was pre-rendered on the server"),
      ]),
    ],
  )

  // Pre-render to cache
  let cached_html = @render.render_to_string(cached_fragment).html

  // On subsequent requests, inject cached HTML directly
  let container = doc.createElement("div")
  inject_static_html(container, cached_html)
  assert_eq(get_inner_html(container), cached_html)
  assert_true(get_inner_html(container).contains("Cached Section"))
}

// =============================================================================
// Sol SSG Integration Tests
// =============================================================================

///|
test "ssg_pattern: markdown document structure" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Sol SSG renders Markdown as VNode then to HTML
  // Simulating a typical documentation page structure
  // Note: Avoid single quotes in text content as SSR escapes them differently
  let doc_page : @luna.Node[Unit, String] = @luna.h(
    "article",
    [("class", @luna.attr_static("markdown-body"))],
    [
      @luna.h("h1", [], [@luna.text("Getting Started")]),
      @luna.h("p", [], [@luna.text("Welcome to the documentation.")]),
      @luna.h("h2", [], [@luna.text("Installation")]),
      @luna.h("pre", [], [
        @luna.h("code", [("class", @luna.attr_static("language-bash"))], [
          @luna.text("npm install luna"),
        ]),
      ]),
      @luna.h("h2", [], [@luna.text("Usage")]),
      @luna.h("p", [], [
        @luna.text("Import the library with: "),
        @luna.h("code", [], [@luna.text("import { h } from luna")]),
      ]),
    ],
  )
  let ssr_html = @render.render_to_string(doc_page).html
  let container = doc.createElement("div")
  inject_static(container, doc_page)

  // Content should match exactly
  assert_eq(ssr_html, get_inner_html(container))

  // Verify Markdown-like structure
  assert_true(ssr_html.contains("markdown-body"))
  assert_true(ssr_html.contains("<h1>"))
  assert_true(ssr_html.contains("<pre>"))
  assert_true(ssr_html.contains("language-bash"))
}

///|
test "ssg_pattern: navigation sidebar" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Sol SSG auto-generates sidebar navigation
  let sidebar : @luna.Node[Unit, String] = @luna.h(
    "aside",
    [("class", @luna.attr_static("sidebar"))],
    [
      @luna.h("div", [("class", @luna.attr_static("sidebar-group"))], [
        @luna.h("h3", [], [@luna.text("Guide")]),
        @luna.h("ul", [], [
          @luna.h("li", [], [
            @luna.h("a", [("href", @luna.attr_static("/guide/intro"))], [
              @luna.text("Introduction"),
            ]),
          ]),
          @luna.h("li", [], [
            @luna.h("a", [("href", @luna.attr_static("/guide/quickstart"))], [
              @luna.text("Quick Start"),
            ]),
          ]),
        ]),
      ]),
      @luna.h("div", [("class", @luna.attr_static("sidebar-group"))], [
        @luna.h("h3", [], [@luna.text("API")]),
        @luna.h("ul", [], [
          @luna.h("li", [], [
            @luna.h("a", [("href", @luna.attr_static("/api/core"))], [
              @luna.text("Core"),
            ]),
          ]),
          @luna.h("li", [], [
            @luna.h("a", [("href", @luna.attr_static("/api/render"))], [
              @luna.text("Render"),
            ]),
          ]),
        ]),
      ]),
    ],
  )
  let ssr_html = @render.render_to_string(sidebar).html
  let container = doc.createElement("div")
  inject_static(container, sidebar)
  assert_eq(ssr_html, get_inner_html(container))
}

///|
test "ssg_pattern: i18n language switcher" {
  @global_jsdom.register()
  let doc = @js_dom.document()

  // Sol SSG i18n language selector
  let lang_switcher : @luna.Node[Unit, String] = @luna.h(
    "div",
    [("class", @luna.attr_static("lang-switcher"))],
    [
      @luna.h(
        "a",
        [
          ("href", @luna.attr_static("/en/docs")),
          ("lang", @luna.attr_static("en")),
        ],
        [@luna.text("English")],
      ),
      @luna.h(
        "a",
        [
          ("href", @luna.attr_static("/ja/docs")),
          ("lang", @luna.attr_static("ja")),
        ],
        [@luna.text("日本語")],
      ),
      @luna.h(
        "a",
        [
          ("href", @luna.attr_static("/zh/docs")),
          ("lang", @luna.attr_static("zh")),
        ],
        [@luna.text("中文")],
      ),
    ],
  )
  let ssr_html = @render.render_to_string(lang_switcher).html
  let container = doc.createElement("div")
  inject_static(container, lang_switcher)
  assert_eq(ssr_html, get_inner_html(container))

  // Japanese characters should be preserved
  assert_true(ssr_html.contains("日本語"))
  assert_true(ssr_html.contains("中文"))
}
