///| SSG Configuration Parser

///| Parse SSG config from sol.config.json content
pub fn parse_ssg_from_sol_config(json_str : String) -> SsgConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }

    // Get ssg section
    guard obj.get("ssg") is Some(Object(ssg_obj)) else {
      // No ssg section, return default
      return Some(SsgConfig::default())
    }

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

    // Get islands from root config
    let islands = match obj.get("islands") {
      Some(Array(arr)) => parse_string_array_json(arr)
      _ => []
    }

    // Parse i18n config
    let i18n = parse_i18n_config(ssg_obj)

    Some(
      SsgConfig::{
        docs_dir,
        output_dir,
        title,
        base_url,
        nav,
        sidebar,
        islands,
        theme,
        i18n,
      },
    )
  } catch {
    _ => None
  }
}

///| Parse navigation items from config
fn parse_nav_items(obj : Map[String, Json]) -> Array[NavItem] {
  match obj.get("nav") {
    Some(Array(arr)) => {
      let result : Array[NavItem] = []
      for item in arr {
        match parse_nav_item(item) {
          Some(nav_item) => result.push(nav_item)
          None => ()
        }
      }
      result
    }
    _ => []
  }
}

///| Parse single nav item
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
        match parse_nav_item(item) {
          Some(nav_item) => result.push(nav_item)
          None => ()
        }
      }
      result
    }
    _ => []
  }
  Some(NavItem::{ text, link, items })
}

///| Parse sidebar configuration
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
        match sidebar_obj.get(key) {
          Some(Array(arr)) =>
            match parse_sidebar_group_from_array(key, arr) {
              Some(group) => groups.push(group)
              None => ()
            }
          _ => ()
        }
      }
      SidebarConfig::Manual(groups)
    }
    Some(Array(arr)) => {
      // Direct array of sidebar groups
      let groups : Array[SidebarGroup] = []
      for item in arr {
        match parse_sidebar_group(item) {
          Some(group) => groups.push(group)
          None => ()
        }
      }
      SidebarConfig::Manual(groups)
    }
    _ => SidebarConfig::Auto
  }
}

///| Parse sidebar group from path-keyed array
fn parse_sidebar_group_from_array(
  path : String,
  arr : Array[Json]
) -> SidebarGroup? {
  let items : Array[SidebarItem] = []
  for item in arr {
    match parse_sidebar_item(item) {
      Some(sidebar_item) => items.push(sidebar_item)
      None => ()
    }
  }
  Some(SidebarGroup::{ text: path, collapsed: false, items })
}

///| Parse sidebar group
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
        match parse_sidebar_item(item) {
          Some(sidebar_item) => result.push(sidebar_item)
          None => ()
        }
      }
      result
    }
    _ => []
  }
  Some(SidebarGroup::{ text, collapsed, items })
}

///| Parse sidebar item
fn parse_sidebar_item(json : Json) -> SidebarItem? {
  guard json is Object(obj) else { return None }
  // Check if it's a group (has items) or a link
  match obj.get("items") {
    Some(Array(_)) =>
      // It's a nested group
      match parse_sidebar_group(json) {
        Some(group) => Some(SidebarItem::Group(group))
        None => None
      }
    _ => {
      // It's a link
      let text = match obj.get("text") {
        Some(String(s)) => s
        _ => return None
      }
      let link = match obj.get("link") {
        Some(String(s)) => s
        _ => return None
      }
      Some(SidebarItem::Link(text~, link~))
    }
  }
}

///| Parse theme configuration
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
      ThemeConfig::{ primary_color, logo, footer }
    }
    _ => ThemeConfig::default()
  }
}

///| Parse string array from JSON array
fn parse_string_array_json(arr : Array[Json]) -> Array[String] {
  let result : Array[String] = []
  for item in arr {
    guard item is String(s) else { continue }
    result.push(s)
  }
  result
}

///| Parse i18n configuration
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

///| Parse locale configurations
fn parse_locale_configs(arr : Array[Json]) -> Array[LocaleConfig] {
  let result : Array[LocaleConfig] = []
  for item in arr {
    match parse_locale_config(item) {
      Some(locale) => result.push(locale)
      None => ()
    }
  }
  result
}

///| Parse single locale configuration
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
