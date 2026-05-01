// Page Generator - Site and page generation core logic

// =============================================================================
// Public API
// =============================================================================

///|
/// Generate entire static site (sync version, requires pre-created highlighter for syntax highlighting)
/// Use generate_site_async or generate_site_with_highlighter for syntax highlighting
pub fn generate_site(
  config : @astra.SsgConfig,
  cwd : String,
) -> Result[Unit, String] {
  generate_site_internal(config, cwd, None)
}

///|
/// Generate entire static site with Shiki syntax highlighting (async)
/// Supports async component SSR loading
pub async fn generate_site_async(
  config : @astra.SsgConfig,
  cwd : String,
) -> Result[Unit, String] {
  // Create Shiki highlighter
  let highlighter = @shiki.create_default_highlighter()
  generate_site_internal_async(config, cwd, Some(highlighter))
}

///|
/// Generate entire static site with pre-created highlighter
pub fn generate_site_with_highlighter(
  config : @astra.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter,
  is_dev? : Bool = false,
) -> Result[Unit, String] {
  generate_site_internal(config, cwd, Some(highlighter), is_dev~)
}

///|
/// Generate a single page (for incremental builds in dev mode)
pub fn generate_single_page(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  highlighter : @shiki.Highlighter,
) -> Result[Unit, String] {
  generate_page_with_highlight(ctx, page, Some(highlighter))
}

// =============================================================================
// Internal Site Generation
// =============================================================================

///|
/// Internal site generation
fn generate_site_internal(
  config : @astra.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter?,
  is_dev? : Bool = false,
) -> Result[Unit, String] {
  println("Scanning docs directory: \{config.docs_dir}")

  // Step 1: Scan docs directory with i18n and exclude support
  let scanned_pages = @routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
    trailing_slash=config.trailing_slash,
  )
  if scanned_pages.is_empty() {
    return Err("No markdown files found in \{config.docs_dir}")
  }
  println("Found \{scanned_pages.length()} pages")

  // Step 1.5: Resolve duplicate pages (static paths take priority over dynamic)
  let (pages, unresolved) = @routes.resolve_duplicate_pages(scanned_pages)
  if !(unresolved.is_empty()) {
    let errors = unresolved.map(@routes.format_duplicate_error)
    return Err("Unresolvable duplicate pages:\n" + errors.join("\n"))
  }

  // Step 2: Generate sidebar
  let sidebar = match config.sidebar {
    @astra.SidebarConfig::Auto => @routes.generate_auto_sidebar(pages)
    @astra.SidebarConfig::Manual(groups) => groups
  }

  // Step 3: Build document tree for navigation
  let doc_tree = Some(@tree.build_document_tree(config, pages, cwd))

  // Step 4: Create build context
  let ctx = @astra.BuildContext::{ config, pages, sidebar, cwd, doc_tree, is_dev }

  // Step 5: Create output directory
  let output_dir = @path.join2(cwd, config.output_dir)
  ensure_dir(output_dir)

  // Step 5: Generate each page
  for page in pages {
    match generate_page_with_highlight(ctx, page, highlighter) {
      Ok(_) => println("  Generated: \{page.url_path}")
      Err(e) => println("  Error generating \{page.url_path}: \{e}")
    }
  }

  // Step 6: Copy static assets (if any)
  copy_static_assets(ctx)

  // Step 7: Build DocumentTree and generate meta files (sitemap, RSS, llms.txt)
  let doc_tree = @tree.build_document_tree(config, pages, cwd)
  generate_meta_files(ctx, doc_tree)

  // Step 8: Generate 404 page
  generate_404_page(ctx)

  // Step 9: Generate client manifest for chunk loading
  generate_client_manifest(ctx)

  // Step 10: Generate ISR manifest (if any pages have revalidate)
  let isr_manifest = build_isr_manifest(pages)
  write_isr_manifest(isr_manifest, @path.join2(cwd, config.output_dir))

  // Step 11: Run deploy adapter (generates platform-specific files)
  @adapters.run_adapter(ctx)
  Ok(())
}

