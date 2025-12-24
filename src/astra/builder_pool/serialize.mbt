// Astra Builder Pool - JSON Serialization for IPC
//
// Serializes SsgConfig, PageMeta, SidebarGroup for worker communication

// =============================================================================
// SsgConfig Serialization
// =============================================================================

///|
/// Serialize SsgConfig to JSON string
pub fn ssg_config_to_json(config : @astra.SsgConfig) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{")
  buf.write_string("\"docs\":\"")
  write_escaped_string(config.docs_dir, buf)
  buf.write_string("\",\"output\":\"")
  write_escaped_string(config.output_dir, buf)
  buf.write_string("\",\"title\":\"")
  write_escaped_string(config.title, buf)
  buf.write_string("\",\"base\":\"")
  write_escaped_string(config.base_url, buf)
  buf.write_string("\",\"nav\":")
  write_nav_items(config.nav, buf)
  buf.write_string(",\"sidebar\":")
  write_sidebar_config(config.sidebar, buf)
  buf.write_string(",\"islands\":")
  write_islands_config(config.islands, buf)
  buf.write_string(",\"theme\":")
  write_theme_config(config.theme, buf)
  buf.write_string(",\"navigation\":")
  write_navigation_config(config.navigation, buf)
  buf.write_string(",\"i18n\":")
  write_i18n_config(config.i18n, buf)
  buf.write_string(",\"exclude\":")
  write_string_array(config.exclude, buf)
  buf.write_string(",\"trailingSlash\":")
  buf.write_string(if config.trailing_slash { "true" } else { "false" })
  buf.write_string(",\"ogp\":")
  write_ogp_config(config.ogp, buf)
  buf.write_string("}")
  buf.to_string()
}

///|
fn write_escaped_string(s : String, buf : StringBuilder) -> Unit {
  for char in s {
    match char {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ =>
        if char.to_int() < 32 {
          buf.write_string("\\u")
          write_hex4(char.to_int(), buf)
        } else {
          buf.write_char(char)
        }
    }
  }
}

///|
fn write_hex4(n : Int, buf : StringBuilder) -> Unit {
  let hex_chars = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f',
  ]
  buf.write_char(hex_chars[(n >> 12) & 0xF])
  buf.write_char(hex_chars[(n >> 8) & 0xF])
  buf.write_char(hex_chars[(n >> 4) & 0xF])
  buf.write_char(hex_chars[n & 0xF])
}

///|
fn write_string_array(arr : Array[String], buf : StringBuilder) -> Unit {
  buf.write_string("[")
  for i, s in arr {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string("\"")
    write_escaped_string(s, buf)
    buf.write_string("\"")
  }
  buf.write_string("]")
}

///|
fn write_nav_items(items : Array[@astra.NavItem], buf : StringBuilder) -> Unit {
  buf.write_string("[")
  for i, item in items {
    if i > 0 {
      buf.write_string(",")
    }
    write_nav_item(item, buf)
  }
  buf.write_string("]")
}

///|
fn write_nav_item(item : @astra.NavItem, buf : StringBuilder) -> Unit {
  buf.write_string("{\"text\":\"")
  write_escaped_string(item.text, buf)
  buf.write_string("\",\"link\":\"")
  write_escaped_string(item.link, buf)
  buf.write_string("\",\"items\":")
  write_nav_items(item.items, buf)
  buf.write_string("}")
}

///|
fn write_sidebar_config(config : @astra.SidebarConfig, buf : StringBuilder) -> Unit {
  match config {
    @astra.SidebarConfig::Auto => buf.write_string("\"auto\"")
    @astra.SidebarConfig::Manual(groups) => {
      buf.write_string("[")
      for i, g in groups {
        if i > 0 {
          buf.write_string(",")
        }
        write_sidebar_group(g, buf)
      }
      buf.write_string("]")
    }
  }
}

///|
fn write_sidebar_group(group : @astra.SidebarGroup, buf : StringBuilder) -> Unit {
  buf.write_string("{\"text\":\"")
  write_escaped_string(group.text, buf)
  buf.write_string("\"")
  match group.link {
    Some(l) => {
      buf.write_string(",\"link\":\"")
      write_escaped_string(l, buf)
      buf.write_string("\"")
    }
    None => ()
  }
  buf.write_string(",\"collapsed\":")
  buf.write_string(if group.collapsed { "true" } else { "false" })
  buf.write_string(",\"items\":[")
  for i, item in group.items {
    if i > 0 {
      buf.write_string(",")
    }
    write_sidebar_item(item, buf)
  }
  buf.write_string("]}")
}

