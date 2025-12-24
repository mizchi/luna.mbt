// SSG Configuration Parser
//

///|
/// Parse SSG config directly (astra.json format)
pub fn parse_ssg_config(json_str : String) -> SsgConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(ssg_obj) else { return None }
    parse_ssg_object(ssg_obj)
  } catch {
    _ => None
  }
}

///|
/// Parse SSG config from sol.config.json content
pub fn parse_ssg_from_sol_config(json_str : String) -> SsgConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }

    // Get ssg section
    guard obj.get("ssg") is Some(Object(ssg_obj)) else {
      // No ssg section, return default
      return Some(SsgConfig::default())
    }
    parse_ssg_object(ssg_obj)
  } catch {
    _ => None
  }
}

///|
/// Parse SSG object (shared by both config formats)
fn parse_ssg_object(ssg_obj : Map[String, Json]) -> SsgConfig? {
  // Parse ssg fields using json_utils helpers
  let docs_dir = @json_utils.extract_string(ssg_obj, "docs", "docs")
  let output_dir = @json_utils.extract_string(ssg_obj, "output", "dist")
  let title = @json_utils.extract_string(ssg_obj, "title", "Documentation")
  let base_url = @json_utils.extract_string(ssg_obj, "base", "/")

  // Parse nav items
  let nav = parse_nav_items(ssg_obj)

  // Parse sidebar config
  let sidebar = parse_sidebar_config(ssg_obj)

  // Parse theme
  let theme = parse_theme_config(ssg_obj)

  // Parse i18n config
  let i18n = parse_i18n_config(ssg_obj)

  // Parse exclude patterns
  let exclude = @json_utils.extract_string_array(ssg_obj, "exclude")

  // Parse islands config
  let islands_config = parse_islands_config(ssg_obj)

  // Parse navigation config
  let navigation = parse_navigation_config(ssg_obj)

  // Parse trailing slash config (default: true for SSG compatibility)
  let trailing_slash = @json_utils.extract_bool(ssg_obj, "trailingSlash", true)

  // Parse OGP config
  let ogp = parse_ogp_config(ssg_obj)
  let ogp_text = @json_utils.extract_string_opt(ssg_obj, "ogpText")

  // Parse custom snippets
  let head_snippets = @json_utils.extract_string_array(ssg_obj, "headSnippets")
  let body_snippets = @json_utils.extract_string_array(ssg_obj, "bodySnippets")

  // Parse sanitize HTML option (default: false)
  let sanitize_html = @json_utils.extract_bool(ssg_obj, "sanitizeHtml", false)

  // Parse deploy target (default: static)
  let deploy_target = parse_deploy_target(ssg_obj)
  Some(SsgConfig::{
    docs_dir,
    output_dir,
    title,
    base_url,
    nav,
    sidebar,
    islands: islands_config,
    theme,
    navigation,
    i18n,
    exclude,
    trailing_slash,
    ogp,
    ogp_text,
    head_snippets,
    body_snippets,
    sanitize_html,
    deploy_target,
  })
}

///|
/// Parse deploy target from config
fn parse_deploy_target(obj : Map[String, Json]) -> DeployTarget {
  match obj.get("deploy") {
    Some(String(s)) =>
      if s == "cloudflare" {
        Cloudflare
      } else if s == "node" {
        Node
      } else {
        Static
      }
    _ => Static
  }
}

///|
/// Parse navigation items from config
fn parse_nav_items(obj : Map[String, Json]) -> Array[NavItem] {
  match obj.get("nav") {
    Some(Array(arr)) => {
      let result : Array[NavItem] = []
      for item in arr {
        if parse_nav_item(item) is Some(nav_item) {
          result.push(nav_item)
        }
      }
      result
    }
    _ => []
  }
}

///|
/// Parse single nav item
fn parse_nav_item(json : Json) -> NavItem? {
  guard json is Object(obj) else { return None }
  guard @json_utils.extract_string_opt(obj, "text") is Some(text) else {
    return None
  }
  let link = @json_utils.extract_string(obj, "link", "")
  let items = match obj.get("items") {
    Some(Array(arr)) => {
      let result : Array[NavItem] = []
      for item in arr {
        if parse_nav_item(item) is Some(nav_item) {
          result.push(nav_item)
        }
      }
      result
    }
    _ => []
  }
  Some(NavItem::{ text, link, items })
}

