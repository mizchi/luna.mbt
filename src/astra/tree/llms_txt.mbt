///|
/// llms.txt Generator
/// DocumentTree から llms.txt を生成する
/// 参考: https://llmstxt.org/
/// llms.txt を生成
pub fn generate_llms_txt(tree : @ssg.DocumentTree) -> String {
  let mut result = ""
  // ヘッダー
  result = result + "# " + tree.site.title + "\n\n"
  if tree.site.description != "" {
    result = result + "> " + tree.site.description + "\n\n"
  }
  // 目次
  result = result + "## Table of Contents\n\n"
  result = result + generate_toc(tree)
  result = result + "\n---\n\n"
  // 各ページのコンテンツ
  for page in tree.pages {
    if page.locale == tree.site.language {
      result = result + generate_page_content(page)
    }
  }
  result
}

///|
/// 目次を生成
fn generate_toc(tree : @ssg.DocumentTree) -> String {
  let mut result = ""
  result = result + generate_toc_node(tree.root, tree, 0)
  result
}

///|
fn generate_toc_node(
  node : @ssg.TreeNode,
  tree : @ssg.DocumentTree,
  depth : Int,
) -> String {
  let indent = "  ".repeat(depth)
  match node {
    @ssg.TreeNode::Page(page_id~) =>
      match tree.get_page(page_id) {
        Some(page) => indent + "- [" + page.title + "](" + page.url_path + ")\n"
        None => ""
      }
    @ssg.TreeNode::Section(name~, children~, ..) => {
      let mut result = ""
      if name != "" {
        result = result + indent + "- " + name + "\n"
      }
      for child in children {
        result = result + generate_toc_node(child, tree, depth + 1)
      }
      result
    }
  }
}

///|
/// ページコンテンツを生成
fn generate_page_content(page : @ssg.PageInfo) -> String {
  let mut result = ""
  // ページタイトル
  result = result + "# " + page.title + "\n\n"
  // URL
  result = result + "URL: " + page.url_path + "\n\n"
  // 説明
  if page.description != "" {
    result = result + "> " + page.description + "\n\n"
  }
  // 見出し構造
  if page.headings.length() > 0 {
    result = result + "## Outline\n\n"
    for heading in page.headings {
      let indent = "  ".repeat(heading.level - 1)
      result = result + indent + "- " + heading.text + "\n"
    }
    result = result + "\n"
  }
  // Markdownコンテンツ（frontmatter を除去）
  let content = strip_frontmatter(page.content_md)
  if content != "" {
    result = result + "## Content\n\n"
    result = result + content + "\n"
  }
  result = result + "\n---\n\n"
  result
}

///|
/// frontmatter を除去
fn strip_frontmatter(content : String) -> String {
  if not(content.has_prefix("---")) {
    return content
  }
  // 2つ目の "---" を探す
  let after_first = content[3:].to_string() catch { _ => return content }
  match find_substring(after_first, "---") {
    Some(idx) =>
      after_first[idx + 3:].trim(chars=" \t\n\r").to_string() catch {
        _ => content
      }
    None => content
  }
}

///|
/// 部分文字列を検索
fn find_substring(haystack : String, needle : String) -> Int? {
  let needle_chars = needle.to_array()
  let haystack_chars = haystack.to_array()
  let needle_len = needle_chars.length()
  let haystack_len = haystack_chars.length()
  if needle_len > haystack_len {
    return None
  }
  for i = 0; i <= haystack_len - needle_len; i = i + 1 {
    let mut found = true
    for j = 0; j < needle_len; j = j + 1 {
      if haystack_chars[i + j] != needle_chars[j] {
        found = false
        break
      }
    }
    if found {
      return Some(i)
    }
  }
  None
}
