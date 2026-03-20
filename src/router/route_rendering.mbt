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
    if not(seen.contains(url)) {
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
      preload_libs, result.preload_urls, chunk_manifest,
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
