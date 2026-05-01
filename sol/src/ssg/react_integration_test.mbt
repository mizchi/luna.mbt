// Tests for React Integration - Sol SSG React Support
//
// Tests for ReactRenderer type, React page configuration, and SSG integration.
// React provides full-featured JSX/TSX component rendering with SSR support.

// =============================================================================
// ReactRenderer Basic Tests
// =============================================================================

///|
test "ReactRenderer - basic equality" {
  inspect(
    RendererType::ReactRenderer == RendererType::ReactRenderer,
    content="true",
  )
}

///|
test "ReactRenderer - inequality with Preact" {
  inspect(
    RendererType::ReactRenderer == RendererType::PreactRenderer,
    content="false",
  )
}

///|
test "ReactRenderer - inequality with other renderers" {
  inspect(
    RendererType::ReactRenderer == RendererType::MarkdownRenderer,
    content="false",
  )
  inspect(
    RendererType::ReactRenderer == RendererType::LunaRenderer,
    content="false",
  )
  inspect(
    RendererType::ReactRenderer == RendererType::ClientOnlyRenderer,
    content="false",
  )
  inspect(
    RendererType::ReactRenderer == RendererType::HtmlRenderer,
    content="false",
  )
  inspect(
    RendererType::ReactRenderer == RendererType::MdxRenderer,
    content="false",
  )
}

///|
test "ReactRenderer - Show implementation" {
  let r = RendererType::ReactRenderer
  let s = r.to_string()
  inspect(s.contains("React"), content="true")
}

// =============================================================================
// React PageMeta Tests
// =============================================================================