///|
/// Internal site generation (async version with SSR component support)
async fn generate_site_internal_async(
  config : @astra.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter?,
  is_dev? : Bool = false,
) -> Result[Unit, String] {
  println("Scanning docs directory: \{config.docs_dir}")

  // Step 1: Scan docs directory with i18n and exclude support
  let scanned_pages = @routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
    trailing_slash=config.trailing_slash,
  )
  if scanned_pages.is_empty() {
    return Err("No markdown files found in \{config.docs_dir}")
  }
  println("Found \{scanned_pages.length()} pages")

  // Step 1.5: Resolve duplicate pages (static paths take priority over dynamic)
  let (pages, unresolved) = @routes.resolve_duplicate_pages(scanned_pages)
  if !(unresolved.is_empty()) {
    let errors = unresolved.map(@routes.format_duplicate_error)
    return Err("Unresolvable duplicate pages:\n" + errors.join("\n"))
  }

  // Step 2: Generate sidebar
  let sidebar = match config.sidebar {
    @astra.SidebarConfig::Auto => @routes.generate_auto_sidebar(pages)
    @astra.SidebarConfig::Manual(groups) => groups
  }

  // Step 3: Build document tree for navigation
  let doc_tree = Some(@tree.build_document_tree(config, pages, cwd))

  // Step 4: Create build context
  let ctx = @astra.BuildContext::{ config, pages, sidebar, cwd, doc_tree, is_dev }

  // Step 5: Create output directory
  let output_dir = @path.join2(cwd, config.output_dir)
  ensure_dir(output_dir)

  // Step 4.5: Initialize cache manager
  let cache_manager = @cache.CacheManager::new(cwd, config)
  let mut cache_hits = 0
  let mut cache_misses = 0

  // Step 5: Generate each page (async for component SSR) with caching
  for page in pages {
    // Compute source hash for cache key
    let source_hash = compute_page_source_hash(ctx, page)

    // Check cache
    match cache_manager.get(page.url_path, source_hash) {
      Some(cached_html) => {
        // Cache hit - write cached HTML directly
        let output_path = @path.join2(
          @path.join2(ctx.cwd, ctx.config.output_dir),
          @routes.url_to_output_path(page.url_path),
        )
        let parent_dir = @path.dirname(output_path)
        ensure_dir(parent_dir)
        @fs.writeFileSync(output_path, @js.any(cached_html)) catch {
          e => {
            println("  Error writing cached \{page.url_path}: \{e}")
            continue
          }
        }
        cache_hits = cache_hits + 1
        println("  Cached: \{page.url_path}")
      }
      None =>
        // Cache miss - generate and cache
        match generate_page_with_highlight_async(ctx, page, highlighter) {
          Ok(html) => {
            cache_manager.set(page.url_path, source_hash, html)
            cache_misses = cache_misses + 1
            println("  Generated: \{page.url_path}")
          }
          Err(e) => println("  Error generating \{page.url_path}: \{e}")
        }
    }
  }

  // Step 5.5: Save cache metadata
  cache_manager.save()
  println("  Cache: \{cache_hits} hits, \{cache_misses} misses")

  // Step 6: Copy static assets with CSS extraction (async)
  copy_static_assets_async(ctx)

  // Step 7: Build DocumentTree and generate meta files (sitemap, RSS, llms.txt)
  let doc_tree = @tree.build_document_tree(config, pages, cwd)
  generate_meta_files(ctx, doc_tree)

  // Step 8: Generate 404 page
  generate_404_page(ctx)

  // Step 9: Generate client manifest for chunk loading
  generate_client_manifest(ctx)

  // Step 10: Generate ISR manifest (if any pages have revalidate)
  let isr_manifest = build_isr_manifest(pages)
  write_isr_manifest(isr_manifest, @path.join2(cwd, config.output_dir))

  // Step 11: Run deploy adapter (generates platform-specific files)
  @adapters.run_adapter(ctx)
  Ok(())
}

// =============================================================================
// Page Generation
// =============================================================================

///|
/// Parse dynamic source path to extract actual file path and params
/// Format: "path/to/_slug_/index.md?slug=guide%2Fintro" -> ("path/to/_slug_/index.md", {"slug": "guide/intro"})
extern "js" fn decode_query_component(value : String) -> String =
  #| (value) => {
  #|   try {
  #|     return decodeURIComponent(value);
  #|   } catch (_e) {
  #|     return value;
  #|   }
  #| }

