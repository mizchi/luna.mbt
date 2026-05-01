// Tests for Preact Integration - Sol SSG Preact Support
//
// Tests for PreactRenderer type, Preact page configuration, and SSG integration.
// Preact provides a lightweight React-compatible alternative for islands.

// =============================================================================
// PreactRenderer Basic Tests
// =============================================================================

///|
test "PreactRenderer - basic equality" {
  inspect(
    RendererType::PreactRenderer == RendererType::PreactRenderer,
    content="true",
  )
}

///|
test "PreactRenderer - inequality with React" {
  inspect(
    RendererType::PreactRenderer == RendererType::ReactRenderer,
    content="false",
  )
}

///|
test "PreactRenderer - inequality with other renderers" {
  inspect(
    RendererType::PreactRenderer == RendererType::MarkdownRenderer,
    content="false",
  )
  inspect(
    RendererType::PreactRenderer == RendererType::LunaRenderer,
    content="false",
  )
  inspect(
    RendererType::PreactRenderer == RendererType::ClientOnlyRenderer,
    content="false",
  )
  inspect(
    RendererType::PreactRenderer == RendererType::HtmlRenderer,
    content="false",
  )
  inspect(
    RendererType::PreactRenderer == RendererType::MdxRenderer,
    content="false",
  )
}

///|
test "PreactRenderer - Show implementation" {
  let r = RendererType::PreactRenderer
  let s = r.to_string()
  inspect(s.contains("Preact"), content="true")
}

// =============================================================================
// Preact PageMeta Tests
// =============================================================================

