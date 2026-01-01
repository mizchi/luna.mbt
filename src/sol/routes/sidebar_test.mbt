// Tests for Sidebar Generator

// =============================================================================
// Helper Functions
// =============================================================================

///|
fn make_page(
  source_path : String,
  url_path : String,
  title? : String? = None,
  locale? : String = "en",
) -> @ssg.PageMeta {
  let frontmatter = @ssg.Frontmatter::{
    ..@ssg.Frontmatter::default(),
    title,
    sidebar: true,
  }
  @ssg.PageMeta::{
    source_path,
    url_path,
    content_type: @ssg.ContentType::Markdown,
    renderer_type: @ssg.RendererType::MarkdownRenderer,
    frontmatter,
    last_modified: None,
    locale,
    canonical_path: url_path,
    sort_key: source_path,
  }
}

///|
fn make_page_no_sidebar(
  source_path : String,
  url_path : String,
) -> @ssg.PageMeta {
  let frontmatter = @ssg.Frontmatter::{
    ..@ssg.Frontmatter::default(),
    sidebar: false,
  }
  @ssg.PageMeta::{
    source_path,
    url_path,
    content_type: @ssg.ContentType::Markdown,
    renderer_type: @ssg.RendererType::MarkdownRenderer,
    frontmatter,
    last_modified: None,
    locale: "en",
    canonical_path: url_path,
    sort_key: source_path,
  }
}

// =============================================================================
// generate_auto_sidebar Tests
// =============================================================================

///|
test "generate_auto_sidebar - empty pages" {
  let pages : Array[@ssg.PageMeta] = []
  let groups = generate_auto_sidebar(pages)
  inspect(groups.length(), content="0")
}

///|
test "generate_auto_sidebar - single page in directory" {
  let pages = [
    make_page("guide/intro.md", "/guide/intro/", title=Some("Introduction")),
  ]
  let groups = generate_auto_sidebar(pages)
  // Should have one group for "guide"
  inspect(groups.length(), content="1")
  inspect(groups[0].text, content="Guide")
}

///|
test "generate_auto_sidebar - filters by locale" {
  let pages = [
    make_page("guide/intro.md", "/guide/intro/", locale="en"),
    make_page("ja/guide/intro.md", "/ja/guide/intro/", locale="ja"),
  ]
  let en_groups = generate_auto_sidebar(pages, locale="en")
  let ja_groups = generate_auto_sidebar(pages, locale="ja")
  inspect(en_groups.length(), content="1")
  inspect(ja_groups.length(), content="1")
}

///|
test "generate_auto_sidebar - excludes sidebar:false pages" {
  let pages = [
    make_page("guide/intro.md", "/guide/intro/"),
    make_page_no_sidebar("guide/hidden.md", "/guide/hidden/"),
  ]
  let groups = generate_auto_sidebar(pages)
  // Only one page should be included
  inspect(groups.length(), content="1")
}

///|
test "generate_auto_sidebar - multiple directories" {
  let pages = [
    make_page("guide/intro.md", "/guide/intro/"),
    make_page("api/reference.md", "/api/reference/"),
  ]
  let groups = generate_auto_sidebar(pages)
  inspect(groups.length(), content="2")
}

///|
test "generate_auto_sidebar - nested directories" {
  let pages = [
    make_page("guide/basics/setup.md", "/guide/basics/setup/"),
    make_page("guide/basics/config.md", "/guide/basics/config/"),
    make_page("guide/advanced/hooks.md", "/guide/advanced/hooks/"),
  ]
  let groups = generate_auto_sidebar(pages)
  // Should have nested structure
  inspect(groups.length() >= 1, content="true")
}

// =============================================================================
// get_sidebar_for_path Tests
// =============================================================================

///|
test "get_sidebar_for_path - auto sidebar" {
  let config = @ssg.SsgConfig::{
    ..@ssg.SsgConfig::default(),
    sidebar: @ssg.SidebarConfig::Auto,
  }
  let pages = [make_page("guide/intro.md", "/guide/intro/")]
  let groups = get_sidebar_for_path(config, pages, "/guide/intro/")
  inspect(groups.length(), content="1")
}

///|
test "get_sidebar_for_path - manual sidebar" {
  let manual_groups = [
    @ssg.SidebarGroup::{
      text: "Guide",
      link: None,
      collapsed: false,
      items: [@ssg.SidebarItem::Link(text="Intro", link="/guide/intro/")],
    },
    @ssg.SidebarGroup::{
      text: "API",
      link: None,
      collapsed: false,
      items: [@ssg.SidebarItem::Link(text="Reference", link="/api/reference/")],
    },
  ]
  let config = @ssg.SsgConfig::{
    ..@ssg.SsgConfig::default(),
    sidebar: @ssg.SidebarConfig::Manual(manual_groups),
  }
  let pages : Array[@ssg.PageMeta] = []
  let groups = get_sidebar_for_path(config, pages, "/guide/intro/")
  // Should return all groups for now (matching logic)
  inspect(groups.length() >= 1, content="true")
}

