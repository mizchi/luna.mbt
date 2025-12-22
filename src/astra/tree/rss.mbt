///| RSS Feed Generator

///|

///| DocumentTree から RSS 2.0 フィードを生成する

///|
/// RSS 2.0 フィードを生成
pub fn generate_rss(tree : DocumentTree, limit? : Int = 20) -> String {
  let pages = tree.get_pages_sorted_by_date(limit~)
  let mut items = ""
  for page in pages {
    items = items + generate_rss_item(page, tree.site.base_url)
  }
  let rfc822_date = iso_to_rfc822(tree.site.updated_at)
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n  <channel>\n    <title>" +
  escape_xml(tree.site.title) +
  "</title>\n    <link>" +
  escape_xml(tree.site.base_url) +
  "</link>\n    <description>" +
  escape_xml(tree.site.description) +
  "</description>\n    <language>" +
  tree.site.language +
  "</language>\n    <lastBuildDate>" +
  rfc822_date +
  "</lastBuildDate>\n    <atom:link href=\"" +
  escape_xml(tree.site.base_url) +
  "/feed.xml\" rel=\"self\" type=\"application/rss+xml\"/>\n" +
  items +
  "  </channel>\n</rss>\n"
}

///|
fn generate_rss_item(page : PageInfo, base_url : String) -> String {
  let url = page.canonical_url(base_url)
  let rfc822_date = iso_to_rfc822(page.updated_at)
  "    <item>\n      <title>" +
  escape_xml(page.title) +
  "</title>\n      <link>" +
  escape_xml(url) +
  "</link>\n      <description>" +
  escape_xml(page.description) +
  "</description>\n      <pubDate>" +
  rfc822_date +
  "</pubDate>\n      <guid isPermaLink=\"true\">" +
  escape_xml(url) +
  "</guid>\n    </item>\n"
}

///|
/// ISO 8601 日時を RFC 822 形式に変換
/// "2024-12-22T12:00:00.000Z" -> "Sun, 22 Dec 2024 12:00:00 GMT"
fn iso_to_rfc822(iso_date : String) -> String {
  if iso_date == "" {
    return ""
  }
  // 簡易的な変換（完全な実装ではない）
  // フォーマット: YYYY-MM-DDTHH:MM:SS
  if iso_date.length() < 10 {
    return iso_date
  }
  let year = iso_date[:4].to_string() catch { _ => return iso_date }
  let month = iso_date[5:7].to_string() catch { _ => return iso_date }
  let day = iso_date[8:10].to_string() catch { _ => return iso_date }
  let time = if iso_date.length() >= 19 {
    iso_date[11:19].to_string() catch {
      _ => "00:00:00"
    }
  } else {
    "00:00:00"
  }
  let month_name = month_to_name(month)
  // RFC 822: "22 Dec 2024 12:00:00 GMT"
  day + " " + month_name + " " + year + " " + time + " GMT"
}

///|
fn month_to_name(month : String) -> String {
  match month {
    "01" => "Jan"
    "02" => "Feb"
    "03" => "Mar"
    "04" => "Apr"
    "05" => "May"
    "06" => "Jun"
    "07" => "Jul"
    "08" => "Aug"
    "09" => "Sep"
    "10" => "Oct"
    "11" => "Nov"
    "12" => "Dec"
    _ => "Jan"
  }
}

///|
/// XML特殊文字をエスケープ
fn escape_xml(s : String) -> String {
  let mut result = ""
  for c in s {
    match c {
      '&' => result = result + "&amp;"
      '<' => result = result + "&lt;"
      '>' => result = result + "&gt;"
      '"' => result = result + "&quot;"
      '\'' => result = result + "&#39;"
      _ => result = result + c.to_string()
    }
  }
  result
}