///|
test "PageMeta - Preact component page" {
  let page = PageMeta::new(
    "components/Counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  inspect(page.renderer_type == RendererType::PreactRenderer, content="true")
  inspect(page.content_type == ContentType::TsxComponent, content="true")
  inspect(page.url_path, content="/counter/")
}

///|
test "PageMeta - Preact vs React differentiation" {
  let preact_page = PageMeta::new(
    "islands/Counter.tsx",
    "/islands/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  let react_page = PageMeta::new(
    "islands/Counter.tsx",
    "/islands/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  // Same source can be rendered with different runtimes
  inspect(preact_page.source_path == react_page.source_path, content="true")
  inspect(
    preact_page.renderer_type == react_page.renderer_type,
    content="false",
  )
}

///|
test "PageMeta - Preact with locale" {
  let page = PageMeta::new(
    "ja/components/Counter.tsx",
    "/ja/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
    locale="ja",
  )
  inspect(page.locale, content="ja")
  inspect(page.renderer_type == RendererType::PreactRenderer, content="true")
}

///|
test "PageMeta - Preact with canonical path" {
  let page = PageMeta::new(
    "ja/islands/Counter.tsx",
    "/ja/islands/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
    canonical_path="/islands/counter/",
  )
  inspect(page.canonical_path, content="/islands/counter/")
}

// =============================================================================
// RendererType Pattern Matching with Preact
// =============================================================================

///|
test "RendererType pattern matching - includes PreactRenderer" {
  fn check_variant(r : RendererType) -> String {
    match r {
      RendererType::MarkdownRenderer => "markdown"
      RendererType::HtmlRenderer => "html"
      RendererType::LunaRenderer => "luna"
      RendererType::ReactRenderer => "react"
      RendererType::PreactRenderer => "preact"
      RendererType::ClientOnlyRenderer => "client"
      RendererType::MdxRenderer => "mdx"
    }
  }

  inspect(check_variant(RendererType::PreactRenderer), content="preact")
  inspect(check_variant(RendererType::ReactRenderer), content="react")
  inspect(check_variant(RendererType::LunaRenderer), content="luna")
}

///|
test "RendererType - all variants count with Preact" {
  // Verify all 7 renderer types are available (including PreactRenderer)
  let renderers = [
    RendererType::MarkdownRenderer,
    RendererType::HtmlRenderer,
    RendererType::LunaRenderer,
    RendererType::ReactRenderer,
    RendererType::PreactRenderer,
    RendererType::ClientOnlyRenderer,
    RendererType::MdxRenderer,
  ]
  inspect(renderers.length(), content="7")
}

// =============================================================================
// Preact + React Coexistence Tests
// =============================================================================

///|
test "Preact and React - can coexist in same project" {
  // Both renderers can be configured for different components
  let preact_page = PageMeta::new(
    "widgets/preact/Counter.tsx",
    "/widgets/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  let react_page = PageMeta::new(
    "widgets/react/Dashboard.tsx",
    "/widgets/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  // Different renderers for different use cases
  inspect(
    preact_page.renderer_type == RendererType::PreactRenderer,
    content="true",
  )
  inspect(
    react_page.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
  // Same content type (TSX)
  inspect(preact_page.content_type == react_page.content_type, content="true")
}

///|
test "Preact - frontmatter integration" {
  let page = PageMeta::new(
    "components/Counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Preact Counter"),
    description: Some("A counter component using Preact"),
  }
  let updated = page.with_frontmatter(fm)
  guard updated.frontmatter.title is Some(title) else {
    fail("Expected Some title")
  }
  inspect(title, content="Preact Counter")
}

// =============================================================================
// Preact PageInfo Tests
// =============================================================================

///|
test "PageInfo - Preact renderer" {
  let info = PageInfo::new(
    id="counter",
    url_path="/counter/",
    source_path="components/Counter.tsx",
    title="Counter",
    renderer_type=RendererType::PreactRenderer,
  )
  inspect(info.renderer_type == RendererType::PreactRenderer, content="true")
  inspect(info.url_path, content="/counter/")
}

///|
test "PageInfo - Preact vs React" {
  let preact_info = PageInfo::new(
    id="preact-counter",
    url_path="/preact/counter/",
    renderer_type=RendererType::PreactRenderer,
  )
  let react_info = PageInfo::new(
    id="react-counter",
    url_path="/react/counter/",
    renderer_type=RendererType::ReactRenderer,
  )
  inspect(
    preact_info.renderer_type == react_info.renderer_type,
    content="false",
  )
}

// =============================================================================
// Preact BuildContext Tests
// =============================================================================

///|
test "BuildContext - Preact pages" {
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")
  // Add Preact pages
  let preact_page = PageMeta::new(
    "islands/Counter.tsx",
    "/islands/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  ctx.pages.push(preact_page)
  inspect(ctx.pages.length(), content="1")
  inspect(
    ctx.pages[0].renderer_type == RendererType::PreactRenderer,
    content="true",
  )
}

///|
test "BuildContext - mixed Preact and React pages" {
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")

  // Add Preact page
  ctx.pages.push(
    PageMeta::new(
      "islands/preact/Counter.tsx",
      "/islands/counter/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::PreactRenderer,
    ),
  )

  // Add React page
  ctx.pages.push(
    PageMeta::new(
      "islands/react/Dashboard.tsx",
      "/islands/dashboard/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
    ),
  )

  // Add Markdown page
  ctx.pages.push(PageMeta::new("docs/intro.md", "/docs/intro/"))
  inspect(ctx.pages.length(), content="3")

  // Count renderers
  let mut preact_count = 0
  let mut react_count = 0
  let mut markdown_count = 0
  for page in ctx.pages {
    match page.renderer_type {
      RendererType::PreactRenderer => preact_count = preact_count + 1
      RendererType::ReactRenderer => react_count = react_count + 1
      RendererType::MarkdownRenderer => markdown_count = markdown_count + 1
      _ => ()
    }
  }
  inspect(preact_count, content="1")
  inspect(react_count, content="1")
  inspect(markdown_count, content="1")
}

// =============================================================================
// Preact TreeNode Tests
// =============================================================================

///|
test "TreeNode::Page - Preact renderer" {
  let node = TreeNode::Page(
    page_id="counter",
    renderer=RendererType::PreactRenderer,
  )
  guard node is TreeNode::Page(page_id~, renderer~) else {
    fail("Expected Page node")
  }
  inspect(page_id, content="counter")
  inspect(renderer == RendererType::PreactRenderer, content="true")
}

///|
test "TreeNode - Preact in document tree" {
  // Simulating a document tree with Preact islands
  let tree = [
    TreeNode::Page(page_id="index", renderer=RendererType::MarkdownRenderer),
    TreeNode::Section(name="islands", path="/islands/", children=[
      TreeNode::Page(
        page_id="preact-counter",
        renderer=RendererType::PreactRenderer,
      ),
      TreeNode::Page(
        page_id="react-dashboard",
        renderer=RendererType::ReactRenderer,
      ),
    ]),
  ]
  inspect(tree.length(), content="2")
  guard tree[1] is TreeNode::Section(children~, ..) else {
    fail("Expected Section node")
  }
  inspect(children.length(), content="2")
}

// =============================================================================
// Preact Lightweight Comparison Tests
// =============================================================================

///|
test "Preact - lightweight alternative to React" {
  // Document Preact vs React use cases
  // Preact: Smaller bundle size, same JSX syntax
  // React: Full feature set, larger ecosystem

  let small_component = PageMeta::new(
    "widgets/SmallCounter.tsx",
    "/widgets/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer, // Preact for small widgets
  )
  let complex_component = PageMeta::new(
    "widgets/ComplexDashboard.tsx",
    "/widgets/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer, // React for complex apps
  )
  inspect(
    small_component.renderer_type == RendererType::PreactRenderer,
    content="true",
  )
  inspect(
    complex_component.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
}

// =============================================================================
// Preact Signals Integration Pattern Tests
// =============================================================================

///|
test "Preact - signals pattern metadata" {
  // Preact signals can be used with PreactRenderer
  // The state format is compatible with @preact/signals
  let signals_component = PageMeta::new(
    "components/SignalsCounter.tsx",
    "/signals-counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Signals Counter"),
    description: Some("Counter using @preact/signals"),
  }
  let updated = signals_component.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("signals"), content="true")
}

// =============================================================================
// Preact SSR Configuration Tests
// =============================================================================

///|
test "Preact - SSR with client hydration" {
  // Preact supports client:only, client:load, client:visible, etc.
  // These are configured via the island trigger, not the renderer
  let ssr_page = PageMeta::new(
    "islands/Counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  // SSR is enabled by default for PreactRenderer
  inspect(
    ssr_page.renderer_type == RendererType::PreactRenderer,
    content="true",
  )

  // Client-only mode uses ClientOnlyRenderer
  let client_only_page = PageMeta::new(
    "islands/Canvas.tsx",
    "/canvas/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ClientOnlyRenderer,
  )
  inspect(
    client_only_page.renderer_type == RendererType::ClientOnlyRenderer,
    content="true",
  )
}

///|
test "Preact - with custom sort key" {
  let page = PageMeta::new(
    "islands/01_Counter.tsx",
    "/islands/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
    sort_key="01_islands/01_counter",
  )
  inspect(page.sort_key, content="01_islands/01_counter")
}