///|
fn write_sidebar_item(item : @astra.SidebarItem, buf : StringBuilder) -> Unit {
  match item {
    @astra.SidebarItem::Link(text=t, link=l) => {
      buf.write_string("{\"type\":\"link\",\"text\":\"")
      write_escaped_string(t, buf)
      buf.write_string("\",\"link\":\"")
      write_escaped_string(l, buf)
      buf.write_string("\"}")
    }
    @astra.SidebarItem::Group(g) => {
      buf.write_string("{\"type\":\"group\",\"group\":")
      write_sidebar_group(g, buf)
      buf.write_string("}")
    }
  }
}

///|
fn write_islands_config(config : @astra.IslandsConfig?, buf : StringBuilder) -> Unit {
  match config {
    Some(c) => {
      buf.write_string("{\"dir\":\"")
      write_escaped_string(c.dir, buf)
      buf.write_string("\",\"basePath\":\"")
      write_escaped_string(c.base_path, buf)
      buf.write_string("\"}")
    }
    None => buf.write_string("null")
  }
}

///|
fn write_theme_config(config : @astra.ThemeConfig, buf : StringBuilder) -> Unit {
  buf.write_string("{")
  let mut first = true
  match config.primary_color {
    Some(c) => {
      buf.write_string("\"primaryColor\":\"")
      write_escaped_string(c, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  match config.logo {
    Some(l) => {
      if not(first) {
        buf.write_string(",")
      }
      buf.write_string("\"logo\":\"")
      write_escaped_string(l, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  match config.footer {
    Some(f) => {
      if not(first) {
        buf.write_string(",")
      }
      buf.write_string("\"footer\":")
      write_footer_config(f, buf)
      first = false
    }
    None => ()
  }
  if not(first) {
    buf.write_string(",")
  }
  buf.write_string("\"socialLinks\":[")
  for i, link in config.social_links {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string("{\"icon\":\"")
    write_escaped_string(link.icon, buf)
    buf.write_string("\",\"link\":\"")
    write_escaped_string(link.link, buf)
    buf.write_string("\"}")
  }
  buf.write_string("]}")
}

///|
fn write_footer_config(config : @astra.FooterConfig, buf : StringBuilder) -> Unit {
  buf.write_string("{")
  let mut first = true
  match config.message {
    Some(m) => {
      buf.write_string("\"message\":\"")
      write_escaped_string(m, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  match config.copyright {
    Some(c) => {
      if not(first) {
        buf.write_string(",")
      }
      buf.write_string("\"copyright\":\"")
      write_escaped_string(c, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  if not(first) {
    buf.write_string(",")
  }
  buf.write_string("\"links\":[")
  for i, col in config.links {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string("{\"title\":\"")
    write_escaped_string(col.title, buf)
    buf.write_string("\",\"items\":[")
    for j, item in col.items {
      if j > 0 {
        buf.write_string(",")
      }
      buf.write_string("{\"label\":\"")
      write_escaped_string(item.label, buf)
      buf.write_string("\",\"href\":\"")
      write_escaped_string(item.href, buf)
      buf.write_string("\"}")
    }
    buf.write_string("]}")
  }
  buf.write_string("]}")
}

///|
fn write_navigation_config(config : @ssg.NavigationConfig, buf : StringBuilder) -> Unit {
  buf.write_string("{\"spa\":")
  buf.write_string(if config.spa { "true" } else { "false" })
  buf.write_string(",\"viewTransitions\":")
  buf.write_string(if config.view_transitions { "true" } else { "false" })
  buf.write_string(",\"keyboard\":")
  buf.write_string(if config.keyboard { "true" } else { "false" })
  buf.write_string("}")
}

///|
fn write_i18n_config(config : @ssg.I18nConfig, buf : StringBuilder) -> Unit {
  buf.write_string("{\"defaultLocale\":\"")
  write_escaped_string(config.default_locale, buf)
  buf.write_string("\",\"locales\":[")
  for i, l in config.locales {
    if i > 0 {
      buf.write_string(",")
    }
    buf.write_string("{\"code\":\"")
    write_escaped_string(l.code, buf)
    buf.write_string("\",\"label\":\"")
    write_escaped_string(l.label, buf)
    buf.write_string("\",\"path\":\"")
    write_escaped_string(l.path, buf)
    buf.write_string("\"}")
  }
  buf.write_string("]}")
}

///|
fn write_ogp_config(config : @astra.OgpConfig, buf : StringBuilder) -> Unit {
  buf.write_string("{")
  let mut first = true
  match config.site_url {
    Some(u) => {
      buf.write_string("\"siteUrl\":\"")
      write_escaped_string(u, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  match config.image {
    Some(i) => {
      if not(first) {
        buf.write_string(",")
      }
      buf.write_string("\"image\":\"")
      write_escaped_string(i, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  match config.twitter_handle {
    Some(h) => {
      if not(first) {
        buf.write_string(",")
      }
      buf.write_string("\"twitterHandle\":\"")
      write_escaped_string(h, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  match config.twitter_card {
    Some(c) => {
      if not(first) {
        buf.write_string(",")
      }
      buf.write_string("\"twitterCard\":\"")
      write_escaped_string(c, buf)
      buf.write_string("\"")
    }
    None => ()
  }
  buf.write_string("}")
}

// =============================================================================
// SsgConfig Deserialization
// =============================================================================

///|
/// Parse SsgConfig from JSON string
pub fn ssg_config_from_json(json_str : String) -> @astra.SsgConfig? {
  try {
    let json = @json.parse(json_str.view())
    guard json is Object(obj) else { return None }
    parse_ssg_config_obj(obj)
  } catch {
    _ => None
  }
}

///|
fn parse_ssg_config_obj(obj : Map[String, Json]) -> @astra.SsgConfig? {
  let docs_dir = match obj.get("docs") {
    Some(String(s)) => s
    _ => "docs"
  }
  let output_dir = match obj.get("output") {
    Some(String(s)) => s
    _ => "dist"
  }
  let title = match obj.get("title") {
    Some(String(s)) => s
    _ => "Documentation"
  }
  let base_url = match obj.get("base") {
    Some(String(s)) => s
    _ => "/"
  }
  let nav = match obj.get("nav") {
    Some(Array(arr)) => parse_nav_items(arr)
    _ => []
  }
  let sidebar = match obj.get("sidebar") {
    Some(String("auto")) => @astra.SidebarConfig::Auto
    Some(Array(arr)) => @astra.SidebarConfig::Manual(parse_sidebar_groups(arr))
    _ => @astra.SidebarConfig::Auto
  }
  let islands : @astra.IslandsConfig? = match obj.get("islands") {
    Some(Object(islands_obj)) => parse_islands_config(islands_obj)
    _ => None
  }
  let theme = match obj.get("theme") {
    Some(Object(theme_obj)) => parse_theme_config(theme_obj)
    _ => @astra.ThemeConfig::default()
  }
  let navigation = match obj.get("navigation") {
    Some(Object(nav_obj)) => parse_navigation_config(nav_obj)
    _ => @ssg.NavigationConfig::default()
  }
  let i18n = match obj.get("i18n") {
    Some(Object(i18n_obj)) => parse_i18n_config(i18n_obj)
    _ => @ssg.I18nConfig::default()
  }
  let exclude = match obj.get("exclude") {
    Some(Array(arr)) => {
      let result : Array[String] = []
      for item in arr {
        if item is String(s) {
          result.push(s)
        }
      }
      result
    }
    _ => []
  }
  let trailing_slash = match obj.get("trailingSlash") {
    Some(True) => true
    Some(False) => false
    _ => true
  }
  let ogp = match obj.get("ogp") {
    Some(Object(ogp_obj)) => parse_ogp_config(ogp_obj)
    _ => @astra.OgpConfig::default()
  }
  Some(
    @astra.SsgConfig::{
      docs_dir,
      output_dir,
      title,
      base_url,
      nav,
      sidebar,
      islands,
      theme,
      navigation,
      i18n,
      exclude,
      trailing_slash,
      ogp,
      ogp_text: None,
      head_snippets: [],
      body_snippets: [],
    },
  )
}

///|
fn parse_nav_items(arr : Array[Json]) -> Array[@astra.NavItem] {
  let result : Array[@astra.NavItem] = []
  for item in arr {
    if item is Object(obj) {
      let text = match obj.get("text") {
        Some(String(s)) => s
        _ => ""
      }
      let link = match obj.get("link") {
        Some(String(s)) => s
        _ => ""
      }
      let items = match obj.get("items") {
        Some(Array(arr)) => parse_nav_items(arr)
        _ => []
      }
      result.push(@astra.NavItem::{ text, link, items })
    }
  }
  result
}

///|
fn parse_sidebar_groups(arr : Array[Json]) -> Array[@astra.SidebarGroup] {
  let result : Array[@astra.SidebarGroup] = []
  for item in arr {
    if item is Object(obj) {
      let text = match obj.get("text") {
        Some(String(s)) => s
        _ => ""
      }
      let link : String? = match obj.get("link") {
        Some(String(s)) => Some(s)
        _ => None
      }
      let collapsed = match obj.get("collapsed") {
        Some(True) => true
        _ => false
      }
      let items = match obj.get("items") {
        Some(Array(arr)) => parse_sidebar_items(arr)
        _ => []
      }
      result.push(@astra.SidebarGroup::{ text, link, collapsed, items })
    }
  }
  result
}

///|
fn parse_sidebar_items(arr : Array[Json]) -> Array[@astra.SidebarItem] {
  let result : Array[@astra.SidebarItem] = []
  for item in arr {
    if item is Object(obj) {
      let item_type = match obj.get("type") {
        Some(String(s)) => s
        _ => "link"
      }
      match item_type {
        "group" =>
          match obj.get("group") {
            Some(Object(group_obj)) => {
              let groups = parse_sidebar_groups([Object(group_obj)])
              if groups.length() > 0 {
                result.push(@astra.SidebarItem::Group(groups[0]))
              }
            }
            _ => ()
          }
        _ => {
          let text = match obj.get("text") {
            Some(String(s)) => s
            _ => ""
          }
          let link = match obj.get("link") {
            Some(String(s)) => s
            _ => ""
          }
          result.push(@astra.SidebarItem::Link(text~, link~))
        }
      }
    }
  }
  result
}

///|
fn parse_islands_config(obj : Map[String, Json]) -> @astra.IslandsConfig? {
  let dir = match obj.get("dir") {
    Some(String(s)) => s
    _ => "docs/components"
  }
  let base_path = match obj.get("basePath") {
    Some(String(s)) => s
    _ => "/components/"
  }
  Some(@astra.IslandsConfig::{ dir, base_path })
}

///|
fn parse_theme_config(obj : Map[String, Json]) -> @astra.ThemeConfig {
  let primary_color : String? = match obj.get("primaryColor") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let logo : String? = match obj.get("logo") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let footer : @astra.FooterConfig? = match obj.get("footer") {
    Some(Object(footer_obj)) => parse_footer_config(footer_obj)
    _ => None
  }
  let social_links = match obj.get("socialLinks") {
    Some(Array(arr)) => parse_social_links(arr)
    _ => []
  }
  @astra.ThemeConfig::{ primary_color, logo, footer, social_links }
}

///|
fn parse_footer_config(obj : Map[String, Json]) -> @astra.FooterConfig? {
  let message : String? = match obj.get("message") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let copyright : String? = match obj.get("copyright") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let links = match obj.get("links") {
    Some(Array(arr)) => parse_footer_columns(arr)
    _ => []
  }
  Some(@astra.FooterConfig::{ message, copyright, links })
}

///|
fn parse_footer_columns(arr : Array[Json]) -> Array[@astra.FooterColumn] {
  let result : Array[@astra.FooterColumn] = []
  for item in arr {
    if item is Object(obj) {
      let title = match obj.get("title") {
        Some(String(s)) => s
        _ => ""
      }
      let items = match obj.get("items") {
        Some(Array(links_arr)) => parse_footer_links(links_arr)
        _ => []
      }
      result.push(@astra.FooterColumn::{ title, items })
    }
  }
  result
}

///|
fn parse_footer_links(arr : Array[Json]) -> Array[@astra.FooterLink] {
  let result : Array[@astra.FooterLink] = []
  for item in arr {
    if item is Object(obj) {
      let label = match obj.get("label") {
        Some(String(s)) => s
        _ => ""
      }
      let href = match obj.get("href") {
        Some(String(s)) => s
        _ => ""
      }
      result.push(@astra.FooterLink::{ label, href })
    }
  }
  result
}

///|
fn parse_social_links(arr : Array[Json]) -> Array[@astra.SocialLink] {
  let result : Array[@astra.SocialLink] = []
  for item in arr {
    if item is Object(obj) {
      let icon = match obj.get("icon") {
        Some(String(s)) => s
        _ => ""
      }
      let link = match obj.get("link") {
        Some(String(s)) => s
        _ => ""
      }
      result.push(@astra.SocialLink::{ icon, link })
    }
  }
  result
}

///|
fn parse_navigation_config(obj : Map[String, Json]) -> @ssg.NavigationConfig {
  let spa = match obj.get("spa") {
    Some(True) => true
    _ => false
  }
  let view_transitions = match obj.get("viewTransitions") {
    Some(False) => false
    _ => true
  }
  let keyboard = match obj.get("keyboard") {
    Some(False) => false
    _ => true
  }
  @ssg.NavigationConfig::{ spa, view_transitions, keyboard }
}

///|
fn parse_i18n_config(obj : Map[String, Json]) -> @ssg.I18nConfig {
  let default_locale = match obj.get("defaultLocale") {
    Some(String(s)) => s
    _ => "en"
  }
  let locales = match obj.get("locales") {
    Some(Array(arr)) => parse_locales(arr)
    _ => [@ssg.LocaleConfig::{ code: "en", label: "English", path: "" }]
  }
  @ssg.I18nConfig::{ default_locale, locales }
}

///|
fn parse_locales(arr : Array[Json]) -> Array[@ssg.LocaleConfig] {
  let result : Array[@ssg.LocaleConfig] = []
  for item in arr {
    if item is Object(obj) {
      let code = match obj.get("code") {
        Some(String(s)) => s
        _ => "en"
      }
      let label = match obj.get("label") {
        Some(String(s)) => s
        _ => "English"
      }
      let path = match obj.get("path") {
        Some(String(s)) => s
        _ => ""
      }
      result.push(@ssg.LocaleConfig::{ code, label, path })
    }
  }
  result
}

///|
fn parse_ogp_config(obj : Map[String, Json]) -> @astra.OgpConfig {
  let site_url : String? = match obj.get("siteUrl") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let image : String? = match obj.get("image") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let twitter_handle : String? = match obj.get("twitterHandle") {
    Some(String(s)) => Some(s)
    _ => None
  }
  let twitter_card : String? = match obj.get("twitterCard") {
    Some(String(s)) => Some(s)
    _ => None
  }
  @astra.OgpConfig::{ site_url, image, twitter_handle, twitter_card }
}

// =============================================================================
// PageMeta Serialization
// =============================================================================

///|
/// Serialize Array[PageMeta] to JSON string
pub fn pages_to_json(pages : Array[@astra.PageMeta]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i, page in pages {
    if i > 0 {
      buf.write_string(",")
    }
    write_page_meta(page, buf)
  }
  buf.write_string("]")
  buf.to_string()
}

///|
fn write_page_meta(page : @astra.PageMeta, buf : StringBuilder) -> Unit {
  buf.write_string("{\"sourcePath\":\"")
  write_escaped_string(page.source_path, buf)
  buf.write_string("\",\"urlPath\":\"")
  write_escaped_string(page.url_path, buf)
  buf.write_string("\",\"frontmatter\":")
  write_frontmatter(page.frontmatter, buf)
  match page.last_modified {
    Some(lm) => {
      buf.write_string(",\"lastModified\":\"")
      write_escaped_string(lm, buf)
      buf.write_string("\"")
    }
    None => ()
  }
  buf.write_string(",\"locale\":\"")
  write_escaped_string(page.locale, buf)
  buf.write_string("\",\"canonicalPath\":\"")
  write_escaped_string(page.canonical_path, buf)
  buf.write_string("\",\"sortKey\":\"")
  write_escaped_string(page.sort_key, buf)
  buf.write_string("\"}")
}

///|
fn write_frontmatter(fm : @astra.Frontmatter, buf : StringBuilder) -> Unit {
  buf.write_string("{")
  let mut first = true
  match fm.title {
    Some(t) => {
      buf.write_string("\"title\":\"")
      write_escaped_string(t, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  match fm.description {
    Some(d) => {
      if not(first) {
        buf.write_string(",")
      }
      buf.write_string("\"description\":\"")
      write_escaped_string(d, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  match fm.layout {
    Some(l) => {
      if not(first) {
        buf.write_string(",")
      }
      buf.write_string("\"layout\":\"")
      write_escaped_string(l, buf)
      buf.write_string("\"")
      first = false
    }
    None => ()
  }
  if not(first) {
    buf.write_string(",")
  }
  buf.write_string("\"sidebar\":")
  buf.write_string(if fm.sidebar { "true" } else { "false" })
  buf.write_string(",\"islands\":")
  write_string_array(fm.islands, buf)
  match fm.image {
    Some(i) => {
      buf.write_string(",\"image\":\"")
      write_escaped_string(i, buf)
      buf.write_string("\"")
    }
    None => ()
  }
  match fm.og_type {
    Some(t) => {
      buf.write_string(",\"ogType\":\"")
      write_escaped_string(t, buf)
      buf.write_string("\"")
    }
    None => ()
  }
  match fm.twitter_card {
    Some(c) => {
      buf.write_string(",\"twitterCard\":\"")
      write_escaped_string(c, buf)
      buf.write_string("\"")
    }
    None => ()
  }
  buf.write_string("}")
}

///|
/// Parse Array[PageMeta] from JSON string
pub fn pages_from_json(json_str : String) -> Array[@astra.PageMeta] {
  try {
    let json = @json.parse(json_str.view())
    guard json is Array(arr) else { return [] }
    let result : Array[@astra.PageMeta] = []
    for item in arr {
      if parse_page_meta(item) is Some(page) {
        result.push(page)
      }
    }
    result
  } catch {
    _ => []
  }
}

///|
fn parse_page_meta(json : Json) -> @astra.PageMeta? {
  guard json is Object(obj) else { return None }
  guard obj.get("sourcePath") is Some(String(source_path)) else { return None }
  guard obj.get("urlPath") is Some(String(url_path)) else { return None }
  let frontmatter = match obj.get("frontmatter") {
    Some(Object(fm_obj)) => parse_frontmatter(fm_obj)
    _ => @astra.Frontmatter::default()
  }
  let last_modified : String? = match obj.get("lastModified") {
    Some(String(lm)) => Some(lm)
    _ => None
  }
  let locale = match obj.get("locale") {
    Some(String(l)) => l
    _ => "en"
  }
  let canonical_path = match obj.get("canonicalPath") {
    Some(String(cp)) => cp
    _ => url_path
  }
  let sort_key = match obj.get("sortKey") {
    Some(String(sk)) => sk
    _ => source_path
  }
  Some(
    @astra.PageMeta::{
      source_path,
      url_path,
      frontmatter,
      last_modified,
      locale,
      canonical_path,
      sort_key,
    },
  )
}

///|
fn parse_frontmatter(obj : Map[String, Json]) -> @astra.Frontmatter {
  let title : String? = match obj.get("title") {
    Some(String(t)) => Some(t)
    _ => None
  }
  let description : String? = match obj.get("description") {
    Some(String(d)) => Some(d)
    _ => None
  }
  let layout : String? = match obj.get("layout") {
    Some(String(l)) => Some(l)
    _ => None
  }
  let sidebar = match obj.get("sidebar") {
    Some(False) => false
    _ => true
  }
  let islands = match obj.get("islands") {
    Some(Array(arr)) => {
      let result : Array[String] = []
      for item in arr {
        if item is String(s) {
          result.push(s)
        }
      }
      result
    }
    _ => []
  }
  let image : String? = match obj.get("image") {
    Some(String(i)) => Some(i)
    _ => None
  }
  let og_type : String? = match obj.get("ogType") {
    Some(String(t)) => Some(t)
    _ => None
  }
  let twitter_card : String? = match obj.get("twitterCard") {
    Some(String(c)) => Some(c)
    _ => None
  }
  @astra.Frontmatter::{
    title,
    description,
    layout,
    sidebar,
    outline: None,
    islands,
    prev: None,
    next: None,
    image,
    og_type,
    twitter_card,
  }
}

// =============================================================================
// SidebarGroup Serialization
// =============================================================================

///|
/// Serialize Array[SidebarGroup] to JSON string
pub fn sidebar_to_json(sidebar : Array[@astra.SidebarGroup]) -> String {
  let buf = StringBuilder::new()
  buf.write_string("[")
  for i, g in sidebar {
    if i > 0 {
      buf.write_string(",")
    }
    write_sidebar_group(g, buf)
  }
  buf.write_string("]")
  buf.to_string()
}

///|
/// Parse Array[SidebarGroup] from JSON string
pub fn sidebar_from_json(json_str : String) -> Array[@astra.SidebarGroup] {
  try {
    let json = @json.parse(json_str.view())
    guard json is Array(arr) else { return [] }
    parse_sidebar_groups(arr)
  } catch {
    _ => []
  }
}