///|
fn parse_query_params(query : String, params : Map[String, String]) -> Unit {
  for part_view in query.split("&") {
    let part = part_view.to_string()
    if part.is_empty() {
      continue
    }
    match part.find("=") {
      Some(eq_idx) => {
        let key_raw = @utils.extract_substring(part, 0, eq_idx)
        let value_raw = @utils.extract_substring(
          part,
          eq_idx + 1,
          part.length(),
        )
        let key = decode_query_component(key_raw)
        if !(key.is_empty()) {
          params[key] = decode_query_component(value_raw)
        }
      }
      None => {
        let key = decode_query_component(part)
        if !(key.is_empty()) {
          params[key] = ""
        }
      }
    }
  }
}

///|
fn parse_dynamic_source_path(
  source_path : String,
) -> (String, Map[String, String]) {
  let params : Map[String, String] = {}

  // Check if path contains query params
  match source_path.find("?") {
    Some(idx) => {
      // Split path and query string
      let file_path = @utils.extract_substring(source_path, 0, idx)
      let query = @utils.extract_substring(
        source_path,
        idx + 1,
        source_path.length(),
      )

      // Parse query params from URL-encoded key=value pairs.
      parse_query_params(query, params)
      (file_path, params)
    }
    None => (source_path, params)
  }
}

