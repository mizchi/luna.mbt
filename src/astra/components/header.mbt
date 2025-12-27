// Astra Components - Header / Navigation Bar
// Element-based compositional header system

///|
/// Build the main navigation header using element configuration
pub fn build_nav(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  // Get header config or use default
  let header_config = ctx.config.theme.header.unwrap_or(
    @astra.HeaderConfig::default(),
  )

  // Build left section
  let left_elements = render_header_elements(
    header_config.left,
    ctx,
    page,
    "nav-left",
  )

  // Build center section
  let center_elements = render_header_elements(
    header_config.center,
    ctx,
    page,
    "nav-center",
  )

  // Build right section
  let right_elements = render_header_elements(
    header_config.right,
    ctx,
    page,
    "nav-right",
  )

  // Build header with sticky class if configured
  let header_class = if header_config.sticky {
    "nav-bar nav-bar-sticky"
  } else {
    "nav-bar"
  }
  h("header", [attr("class", header_class)], [
    h("div", [attr("class", "nav-container")], [
      left_elements,
      center_elements,
      right_elements,
    ]),
  ])
}

///|
/// Render an array of header elements into a container
fn render_header_elements(
  elements : Array[@astra.HeaderElement],
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  class_name : String,
) -> @luna.Node[Unit] {
  if elements.is_empty() {
    return empty()
  }
  let children : Array[@luna.Node[Unit]] = []
  for element in elements {
    children.push(render_header_element(element, ctx, page))
  }
  h("div", [attr("class", class_name)], children)
}

///|
/// Render a single header element
fn render_header_element(
  element : @astra.HeaderElement,
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  match element {
    @astra.Logo => build_logo(ctx)
    @astra.NavLinks => build_nav_links(ctx)
    @astra.Search => build_search()
    @astra.ThemeToggle => build_theme_toggle()
    @astra.SocialLinks => build_social_links(ctx.config.theme.social_links)
    @astra.LangSwitcher => build_language_switcher(ctx, page)
    @astra.Spacer => h("div", [attr("class", "nav-spacer")], [])
    @astra.Custom(tag) => h(tag, [], [])
  }
}

///|
/// Build logo/title element
fn build_logo(ctx : @astra.BuildContext) -> @luna.Node[Unit] {
  let logo = match ctx.config.theme.logo {
    Some(src) =>
      h(
        "img",
        [
          attr("src", src),
          attr("alt", ctx.config.title),
          attr("class", "nav-logo"),
        ],
        [],
      )
    None =>
      h("span", [attr("class", "nav-title")], [@luna.text(ctx.config.title)])
  }
  h(
    "a",
    [attr("href", ctx.config.base_url), attr("class", "nav-home")],
    [logo],
  )
}

///|
/// Build navigation links from config.nav
fn build_nav_links(ctx : @astra.BuildContext) -> @luna.Node[Unit] {
  if ctx.config.nav.is_empty() {
    return empty()
  }
  let nav_items = ctx.config.nav.map(item => build_nav_item(item))
  h("nav", [attr("class", "nav-links")], nav_items)
}

///|
/// Build single nav item
pub fn build_nav_item(item : @astra.NavItem) -> @luna.Node[Unit] {
  if item.items.is_empty() {
    // Simple link
    h("a", [attr("href", item.link), attr("class", "nav-link")], [
      @luna.text(item.text),
    ])
  } else {
    // Dropdown (simplified - actual dropdown needs JS)
    let dropdown_items = item.items.map(fn(sub) {
      h("a", [attr("href", sub.link), attr("class", "nav-dropdown-item")], [
        @luna.text(sub.text),
      ])
    })
    h("div", [attr("class", "nav-dropdown")], [
      h("span", [attr("class", "nav-dropdown-trigger")], [@luna.text(item.text)]),
      h("div", [attr("class", "nav-dropdown-menu")], dropdown_items),
    ])
  }
}

///|
/// Build search box (placeholder for now)
fn build_search() -> @luna.Node[Unit] {
  h("div", [attr("class", "nav-search")], [
    h(
      "input",
      [
        attr("type", "search"),
        attr("placeholder", "Search..."),
        attr("class", "search-input"),
      ],
      [],
    ),
  ])
}

