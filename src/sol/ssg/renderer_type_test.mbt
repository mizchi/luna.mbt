// Tests for RendererType - Unified SSR Renderer Support
//
// Tests for renderer type selection and handling.
// Supports multiple rendering strategies: Markdown, HTML, Luna, React, MDX, ClientOnly.

// =============================================================================
// RendererType Basic Tests
// =============================================================================

///|
test "RendererType::default - returns RendererType::MarkdownRenderer" {
  let default = RendererType::default()
  inspect(default == RendererType::MarkdownRenderer, content="true")
}

///|
test "RendererType - equality comparison" {
  inspect(
    RendererType::MarkdownRenderer == RendererType::MarkdownRenderer,
    content="true",
  )
  inspect(
    RendererType::HtmlRenderer == RendererType::HtmlRenderer,
    content="true",
  )
  inspect(
    RendererType::LunaRenderer == RendererType::LunaRenderer,
    content="true",
  )
  inspect(
    RendererType::ReactRenderer == RendererType::ReactRenderer,
    content="true",
  )
  inspect(
    RendererType::PreactRenderer == RendererType::PreactRenderer,
    content="true",
  )
  inspect(
    RendererType::ClientOnlyRenderer == RendererType::ClientOnlyRenderer,
    content="true",
  )
  inspect(
    RendererType::MdxRenderer == RendererType::MdxRenderer,
    content="true",
  )
}

///|
test "RendererType - inequality comparison" {
  inspect(
    RendererType::MarkdownRenderer == RendererType::HtmlRenderer,
    content="false",
  )
  inspect(
    RendererType::LunaRenderer == RendererType::ReactRenderer,
    content="false",
  )
  inspect(
    RendererType::MdxRenderer == RendererType::ClientOnlyRenderer,
    content="false",
  )
}

// =============================================================================
// RendererType Show Implementation Tests
// =============================================================================

///|
test "RendererType - Show for RendererType::MarkdownRenderer" {
  let r = RendererType::MarkdownRenderer
  let s = r.to_string()
  inspect(s.contains("Markdown"), content="true")
}

///|
test "RendererType - Show for RendererType::HtmlRenderer" {
  let r = RendererType::HtmlRenderer
  let s = r.to_string()
  inspect(s.contains("Html"), content="true")
}

///|
test "RendererType - Show for RendererType::LunaRenderer" {
  let r = RendererType::LunaRenderer
  let s = r.to_string()
  inspect(s.contains("Luna"), content="true")
}

///|
test "RendererType - Show for RendererType::ReactRenderer" {
  let r = RendererType::ReactRenderer
  let s = r.to_string()
  inspect(s.contains("React"), content="true")
}

///|
test "RendererType - Show for RendererType::ClientOnlyRenderer" {
  let r = RendererType::ClientOnlyRenderer
  let s = r.to_string()
  inspect(s.contains("ClientOnly"), content="true")
}

///|
test "RendererType - Show for RendererType::MdxRenderer" {
  let r = RendererType::MdxRenderer
  let s = r.to_string()
  inspect(s.contains("Mdx"), content="true")
}

// =============================================================================
// RendererType Pattern Matching Tests
// =============================================================================

///|
test "RendererType - pattern matching all variants" {
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

  inspect(check_variant(RendererType::MarkdownRenderer), content="markdown")
  inspect(check_variant(RendererType::HtmlRenderer), content="html")
  inspect(check_variant(RendererType::LunaRenderer), content="luna")
  inspect(check_variant(RendererType::ReactRenderer), content="react")
  inspect(check_variant(RendererType::PreactRenderer), content="preact")
  inspect(check_variant(RendererType::ClientOnlyRenderer), content="client")
  inspect(check_variant(RendererType::MdxRenderer), content="mdx")
}

// =============================================================================
// ContentType Tests
// =============================================================================

///|
test "ContentType - equality comparison" {
  inspect(ContentType::Markdown == ContentType::Markdown, content="true")
  inspect(ContentType::Html == ContentType::Html, content="true")
  inspect(ContentType::Component == ContentType::Component, content="true")
  inspect(
    ContentType::TsxComponent == ContentType::TsxComponent,
    content="true",
  )
  inspect(ContentType::Mdx == ContentType::Mdx, content="true")
}

///|
test "ContentType - inequality comparison" {
  inspect(ContentType::Markdown == ContentType::Html, content="false")
  inspect(ContentType::Component == ContentType::TsxComponent, content="false")
}

///|
test "ContentType - Show implementation" {
  inspect(
    ContentType::Markdown.to_string().contains("Markdown"),
    content="true",
  )
  inspect(ContentType::Html.to_string().contains("Html"), content="true")
  inspect(
    ContentType::Component.to_string().contains("Component"),
    content="true",
  )
  inspect(ContentType::Mdx.to_string().contains("Mdx"), content="true")
}