///|
/// Parse sidebar configuration
fn parse_sidebar_config(obj : Map[String, Json]) -> SidebarConfig {
  match obj.get("sidebar") {
    Some(String(s)) =>
      if s == "auto" {
        SidebarConfig::Auto
      } else {
        SidebarConfig::Auto
      }
    Some(Object(sidebar_obj)) => {
      // Manual sidebar with path-keyed groups
      let groups : Array[SidebarGroup] = []
      for key in sidebar_obj.keys() {
        if sidebar_obj.get(key) is Some(Array(arr)) {
          if parse_sidebar_group_from_array(key, arr) is Some(group) {
            groups.push(group)
          }
        }
      }
      SidebarConfig::Manual(groups)
    }
    Some(Array(arr)) => {
      // Direct array of sidebar groups
      let groups : Array[SidebarGroup] = []
      for item in arr {
        if parse_sidebar_group(item) is Some(group) {
          groups.push(group)
        }
      }
      SidebarConfig::Manual(groups)
    }
    _ => SidebarConfig::Auto
  }
}

///|
/// Parse sidebar group from path-keyed array
fn parse_sidebar_group_from_array(
  path : String,
  arr : Array[Json],
) -> SidebarGroup? {
  let items : Array[SidebarItem] = []
  for item in arr {
    if parse_sidebar_item(item) is Some(sidebar_item) {
      items.push(sidebar_item)
    }
  }
  Some(SidebarGroup::{ text: path, link: None, collapsed: false, items })
}

///|
/// Parse sidebar group
fn parse_sidebar_group(json : Json) -> SidebarGroup? {
  guard json is Object(obj) else { return None }
  let text = @json_utils.extract_string(obj, "text", "")
  let collapsed = @json_utils.extract_bool(obj, "collapsed", false)
  let items = match obj.get("items") {
    Some(Array(arr)) => {
      let result : Array[SidebarItem] = []
      for item in arr {
        if parse_sidebar_item(item) is Some(sidebar_item) {
          result.push(sidebar_item)
        }
      }
      result
    }
    _ => []
  }
  Some(SidebarGroup::{ text, link: None, collapsed, items })
}

///|
/// Parse sidebar item
fn parse_sidebar_item(json : Json) -> SidebarItem? {
  guard json is Object(obj) else { return None }
  // Check if it's a group (has items) or a link
  if obj.get("items") is Some(Array(_)) {
    // It's a nested group
    if parse_sidebar_group(json) is Some(group) {
      return Some(SidebarItem::Group(group))
    }
    return None
  }
  // It's a link
  guard @json_utils.extract_string_opt(obj, "text") is Some(text) else {
    return None
  }
  guard @json_utils.extract_string_opt(obj, "link") is Some(link) else {
    return None
  }
  Some(SidebarItem::Link(text~, link~))
}

///|
/// Parse theme configuration
fn parse_theme_config(obj : Map[String, Json]) -> ThemeConfig {
  guard @json_utils.extract_object(obj, "theme") is Some(theme_obj) else {
    return ThemeConfig::default()
  }
  let primary_color = Some(
    @json_utils.extract_string(theme_obj, "primaryColor", "#3451b2"),
  )
  let logo = @json_utils.extract_string_opt(theme_obj, "logo")
  let footer = match @json_utils.extract_object(theme_obj, "footer") {
    Some(footer_obj) => {
      let message = @json_utils.extract_string_opt(footer_obj, "message")
      let copyright = @json_utils.extract_string_opt(footer_obj, "copyright")
      let links = match footer_obj.get("links") {
        Some(Array(arr)) => parse_footer_columns(arr)
        _ => []
      }
      Some(FooterConfig::{ message, copyright, links })
    }
    None => None
  }
  let social_links = match theme_obj.get("socialLinks") {
    Some(Array(arr)) => parse_social_links(arr)
    _ => []
  }
  ThemeConfig::{ primary_color, logo, footer, social_links }
}

///|
/// Parse social links array
fn parse_social_links(arr : Array[Json]) -> Array[SocialLink] {
  let result : Array[SocialLink] = []
  for item in arr {
    guard item is Object(obj) else { continue }
    guard @json_utils.extract_string_opt(obj, "icon") is Some(icon) else {
      continue
    }
    guard @json_utils.extract_string_opt(obj, "link") is Some(link) else {
      continue
    }
    result.push(SocialLink::{ icon, link })
  }
  result
}

