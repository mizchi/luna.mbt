///| DocumentTree Builder

///|

///| PageMeta と SsgConfig から DocumentTree を構築する

///|
/// SsgConfig と PageMeta 配列から DocumentTree を構築（実ファイルシステムを使用）
pub fn build_document_tree(
  config : @astra.SsgConfig,
  pages : Array[@astra.PageMeta],
  cwd : String,
) -> DocumentTree {
  let fs = @fs_adapter.NodeFsAdapter::new()
  build_document_tree_with_fs(fs, config, pages, cwd)
}

///|
/// SsgConfig と PageMeta 配列から DocumentTree を構築（FileSystem trait を使用）
pub fn[F : @env.FileSystem] build_document_tree_with_fs(
  fs : F,
  config : @astra.SsgConfig,
  pages : Array[@astra.PageMeta],
  cwd : String,
) -> DocumentTree {
  // SiteInfo の構築
  let site = SiteInfo::new(
    title=config.title,
    description=config.title, // TODO: config に description を追加
    base_url=config.base_url,
    language=config.i18n.default_locale,
    updated_at=get_latest_update(pages),
  )
  // PageInfo 配列の構築
  let page_infos = build_page_infos_with_fs(fs, pages, cwd, config.docs_dir)
  // TreeNode の構築
  let root = build_tree_node(page_infos, config.i18n.default_locale)
  DocumentTree::new(site~, pages=page_infos, root~)
}

///|
fn get_latest_update(pages : Array[@astra.PageMeta]) -> String {
  let mut latest = ""
  for page in pages {
    match page.last_modified {
      Some(lm) => if lm > latest { latest = lm }
      None => ()
    }
  }
  latest
}

///|
fn[F : @env.FileSystem] build_page_infos_with_fs(
  fs : F,
  pages : Array[@astra.PageMeta],
  cwd : String,
  docs_dir : String,
) -> Array[PageInfo] {
  let result : Array[PageInfo] = []
  for page in pages {
    let info = page_meta_to_page_info_with_fs(fs, page, cwd, docs_dir)
    result.push(info)
  }
  result
}

///|
fn[F : @env.FileSystem] page_meta_to_page_info_with_fs(
  fs : F,
  meta : @astra.PageMeta,
  cwd : String,
  docs_dir : String,
) -> PageInfo {
  // ファイルからMarkdownコンテンツを読み込み
  let full_path = join_path(cwd, docs_dir, meta.source_path)
  let content_md = read_file_content_with_fs(fs, full_path)
  // 見出しを抽出
  let headings = extract_headings(content_md)
  // IDを生成（URLパスから）
  let id = url_to_id(meta.url_path)
  PageInfo::new(
    id~,
    url_path=meta.url_path,
    source_path=meta.source_path,
    title=meta.frontmatter.title.unwrap_or(""),
    description=meta.frontmatter.description.unwrap_or(""),
    locale=meta.locale,
    updated_at=meta.last_modified.unwrap_or(""),
    content_md~,
    headings~,
    sort_key=meta.sort_key,
  )
}

///|
fn url_to_id(url_path : String) -> String {
  // "/guide/intro/" -> "guide-intro"
  let path = if url_path.has_prefix("/") {
    url_path[1:].to_string() catch {
      _ => url_path
    }
  } else {
    url_path
  }
  let path = if path.has_suffix("/") {
    path[:path.length() - 1].to_string() catch {
      _ => path
    }
  } else {
    path
  }
  if path == "" {
    "index"
  } else {
    path.replace(old="/", new="-")
  }
}

///|
fn join_path(base : String, dir : String, file : String) -> String {
  let base = if base.has_suffix("/") {
    base[:base.length() - 1].to_string() catch {
      _ => base
    }
  } else {
    base
  }
  let dir = if dir.has_prefix("/") {
    dir[1:].to_string() catch {
      _ => dir
    }
  } else {
    dir
  }
  let dir = if dir.has_suffix("/") {
    dir[:dir.length() - 1].to_string() catch {
      _ => dir
    }
  } else {
    dir
  }
  base + "/" + dir + "/" + file
}

