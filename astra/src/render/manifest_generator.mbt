// Manifest Generator - Meta files and client manifest generation

// =============================================================================
// Meta Files Generation
// =============================================================================

///|
/// Generate meta files (sitemap.xml, feed.xml, llms.txt) using DocumentTree
/// Respects MetaFilesConfig settings - only generates enabled files
pub fn generate_meta_files(
  ctx : @astra.BuildContext,
  doc_tree : @astra.DocumentTree,
) -> Unit {
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)
  let meta_config = ctx.config.meta_files

  // Generate sitemap.xml (enabled by default)
  if meta_config.sitemap {
    let sitemap_content = @astra.generate_sitemap(doc_tree)
    let sitemap_path = @path.join2(output_dir, "sitemap.xml")
    @fs.writeFileSync(sitemap_path, @js.any(sitemap_content)) catch {
      e => println("  Warning: Failed to generate sitemap.xml: \{e}")
    }
    println("  Generated: /sitemap.xml")
  }

  // Generate feed.xml (RSS) - disabled by default
  if meta_config.feed {
    let rss_content = @astra.generate_rss(doc_tree)
    let rss_path = @path.join2(output_dir, "feed.xml")
    @fs.writeFileSync(rss_path, @js.any(rss_content)) catch {
      e => println("  Warning: Failed to generate feed.xml: \{e}")
    }
    println("  Generated: /feed.xml")
  }

  // Generate llms.txt - disabled by default
  if meta_config.llms_txt {
    let llms_content = @astra.generate_llms_txt(doc_tree)
    let llms_path = @path.join2(output_dir, "llms.txt")
    @fs.writeFileSync(llms_path, @js.any(llms_content)) catch {
      e => println("  Warning: Failed to generate llms.txt: \{e}")
    }
    println("  Generated: /llms.txt")
  }
}

// =============================================================================
// Client Manifest Generation
// =============================================================================

///|
/// Generate client manifest.json for chunk loading
/// This enables dynamic chunk loading in the client-side router
pub fn generate_client_manifest(ctx : @astra.BuildContext) -> Unit {
  // Convert PageMeta to RouteManifest
  let route_manifest = @routes.page_metas_to_manifest(ctx.pages, ctx.config)

  // Collect page configs for SPA detection
  let page_configs = collect_page_configs(ctx)

  // Check if we should use hierarchical manifest (v2)
  let has_spa_segments = has_spa_config(page_configs)

  // Output directory
  let luna_dir = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "_luna",
  )
  ensure_dir(luna_dir)
  if has_spa_segments {
    // Generate v2 hierarchical manifest
    generate_hierarchical_manifest(ctx, route_manifest, page_configs, luna_dir)
  } else {
    // Generate v1 flat manifest
    generate_flat_manifest(route_manifest, luna_dir)
  }
}

///|
/// Generate v1 flat manifest (backward compatible)
fn generate_flat_manifest(
  route_manifest : @routes.RouteManifest,
  luna_dir : String,
) -> Unit {
  // Define chunk file mappings
  let chunk_files : Array[(String, String)] = [
    ("boot", "boot.js"),
    ("hydrate", "boot/index.js"),
    ("signal", "boot/loader.js"),
    ("router", "boot/router.js"),
  ]

  // Convert RouteManifest to ChunkManifest with chunk mappings
  let chunk_manifest = @routes.build_chunk_manifest(
    route_manifest,
    chunk_files~,
    base="/_luna/",
  )

  // Serialize to JSON
  let manifest_json = chunk_manifest.to_json()
  let manifest_path = @path.join2(luna_dir, "manifest.json")
  @fs.writeFileSync(manifest_path, @js.any(manifest_json)) catch {
    e => println("  Warning: Failed to generate manifest.json: \{e}")
  }
  println("  Generated: /_luna/manifest.json (v1)")
}

