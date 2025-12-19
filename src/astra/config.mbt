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
  // Parse ssg fields
  let docs_dir = match ssg_obj.get("docs") {
    Some(String(s)) => s
    _ => "docs"
  }
  let output_dir = match ssg_obj.get("output") {
    Some(String(s)) => s
    _ => "dist"
  }
  let title = match ssg_obj.get("title") {
    Some(String(s)) => s
    _ => "Documentation"
  }
  let base_url = match ssg_obj.get("base") {
    Some(String(s)) => s
    _ => "/"
  }

  // Parse nav items
  let nav = parse_nav_items(ssg_obj)

  // Parse sidebar config
  let sidebar = parse_sidebar_config(ssg_obj)

  // Parse theme
  let theme = parse_theme_config(ssg_obj)

  // Parse i18n config
  let i18n = parse_i18n_config(ssg_obj)

  // Parse exclude patterns
  let exclude = match ssg_obj.get("exclude") {
    Some(Array(arr)) => parse_string_array_json(arr)
    _ => []
  }

  // Parse islands config
  let islands_config = parse_islands_config(ssg_obj)

  // Parse navigation config
  let navigation = parse_navigation_config(ssg_obj)

  // Parse trailing slash config (default: true for SSG compatibility)
  let trailing_slash = match ssg_obj.get("trailingSlash") {
    Some(False) => false
    _ => true
  }

  // Parse OGP config
  let ogp = parse_ogp_config(ssg_obj)

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
  })
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
  let text = match obj.get("text") {
    Some(String(s)) => s
    _ => return None
  }
  let link = match obj.get("link") {
    Some(String(s)) => s
    _ => ""
  }
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
  Some(SidebarGroup::{ text: path, collapsed: false, items })
}

///|
/// Parse sidebar group
fn parse_sidebar_group(json : Json) -> SidebarGroup? {
  guard json is Object(obj) else { return None }
  let text = match obj.get("text") {
    Some(String(s)) => s
    _ => ""
  }
  let collapsed = match obj.get("collapsed") {
    Some(True) => true
    _ => false
  }
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
  Some(SidebarGroup::{ text, collapsed, items })
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
  guard obj.get("text") is Some(String(text)) else { return None }
  guard obj.get("link") is Some(String(link)) else { return None }
  Some(SidebarItem::Link(text~, link~))
}

///|
/// Parse theme configuration
fn parse_theme_config(obj : Map[String, Json]) -> ThemeConfig {
  match obj.get("theme") {
    Some(Object(theme_obj)) => {
      let primary_color = match theme_obj.get("primaryColor") {
        Some(String(s)) => Some(s)
        _ => Some("#3451b2")
      }
      let logo = match theme_obj.get("logo") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let footer = match theme_obj.get("footer") {
        Some(Object(footer_obj)) => {
          let message = match footer_obj.get("message") {
            Some(String(s)) => Some(s)
            _ => None
          }
          let copyright = match footer_obj.get("copyright") {
            Some(String(s)) => Some(s)
            _ => None
          }
          Some(FooterConfig::{ message, copyright })
        }
        _ => None
      }
      let social_links = match theme_obj.get("socialLinks") {
        Some(Array(arr)) => parse_social_links(arr)
        _ => []
      }
      ThemeConfig::{ primary_color, logo, footer, social_links }
    }
    _ => ThemeConfig::default()
  }
}

///|
/// Parse social links array
fn parse_social_links(arr : Array[Json]) -> Array[SocialLink] {
  let result : Array[SocialLink] = []
  for item in arr {
    guard item is Object(obj) else { continue }
    let icon = match obj.get("icon") {
      Some(String(s)) => s
      _ => continue
    }
    let link = match obj.get("link") {
      Some(String(s)) => s
      _ => continue
    }
    result.push(SocialLink::{ icon, link })
  }
  result
}

///|
/// Parse string array from JSON array
fn parse_string_array_json(arr : Array[Json]) -> Array[String] {
  let result : Array[String] = []
  for item in arr {
    guard item is String(s) else { continue }
    result.push(s)
  }
  result
}

///|
/// Parse i18n configuration
fn parse_i18n_config(obj : Map[String, Json]) -> I18nConfig {
  match obj.get("i18n") {
    Some(Object(i18n_obj)) => {
      let default_locale = match i18n_obj.get("defaultLocale") {
        Some(String(s)) => s
        _ => "en"
      }
      let locales = match i18n_obj.get("locales") {
        Some(Array(arr)) => parse_locale_configs(arr)
        _ => [LocaleConfig::{ code: "en", label: "English", path: "" }]
      }
      I18nConfig::{ default_locale, locales }
    }
    _ => I18nConfig::default()
  }
}

///|
/// Parse locale configurations
fn parse_locale_configs(arr : Array[Json]) -> Array[LocaleConfig] {
  let result : Array[LocaleConfig] = []
  for item in arr {
    if parse_locale_config(item) is Some(locale) {
      result.push(locale)
    }
  }
  result
}

///|
/// Parse single locale configuration
fn parse_locale_config(json : Json) -> LocaleConfig? {
  guard json is Object(obj) else { return None }
  let code = match obj.get("code") {
    Some(String(s)) => s
    _ => return None
  }
  let label = match obj.get("label") {
    Some(String(s)) => s
    _ => code // Fallback to code if no label
  }
  let path = match obj.get("path") {
    Some(String(s)) => s
    _ => if code == "en" { "" } else { code }
  }
  Some(LocaleConfig::{ code, label, path })
}

///|
/// Parse navigation configuration
fn parse_navigation_config(obj : Map[String, Json]) -> NavigationConfig {
  match obj.get("navigation") {
    Some(Object(nav_obj)) => {
      let spa = match nav_obj.get("spa") {
        Some(True) => true
        _ => false
      }
      let view_transitions = match nav_obj.get("viewTransitions") {
        Some(False) => false
        _ => true // default to true
      }
      let keyboard = match nav_obj.get("keyboard") {
        Some(False) => false
        _ => true // default to true
      }
      NavigationConfig::{ spa, view_transitions, keyboard }
    }
    _ => NavigationConfig::default()
  }
}

///|
/// Parse OGP configuration
fn parse_ogp_config(obj : Map[String, Json]) -> OgpConfig {
  match obj.get("ogp") {
    Some(Object(ogp_obj)) => {
      let site_url = match ogp_obj.get("siteUrl") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let image = match ogp_obj.get("image") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let twitter_handle = match ogp_obj.get("twitterHandle") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let twitter_card = match ogp_obj.get("twitterCard") {
        Some(String(s)) => Some(s)
        _ => None
      }
      OgpConfig::{ site_url, image, twitter_handle, twitter_card }
    }
    _ => OgpConfig::default()
  }
}

///|
/// Parse Islands configuration
fn parse_islands_config(obj : Map[String, Json]) -> IslandsConfig? {
  match obj.get("islands") {
    Some(Object(islands_obj)) => {
      let dir = match islands_obj.get("dir") {
        Some(String(s)) => s
        _ => "islands"
      }
      let base_path = match islands_obj.get("basePath") {
        Some(String(s)) => s
        _ => "/islands/"
      }
      Some(IslandsConfig::{ dir, base_path })
    }
    _ => None
  }
}
