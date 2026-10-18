// Tests for RendererType - Unified SSR Renderer Support
//
// Tests for renderer type selection and handling.
// Supports multiple rendering strategies: Markdown, HTML, Luna, React, MDX, ClientOnly.

// =============================================================================
// RendererType Basic Tests
// =============================================================================

///|
test "RendererType::default - returns RendererType::MarkdownRenderer" {
  let default = @astra.RendererType::default()
  inspect(default == @astra.RendererType::MarkdownRenderer, content="true")
}

///|
test "RendererType - equality comparison" {
  inspect(
    @astra.RendererType::MarkdownRenderer ==
    @astra.RendererType::MarkdownRenderer,
    content="true",
  )
  inspect(
    @astra.RendererType::HtmlRenderer == @astra.RendererType::HtmlRenderer,
    content="true",
  )
  inspect(
    @astra.RendererType::LunaRenderer == @astra.RendererType::LunaRenderer,
    content="true",
  )
  inspect(
    @astra.RendererType::ReactRenderer == @astra.RendererType::ReactRenderer,
    content="true",
  )
  inspect(
    @astra.RendererType::PreactRenderer == @astra.RendererType::PreactRenderer,
    content="true",
  )
  inspect(
    @astra.RendererType::ClientOnlyRenderer ==
    @astra.RendererType::ClientOnlyRenderer,
    content="true",
  )
  inspect(
    @astra.RendererType::MdxRenderer == @astra.RendererType::MdxRenderer,
    content="true",
  )
}

///|
test "RendererType - inequality comparison" {
  inspect(
    @astra.RendererType::MarkdownRenderer == @astra.RendererType::HtmlRenderer,
    content="false",
  )
  inspect(
    @astra.RendererType::LunaRenderer == @astra.RendererType::ReactRenderer,
    content="false",
  )
  inspect(
    @astra.RendererType::MdxRenderer == @astra.RendererType::ClientOnlyRenderer,
    content="false",
  )
}

// =============================================================================
// RendererType Debug Representation Tests
// =============================================================================

///|
test "RendererType - Debug for RendererType::MarkdownRenderer" {
  debug_inspect(
    @astra.RendererType::MarkdownRenderer,
    content="MarkdownRenderer",
  )
}

///|
test "RendererType - Debug for RendererType::HtmlRenderer" {
  debug_inspect(@astra.RendererType::HtmlRenderer, content="HtmlRenderer")
}

///|
test "RendererType - Debug for RendererType::LunaRenderer" {
  debug_inspect(@astra.RendererType::LunaRenderer, content="LunaRenderer")
}

///|
test "RendererType - Debug for RendererType::ReactRenderer" {
  debug_inspect(@astra.RendererType::ReactRenderer, content="ReactRenderer")
}

///|
test "RendererType - Debug for RendererType::ClientOnlyRenderer" {
  debug_inspect(
    @astra.RendererType::ClientOnlyRenderer,
    content="ClientOnlyRenderer",
  )
}

///|
test "RendererType - Debug for RendererType::MdxRenderer" {
  debug_inspect(@astra.RendererType::MdxRenderer, content="MdxRenderer")
}

// =============================================================================
// RendererType Pattern Matching Tests
// =============================================================================

///|
test "RendererType - pattern matching all variants" {
  fn check_variant(r : @astra.RendererType) -> String {
    match r {
      @astra.RendererType::MarkdownRenderer => "markdown"
      @astra.RendererType::HtmlRenderer => "html"
      @astra.RendererType::LunaRenderer => "luna"
      @astra.RendererType::ReactRenderer => "react"
      @astra.RendererType::PreactRenderer => "preact"
      @astra.RendererType::ClientOnlyRenderer => "client"
      @astra.RendererType::MdxRenderer => "mdx"
    }
  }

  inspect(
    check_variant(@astra.RendererType::MarkdownRenderer),
    content="markdown",
  )
  inspect(check_variant(@astra.RendererType::HtmlRenderer), content="html")
  inspect(check_variant(@astra.RendererType::LunaRenderer), content="luna")
  inspect(check_variant(@astra.RendererType::ReactRenderer), content="react")
  inspect(check_variant(@astra.RendererType::PreactRenderer), content="preact")
  inspect(
    check_variant(@astra.RendererType::ClientOnlyRenderer),
    content="client",
  )
  inspect(check_variant(@astra.RendererType::MdxRenderer), content="mdx")
}