///|
/// Generate single page with optional syntax highlighting
fn generate_page_with_highlight(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  highlighter : @shiki.Highlighter?,
) -> Result[Unit, String] {
  // Build available URLs list for link fallback checking
  let available_urls : Array[String] = ctx.pages.map(fn(p) { p.url_path })

  // Parse dynamic source path to get actual file path and params
  let (actual_source, _params) = parse_dynamic_source_path(page.source_path)

  // Build full source path
  let source_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.docs_dir),
    actual_source,
  )

  // Process based on renderer type
  let (frontmatter, content_vnode, toc) = match page.renderer_type {
    @astra.RendererType::MarkdownRenderer => {
      // Read source file
      let content : String = @fs.readFileSync(source_path).to_string() catch {
        e => return Err("Failed to read \{source_path}: \{e}")
      }
      // Parse markdown
      let (parsed_frontmatter, nodes) = @markdown.parse_markdown(content)

      // Auto-generate description from first paragraph if not provided
      let fm = if parsed_frontmatter.description is None {
        match @markdown.extract_description(nodes) {
          Some(desc) => { ..parsed_frontmatter, description: Some(desc) }
          None => parsed_frontmatter
        }
      } else {
        parsed_frontmatter
      }

      // Get islands base path from config
      let islands_base_path = match ctx.config.islands {
        Some(islands_config) => islands_config.base_path
        None => "/static/"
      }

      // Convert to VNode with link resolution
      // Index pages use standard browser behavior, content pages use sibling behavior
      let is_index = page.source_path.has_suffix("index.md")
      // Get locale prefix for i18n link resolution
      let locale_prefix = @astra.get_locale_url_prefix(
        ctx.config.i18n,
        page.locale,
      )
      let vnode = @markdown.md_nodes_to_vnode(
        nodes,
        islands_base_path~,
        current_url_path=page.url_path,
        is_index~,
        locale_prefix~,
        available_urls~,
      )

      // Extract TOC
      let extracted_toc = @markdown.extract_toc(nodes)
      (fm, vnode, extracted_toc)
    }
    @astra.RendererType::HtmlRenderer => {
      // Read source file
      let content : String = @fs.readFileSync(source_path).to_string() catch {
        e => return Err("Failed to read \{source_path}: \{e}")
      }
      // For HTML files, use the content as raw HTML
      // Optionally sanitize if configured
      let sanitized = if ctx.config.sanitize_html {
        sanitize_html(content)
      } else {
        content
      }
      // Transform internal links (remove numeric prefixes like /00_intro/ -> /intro/)
      let html_content = transform_internal_links(
        sanitized,
        ctx.config.trailing_slash,
      )
      // Wrap raw HTML in a fragment
      let vnode = @luna.raw_html(html_content)
      // Use page frontmatter (from file_router, which is default for HTML)
      // No TOC for HTML files
      (page.frontmatter, vnode, [])
    }
    @astra.RendererType::LunaRenderer => {
      // Luna component SSR - try to load and render the component
      let component_name = get_component_name_from_path(page.source_path)
      let vnode = match render_component_ssr(ctx.cwd, page.source_path) {
        Some(node) => node
        None => {
          // Fallback to placeholder if component rendering fails
          let placeholder_html = "<div data-component=\"\{component_name}\" data-ssr=\"pending\" class=\"component-placeholder\"><p>Component: \{component_name}</p><p>SSR pending - compile component with <code>moon build</code></p></div>"
          @luna.raw_html(placeholder_html)
        }
      }
      (page.frontmatter, vnode, [])
    }
    @astra.RendererType::ReactRenderer => {
      // TSX component pages - sync version shows placeholder (use async for SSR)
      let component_name = get_component_name_from_path(page.source_path)
      let placeholder_html = "<div data-tsx-component=\"\{component_name}\" data-ssr=\"pending\" class=\"tsx-component-placeholder\"><p>TSX Component: \{component_name}</p><p>Use async build for TSX SSR</p></div>"
      (page.frontmatter, @luna.raw_html(placeholder_html), [])
    }
    @astra.RendererType::PreactRenderer => {
      // Preact component pages - similar to React but with Preact runtime
      let component_name = get_component_name_from_path(page.source_path)
      let placeholder_html = "<div data-preact-component=\"\{component_name}\" data-ssr=\"pending\" class=\"preact-component-placeholder\"><p>Preact Component: \{component_name}</p><p>Use async build for Preact SSR</p></div>"
      (page.frontmatter, @luna.raw_html(placeholder_html), [])
    }
    @astra.RendererType::ClientOnlyRenderer => {
      // Client-only components - render placeholder that will be hydrated
      let component_name = get_component_name_from_path(page.source_path)
      let vnode = match page.content_type {
        @astra.ContentType::Component => {
          let placeholder_html = "<div data-component=\"\{component_name}\" data-hydrate=\"true\" class=\"component-loading\"><p>Loading \{component_name}...</p></div>"
          @luna.raw_html(placeholder_html)
        }
        @astra.ContentType::TsxComponent => {
          let placeholder_html = "<div data-tsx-component=\"\{component_name}\" data-hydrate=\"true\" class=\"tsx-component-loading\"><p>Loading \{component_name}...</p></div>"
          @luna.raw_html(placeholder_html)
        }
        _ =>
          // Unexpected: should not reach here
          @luna.raw_html(
            "<div>Unexpected content type for ClientOnlyRenderer</div>",
          )
      }
      (page.frontmatter, vnode, [])
    }
    @astra.RendererType::MdxRenderer => {
      // MDX renderer - parse MDX with JSX support
      let content : String = @fs.readFileSync(source_path).to_string() catch {
        e => return Err("Failed to read \{source_path}: \{e}")
      }
      // Parse using MDX parser (handles import/export/JSX)
      let (parsed_frontmatter, nodes) = @mdx.parse_mdx(content)

      // Auto-generate description from first paragraph if not provided
      let fm = if parsed_frontmatter.description is None {
        match @markdown.extract_description(nodes) {
          Some(desc) => { ..parsed_frontmatter, description: Some(desc) }
          None => parsed_frontmatter
        }
      } else {
        parsed_frontmatter
      }

      // Get islands base path from config
      let islands_base_path = match ctx.config.islands {
        Some(islands_config) => islands_config.base_path
        None => "/static/"
      }

      // Convert to VNode (JsxComponent nodes are handled in transformer)
      let is_index = page.source_path.has_suffix("index.mdx")
      // Get locale prefix for i18n link resolution
      let locale_prefix = @astra.get_locale_url_prefix(
        ctx.config.i18n,
        page.locale,
      )
      let vnode = @markdown.md_nodes_to_vnode(
        nodes,
        islands_base_path~,
        current_url_path=page.url_path,
        is_index~,
        locale_prefix~,
        available_urls~,
      )

      // Extract TOC
      let extracted_toc = @markdown.extract_toc(nodes)
      (fm, vnode, extracted_toc)
    }
  }

  // Build page HTML
  let html = build_page_html(ctx, page, frontmatter, content_vnode, toc)

  // Apply syntax highlighting if highlighter is available
  let final_html = match highlighter {
    Some(h) => apply_syntax_highlighting(html, h)
    None => html
  }

  // Write to output
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    @routes.url_to_output_path(page.url_path),
  )

  // Ensure parent directory exists
  let parent_dir = @path.dirname(output_path)
  ensure_dir(parent_dir)
  try {
    @fs.writeFileSync(output_path, @js.any(final_html))
    Ok(())
  } catch {
    e => Err("Failed to write \{output_path}: \{e}")
  }
}