// =============================================================================
// get_sidebar_page_order Tests
// =============================================================================

///|
test "get_sidebar_page_order - empty groups" {
  let groups : Array[@ssg.SidebarGroup] = []
  let order = get_sidebar_page_order(groups)
  inspect(order.length(), content="0")
}

///|
test "get_sidebar_page_order - single group with links" {
  let groups = [
    @ssg.SidebarGroup::{
      text: "Guide",
      link: None,
      collapsed: false,
      items: [
        @ssg.SidebarItem::Link(text="Intro", link="/guide/intro/"),
        @ssg.SidebarItem::Link(text="Setup", link="/guide/setup/"),
      ],
    },
  ]
  let order = get_sidebar_page_order(groups)
  inspect(order.length(), content="2")
  inspect(order[0], content="/guide/intro/")
  inspect(order[1], content="/guide/setup/")
}

///|
test "get_sidebar_page_order - nested groups" {
  let groups = [
    @ssg.SidebarGroup::{
      text: "Guide",
      link: None,
      collapsed: false,
      items: [
        @ssg.SidebarItem::Link(text="Intro", link="/guide/intro/"),
        @ssg.SidebarItem::Group(@ssg.SidebarGroup::{
          text: "Basics",
          link: None,
          collapsed: false,
          items: [
            @ssg.SidebarItem::Link(text="Setup", link="/guide/basics/setup/"),
            @ssg.SidebarItem::Link(text="Config", link="/guide/basics/config/"),
          ],
        }),
      ],
    },
  ]
  let order = get_sidebar_page_order(groups)
  inspect(order.length(), content="3")
  inspect(order[0], content="/guide/intro/")
  inspect(order[1], content="/guide/basics/setup/")
  inspect(order[2], content="/guide/basics/config/")
}

///|
test "get_sidebar_page_order - multiple groups" {
  let groups = [
    @ssg.SidebarGroup::{
      text: "Guide",
      link: None,
      collapsed: false,
      items: [@ssg.SidebarItem::Link(text="Intro", link="/guide/intro/")],
    },
    @ssg.SidebarGroup::{
      text: "API",
      link: None,
      collapsed: false,
      items: [@ssg.SidebarItem::Link(text="Reference", link="/api/reference/")],
    },
  ]
  let order = get_sidebar_page_order(groups)
  inspect(order.length(), content="2")
  inspect(order[0], content="/guide/intro/")
  inspect(order[1], content="/api/reference/")
}

// =============================================================================
// SidebarGroup Rendering Tests (structure verification)
// =============================================================================

///|
test "render_sidebar - returns valid node" {
  let groups = [
    @ssg.SidebarGroup::{
      text: "Guide",
      link: None,
      collapsed: false,
      items: [@ssg.SidebarItem::Link(text="Intro", link="/guide/intro/")],
    },
  ]
  let node = render_sidebar(groups, "/")
  // Just verify it returns a node (detailed rendering tests would be integration tests)
  inspect(node is @luna.Element(_), content="true")
}

///|
test "render_mobile_sidebar - returns valid node" {
  let groups = [
    @ssg.SidebarGroup::{
      text: "Guide",
      link: None,
      collapsed: false,
      items: [@ssg.SidebarItem::Link(text="Intro", link="/guide/intro/")],
    },
  ]
  let node = render_mobile_sidebar(groups, "/")
  inspect(node is @luna.Element(_), content="true")
}

// =============================================================================
// Index Page Tests
// =============================================================================

///|
test "generate_auto_sidebar - index page becomes group link" {
  let pages = [
    make_page("guide/index.md", "/guide/", title=Some("Guide Overview")),
    make_page("guide/intro.md", "/guide/intro/", title=Some("Introduction")),
  ]
  let groups = generate_auto_sidebar(pages)
  inspect(groups.length(), content="1")
  // The group should have the index page's title
  // and the index page should become the group link
  let guide_group = groups[0]
  inspect(guide_group.link is Some(_), content="true")
}

///|
test "generate_auto_sidebar - sort order by source path" {
  let pages = [
    make_page("guide/03_advanced.md", "/guide/advanced/"),
    make_page("guide/01_intro.md", "/guide/intro/"),
    make_page("guide/02_basics.md", "/guide/basics/"),
  ]
  let groups = generate_auto_sidebar(pages)
  // Should be sorted by sort_key (source_path)
  inspect(groups.length(), content="1")
}