// =============================================================================
// ContentType Tests
// =============================================================================

///|
test "ContentType - equality comparison" {
  inspect(
    @astra.ContentType::Markdown == @astra.ContentType::Markdown,
    content="true",
  )
  inspect(@astra.ContentType::Html == @astra.ContentType::Html, content="true")
  inspect(
    @astra.ContentType::Component == @astra.ContentType::Component,
    content="true",
  )
  inspect(
    @astra.ContentType::TsxComponent == @astra.ContentType::TsxComponent,
    content="true",
  )
  inspect(@astra.ContentType::Mdx == @astra.ContentType::Mdx, content="true")
}

///|
test "ContentType - inequality comparison" {
  inspect(
    @astra.ContentType::Markdown == @astra.ContentType::Html,
    content="false",
  )
  inspect(
    @astra.ContentType::Component == @astra.ContentType::TsxComponent,
    content="false",
  )
}

///|
test "ContentType - Debug representation" {
  debug_inspect(@astra.ContentType::Markdown, content="Markdown")
  debug_inspect(@astra.ContentType::Html, content="Html")
  debug_inspect(@astra.ContentType::Component, content="Component")
  debug_inspect(@astra.ContentType::Mdx, content="Mdx")
}

// =============================================================================
// PageMeta Tests
// =============================================================================

///|
test "PageMeta::new - basic creation" {
  let page = @astra.PageMeta::new("docs/intro.md", "/intro/")
  inspect(page.source_path, content="docs/intro.md")
  inspect(page.url_path, content="/intro/")
  inspect(page.content_type == @astra.ContentType::Markdown, content="true")
  inspect(
    page.renderer_type == @astra.RendererType::MarkdownRenderer,
    content="true",
  )
  inspect(page.locale, content="en")
}

///|
test "PageMeta::new - with custom content_type" {
  let page = @astra.PageMeta::new(
    "docs/page.html",
    "/page/",
    content_type=@astra.ContentType::Html,
  )
  inspect(page.content_type == @astra.ContentType::Html, content="true")
}

///|
test "PageMeta::new - with custom renderer_type" {
  let page = @astra.PageMeta::new(
    "docs/component/index.tsx",
    "/component/",
    renderer_type=@astra.RendererType::ReactRenderer,
  )
  inspect(
    page.renderer_type == @astra.RendererType::ReactRenderer,
    content="true",
  )
}

///|
test "PageMeta::new - with custom locale" {
  let page = @astra.PageMeta::new("ja/docs/intro.md", "/ja/intro/", locale="ja")
  inspect(page.locale, content="ja")
}

///|
test "PageMeta::new - canonical_path defaults to url_path" {
  let page = @astra.PageMeta::new("docs/intro.md", "/intro/")
  inspect(page.canonical_path, content="/intro/")
}

///|
test "PageMeta::new - with custom canonical_path" {
  let page = @astra.PageMeta::new(
    "ja/docs/intro.md",
    "/ja/intro/",
    canonical_path="/intro/",
  )
  inspect(page.canonical_path, content="/intro/")
}

///|
test "PageMeta::new - sort_key defaults to source_path" {
  let page = @astra.PageMeta::new("01_guide/02_intro.md", "/guide/intro/")
  inspect(page.sort_key, content="01_guide/02_intro.md")
}

///|
test "PageMeta::new - with custom sort_key" {
  let page = @astra.PageMeta::new(
    "guide/intro.md",
    "/guide/intro/",
    sort_key="01_guide/01_intro",
  )
  inspect(page.sort_key, content="01_guide/01_intro")
}

///|
test "PageMeta::with_frontmatter - updates frontmatter" {
  let page = @astra.PageMeta::new("docs/intro.md", "/intro/")
  let fm = @frontmatter.Frontmatter::{
    ..@frontmatter.Frontmatter::default(),
    title: Some("Introduction"),
  }
  let updated = page.with_frontmatter(fm)
  guard updated.frontmatter.title is Some(title) else {
    fail("Expected Some title")
  }
  inspect(title, content="Introduction")
}

// =============================================================================
// Renderer Selection by Extension Tests
// =============================================================================

