///|
/// Sitemap Generator
/// DocumentTree から sitemap.xml を生成する
/// sitemap.xml を生成
pub fn generate_sitemap(tree : @ssg.DocumentTree) -> String {
  let mut urls = ""
  for page in tree.pages {
    urls = urls + generate_sitemap_url(page, tree.site.base_url)
  }
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n" +
  urls +
  "</urlset>\n"
}

///|
fn generate_sitemap_url(page : @ssg.PageInfo, base_url : String) -> String {
  let url = page.canonical_url(base_url)
  let lastmod = iso_to_date(page.updated_at)
  "  <url>\n    <loc>" +
  escape_xml(url) +
  "</loc>\n" +
  (if lastmod != "" { "    <lastmod>" + lastmod + "</lastmod>\n" } else { "" }) +
  "  </url>\n"
}

///|
/// ISO 8601 日時を日付のみに変換
/// "2024-12-22T12:00:00.000Z" -> "2024-12-22"
fn iso_to_date(iso_date : String) -> String {
  if iso_date.length() >= 10 {
    iso_date[:10].to_string() catch {
      _ => iso_date
    }
  } else {
    iso_date
  }
}
