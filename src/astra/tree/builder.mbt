///|
/// DocumentTree Builder
/// PageMeta と SsgConfig から DocumentTree を構築する
/// SsgConfig と PageMeta 配列から DocumentTree を構築（実ファイルシステムを使用）
pub fn build_document_tree(
  config : @astra.SsgConfig,
  pages : Array[@astra.PageMeta],
  cwd : String,
) -> @ssg.DocumentTree {
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
) -> @ssg.DocumentTree {
  // fs and cwd are kept for API compatibility and future use
  // when async file I/O issues in MoonBit coroutine scheduler are resolved
  let _ = (fs, cwd)
  // SiteInfo の構築
  let site = @ssg.SiteInfo::new(
    title=config.title,
    description=config.title, // TODO: config に description を追加
    base_url=config.base_url,
    language=config.i18n.default_locale,
    updated_at=get_latest_update(pages),
  )
  // PageInfo 配列の構築 (using metadata only to avoid async issue with file reads)
  let page_infos = build_page_infos_from_meta(pages)
  // TreeNode の構築
  let root = build_tree_node(page_infos, config.i18n.default_locale)
  @ssg.DocumentTree::new(site~, pages=page_infos, root~)
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
/// Build PageInfo array from PageMeta only (avoids async file I/O issues)
fn build_page_infos_from_meta(
  pages : Array[@astra.PageMeta],
) -> Array[@ssg.PageInfo] {
  // Build minimal PageInfo without reading files
  let result : Array[@ssg.PageInfo] = []
  for page in pages {
    let id = url_to_id(page.url_path)
    let info = @ssg.PageInfo::new(
      id~,
      url_path=page.url_path,
      source_path=page.source_path,
      title=page.frontmatter.title.unwrap_or(""),
      description=page.frontmatter.description.unwrap_or(""),
      locale=page.locale,
      updated_at=page.last_modified.unwrap_or(""),
      content_md="",
      headings=[],
      sort_key=page.sort_key,
    )
    result.push(info)
  }
  result
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
/// PageInfo 配列から TreeNode を構築
fn build_tree_node(
  pages : Array[@ssg.PageInfo],
  default_locale : String,
) -> @ssg.TreeNode {
  // デフォルトロケールのページのみでツリーを構築
  let filtered : Array[@ssg.PageInfo] = []
  for page in pages {
    if page.locale == default_locale {
      filtered.push(page)
    }
  }
  // パスでソート
  filtered.sort_by(fn(a, b) { a.sort_key.compare(b.sort_key) })
  // ツリー構築
  let children = build_tree_children(filtered, "")
  @ssg.TreeNode::Section(name="", path="/", children~)
}

///|
/// 再帰的にツリーを構築
fn build_tree_children(
  pages : Array[@ssg.PageInfo],
  parent_path : String,
) -> Array[@ssg.TreeNode] {
  let children : Array[@ssg.TreeNode] = []
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
      children.push(
        @ssg.TreeNode::Page(page_id=page.id, renderer=page.renderer_type),
      )
    } else if not(rel_path.contains("/")) {
      // 直接の子ページ
      children.push(
        @ssg.TreeNode::Page(page_id=page.id, renderer=page.renderer_type),
      )
    } else {
      // サブディレクトリ
      let segments = rel_path.split("/").collect()
      let first_segment = segments[0].to_string()
      if not(seen_dirs.contains(first_segment)) {
        seen_dirs[first_segment] = true
        let sub_path = parent_path + "/" + first_segment
        let sub_children = build_tree_children(pages, sub_path + "/")
        children.push(
          @ssg.TreeNode::Section(
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
