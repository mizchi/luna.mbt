///| Astra DocumentTree Types

///|

///| 中間表現としてのドキュメントツリー。

///| ファイルシステムからスキャンした構造を保持し、

///| 複数の出力形式（HTML, RSS, sitemap, llms.txt）に変換可能。

///|
/// サイト全体を表現するルート構造
pub struct DocumentTree {
  site : SiteInfo
  pages : Array[PageInfo]
  root : TreeNode
}

///|
/// サイト全体のメタデータ
pub struct SiteInfo {
  title : String
  description : String
  base_url : String
  language : String
  updated_at : String
}

///|
/// 1ページの完全な情報
pub struct PageInfo {
  // 識別子
  id : String
  url_path : String
  source_path : String
  // メタデータ
  title : String
  description : String
  locale : String
  // 日時 (ISO 8601)
  updated_at : String
  // コンテンツ
  content_md : String
  // 構造
  headings : Array[Heading]
  // ソート用
  sort_key : String
}

///|
/// 階層構造を表現するノード
pub enum TreeNode {
  /// セクション（ディレクトリに対応）
  Section(name~ : String, path~ : String, children~ : Array[TreeNode])
  /// ページへの参照
  Page(page_id~ : String)
}

///|
/// 見出し情報（TOC、llms.txt用）
pub struct Heading {
  level : Int
  text : String
  id : String
}

// =============================================================================
// Constructors
// =============================================================================

///|
pub fn SiteInfo::new(
  title~ : String,
  description? : String = "",
  base_url? : String = "",
  language? : String = "en",
  updated_at? : String = "",
) -> SiteInfo {
  { title, description, base_url, language, updated_at }
}

///|
pub fn PageInfo::new(
  id~ : String,
  url_path~ : String,
  source_path? : String = "",
  title? : String = "",
  description? : String = "",
  locale? : String = "en",
  updated_at? : String = "",
  content_md? : String = "",
  headings? : Array[Heading] = [],
  sort_key? : String = "",
) -> PageInfo {
  {
    id,
    url_path,
    source_path,
    title,
    description,
    locale,
    updated_at,
    content_md,
    headings,
    sort_key,
  }
}

///|
pub fn Heading::new(level~ : Int, text~ : String, id? : String = "") -> Heading {
  { level, text, id }
}

///|
pub fn DocumentTree::new(
  site~ : SiteInfo,
  pages? : Array[PageInfo] = [],
  root? : TreeNode = TreeNode::Section(name="", path="/", children=[]),
) -> DocumentTree {
  { site, pages, root }
}

// =============================================================================
// Helper Methods
// =============================================================================

///|
/// ページIDからPageInfoを取得
pub fn DocumentTree::get_page(self : DocumentTree, id : String) -> PageInfo? {
  for page in self.pages {
    if page.id == id {
      return Some(page)
    }
  }
  None
}

///|
/// URLパスからPageInfoを取得
pub fn DocumentTree::get_page_by_url(
  self : DocumentTree,
  url_path : String,
) -> PageInfo? {
  for page in self.pages {
    if page.url_path == url_path {
      return Some(page)
    }
  }
  None
}

///|
/// ロケールでフィルタしたページ一覧を取得
pub fn DocumentTree::get_pages_by_locale(
  self : DocumentTree,
  locale : String,
) -> Array[PageInfo] {
  let result : Array[PageInfo] = []
  for page in self.pages {
    if page.locale == locale {
      result.push(page)
    }
  }
  result
}

///|
/// 更新日時でソートしたページ一覧を取得（新しい順）
pub fn DocumentTree::get_pages_sorted_by_date(
  self : DocumentTree,
  limit? : Int,
) -> Array[PageInfo] {
  let pages = self.pages.copy()
  pages.sort_by(fn(a, b) { b.updated_at.compare(a.updated_at) })
  match limit {
    Some(n) => {
      let result : Array[PageInfo] = []
      for i = 0; i < n && i < pages.length(); i = i + 1 {
        result.push(pages[i])
      }
      result
    }
    None => pages
  }
}

///|
/// 正規URLを生成
pub fn PageInfo::canonical_url(self : PageInfo, base_url : String) -> String {
  let base = if base_url.has_suffix("/") {
    base_url[:base_url.length() - 1].to_string() catch {
      _ => base_url
    }
  } else {
    base_url
  }
  base + self.url_path
}

///|
/// TreeNodeをフラットなページID配列に変換
pub fn TreeNode::flatten(self : TreeNode) -> Array[String] {
  let result : Array[String] = []
  self.flatten_into(result)
  result
}

///|
fn TreeNode::flatten_into(self : TreeNode, result : Array[String]) -> Unit {
  match self {
    Page(page_id~) => result.push(page_id)
    Section(children~, ..) =>
      for child in children {
        child.flatten_into(result)
      }
  }
}