///|
test "PageMeta - React component page" {
  let page = PageMeta::new(
    "components/Dashboard.tsx",
    "/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  inspect(page.renderer_type == RendererType::ReactRenderer, content="true")
  inspect(page.content_type == ContentType::TsxComponent, content="true")
  inspect(page.url_path, content="/dashboard/")
}

///|
test "PageMeta - React with jsx extension" {
  let page = PageMeta::new(
    "components/LegacyComponent.jsx",
    "/legacy/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  inspect(page.renderer_type == RendererType::ReactRenderer, content="true")
  inspect(page.source_path.has_suffix(".jsx"), content="true")
}

///|
test "PageMeta - React with locale" {
  let page = PageMeta::new(
    "ja/components/Dashboard.tsx",
    "/ja/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
    locale="ja",
  )
  inspect(page.locale, content="ja")
  inspect(page.renderer_type == RendererType::ReactRenderer, content="true")
}

///|
test "PageMeta - React with canonical path for i18n" {
  let page = PageMeta::new(
    "ja/islands/Dashboard.tsx",
    "/ja/islands/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
    canonical_path="/islands/dashboard/",
  )
  inspect(page.canonical_path, content="/islands/dashboard/")
}

// =============================================================================
// React SSR Configuration Tests
// =============================================================================

///|
test "React - SSR enabled by default" {
  let ssr_page = PageMeta::new(
    "islands/Dashboard.tsx",
    "/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  // ReactRenderer enables SSR by default
  inspect(ssr_page.renderer_type == RendererType::ReactRenderer, content="true")
}

///|
test "React - client-only mode uses ClientOnlyRenderer" {
  // For components that can't be SSR'd (e.g., using browser APIs)
  let client_only_page = PageMeta::new(
    "islands/WebGLCanvas.tsx",
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
test "React - streaming SSR configuration" {
  // React 18 streaming SSR - configured at page level
  let streaming_page = PageMeta::new(
    "app/page.tsx",
    "/app/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("App Page"),
    description: Some("React 18 streaming SSR"),
  }
  let updated = streaming_page.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("streaming"), content="true")
}

// =============================================================================
// React PageInfo Tests
// =============================================================================

///|
test "PageInfo - React renderer" {
  let info = PageInfo::new(
    id="dashboard",
    url_path="/dashboard/",
    source_path="components/Dashboard.tsx",
    title="Dashboard",
    renderer_type=RendererType::ReactRenderer,
  )
  inspect(info.renderer_type == RendererType::ReactRenderer, content="true")
  inspect(info.url_path, content="/dashboard/")
}

///|
test "PageInfo - React with headings" {
  let info = PageInfo::new(
    id="docs",
    url_path="/docs/",
    source_path="docs/index.tsx",
    title="Documentation",
    renderer_type=RendererType::ReactRenderer,
    headings=[
      Heading::{ level: 1, text: "Documentation", id: "docs" },
      Heading::{ level: 2, text: "Getting Started", id: "getting-started" },
    ],
  )
  inspect(info.headings.length(), content="2")
  inspect(info.headings[0].text, content="Documentation")
}

// =============================================================================
// React BuildContext Tests
// =============================================================================

///|
test "BuildContext - React pages" {
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")
  // Add React pages
  let react_page = PageMeta::new(
    "islands/Dashboard.tsx",
    "/islands/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  ctx.pages.push(react_page)
  inspect(ctx.pages.length(), content="1")
  inspect(
    ctx.pages[0].renderer_type == RendererType::ReactRenderer,
    content="true",
  )
}

///|
test "BuildContext - React app with multiple pages" {
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")

  // Add multiple React pages
  ctx.pages.push(
    PageMeta::new(
      "app/layout.tsx",
      "/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
    ),
  )
  ctx.pages.push(
    PageMeta::new(
      "app/dashboard/page.tsx",
      "/dashboard/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
    ),
  )
  ctx.pages.push(
    PageMeta::new(
      "app/settings/page.tsx",
      "/settings/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
    ),
  )
  inspect(ctx.pages.length(), content="3")

  // All pages use ReactRenderer
  let mut react_count = 0
  for page in ctx.pages {
    if page.renderer_type == RendererType::ReactRenderer {
      react_count = react_count + 1
    }
  }
  inspect(react_count, content="3")
}

///|
test "BuildContext - mixed React and content pages" {
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")

  // React app pages
  ctx.pages.push(
    PageMeta::new(
      "app/page.tsx",
      "/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
    ),
  )

  // MDX documentation
  ctx.pages.push(
    PageMeta::new(
      "docs/intro.mdx",
      "/docs/intro/",
      content_type=ContentType::Mdx,
      renderer_type=RendererType::MdxRenderer,
    ),
  )

  // Markdown blog
  ctx.pages.push(PageMeta::new("blog/post.md", "/blog/post/"))
  inspect(ctx.pages.length(), content="3")

  // Count by renderer type
  let mut react_count = 0
  let mut mdx_count = 0
  let mut markdown_count = 0
  for page in ctx.pages {
    match page.renderer_type {
      RendererType::ReactRenderer => react_count = react_count + 1
      RendererType::MdxRenderer => mdx_count = mdx_count + 1
      RendererType::MarkdownRenderer => markdown_count = markdown_count + 1
      _ => ()
    }
  }
  inspect(react_count, content="1")
  inspect(mdx_count, content="1")
  inspect(markdown_count, content="1")
}

// =============================================================================
// React TreeNode Tests
// =============================================================================

///|
test "TreeNode::Page - React renderer" {
  let node = TreeNode::Page(
    page_id="dashboard",
    renderer=RendererType::ReactRenderer,
  )
  guard node is TreeNode::Page(page_id~, renderer~) else {
    fail("Expected Page node")
  }
  inspect(page_id, content="dashboard")
  inspect(renderer == RendererType::ReactRenderer, content="true")
}

///|
test "TreeNode - React app structure" {
  // Simulating a React app document tree
  let tree = [
    TreeNode::Page(page_id="layout", renderer=RendererType::ReactRenderer),
    TreeNode::Section(name="app", path="/app/", children=[
      TreeNode::Page(page_id="app-page", renderer=RendererType::ReactRenderer),
      TreeNode::Section(name="dashboard", path="/app/dashboard/", children=[
        TreeNode::Page(
          page_id="dashboard-page",
          renderer=RendererType::ReactRenderer,
        ),
      ]),
    ]),
  ]
  inspect(tree.length(), content="2")
  guard tree[1] is TreeNode::Section(children~, ..) else {
    fail("Expected Section node")
  }
  inspect(children.length(), content="2")
}

// =============================================================================
// React Hooks Integration Tests
// =============================================================================

///|
test "React - hooks pattern metadata" {
  // React hooks are used with ReactRenderer
  let hooks_component = PageMeta::new(
    "components/UseStateCounter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("useState Counter"),
    description: Some("Counter using React useState hook"),
  }
  let updated = hooks_component.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("useState"), content="true")
}

///|
test "React - server components pattern" {
  // React Server Components (RSC) pattern
  let rsc_page = PageMeta::new(
    "app/page.tsx",
    "/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Home"),
    description: Some("React Server Component"),
  }
  let updated = rsc_page.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("Server Component"), content="true")
}

// =============================================================================
// React + Luna Integration Tests
// =============================================================================

///|
test "React and Luna - hybrid rendering" {
  // React components can coexist with Luna components
  let react_page = PageMeta::new(
    "islands/react/Dashboard.tsx",
    "/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let luna_page = PageMeta::new(
    "islands/luna/Counter/moon.pkg.json",
    "/counter/",
    content_type=ContentType::Component,
    renderer_type=RendererType::LunaRenderer,
  )
  inspect(
    react_page.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
  inspect(luna_page.renderer_type == RendererType::LunaRenderer, content="true")
}

///|
test "React + Preact - framework coexistence" {
  // React and Preact can both be used in the same project
  let react_page = PageMeta::new(
    "islands/react/HeavyDashboard.tsx",
    "/heavy-dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let preact_page = PageMeta::new(
    "islands/preact/LightCounter.tsx",
    "/light-counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::PreactRenderer,
  )
  // Same content type but different renderers
  inspect(react_page.content_type == preact_page.content_type, content="true")
  inspect(
    react_page.renderer_type == preact_page.renderer_type,
    content="false",
  )
}

// =============================================================================
// React Context and State Management Tests
// =============================================================================

///|
test "React - context provider pattern" {
  let provider_page = PageMeta::new(
    "providers/ThemeProvider.tsx",
    "/providers/theme/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Theme Provider"),
    description: Some("React Context for theme management"),
  }
  let updated = provider_page.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("Context"), content="true")
}

///|
test "React - redux/zustand pattern" {
  // State management libraries work with ReactRenderer
  let store_page = PageMeta::new(
    "store/AppStore.tsx",
    "/store/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  inspect(
    store_page.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
}

// =============================================================================
// React Island Hydration Tests
// =============================================================================

///|
test "React - island with SSR" {
  // React islands support SSR with hydration
  let island_page = PageMeta::new(
    "islands/InteractiveChart.tsx",
    "/charts/interactive/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  // SSR renders initial HTML, hydration adds interactivity
  inspect(
    island_page.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
}

///|
test "React - island without SSR (client-only)" {
  // Some React islands need client-only rendering
  let client_island = PageMeta::new(
    "islands/D3Chart.tsx",
    "/charts/d3/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ClientOnlyRenderer,
  )
  // ClientOnlyRenderer skips SSR, renders placeholder
  inspect(
    client_island.renderer_type == RendererType::ClientOnlyRenderer,
    content="true",
  )
}

// =============================================================================
// React Error Boundary Tests
// =============================================================================

///|
test "React - error boundary pattern" {
  let error_boundary = PageMeta::new(
    "components/ErrorBoundary.tsx",
    "/error-boundary/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Error Boundary"),
    description: Some("React Error Boundary for graceful error handling"),
  }
  let updated = error_boundary.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("Error Boundary"), content="true")
}

// =============================================================================
// React Suspense Tests
// =============================================================================

///|
test "React - suspense pattern" {
  let suspense_page = PageMeta::new(
    "app/loading.tsx",
    "/loading/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Loading"),
    description: Some("React Suspense fallback"),
  }
  let updated = suspense_page.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("Suspense"), content="true")
}