///|
test "RendererType selection - .md files use RendererType::MarkdownRenderer" {
  let page = @astra.PageMeta::new(
    "docs/intro.md",
    "/intro/",
    content_type=@astra.ContentType::Markdown,
    renderer_type=@astra.RendererType::MarkdownRenderer,
  )
  inspect(
    page.renderer_type == @astra.RendererType::MarkdownRenderer,
    content="true",
  )
}

///|
test "RendererType selection - .html files use RendererType::HtmlRenderer" {
  let page = @astra.PageMeta::new(
    "docs/page.html",
    "/page/",
    content_type=@astra.ContentType::Html,
    renderer_type=@astra.RendererType::HtmlRenderer,
  )
  inspect(
    page.renderer_type == @astra.RendererType::HtmlRenderer,
    content="true",
  )
}

///|
test "RendererType selection - .tsx files use RendererType::ReactRenderer" {
  let page = @astra.PageMeta::new(
    "components/counter.tsx",
    "/counter/",
    content_type=@astra.ContentType::TsxComponent,
    renderer_type=@astra.RendererType::ReactRenderer,
  )
  inspect(
    page.renderer_type == @astra.RendererType::ReactRenderer,
    content="true",
  )
}

///|
test "RendererType selection - moon.pkg.json uses RendererType::LunaRenderer" {
  let page = @astra.PageMeta::new(
    "components/button/moon.pkg.json",
    "/button/",
    content_type=@astra.ContentType::Component,
    renderer_type=@astra.RendererType::LunaRenderer,
  )
  inspect(
    page.renderer_type == @astra.RendererType::LunaRenderer,
    content="true",
  )
}

///|
test "RendererType selection - .mdx files use RendererType::MdxRenderer" {
  let page = @astra.PageMeta::new(
    "docs/interactive.mdx",
    "/interactive/",
    content_type=@astra.ContentType::Mdx,
    renderer_type=@astra.RendererType::MdxRenderer,
  )
  inspect(
    page.renderer_type == @astra.RendererType::MdxRenderer,
    content="true",
  )
}

// =============================================================================
// DeployTarget Tests
// =============================================================================

///|
test "DeployTarget::default - returns Static" {
  let default = @astra.DeployTarget::default()
  inspect(default == @astra.DeployTarget::Static, content="true")
}

///|
test "DeployTarget - all variants" {
  let targets = [
    @astra.DeployTarget::Static,
    @astra.DeployTarget::Cloudflare,
    @astra.DeployTarget::GithubPages,
    @astra.DeployTarget::Vercel,
    @astra.DeployTarget::Netlify,
    @astra.DeployTarget::Deno,
    @astra.DeployTarget::Node,
  ]
  inspect(targets.length(), content="7")
}

///|
test "DeployTarget - Debug representation" {
  debug_inspect(@astra.DeployTarget::Static, content="Static")
  debug_inspect(@astra.DeployTarget::Cloudflare, content="Cloudflare")
  debug_inspect(@astra.DeployTarget::Node, content="Node")
}

// =============================================================================
// SsgConfig Tests
// =============================================================================

///|
test "SsgConfig::default - has expected values" {
  let config = @astra.SsgConfig::default()
  inspect(config.docs_dir, content="docs")
  inspect(config.output_dir, content="dist")
  inspect(config.title, content="Documentation")
  inspect(config.base_url, content="/")
  inspect(config.trailing_slash, content="true")
  inspect(config.sanitize_html, content="false")
}

///|
test "SsgConfig::default - deploy_target is Static" {
  let config = @astra.SsgConfig::default()
  inspect(config.deploy_target == @astra.DeployTarget::Static, content="true")
}

///|
test "SsgConfig::default - sidebar is Auto" {
  let config = @astra.SsgConfig::default()
  inspect(config.sidebar is @astra.SidebarConfig::Auto, content="true")
}

///|
test "SsgConfig::default - i18n is English" {
  let config = @astra.SsgConfig::default()
  inspect(config.i18n.default_locale, content="en")
  inspect(config.i18n.locales.length(), content="1")
}

///|
test "SsgConfig::default - meta_files has sitemap enabled" {
  let config = @astra.SsgConfig::default()
  inspect(config.meta_files.sitemap, content="true")
  inspect(config.meta_files.feed, content="false")
  inspect(config.meta_files.llms_txt, content="false")
}

// =============================================================================
// I18nConfig Tests
// =============================================================================

