// Router HTML rendering helpers

///|
/// Format page title with prefix
fn format_title(
  title : String,
  title_prefix~ : String,
  default_title~ : String,
) -> String {
  if title.is_empty() {
    default_title
  } else if title_prefix.is_empty() {
    title
  } else {
    "\{title_prefix} - \{title}"
  }
}

///|
/// Collect preload URLs: libs first, then chunk deps, then island entries (pure, no IO)
fn collect_preload_urls(
  preload_libs : Array[String],
  island_urls : Array[String],
  chunk_manifest : ChunkManifest?,
) -> Array[String] {
  let seen : @hashset.T[String] = @hashset.new()
  let all_urls : Array[String] = []
  let add = fn(url : String) {
    if !seen.contains(url) {
      seen.insert(url)
      all_urls.push(url)
    }
  }
  for u in preload_libs {
    add(u)
  }
  match chunk_manifest {
    Some(manifest) =>
      for url in island_urls {
        for chunk in manifest.get_chunks(url) {
          add(chunk)
        }
      }
    None => ()
  }
  for url in island_urls {
    add(url)
  }
  all_urls
}

///|
fn merge_asset_paths(
  base : Array[String],
  extra : Array[String],
) -> Array[String] {
  let merged = base.copy()
  for path in extra {
    if !merged.contains(path) {
      merged.push(path)
    }
  }
  merged
}

///|
fn is_external_asset_url(path : String) -> Bool {
  path.has_prefix("http://") ||
  path.has_prefix("https://") ||
  path.has_prefix("//") ||
  path.has_prefix("/")
}

///|
fn strip_dot_slash(path : String) -> String {
  if path.has_prefix("./") {
    path[2:].to_owned()
  } else {
    path
  }
}

///|
fn normalize_asset_url(path : String) -> String {
  if path.is_empty() {
    return ""
  }
  if is_external_asset_url(path) {
    return path
  }
  let local_path = strip_dot_slash(path)
  if local_path.has_prefix("static/") {
    "/" + local_path
  } else {
    "/static/" + local_path
  }
}

///|
fn push_normalized_asset(paths : Array[String], path : String) -> Unit {
  let url = normalize_asset_url(path)
  if !url.is_empty() && !paths.contains(url) {
    paths.push(url)
  }
}

///|
fn normalize_asset_urls(paths : Array[String]) -> Array[String] {
  let normalized : Array[String] = []
  for path in paths {
    push_normalized_asset(normalized, path)
  }
  normalized
}

///|
fn render_asset_tags(styles : Array[String], scripts : Array[String]) -> String {
  let buf = StringBuilder::new()
  for href in normalize_asset_urls(styles) {
    buf.write_string("<link rel=\"stylesheet\" href=\"")
    buf.write_string(@page_shell.escape_html_text(href))
    buf.write_string("\">")
  }
  for src in normalize_asset_urls(scripts) {
    buf.write_string("<script type=\"module\" src=\"")
    buf.write_string(@page_shell.escape_html_text(src))
    buf.write_string("\"></script>")
  }
  buf.to_string()
}

///|
fn build_page_head(
  base_head : String,
  styles : Array[String],
  scripts : Array[String],
  assets : @server_dom.ServerAssets,
) -> String {
  base_head +
  render_asset_tags(
    merge_asset_paths(styles, assets.styles),
    merge_asset_paths(scripts, assets.scripts),
  )
}

///|
/// Render VNode to full HTML page with template-based rendering
fn[E] render_page_html(
  node : @luna.Node[E, String],
  title : String,
  head : String,
  hydration : Bool,
  template : String,
  enable_preload? : Bool = true,
  preload_libs? : Array[String] = [],
  chunk_manifest? : ChunkManifest? = None,
) -> String {
  // Collect preload URLs from initial render (shared for both paths)
  let result = @render.render_to_string(node, preload=enable_preload)
  let preload_tags = if enable_preload {
    let all_urls = collect_preload_urls(
      preload_libs,
      result.preload_urls,
      chunk_manifest,
    )
    @render.generate_preload_tags(all_urls)
  } else {
    ""
  }
  // Hydration path adds markers; non-hydration uses the already-rendered HTML
  let body_html = if hydration {
    @render.render_to_string_with_hydration(node)
  } else {
    result.html
  }
  let full_head = @hot_reload.with_dev_head_script(head)
  @page_shell.render_template(
    template, title, full_head, preload_tags, body_html,
  )
}