///|
/// Build theme toggle button (dark/light mode)
pub fn build_theme_toggle() -> @luna.Node[Unit] {
  // Sun icon (for dark mode - click to switch to light)
  let sun_icon = h(
    "svg",
    [
      attr("class", "theme-icon theme-icon-light"),
      attr("viewBox", "0 0 24 24"),
      attr("width", "18"),
      attr("height", "18"),
      attr("fill", "none"),
      attr("stroke", "currentColor"),
      attr("stroke-width", "2"),
    ],
    [
      h("circle", [attr("cx", "12"), attr("cy", "12"), attr("r", "5")], []),
      h(
        "path",
        [
          attr(
            "d", "M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42",
          ),
        ],
        [],
      ),
    ],
  )

  // Moon icon (for light mode - click to switch to dark)
  let moon_icon = h(
    "svg",
    [
      attr("class", "theme-icon theme-icon-dark"),
      attr("viewBox", "0 0 24 24"),
      attr("width", "18"),
      attr("height", "18"),
      attr("fill", "none"),
      attr("stroke", "currentColor"),
      attr("stroke-width", "2"),
    ],
    [
      h(
        "path",
        [attr("d", "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z")],
        [],
      ),
    ],
  )
  h(
    "button",
    [
      attr("class", "theme-toggle"),
      attr("type", "button"),
      attr("aria-label", "Toggle dark mode"),
      attr("onclick", "toggleTheme()"),
    ],
    [sun_icon, moon_icon],
  )
}

///|
/// Build social links (GitHub, Twitter, etc.)
pub fn build_social_links(links : Array[@astra.SocialLink]) -> @luna.Node[Unit] {
  if links.is_empty() {
    return empty()
  }
  let link_nodes = links.map(link => {
    let icon = build_social_icon(link.icon)
    h(
      "a",
      [
        attr("href", link.link),
        attr("class", "social-link"),
        attr("target", "_blank"),
        attr("rel", "noopener noreferrer"),
        attr("aria-label", link.icon),
      ],
      [icon],
    )
  })
  h("div", [attr("class", "social-links")], link_nodes)
}

///|
/// Build SVG icon element for social platform
pub fn build_social_icon(icon : String) -> @luna.Node[Unit] {
  let path_d = match icon {
    "github" =>
      "M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"
    "twitter" | "x" =>
      "M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
    _ => ""
  }
  if path_d.is_empty() {
    return empty()
  }
  h(
    "svg",
    [
      attr("viewBox", "0 0 24 24"),
      attr("width", "20"),
      attr("height", "20"),
      attr("fill", "currentColor"),
    ],
    [h("path", [attr("d", path_d)], [])],
  )
}

///|
/// Build language switcher dropdown
pub fn build_language_switcher(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> @luna.Node[Unit] {
  let i18n = ctx.config.i18n

  // Only show if more than one locale
  if i18n.locales.length() <= 1 {
    return empty()
  }

  // Get available translations
  let translations = @routes.get_available_translations(
    ctx.pages,
    page.canonical_path,
    i18n,
  )

  // Find current locale label
  let current_label = i18n.locales
    .iter()
    .find_first(l => l.code == page.locale)
    .map(l => l.label)
    .unwrap_or(page.locale)

  // Build dropdown items
  let items : Array[@luna.Node[Unit]] = []
  for item in translations {
    let (locale, translation) = item
    let target_url = match translation {
      Some(p) => p.url_path
      None =>
        // Fallback to default locale version
        match @routes.find_fallback_page(ctx.pages, page.canonical_path, i18n) {
          Some(fallback) => fallback.url_path
          None => page.canonical_path // Just use canonical if no fallback
        }
    }
    let is_current = locale.code == page.locale
    let class_name = if is_current {
      "lang-item lang-item-active"
    } else {
      "lang-item"
    }
    items.push(
      h("a", [attr("href", target_url), attr("class", class_name)], [
        @luna.text(locale.label),
      ]),
    )
  }

  // Build dropdown with details/summary
  let summary = h("summary", [attr("class", "lang-trigger")], [
    @luna.text("🌐 " + current_label),
  ])
  let menu = h("div", [attr("class", "lang-menu")], items)
  h("details", [attr("class", "lang-switcher")], [summary, menu])
}