///|
test "I18nConfig::default - has English locale" {
  let i18n = @astra.I18nConfig::default()
  inspect(i18n.default_locale, content="en")
  inspect(i18n.locales.length(), content="1")
  inspect(i18n.locales[0].code, content="en")
  inspect(i18n.locales[0].label, content="English")
  inspect(i18n.locales[0].path, content="")
}

// =============================================================================
// NavigationConfig Tests
// =============================================================================

///|
test "NavigationConfig::default - has expected values" {
  let nav = @astra.NavigationConfig::default()
  inspect(nav.spa, content="false")
  inspect(nav.view_transitions, content="true")
  inspect(nav.keyboard, content="true")
}

// =============================================================================
// ThemeConfig Tests
// =============================================================================

///|
test "ThemeConfig::default - colors are None by default" {
  let theme = @astra.ThemeConfig::default()
  // Default theme has no explicit colors (uses CSS theme defaults)
  debug_inspect(theme.primary_color, content="None")
  debug_inspect(theme.secondary_color, content="None")
  debug_inspect(theme.accent_color, content="None")
}

// =============================================================================
// HeaderConfig Tests
// =============================================================================

///|
test "HeaderConfig::default - has expected elements" {
  let header = @astra.HeaderConfig::default()
  inspect(header.left.length(), content="1")
  inspect(header.left[0] == @astra.HeaderElement::Logo, content="true")
  inspect(header.center.length(), content="0")
  inspect(header.right.length(), content="4")
  inspect(header.sticky, content="false")
}

// =============================================================================
// BuildContext Tests
// =============================================================================

///|
test "BuildContext::new - creates with config and cwd" {
  let config = @astra.SsgConfig::default()
  let ctx = @astra.BuildContext::new(config, "/project")
  inspect(ctx.cwd, content="/project")
  inspect(ctx.pages.length(), content="0")
  inspect(ctx.sidebar.length(), content="0")
  inspect(ctx.doc_tree is None, content="true")
  inspect(ctx.is_dev, content="false")
}

// =============================================================================
// Integration Type Checking Tests
// =============================================================================

///|
test "RendererType - can represent React integration" {
  let react_page = @astra.PageMeta::new(
    "app/components/Counter.tsx",
    "/components/counter/",
    content_type=@astra.ContentType::TsxComponent,
    renderer_type=@astra.RendererType::ReactRenderer,
  )
  // React components can be integrated as islands
  inspect(
    react_page.renderer_type == @astra.RendererType::ReactRenderer,
    content="true",
  )
  inspect(
    react_page.content_type == @astra.ContentType::TsxComponent,
    content="true",
  )
}

///|
test "RendererType - can represent Luna/MoonBit integration" {
  let luna_page = @astra.PageMeta::new(
    "app/islands/counter/moon.pkg.json",
    "/islands/counter/",
    content_type=@astra.ContentType::Component,
    renderer_type=@astra.RendererType::LunaRenderer,
  )
  // Luna components use MoonBit SSR
  inspect(
    luna_page.renderer_type == @astra.RendererType::LunaRenderer,
    content="true",
  )
  inspect(
    luna_page.content_type == @astra.ContentType::Component,
    content="true",
  )
}

///|
test "RendererType - RendererType::ClientOnlyRenderer for no SSR" {
  let client_page = @astra.PageMeta::new(
    "app/widgets/chart.tsx",
    "/widgets/chart/",
    content_type=@astra.ContentType::TsxComponent,
    renderer_type=@astra.RendererType::ClientOnlyRenderer,
  )
  // Some components only render on client (e.g., canvas-based charts)
  inspect(
    client_page.renderer_type == @astra.RendererType::ClientOnlyRenderer,
    content="true",
  )
}

///|
test "RendererType - RendererType::MdxRenderer for interactive docs" {
  let mdx_page = @astra.PageMeta::new(
    "docs/interactive-demo.mdx",
    "/docs/interactive-demo/",
    content_type=@astra.ContentType::Mdx,
    renderer_type=@astra.RendererType::MdxRenderer,
  )
  // MDX combines markdown with JSX components
  inspect(
    mdx_page.renderer_type == @astra.RendererType::MdxRenderer,
    content="true",
  )
  inspect(mdx_page.content_type == @astra.ContentType::Mdx, content="true")
}