///|
/// Parse footer columns array
fn parse_footer_columns(arr : Array[Json]) -> Array[FooterColumn] {
  let result : Array[FooterColumn] = []
  for item in arr {
    guard item is Object(obj) else { continue }
    guard @json_utils.extract_string_opt(obj, "title") is Some(title) else {
      continue
    }
    let items = match obj.get("items") {
      Some(Array(links_arr)) => parse_footer_links(links_arr)
      _ => []
    }
    result.push(FooterColumn::{ title, items })
  }
  result
}

///|
/// Parse footer links array
fn parse_footer_links(arr : Array[Json]) -> Array[FooterLink] {
  let result : Array[FooterLink] = []
  for item in arr {
    guard item is Object(obj) else { continue }
    guard @json_utils.extract_string_opt(obj, "label") is Some(label) else {
      continue
    }
    guard @json_utils.extract_string_opt(obj, "href") is Some(href) else {
      continue
    }
    result.push(FooterLink::{ label, href })
  }
  result
}

///|
/// Parse i18n configuration
fn parse_i18n_config(obj : Map[String, Json]) -> @ssg.I18nConfig {
  guard @json_utils.extract_object(obj, "i18n") is Some(i18n_obj) else {
    return @ssg.I18nConfig::default()
  }
  let default_locale = @json_utils.extract_string(
    i18n_obj, "defaultLocale", "en",
  )
  let locales = match i18n_obj.get("locales") {
    Some(Array(arr)) => parse_locale_configs(arr)
    _ => [@ssg.LocaleConfig::{ code: "en", label: "English", path: "" }]
  }
  @ssg.I18nConfig::{ default_locale, locales }
}

///|
/// Parse locale configurations
fn parse_locale_configs(arr : Array[Json]) -> Array[@ssg.LocaleConfig] {
  let result : Array[@ssg.LocaleConfig] = []
  for item in arr {
    if parse_locale_config(item) is Some(locale) {
      result.push(locale)
    }
  }
  result
}

///|
/// Parse single locale configuration
fn parse_locale_config(json : Json) -> @ssg.LocaleConfig? {
  guard json is Object(obj) else { return None }
  guard @json_utils.extract_string_opt(obj, "code") is Some(code) else {
    return None
  }
  let label = @json_utils.extract_string(obj, "label", code)
  let path = match @json_utils.extract_string_opt(obj, "path") {
    Some(p) => p
    None => if code == "en" { "" } else { code }
  }
  Some(@ssg.LocaleConfig::{ code, label, path })
}

///|
/// Parse navigation configuration
fn parse_navigation_config(obj : Map[String, Json]) -> @ssg.NavigationConfig {
  guard @json_utils.extract_object(obj, "navigation") is Some(nav_obj) else {
    return @ssg.NavigationConfig::default()
  }
  let spa = @json_utils.extract_bool(nav_obj, "spa", false)
  let view_transitions = @json_utils.extract_bool(
    nav_obj, "viewTransitions", true,
  )
  let keyboard = @json_utils.extract_bool(nav_obj, "keyboard", true)
  @ssg.NavigationConfig::{ spa, view_transitions, keyboard }
}

///|
/// Parse OGP configuration
fn parse_ogp_config(obj : Map[String, Json]) -> OgpConfig {
  guard @json_utils.extract_object(obj, "ogp") is Some(ogp_obj) else {
    return OgpConfig::default()
  }
  let site_url = @json_utils.extract_string_opt(ogp_obj, "siteUrl")
  let image = @json_utils.extract_string_opt(ogp_obj, "image")
  let twitter_handle = @json_utils.extract_string_opt(ogp_obj, "twitterHandle")
  let twitter_card = @json_utils.extract_string_opt(ogp_obj, "twitterCard")
  OgpConfig::{ site_url, image, twitter_handle, twitter_card }
}

///|
/// Parse Islands configuration
fn parse_islands_config(obj : Map[String, Json]) -> IslandsConfig? {
  guard @json_utils.extract_object(obj, "islands") is Some(islands_obj) else {
    return None
  }
  let dir = @json_utils.extract_string(islands_obj, "dir", "islands")
  let base_path = @json_utils.extract_string(
    islands_obj, "basePath", "/islands/",
  )
  Some(IslandsConfig::{ dir, base_path })
}
