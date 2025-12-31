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
/// Extract string with fallback key (supports both camelCase and snake_case)
fn extract_string_with_fallback(
  obj : Map[String, Json],
  key : String,
  fallback_key : String,
  default : String,
) -> String {
  match @json_utils.extract_string_opt(obj, key) {
    Some(v) => v
    None => @json_utils.extract_string(obj, fallback_key, default)
  }
}

///|
/// Extract bool with fallback key (supports both camelCase and snake_case)
fn extract_bool_with_fallback(
  obj : Map[String, Json],
  key : String,
  fallback_key : String,
  default : Bool,
) -> Bool {
  if obj.contains(key) {
    @json_utils.extract_bool(obj, key, default)
  } else {
    @json_utils.extract_bool(obj, fallback_key, default)
  }
}

///|
/// Parse SSG object (shared by both config formats)
fn parse_ssg_object(ssg_obj : Map[String, Json]) -> SsgConfig? {
  // Parse ssg fields using json_utils helpers
  // Support both camelCase and snake_case key names
  let docs_dir = extract_string_with_fallback(
    ssg_obj, "docs", "docs_dir", "docs",
  )
  let output_dir = extract_string_with_fallback(
    ssg_obj, "output", "out_dir", "dist",
  )
  let title = @json_utils.extract_string(ssg_obj, "title", "Documentation")
  let base_url = extract_string_with_fallback(ssg_obj, "base", "base_url", "/")

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
  // Support both camelCase and snake_case
  let trailing_slash = extract_bool_with_fallback(
    ssg_obj, "trailingSlash", "trailing_slash", true,
  )

  // Parse OGP config
  let ogp = parse_ogp_config(ssg_obj)
  let ogp_text = @json_utils.extract_string_opt(ssg_obj, "ogpText")

  // Parse custom snippets
  let head_snippets = @json_utils.extract_string_array(ssg_obj, "headSnippets")
  let body_snippets = @json_utils.extract_string_array(ssg_obj, "bodySnippets")
  let prod_body_snippets = @json_utils.extract_string_array(
    ssg_obj, "prodBodySnippets",
  )

  // Parse sanitize HTML option (default: false)
  let sanitize_html = @json_utils.extract_bool(ssg_obj, "sanitizeHtml", false)

  // Parse deploy target (default: static)
  let deploy_target = parse_deploy_target(ssg_obj)

  // Parse SPA routes for client-side routing fallback
  let spa_routes = @json_utils.extract_string_array(ssg_obj, "spaRoutes")

  // Parse custom components directory
  let components_dir = @json_utils.extract_string_opt(ssg_obj, "componentsDir")

  // Parse CSS utilities configuration
  let css_utilities = parse_css_utilities_config(ssg_obj)

  // Parse meta files configuration
  let meta_files = parse_meta_files_config(ssg_obj)
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
    prod_body_snippets,
    sanitize_html,
    deploy_target,
    spa_routes,
    components_dir,
    css_utilities,
    meta_files,
  })
}

///|
/// Parse deploy target from config
fn parse_deploy_target(obj : Map[String, Json]) -> DeployTarget {
  match obj.get("deploy") {
    Some(String(s)) =>
      if s == "cloudflare" {
        Cloudflare
      } else if s == "github-pages" || s == "github" {
        GithubPages
      } else if s == "vercel" {
        Vercel
      } else if s == "netlify" {
        Netlify
      } else if s == "deno" {
        Deno
      } else if s == "node" {
        Node
      } else {
        Static
      }
    _ => Static
  }
}

///|
/// Parse CSS utilities configuration
fn parse_css_utilities_config(obj : Map[String, Json]) -> CssUtilitiesConfig? {
  guard obj.get("cssUtilities") is Some(Object(css_obj)) else { return None }
  let enabled = @json_utils.extract_bool(css_obj, "enabled", true)
  let split = @json_utils.extract_bool(css_obj, "split", false)
  let inline_threshold = @json_utils.extract_int(
    css_obj, "inlineThreshold", 4096,
  )
  let source_dirs = @json_utils.extract_string_array(css_obj, "sourceDirs")
  Some(CssUtilitiesConfig::{ enabled, split, inline_threshold, source_dirs })
}