///|
/// Generate v2 hierarchical manifest with segment splitting
fn generate_hierarchical_manifest(
  _ctx : @astra.BuildContext,
  route_manifest : @routes.RouteManifest,
  page_configs : Map[String, @routes.PageConfig],
  luna_dir : String,
) -> Unit {
  // Split manifest by segments
  let (hierarchical, segment_manifests) = @routes.split_manifest(
    route_manifest, page_configs,
  )

  // Add chunk file mappings
  let hierarchical_with_chunks = @routes.HierarchicalManifest::{
    ..hierarchical,
    chunks: {
      "boot": "boot.js",
      "hydrate": "boot/index.js",
      "signal": "boot/loader.js",
      "router": "boot/router.js",
    },
  }

  // Write main manifest
  let manifest_json = hierarchical_with_chunks.to_json()
  let manifest_path = @path.join2(luna_dir, "manifest.json")
  @fs.writeFileSync(manifest_path, @js.any(manifest_json)) catch {
    e => println("  Warning: Failed to generate manifest.json: \{e}")
  }
  println("  Generated: /_luna/manifest.json (v2)")

  // Write segment manifests
  let routes_dir = @path.join2(luna_dir, "routes")
  ensure_dir(routes_dir)
  for segment, segment_manifest in segment_manifests {
    let segment_json = segment_manifest.to_json()
    let segment_path = @path.join2(routes_dir, segment + ".json")
    @fs.writeFileSync(segment_path, @js.any(segment_json)) catch {
      e => println("  Warning: Failed to generate \{segment}.json: \{e}")
    }
    println("  Generated: /_luna/routes/\{segment}.json")
  }
}

///|
/// Collect page configs from pages directory
fn collect_page_configs(
  ctx : @astra.BuildContext,
) -> Map[String, @routes.PageConfig] {
  let configs : Map[String, @routes.PageConfig] = {}
  let pages_dir = @path.join2(ctx.cwd, ctx.config.docs_dir)

  // Scan for page.json files in first-level directories
  let entries : Array[String] = @fs.readdirSync(pages_dir) catch { _ => [] }
  for entry in entries {
    let entry_path = @path.join2(pages_dir, entry)
    let is_dir : Bool = @fs.statSync(entry_path).isDirectory() catch {
      _ => false
    }
    if is_dir {
      let page_json_path = @path.join2(entry_path, "page.json")
      if @fs.existsSync(page_json_path) {
        let content : String = @fs.readFileSync(page_json_path).to_string() catch {
          _ => continue
        }
        match @routes.parse_page_config(content) {
          Some(cfg) => configs[entry] = cfg
          None => ()
        }
      }
    }
  }
  configs
}

///|
/// Check if any segment has SPA config
fn has_spa_config(configs : Map[String, @routes.PageConfig]) -> Bool {
  for _, cfg in configs {
    if cfg.spa {
      return true
    }
  }
  false
}

// =============================================================================
// 404 Page Generation
// =============================================================================

///|
/// Generate 404.html page
pub fn generate_404_page(ctx : @astra.BuildContext) -> Unit {
  let base = ctx.config.base_url
  let title = "Page Not Found"
  let site_title = ctx.config.title
  let theme_vars = build_theme_overrides(ctx.config.theme)
  let theme_script = @assets.get_theme_script()

  // Build 404 page content
  let content = "<div style=\"display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; text-align: center; padding: 2rem;\">\n  <h1 style=\"font-size: 6rem; margin: 0; color: var(--text-muted);\">404</h1>\n  <h2 style=\"font-size: 1.5rem; margin: 1rem 0; color: var(--text-color);\">Page Not Found</h2>\n  <p style=\"color: var(--text-muted); margin-bottom: 2rem;\">The page you're looking for doesn't exist or has been moved.</p>\n  <a href=\"\{base}\" style=\"color: var(--primary-color); text-decoration: none; padding: 0.75rem 1.5rem; border: 1px solid var(--primary-color); border-radius: 0.5rem;\">Go to Home</a>\n</div>"
  let theme_style = if theme_vars.is_empty() {
    ""
  } else {
    "  <style>:root{\{theme_vars}}</style>\n"
  }
  let html =
    #|<!DOCTYPE html>
    #|<html lang="en">
    #|<head>
    #|  <meta charset="UTF-8">
    #|  <meta name="viewport" content="width=device-width, initial-scale=1.0">
    #|  <title>
  let html2 =
    #|</title>
    #|  <meta name="robots" content="noindex">
    #|  <script>
  let html3 =
    #|</script>
    #|  <link rel="stylesheet" href="
  let html4 =
    #|assets/style.css">
  let html5 =
    #|</head>
    #|<body>
    #|  <div id="app">
  let html6 =
    #|  </div>
    #|</body>
    #|</html>
  let full_html = html +
    title +
    " | " +
    site_title +
    html2 +
    theme_script +
    html3 +
    base +
    html4 +
    theme_style +
    html5 +
    content +
    html6
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "404.html",
  )
  @fs.writeFileSync(output_path, @js.any(full_html)) catch {
    e => println("  Warning: Failed to generate 404.html: \{e}")
  }
  println("  Generated: /404.html")
}
