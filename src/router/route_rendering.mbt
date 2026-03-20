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
    title_prefix + " - " + title
  }
}

///|
/// Collect preload URLs: libs first, then chunk deps, then island entries (pure, no IO)
fn collect_preload_urls(
  preload_libs : Array[String],
  island_urls : Array[String],
  chunk_manifest : ChunkManifest?,
) -> Array[String] {
  let all_urls = preload_libs.copy()
  // Add chunk dependencies for each island URL (if manifest provided)
  match chunk_manifest {
    Some(manifest) =>
      for url in island_urls {
        let chunks = manifest.get_chunks(url)
        for chunk in chunks {
          if not(all_urls.contains(chunk)) {
            all_urls.push(chunk)
          }
        }
      }
    None => ()
  }
  // Add island entry URLs
  for url in island_urls {
    if not(all_urls.contains(url)) {
      all_urls.push(url)
    }
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
  let (body_html, preload_tags) = if hydration {
    let result = @render.render_to_string(node, preload=enable_preload)
    let tags = if enable_preload {
      let all_urls = collect_preload_urls(
        preload_libs, result.preload_urls, chunk_manifest,
      )
      @render.generate_preload_tags(all_urls)
    } else {
      ""
    }
    let html = @render.render_to_string_with_hydration(node)
    (html, tags)
  } else {
    let result = @render.render_to_string(node, preload=enable_preload)
    let tags = if enable_preload {
      let all_urls = collect_preload_urls(
        preload_libs, result.preload_urls, chunk_manifest,
      )
      @render.generate_preload_tags(all_urls)
    } else {
      ""
    }
    (result.html, tags)
  }
  let full_head = @hot_reload.with_dev_head_script(head)
  @page_shell.render_template(
    template, title, full_head, preload_tags, body_html,
  )
}