///|
fn[F : @env.FileSystem] read_file_content_with_fs(
  fs : F,
  path : String,
) -> String {
  fs.read_file_sync(path) catch {
    _ => ""
  }
}

///|
/// Markdownから見出しを抽出
fn extract_headings(content : String) -> Array[Heading] {
  let headings : Array[Heading] = []
  let lines = content.split("\n")
  for line in lines {
    let trimmed = line.trim(chars=" \t").to_string()
    if trimmed.has_prefix("#") {
      let level = count_heading_level(trimmed)
      if level > 0 && level <= 6 {
        let text = trimmed[level:].trim(chars=" \t#").to_string() catch {
            _ => continue
          }
        let id = text_to_id(text)
        headings.push(Heading::new(level~, text~, id~))
      }
    }
  }
  headings
}

///|
fn count_heading_level(line : String) -> Int {
  let mut count = 0
  for c in line {
    if c == '#' {
      count = count + 1
    } else {
      break
    }
  }
  count
}

///|
fn text_to_id(text : String) -> String {
  // 簡易的なスラッグ生成
  let mut result = ""
  for c in text.to_lower() {
    if (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') {
      result = result + c.to_string()
    } else if c == ' ' || c == '-' || c == '_' {
      if not(result.has_suffix("-")) {
        result = result + "-"
      }
    }
    // 他の文字は無視
  }
  // 末尾のハイフンを除去
  if result.has_suffix("-") {
    result[:result.length() - 1].to_string() catch {
      _ => result
    }
  } else {
    result
  }
}

///|
/// PageInfo 配列から TreeNode を構築
fn build_tree_node(
  pages : Array[PageInfo],
  default_locale : String,
) -> TreeNode {
  // デフォルトロケールのページのみでツリーを構築
  let filtered : Array[PageInfo] = []
  for page in pages {
    if page.locale == default_locale {
      filtered.push(page)
    }
  }
  // パスでソート
  filtered.sort_by(fn(a, b) { a.sort_key.compare(b.sort_key) })
  // ツリー構築
  let children = build_tree_children(filtered, "")
  TreeNode::Section(name="", path="/", children~)
}

///|
/// 再帰的にツリーを構築
fn build_tree_children(
  pages : Array[PageInfo],
  parent_path : String,
) -> Array[TreeNode] {
  let children : Array[TreeNode] = []
  let seen_dirs : Map[String, Bool] = {}
  for page in pages {
    let rel_path = if parent_path == "" {
      page.url_path
      // parent_path からの相対パス
    } else if page.url_path.has_prefix(parent_path) {
      page.url_path[parent_path.length():].to_string() catch {
        _ => continue
      }
    } else {
      continue
    }
    // 先頭の "/" を除去
    let rel_path = if rel_path.has_prefix("/") {
      rel_path[1:].to_string() catch {
        _ => rel_path
      }
    } else {
      rel_path
    }
    // 末尾の "/" を除去
    let rel_path = if rel_path.has_suffix("/") {
      rel_path[:rel_path.length() - 1].to_string() catch {
        _ => rel_path
      }
    } else {
      rel_path
    }
    if rel_path == "" {
      // 親ディレクトリの index
      children.push(TreeNode::Page(page_id=page.id))
    } else if not(rel_path.contains("/")) {
      // 直接の子ページ
      children.push(TreeNode::Page(page_id=page.id))
    } else {
      // サブディレクトリ
      let segments = rel_path.split("/").collect()
      let first_segment = segments[0].to_string()
      if not(seen_dirs.contains(first_segment)) {
        seen_dirs[first_segment] = true
        let sub_path = parent_path + "/" + first_segment
        let sub_children = build_tree_children(pages, sub_path + "/")
        children.push(
          TreeNode::Section(
            name=first_segment,
            path=sub_path + "/",
            children=sub_children,
          ),
        )
      }
    }
  }
  children
}