// =============================================================================
// PageMeta Tests
// =============================================================================

///|
test "PageMeta::new - basic creation" {
  let page = PageMeta::new("docs/intro.md", "/intro/")
  inspect(page.source_path, content="docs/intro.md")
  inspect(page.url_path, content="/intro/")
  inspect(page.content_type == ContentType::Markdown, content="true")
  inspect(page.renderer_type == RendererType::MarkdownRenderer, content="true")
  inspect(page.locale, content="en")
}

///|
test "PageMeta::new - with custom content_type" {
  let page = PageMeta::new(
    "docs/page.html",
    "/page/",
    content_type=ContentType::Html,
  )
  inspect(page.content_type == ContentType::Html, content="true")
}

///|
test "PageMeta::new - with custom renderer_type" {
  let page = PageMeta::new(
    "docs/component/index.tsx",
    "/component/",
    renderer_type=RendererType::ReactRenderer,
  )
  inspect(page.renderer_type == RendererType::ReactRenderer, content="true")
}

///|
test "PageMeta::new - with custom locale" {
  let page = PageMeta::new("ja/docs/intro.md", "/ja/intro/", locale="ja")
  inspect(page.locale, content="ja")
}

///|
test "PageMeta::new - canonical_path defaults to url_path" {
  let page = PageMeta::new("docs/intro.md", "/intro/")
  inspect(page.canonical_path, content="/intro/")
}

///|
test "PageMeta::new - with custom canonical_path" {
  let page = PageMeta::new(
    "ja/docs/intro.md",
    "/ja/intro/",
    canonical_path="/intro/",
  )
  inspect(page.canonical_path, content="/intro/")
}

///|
test "PageMeta::new - sort_key defaults to source_path" {
  let page = PageMeta::new("01_guide/02_intro.md", "/guide/intro/")
  inspect(page.sort_key, content="01_guide/02_intro.md")
}

///|
test "PageMeta::new - with custom sort_key" {
  let page = PageMeta::new(
    "guide/intro.md",
    "/guide/intro/",
    sort_key="01_guide/01_intro",
  )
  inspect(page.sort_key, content="01_guide/01_intro")
}

///|
test "PageMeta::with_frontmatter - updates frontmatter" {
  let page = PageMeta::new("docs/intro.md", "/intro/")
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
  let page = PageMeta::new(
    "docs/intro.md",
    "/intro/",
    content_type=ContentType::Markdown,
    renderer_type=RendererType::MarkdownRenderer,
  )
  inspect(page.renderer_type == RendererType::MarkdownRenderer, content="true")
}

///|
test "RendererType selection - .html files use RendererType::HtmlRenderer" {
  let page = PageMeta::new(
    "docs/page.html",
    "/page/",
    content_type=ContentType::Html,
    renderer_type=RendererType::HtmlRenderer,
  )
  inspect(page.renderer_type == RendererType::HtmlRenderer, content="true")
}

