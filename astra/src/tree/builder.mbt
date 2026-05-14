///|
/// DocumentTree Builder
/// Build DocumentTree from PageMeta and SsgConfig
/// Build DocumentTree from SsgConfig and PageMeta array (using real filesystem)
pub fn build_document_tree(
  config : @astra.SsgConfig,
  pages : Array[@astra.PageMeta],
  cwd : String,
) -> @astra.DocumentTree {
  let fs = @fs_adapter.NodeFsAdapter::new()
  build_document_tree_with_fs(fs, config, pages, cwd)
}

///|
/// Build DocumentTree from SsgConfig and PageMeta array (using FileSystem trait)
pub fn[F] build_document_tree_with_fs(
  fs : F,
  config : @astra.SsgConfig,
  pages : Array[@astra.PageMeta],
  cwd : String,
) -> @astra.DocumentTree {
  // fs and cwd are kept for API compatibility and future use
  // when async file I/O issues in MoonBit coroutine scheduler are resolved
  let _ = (fs, cwd)
  // Build SiteInfo
  let site = @astra.SiteInfo::new(
    title=config.title,
    description=config.title, // TODO: add description to config
    base_url=config.base_url,
    language=config.i18n.default_locale,
    updated_at=get_latest_update(pages),
  )
  // Build PageInfo array (using metadata only to avoid async issue with file reads)
  let page_infos = build_page_infos_from_meta(pages)
  // Build TreeNode
  let root = build_tree_node(page_infos, config.i18n.default_locale)
  @astra.DocumentTree::new(site~, pages=page_infos, root~)
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
) -> Array[@astra.PageInfo] {
  // Build minimal PageInfo without reading files
  let result : Array[@astra.PageInfo] = []
  for page in pages {
    let id = url_to_id(page.url_path)
    let info = @astra.PageInfo::new(
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
    url_path[1:].to_owned()
  } else {
    url_path
  }
  let path = if path.has_suffix("/") {
    path[:path.length() - 1].to_owned()
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
/// Build TreeNode from PageInfo array
fn build_tree_node(
  pages : Array[@astra.PageInfo],
  default_locale : String,
) -> @astra.TreeNode {
  // Build tree only with default locale pages
  let filtered : Array[@astra.PageInfo] = []
  for page in pages {
    if page.locale == default_locale {
      filtered.push(page)
    }
  }
  // Sort by path
  filtered.sort_by(fn(a, b) { a.sort_key.compare(b.sort_key) })
  // Build tree
  let children = build_tree_children(filtered, "")
  @astra.TreeNode::Section(name="", path="/", children~)
}

///|
/// Build tree recursively
fn build_tree_children(
  pages : Array[@astra.PageInfo],
  parent_path : String,
) -> Array[@astra.TreeNode] {
  let children : Array[@astra.TreeNode] = []
  let seen_dirs : Map[String, Bool] = {}
  for page in pages {
    let rel_path = if parent_path == "" {
      page.url_path
      // Relative path from parent_path
    } else if page.url_path.has_prefix(parent_path) {
      page.url_path[parent_path.length():].to_owned()
    } else {
      continue
    }
    // Remove leading "/"
    let rel_path = if rel_path.has_prefix("/") {
      rel_path[1:].to_owned()
    } else {
      rel_path
    }
    // Remove trailing "/"
    let rel_path = if rel_path.has_suffix("/") {
      rel_path[:rel_path.length() - 1].to_owned()
    } else {
      rel_path
    }
    if rel_path == "" {
      // Parent directory index
      children.push(
        @astra.TreeNode::Page(page_id=page.id, renderer=page.renderer_type),
      )
    } else if !rel_path.contains("/") {
      // Direct child page
      children.push(
        @astra.TreeNode::Page(page_id=page.id, renderer=page.renderer_type),
      )
    } else {
      // Subdirectory
      let segments = rel_path.split("/").collect()
      let first_segment = segments[0].to_owned()
      if !seen_dirs.contains(first_segment) {
        seen_dirs[first_segment] = true
        let sub_path = parent_path + "/" + first_segment
        let sub_children = build_tree_children(pages, sub_path + "/")
        children.push(
          @astra.TreeNode::Section(
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