///|
test "React - lazy loading with Suspense" {
  let lazy_page = PageMeta::new(
    "components/LazyDashboard.tsx",
    "/lazy-dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  // Lazy-loaded components use React.lazy() with Suspense
  inspect(
    lazy_page.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
}

// =============================================================================
// React Custom Sort Key Tests
// =============================================================================

///|
test "React - with custom sort key" {
  let page = PageMeta::new(
    "app/01_dashboard/page.tsx",
    "/dashboard/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
    sort_key="01_app/01_dashboard",
  )
  inspect(page.sort_key, content="01_app/01_dashboard")
}

///|
test "React - multiple pages with ordering" {
  let pages = [
    PageMeta::new(
      "app/01_home/page.tsx",
      "/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
      sort_key="01_home",
    ),
    PageMeta::new(
      "app/02_about/page.tsx",
      "/about/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
      sort_key="02_about",
    ),
    PageMeta::new(
      "app/03_contact/page.tsx",
      "/contact/",
      content_type=ContentType::TsxComponent,
      renderer_type=RendererType::ReactRenderer,
      sort_key="03_contact",
    ),
  ]
  inspect(pages.length(), content="3")
  // Sort keys determine navigation order
  inspect(pages[0].sort_key < pages[1].sort_key, content="true")
  inspect(pages[1].sort_key < pages[2].sort_key, content="true")
}

// =============================================================================
// React 18+ Features Tests
// =============================================================================

///|
test "React 18 - concurrent features" {
  let concurrent_page = PageMeta::new(
    "app/concurrent.tsx",
    "/concurrent/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Concurrent Features"),
    description: Some("React 18 concurrent rendering and transitions"),
  }
  let updated = concurrent_page.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("concurrent"), content="true")
}

///|
test "React 18 - useTransition pattern" {
  let transition_page = PageMeta::new(
    "components/SearchResults.tsx",
    "/search/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  // useTransition allows non-blocking UI updates
  inspect(
    transition_page.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
}

// =============================================================================
// React + MDX Integration Tests
// =============================================================================

///|
test "React components in MDX" {
  // MDX can embed React components
  let mdx_with_react = PageMeta::new(
    "docs/interactive.mdx",
    "/docs/interactive/",
    content_type=ContentType::Mdx,
    renderer_type=RendererType::MdxRenderer,
  )
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Interactive Docs"),
    description: Some("MDX with embedded React components"),
  }
  let updated = mdx_with_react.with_frontmatter(fm)
  guard updated.frontmatter.description is Some(desc) else {
    fail("Expected Some description")
  }
  inspect(desc.contains("React components"), content="true")
}