///|
test "RendererType selection - .tsx files use RendererType::ReactRenderer" {
  let page = PageMeta::new(
    "components/counter.tsx",
    "/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  inspect(page.renderer_type == RendererType::ReactRenderer, content="true")
}

///|
test "RendererType selection - moon.pkg.json uses RendererType::LunaRenderer" {
  let page = PageMeta::new(
    "components/button/moon.pkg.json",
    "/button/",
    content_type=ContentType::Component,
    renderer_type=RendererType::LunaRenderer,
  )
  inspect(page.renderer_type == RendererType::LunaRenderer, content="true")
}

///|
test "RendererType selection - .mdx files use RendererType::MdxRenderer" {
  let page = PageMeta::new(
    "docs/interactive.mdx",
    "/interactive/",
    content_type=ContentType::Mdx,
    renderer_type=RendererType::MdxRenderer,
  )
  inspect(page.renderer_type == RendererType::MdxRenderer, content="true")
}

// =============================================================================
// DeployTarget Tests
// =============================================================================

///|
test "DeployTarget::default - returns Static" {
  let default = DeployTarget::default()
  inspect(default == DeployTarget::Static, content="true")
}

///|
test "DeployTarget - all variants" {
  let targets = [
    DeployTarget::Static,
    DeployTarget::Cloudflare,
    DeployTarget::GithubPages,
    DeployTarget::Vercel,
    DeployTarget::Netlify,
    DeployTarget::Deno,
    DeployTarget::Node,
  ]
  inspect(targets.length(), content="7")
}

///|
test "DeployTarget - Show implementation" {
  inspect(DeployTarget::Static.to_string().contains("Static"), content="true")
  inspect(
    DeployTarget::Cloudflare.to_string().contains("Cloudflare"),
    content="true",
  )
  inspect(DeployTarget::Node.to_string().contains("Node"), content="true")
}

// =============================================================================
// SsgConfig Tests
// =============================================================================

///|
test "SsgConfig::default - has expected values" {
  let config = SsgConfig::default()
  inspect(config.docs_dir, content="docs")
  inspect(config.output_dir, content="dist")
  inspect(config.title, content="Documentation")
  inspect(config.base_url, content="/")
  inspect(config.trailing_slash, content="true")
  inspect(config.sanitize_html, content="false")
}

///|
test "SsgConfig::default - deploy_target is Static" {
  let config = SsgConfig::default()
  inspect(config.deploy_target == DeployTarget::Static, content="true")
}

///|
test "SsgConfig::default - sidebar is Auto" {
  let config = SsgConfig::default()
  inspect(config.sidebar is SidebarConfig::Auto, content="true")
}

///|
test "SsgConfig::default - i18n is English" {
  let config = SsgConfig::default()
  inspect(config.i18n.default_locale, content="en")
  inspect(config.i18n.locales.length(), content="1")
}

///|
test "SsgConfig::default - meta_files has sitemap enabled" {
  let config = SsgConfig::default()
  inspect(config.meta_files.sitemap, content="true")
  inspect(config.meta_files.feed, content="false")
  inspect(config.meta_files.llms_txt, content="false")
}

// =============================================================================
// I18nConfig Tests
// =============================================================================

///|
test "I18nConfig::default - has English locale" {
  let i18n = I18nConfig::default()
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
  let nav = NavigationConfig::default()
  inspect(nav.spa, content="false")
  inspect(nav.view_transitions, content="true")
  inspect(nav.keyboard, content="true")
}

// =============================================================================
// ThemeConfig Tests
// =============================================================================

///|
test "ThemeConfig::default - colors are None by default" {
  let theme = ThemeConfig::default()
  // Default theme has no explicit colors (uses CSS theme defaults)
  inspect(theme.primary_color, content="None")
  inspect(theme.secondary_color, content="None")
  inspect(theme.accent_color, content="None")
}

// =============================================================================
// HeaderConfig Tests
// =============================================================================

///|
test "HeaderConfig::default - has expected elements" {
  let header = HeaderConfig::default()
  inspect(header.left.length(), content="1")
  inspect(header.left[0] == HeaderElement::Logo, content="true")
  inspect(header.center.length(), content="0")
  inspect(header.right.length(), content="4")
  inspect(header.sticky, content="false")
}

// =============================================================================
// BuildContext Tests
// =============================================================================

///|
test "BuildContext::new - creates with config and cwd" {
  let config = SsgConfig::default()
  let ctx = BuildContext::new(config, "/project")
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
  let react_page = PageMeta::new(
    "app/components/Counter.tsx",
    "/components/counter/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ReactRenderer,
  )
  // React components can be integrated as islands
  inspect(
    react_page.renderer_type == RendererType::ReactRenderer,
    content="true",
  )
  inspect(react_page.content_type == ContentType::TsxComponent, content="true")
}

///|
test "RendererType - can represent Luna/MoonBit integration" {
  let luna_page = PageMeta::new(
    "app/islands/counter/moon.pkg.json",
    "/islands/counter/",
    content_type=ContentType::Component,
    renderer_type=RendererType::LunaRenderer,
  )
  // Luna components use MoonBit SSR
  inspect(luna_page.renderer_type == RendererType::LunaRenderer, content="true")
  inspect(luna_page.content_type == ContentType::Component, content="true")
}

///|
test "RendererType - RendererType::ClientOnlyRenderer for no SSR" {
  let client_page = PageMeta::new(
    "app/widgets/chart.tsx",
    "/widgets/chart/",
    content_type=ContentType::TsxComponent,
    renderer_type=RendererType::ClientOnlyRenderer,
  )
  // Some components only render on client (e.g., canvas-based charts)
  inspect(
    client_page.renderer_type == RendererType::ClientOnlyRenderer,
    content="true",
  )
}

///|
test "RendererType - RendererType::MdxRenderer for interactive docs" {
  let mdx_page = PageMeta::new(
    "docs/interactive-demo.mdx",
    "/docs/interactive-demo/",
    content_type=ContentType::Mdx,
    renderer_type=RendererType::MdxRenderer,
  )
  // MDX combines markdown with JSX components
  inspect(mdx_page.renderer_type == RendererType::MdxRenderer, content="true")
  inspect(mdx_page.content_type == ContentType::Mdx, content="true")
}