///|
/// Parse meta files configuration
fn parse_meta_files_config(obj : Map[String, Json]) -> MetaFilesConfig {
  guard obj.get("metaFiles") is Some(Object(meta_obj)) else {
    return MetaFilesConfig::default()
  }
  let sitemap = @json_utils.extract_bool(meta_obj, "sitemap", true)
  let feed = @json_utils.extract_bool(meta_obj, "feed", false)
  let llms_txt = extract_bool_with_fallback(
    meta_obj, "llmsTxt", "llms_txt", false,
  )
  MetaFilesConfig::{ sitemap, feed, llms_txt }
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
  let icon = @json_utils.extract_string_opt(obj, "icon")
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
  Some(NavItem::{ text, link, icon, items })
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
  let header = match @json_utils.extract_object(theme_obj, "header") {
    Some(header_obj) => Some(parse_header_config(header_obj))
    None => None
  }
  let footer = match @json_utils.extract_object(theme_obj, "footer") {
    Some(footer_obj) => {
      let message = @json_utils.extract_string_opt(footer_obj, "message")
      let copyright = @json_utils.extract_string_opt(footer_obj, "copyright")
      let links = match footer_obj.get("links") {
        Some(Array(arr)) => parse_footer_columns(arr)
        _ => []
      }
      let top = match footer_obj.get("top") {
        Some(Array(arr)) => parse_footer_elements(arr)
        _ => []
      }
      let bottom = match footer_obj.get("bottom") {
        Some(Array(arr)) => parse_footer_elements(arr)
        _ => []
      }
      Some(FooterConfig::{ message, copyright, links, top, bottom })
    }
    None => None
  }
  let social_links = match theme_obj.get("socialLinks") {
    Some(Array(arr)) => parse_social_links(arr)
    _ => []
  }
  ThemeConfig::{ primary_color, logo, header, footer, social_links }
}

///|
/// Parse header configuration
fn parse_header_config(obj : Map[String, Json]) -> HeaderConfig {
  let left = match obj.get("left") {
    Some(Array(arr)) => parse_header_elements(arr)
    _ => [Logo]
  }
  let center = match obj.get("center") {
    Some(Array(arr)) => parse_header_elements(arr)
    _ => []
  }
  let right = match obj.get("right") {
    Some(Array(arr)) => parse_header_elements(arr)
    _ => [NavLinks, LangSwitcher, SocialLinks, ThemeToggle]
  }
  let sticky = match obj.get("sticky") {
    Some(True) => true
    _ => false
  }
  HeaderConfig::{ left, center, right, sticky }
}

///|
/// Parse header elements array
fn parse_header_elements(arr : Array[Json]) -> Array[HeaderElement] {
  let result : Array[HeaderElement] = []
  for item in arr {
    match item {
      String(s) =>
        match s {
          "logo" => result.push(Logo)
          "nav-links" => result.push(NavLinks)
          "search" => result.push(Search)
          "theme-toggle" => result.push(ThemeToggle)
          "social-links" => result.push(SocialLinks)
          "lang-switcher" => result.push(LangSwitcher)
          "spacer" => result.push(Spacer)
          _ =>
            // Treat unknown strings as custom component tags
            if s.contains("-") {
              result.push(Custom(s))
            }
        }
      _ => ()
    }
  }
  result
}

///|
/// Parse footer elements array
fn parse_footer_elements(arr : Array[Json]) -> Array[FooterElement] {
  let result : Array[FooterElement] = []
  for item in arr {
    match item {
      String(s) =>
        match s {
          "columns" => result.push(FooterElement::Columns)
          "message" => result.push(FooterElement::Message)
          "copyright" => result.push(FooterElement::Copyright)
          "social-links" => result.push(FooterElement::SocialLinks)
          _ =>
            // Treat unknown strings as custom component tags
            if s.contains("-") {
              result.push(FooterElement::Custom(s))
            }
        }
      _ => ()
    }
  }
  result
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
