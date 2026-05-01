// Temporary re-export shim. Removed in Phase C once every sol caller imports mizchi/astra directly.
// Note: pub typealias re-exports the type name only. Bare-variant references (@ssg.Logo) and
// record-literal field access still require consumers to import mizchi/astra directly.

pub typealias @astra.BuildContext as BuildContext

pub typealias @astra.ClsHints as ClsHints

pub typealias @astra.ContentType as ContentType

pub typealias @astra.CssUtilitiesConfig as CssUtilitiesConfig

pub typealias @astra.DeployTarget as DeployTarget

pub typealias @astra.DocumentTree as DocumentTree

pub typealias @astra.FooterColumn as FooterColumn

pub typealias @astra.FooterConfig as FooterConfig

pub typealias @astra.FooterElement as FooterElement

pub typealias @astra.FooterLink as FooterLink

pub typealias @astra.Frontmatter as Frontmatter

pub typealias @astra.HeaderConfig as HeaderConfig

pub typealias @astra.HeaderElement as HeaderElement

pub typealias @astra.Heading as Heading

pub typealias @astra.I18nConfig as I18nConfig

pub typealias @astra.IslandsConfig as IslandsConfig

pub typealias @astra.JsxComponentEmbed as JsxComponentEmbed

pub typealias @astra.LocaleConfig as LocaleConfig

pub typealias @astra.MdNode as MdNode

pub typealias @astra.MdxAttrValue as MdxAttrValue

pub typealias @astra.MetaFilesConfig as MetaFilesConfig

pub typealias @astra.NavItem as NavItem

pub typealias @astra.NavLink as NavLink

pub typealias @astra.NavigationConfig as NavigationConfig

pub typealias @astra.OgpConfig as OgpConfig

pub typealias @astra.PageInfo as PageInfo

pub typealias @astra.PageMeta as PageMeta

pub typealias @astra.RendererType as RendererType

pub typealias @astra.SidebarConfig as SidebarConfig

pub typealias @astra.SidebarGroup as SidebarGroup

pub typealias @astra.SidebarItem as SidebarItem

pub typealias @astra.SiteInfo as SiteInfo

pub typealias @astra.SocialLink as SocialLink

pub typealias @astra.SsgConfig as SsgConfig

pub typealias @astra.ThemeConfig as ThemeConfig

pub typealias @astra.TreeNode as TreeNode

pub fn build_localized_url(
  canonical_path : String,
  locale : String,
  i18n : I18nConfig,
) -> String {
  @astra.build_localized_url(canonical_path, locale, i18n)
}

pub fn build_sort_key(path : String) -> String {
  @astra.build_sort_key(path)
}

pub fn capitalize_first(s : String) -> String {
  @astra.capitalize_first(s)
}

pub fn compare_strings_lex(a : String, b : String) -> Int {
  @astra.compare_strings_lex(a, b)
}

pub fn detect_locale_from_path(
  path : String,
  i18n : I18nConfig,
  trailing_slash? : Bool = true,
) -> (String, String) {
  @astra.detect_locale_from_path(path, i18n, trailing_slash~)
}

pub fn file_to_url_path(
  file_path : String,
  trailing_slash? : Bool = true,
) -> String {
  @astra.file_to_url_path(file_path, trailing_slash~)
}

pub fn get_locale_url_prefix(i18n : I18nConfig, locale_code : String) -> String {
  @astra.get_locale_url_prefix(i18n, locale_code)
}

pub fn get_url_dir(url_path : String) -> String {
  @astra.get_url_dir(url_path)
}

pub fn pad_number(n : Int, width : Int) -> String {
  @astra.pad_number(n, width)
}

pub fn parse_int_simple(s : String) -> Int {
  @astra.parse_int_simple(s)
}

pub fn parse_numeric_prefix(name : String) -> (Int, String) {
  @astra.parse_numeric_prefix(name)
}

pub fn parse_ssg_config(json_str : String) -> SsgConfig? {
  @astra.parse_ssg_config(json_str)
}

pub fn parse_ssg_from_sol_config(json_str : String) -> SsgConfig? {
  @astra.parse_ssg_from_sol_config(json_str)
}

pub fn resolve_base_url(base_url : String, path : String) -> String {
  @astra.resolve_base_url(base_url, path)
}

pub fn strip_numeric_prefixes(path : String) -> String {
  @astra.strip_numeric_prefixes(path)
}

pub fn url_to_output_path(url_path : String) -> String {
  @astra.url_to_output_path(url_path)
}