///|
/// Compute source hash for a page (used for cache key)
fn compute_page_source_hash(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
) -> String {
  // Parse dynamic source path to get actual file path
  let (actual_source, _params) = parse_dynamic_source_path(page.source_path)

  // Build full source path
  let source_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.docs_dir),
    actual_source,
  )

  // Read source content
  let content : String = @fs.readFileSync(source_path).to_string() catch {
    _ => ""
  }

  // Serialize frontmatter to JSON for hash
  let fm = page.frontmatter
  let title = fm.title.unwrap_or("")
  let layout = fm.layout.unwrap_or("")
  let noindex = if fm.noindex { "true" } else { "false" }
  let fm_json = title + "|" + layout + "|" + noindex

  // Get config hash
  let config_hash = @cache.compute_config_hash(ctx.config)

  // Compute combined hash
  @cache.compute_page_hash(content, fm_json, config_hash)
}

///|
/// Generate single page with async SSR component support
/// Returns the generated HTML on success
async fn generate_page_with_highlight_async(
  ctx : @astra.BuildContext,
  page : @astra.PageMeta,
  highlighter : @shiki.Highlighter?,
) -> Result[String, String] {
  // Build available URLs list for link fallback checking
  let available_urls : Array[String] = ctx.pages.map(fn(p) { p.url_path })

  // Parse dynamic source path to get actual file path and params
  let (actual_source, _params) = parse_dynamic_source_path(page.source_path)

  // Build full source path
  let source_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.docs_dir),
    actual_source,
  )

  // Process based on renderer type
  let (frontmatter, content_vnode, toc) = match page.renderer_type {
    @astra.RendererType::MarkdownRenderer => {
      // Read source file
      let content : String = @fs.readFileSync(source_path).to_string() catch {
        e => return Err("Failed to read \{source_path}: \{e}")
      }
      // Parse markdown
      let (parsed_frontmatter, nodes) = @markdown.parse_markdown(content)

      // Auto-generate description from first paragraph if not provided
      let fm = if parsed_frontmatter.description is None {
        match @markdown.extract_description(nodes) {
          Some(desc) => { ..parsed_frontmatter, description: Some(desc) }
          None => parsed_frontmatter
        }
      } else {
        parsed_frontmatter
      }

      // Get islands base path from config
      let islands_base_path = match ctx.config.islands {
        Some(islands_config) => islands_config.base_path
        None => "/static/"
      }

      // Convert to VNode with link resolution
      let is_index = page.source_path.has_suffix("index.md")
      // Get locale prefix for i18n link resolution
      let locale_prefix = @astra.get_locale_url_prefix(
        ctx.config.i18n,
        page.locale,
      )
      let vnode = @markdown.md_nodes_to_vnode(
        nodes,
        islands_base_path~,
        current_url_path=page.url_path,
        is_index~,
        locale_prefix~,
        available_urls~,
      )

      // Extract TOC
      let extracted_toc = @markdown.extract_toc(nodes)
      (fm, vnode, extracted_toc)
    }
    @astra.RendererType::HtmlRenderer => {
      // Read source file
      let content : String = @fs.readFileSync(source_path).to_string() catch {
        e => return Err("Failed to read \{source_path}: \{e}")
      }
      // For HTML files, use the content as raw HTML
      let sanitized = if ctx.config.sanitize_html {
        sanitize_html(content)
      } else {
        content
      }
      // Transform internal links (remove numeric prefixes like /00_intro/ -> /intro/)
      let html_content = transform_internal_links(
        sanitized,
        ctx.config.trailing_slash,
      )
      let vnode = @luna.raw_html(html_content)
      (page.frontmatter, vnode, [])
    }
    @astra.RendererType::LunaRenderer => {
      // Luna component SSR (async)
      let component_name = get_component_name_from_path(page.source_path)
      let vnode = match render_component_ssr_async(ctx.cwd, page.source_path) {
        Some(node) => node
        None => {
          // Fallback to placeholder if component rendering fails
          let placeholder_html = "<div data-component=\"\{component_name}\" data-ssr=\"pending\" class=\"component-placeholder\"><p>Component: \{component_name}</p><p>SSR pending - compile component with <code>moon build</code></p></div>"
          @luna.raw_html(placeholder_html)
        }
      }
      (page.frontmatter, vnode, [])
    }
    @astra.RendererType::ReactRenderer => {
      // TSX component SSR via React
      let component_name = get_component_name_from_path(page.source_path)
      let vnode = match
        render_tsx_component_ssr_async(
          ctx.cwd,
          ctx.config.docs_dir,
          page.source_path,
        ) {
        Some(node) => node
        None => {
          // Fallback to placeholder if SSR fails
          let placeholder_html = "<div data-tsx-component=\"\{component_name}\" data-ssr=\"failed\" class=\"tsx-component-placeholder\"><p>TSX Component: \{component_name}</p><p>SSR failed - check console for errors</p></div>"
          @luna.raw_html(placeholder_html)
        }
      }
      (page.frontmatter, vnode, [])
    }
    @astra.RendererType::PreactRenderer => {
      // Preact component SSR - similar to React but with Preact runtime
      let component_name = get_component_name_from_path(page.source_path)
      // Preact SSR uses the same infrastructure as React (preact-render-to-string)
      let vnode = match
        render_tsx_component_ssr_async(
          ctx.cwd,
          ctx.config.docs_dir,
          page.source_path,
        ) {
        Some(node) => node
        None => {
          let placeholder_html = "<div data-preact-component=\"\{component_name}\" data-ssr=\"failed\" class=\"preact-component-placeholder\"><p>Preact Component: \{component_name}</p><p>SSR failed - check console for errors</p></div>"
          @luna.raw_html(placeholder_html)
        }
      }
      (page.frontmatter, vnode, [])
    }
    @astra.RendererType::ClientOnlyRenderer => {
      // Client-only components - render placeholder that will be hydrated
      let component_name = get_component_name_from_path(page.source_path)
      let vnode = match page.content_type {
        @astra.ContentType::Component => {
          let placeholder_html = "<div data-component=\"\{component_name}\" data-hydrate=\"true\" class=\"component-loading\"><p>Loading \{component_name}...</p></div>"
          @luna.raw_html(placeholder_html)
        }
        @astra.ContentType::TsxComponent => {
          let placeholder_html = "<div data-tsx-component=\"\{component_name}\" data-hydrate=\"true\" class=\"tsx-component-loading\"><p>Loading \{component_name}...</p></div>"
          @luna.raw_html(placeholder_html)
        }
        _ =>
          // Unexpected: should not reach here
          @luna.raw_html(
            "<div>Unexpected content type for ClientOnlyRenderer</div>",
          )
      }
      (page.frontmatter, vnode, [])
    }
    @astra.RendererType::MdxRenderer => {
      // MDX renderer (async) - parse MDX with JSX support
      let content : String = @fs.readFileSync(source_path).to_string() catch {
        e => return Err("Failed to read \{source_path}: \{e}")
      }
      // Parse using MDX parser (handles import/export/JSX)
      let (parsed_frontmatter, nodes) = @mdx.parse_mdx(content)

      // Auto-generate description from first paragraph if not provided
      let fm = if parsed_frontmatter.description is None {
        match @markdown.extract_description(nodes) {
          Some(desc) => { ..parsed_frontmatter, description: Some(desc) }
          None => parsed_frontmatter
        }
      } else {
        parsed_frontmatter
      }

      // Get islands base path from config
      let islands_base_path = match ctx.config.islands {
        Some(islands_config) => islands_config.base_path
        None => "/static/"
      }

      // Convert to VNode (JsxComponent nodes are handled in transformer)
      let is_index = page.source_path.has_suffix("index.mdx")
      // Get locale prefix for i18n link resolution
      let locale_prefix = @astra.get_locale_url_prefix(
        ctx.config.i18n,
        page.locale,
      )
      let vnode = @markdown.md_nodes_to_vnode(
        nodes,
        islands_base_path~,
        current_url_path=page.url_path,
        is_index~,
        locale_prefix~,
        available_urls~,
      )

      // Extract TOC
      let extracted_toc = @markdown.extract_toc(nodes)
      (fm, vnode, extracted_toc)
    }
  }

  // Build page HTML
  let html = build_page_html(ctx, page, frontmatter, content_vnode, toc)

  // Apply syntax highlighting if highlighter is available
  let final_html = match highlighter {
    Some(h) => apply_syntax_highlighting(html, h)
    None => html
  }

  // Write to output
  let output_path = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    @routes.url_to_output_path(page.url_path),
  )

  // Ensure parent directory exists
  let parent_dir = @path.dirname(output_path)
  ensure_dir(parent_dir)
  try {
    @fs.writeFileSync(output_path, @js.any(final_html))
    Ok(final_html)
  } catch {
    e => Err("Failed to write \{output_path}: \{e}")
  }
}
