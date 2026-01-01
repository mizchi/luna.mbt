// Static Site Generator - Main Render Pipeline

// =============================================================================
// Helper Functions (same pattern as transformer.mbt)
// =============================================================================

///|
/// Create a server-side element
fn h(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]],
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///|
/// Create a static attribute
fn attr(key : String, value : String) -> (String, @luna.Attr[Unit]) {
  (key, @luna.attr_static(value))
}

///|
/// Transform internal links in HTML content
/// Converts numeric prefix paths like /00_introduction/ to /introduction/
fn transform_internal_links(html : String, trailing_slash : Bool) -> String {
  // Simple regex-like replacement for href="/NN_name/" patterns
  // We need to find href="..." attributes and transform the paths
  let buf = StringBuilder::new()
  let chars = html.to_array()
  let len = chars.length()
  let mut i = 0
  while i < len {
    // Look for href=" or src="
    if i + 6 < len &&
      chars[i] == 'h' &&
      chars[i + 1] == 'r' &&
      chars[i + 2] == 'e' &&
      chars[i + 3] == 'f' &&
      chars[i + 4] == '=' &&
      chars[i + 5] == '"' {
      // Found href="
      buf.write_string("href=\"")
      i = i + 6
      // Read the URL until closing quote
      let url_start = i
      while i < len && chars[i] != '"' {
        i = i + 1
      }
      let url = String::from_array(chars[url_start:i])
      // Transform the URL if it's an internal link
      let transformed = transform_url_path(url, trailing_slash)
      buf.write_string(transformed)
    } else {
      buf.write_char(chars[i])
      i = i + 1
    }
  }
  buf.to_string()
}

///|
/// Transform a URL path by removing numeric prefixes from path segments
/// e.g., /00_introduction/01_overview/ -> /introduction/overview/
fn transform_url_path(url : String, trailing_slash : Bool) -> String {
  // Only transform internal absolute paths starting with /
  if not(url.has_prefix("/")) || url.has_prefix("//") {
    return url
  }
  // Split by / and process each segment
  let segments = url.split("/").collect()
  let result : Array[String] = []
  for segment in segments {
    if segment.is_empty() {
      result.push("")
    } else {
      // Remove numeric prefix (e.g., "00_intro" -> "intro", "01_getting-started" -> "getting-started")
      let (_, name) = @ssg.parse_numeric_prefix(segment.to_string())
      result.push(name)
    }
  }
  let path = result.join("/")
  // Ensure trailing slash consistency
  if trailing_slash && not(path.has_suffix("/")) && not(path.contains(".")) {
    path + "/"
  } else {
    path
  }
}

///|
/// Try to render a component from its compiled module (async)
/// Returns Some(vnode) if successful, None if component cannot be loaded
async fn render_component_ssr_async(
  cwd : String,
  source_path : String,
) -> @luna.Node[Unit]? {
  let component_name = get_component_name_from_path(source_path)

  // Get parent project root (for examples that are subdirectories)
  let parent_root = @path.dirname(@path.dirname(cwd))

  // Try multiple possible locations for the compiled component
  let possible_paths = [
    // 1. Direct component name (most common for standalone projects)
    @path.join2(
      @path.join2(cwd, "target/js/release/build"),
      component_name + "/" + component_name + ".js",
    ),
    // 2. Standard docs directory convention
    @path.join2(
      @path.join2(cwd, "target/js/release/build/docs"),
      source_path + "/" + component_name + ".js",
    ),
    // 3. Flat structure (component directly in docs build)
    @path.join2(
      @path.join2(cwd, "target/js/release/build/docs"),
      component_name + "/" + component_name + ".js",
    ),
    // 4. Tests directory (for testing SSR)
    @path.join2(
      @path.join2(cwd, "target/js/release/build/tests"),
      component_name + "/" + component_name + ".js",
    ),
    // 5. Source-relative build
    @path.join2(
      @path.join2(cwd, "target/js/release/build"),
      source_path + "/" + component_name + ".js",
    ),
    // 6. Parent project's tests directory (for examples in subdirectories)
    @path.join2(
      @path.join2(parent_root, "target/js/release/build/tests"),
      component_name + "/" + component_name + ".js",
    ),
    // 7. Parent project's source build
    @path.join2(
      @path.join2(parent_root, "target/js/release/build"),
      source_path + "/" + component_name + ".js",
    ),
  ]

  // Find first existing module
  let mut module_path : String? = None
  for path in possible_paths {
    if @fs.existsSync(path) {
      module_path = Some(path)
      break
    }
  }

  // Check if any module was found
  guard module_path is Some(path) else {
    println(
      "  Warning: Component '\{component_name}' not compiled. Tried paths:",
    )
    for p in possible_paths {
      println("    - \{p}")
    }
    return None
  }

  // Load the module and call render()
  match load_component_module(path) {
    Some(vnode) => {
      println("  SSR: Component '\{component_name}' rendered successfully")
      Some(vnode)
    }
    None => {
      println(
        "  Warning: Component '\{component_name}' has no render() function",
      )
      None
    }
  }
}

///|
/// Load a component module and call its render() function
/// Uses dynamic import and expects the module to export a render() function
async fn load_component_module(module_path : String) -> @luna.Node[Unit]? {
  ffi_load_component_render(module_path).wait()
}

///|
/// FFI to dynamically import a component module and call render()
/// Returns a Promise that resolves to the VNode or undefined
extern "js" fn ffi_load_component_render(
  module_path : String,
) -> @js.Promise[@luna.Node[Unit]?] =
  #| async (modulePath) => {
  #|   try {
  #|     // Use file:// URL for Node.js dynamic import
  #|     const fileUrl = 'file://' + modulePath;
  #|     const mod = await import(fileUrl);
  #|     if (typeof mod.render === 'function') {
  #|       return mod.render();
  #|     }
  #|     return undefined;
  #|   } catch (e) {
  #|     console.error('  Error loading component:', e.message);
  #|     return undefined;
  #|   }
  #| }

///|
/// Synchronous wrapper for component SSR (for backwards compatibility)
/// Falls back to placeholder if async loading is not available
fn render_component_ssr(
  _cwd : String,
  source_path : String,
) -> @luna.Node[Unit]? {
  let component_name = get_component_name_from_path(source_path)
  println("  Info: Component '\{component_name}' - use async build for SSR")
  None
}

// =============================================================================
// TSX Component SSR
// =============================================================================

///|
/// Render a TSX component via Node.js (async)
/// Looks for <dirname>.tsx or index.tsx and calls its default export
async fn render_tsx_component_ssr_async(
  cwd : String,
  docs_dir : String,
  source_path : String,
) -> @luna.Node[Unit]? {
  let component_name = get_component_name_from_path(source_path)

  // Build the TSX file path
  // Try <component_name>.tsx first, then index.tsx
  let tsx_path = @path.join2(
    @path.join2(@path.join2(cwd, docs_dir), source_path),
    component_name + ".tsx",
  )
  let tsx_index_path = @path.join2(
    @path.join2(@path.join2(cwd, docs_dir), source_path),
    "index.tsx",
  )
  let actual_path = if @fs.existsSync(tsx_path) {
    tsx_path
  } else if @fs.existsSync(tsx_index_path) {
    tsx_index_path
  } else {
    println(
      "  Warning: TSX component '\{component_name}' not found at \{tsx_path}",
    )
    return None
  }

  // Call Node.js to render the TSX component
  match load_tsx_component(actual_path) {
    Some(html) => {
      println("  SSR: TSX component '\{component_name}' rendered successfully")
      Some(@luna.raw_html(html))
    }
    None => {
      println("  Warning: TSX component '\{component_name}' SSR failed")
      None
    }
  }
}

///|
/// Load and render a TSX component via FFI
async fn load_tsx_component(tsx_path : String) -> String? {
  ffi_render_tsx_component(tsx_path).wait()
}

///|
/// FFI to render a TSX component using Node.js
/// Uses esbuild to transform TSX and React to render
extern "js" fn ffi_render_tsx_component(
  tsx_path : String,
) -> @js.Promise[String?] =
  #| async (tsxPath) => {
  #|   try {
  #|     const fs = await import('fs');
  #|     const path = await import('path');
  #|     const { createRequire } = await import('module');
  #|
  #|     // Find workspace root by looking for pnpm-workspace.yaml or package.json
  #|     const findWorkspaceRoot = (startDir) => {
  #|       let dir = startDir;
  #|       while (dir !== path.dirname(dir)) {
  #|         if (fs.existsSync(path.join(dir, 'pnpm-workspace.yaml'))) return dir;
  #|         if (fs.existsSync(path.join(dir, 'pnpm-lock.yaml'))) return dir;
  #|         dir = path.dirname(dir);
  #|       }
  #|       return startDir; // fallback to start dir
  #|     };
  #|
  #|     // Create require function relative to workspace root (for pnpm hoisted deps)
  #|     const workspaceRoot = findWorkspaceRoot(path.dirname(tsxPath));
  #|     const rootRequire = createRequire(path.join(workspaceRoot, 'package.json'));
  #|
  #|     // Load dependencies from workspace root node_modules
  #|     const esbuild = rootRequire('esbuild');
  #|     const React = rootRequire('react');
  #|     const ReactDOMServer = rootRequire('react-dom/server');
  #|
  #|     // Read TSX source
  #|     const source = fs.readFileSync(tsxPath, 'utf-8');
  #|
  #|     // Transform TSX to JS using esbuild
  #|     const result = await esbuild.transform(source, {
  #|       loader: 'tsx',
  #|       jsx: 'automatic',
  #|       format: 'esm',
  #|       target: 'node18',
  #|     });
  #|
  #|     // Write to temp file and import
  #|     const tempDir = path.dirname(tsxPath);
  #|     const tempFile = path.join(tempDir, '.tsx_temp_' + Date.now() + '.mjs');
  #|     fs.writeFileSync(tempFile, result.code);
  #|
  #|     try {
  #|       const mod = await import('file://' + tempFile);
  #|       const Component = mod.default;
  #|       if (!Component) {
  #|         console.error('  TSX: No default export found');
  #|         return undefined;
  #|       }
  #|
  #|       const element = React.createElement(Component);
  #|       const html = ReactDOMServer.renderToString(element);
  #|       return html;
  #|     } finally {
  #|       // Cleanup temp file
  #|       try { fs.unlinkSync(tempFile); } catch {}
  #|     }
  #|   } catch (e) {
  #|     console.error('  TSX SSR error:', e.message);
  #|     return undefined;
  #|   }
  #| }

///|
/// Extract component name from source path
/// e.g., "counter" from "counter/" or "my-component" from "my-component/"
fn get_component_name_from_path(source_path : String) -> String {
  // Remove trailing slash if present
  let path = if source_path.has_suffix("/") {
    let len = source_path.length()
    let buf = StringBuilder::new()
    let mut idx = 0
    for c in source_path {
      if idx < len - 1 {
        buf.write_char(c)
      }
      idx = idx + 1
    }
    buf.to_string()
  } else {
    source_path
  }

  // Get last segment of path
  let mut last_slash = -1
  let mut idx = 0
  for c in path {
    if c == '/' {
      last_slash = idx
    }
    idx = idx + 1
  }
  if last_slash >= 0 && last_slash < path.length() - 1 {
    @utils.slice_view_from(path, last_slash + 1)
  } else {
    path
  }
}

///|
/// Simple CSS minification - removes excessive whitespace
fn minify_css(css : String) -> String {
  // Simple whitespace normalization using string operations
  css
  .replace(old="\n", new=" ")
  .replace(old="\r", new="")
  .replace(old="\t", new=" ")
  .replace(old="  ", new=" ")
  .replace(old="  ", new=" ")
  .replace(old="  ", new=" ")
  .replace(old=" {", new="{")
  .replace(old="{ ", new="{")
  .replace(old=" }", new="}")
  .replace(old="} ", new="}")
  .replace(old=" :", new=":")
  .replace(old=": ", new=":")
  .replace(old=" ;", new=";")
  .replace(old="; ", new=";")
}

// =============================================================================
// Site Generation
// =============================================================================

///|
/// Generate entire static site (sync version, requires pre-created highlighter for syntax highlighting)
/// Use generate_site_async or generate_site_with_highlighter for syntax highlighting
pub fn generate_site(
  config : @ssg.SsgConfig,
  cwd : String,
) -> Result[Unit, String] {
  generate_site_internal(config, cwd, None)
}

///|
/// Generate entire static site with Shiki syntax highlighting (async)
/// Supports async component SSR loading
pub async fn generate_site_async(
  config : @ssg.SsgConfig,
  cwd : String,
) -> Result[Unit, String] {
  // Create Shiki highlighter
  let highlighter = @shiki.create_default_highlighter().wait()
  generate_site_internal_async(config, cwd, Some(highlighter))
}

///|
/// Generate entire static site with pre-created highlighter
pub fn generate_site_with_highlighter(
  config : @ssg.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter,
  is_dev? : Bool = false,
) -> Result[Unit, String] {
  generate_site_internal(config, cwd, Some(highlighter), is_dev~)
}

///|
/// Generate a single page (for incremental builds in dev mode)
pub fn generate_single_page(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  highlighter : @shiki.Highlighter,
) -> Result[Unit, String] {
  generate_page_with_highlight(ctx, page, Some(highlighter))
}

///|
/// Internal site generation
fn generate_site_internal(
  config : @ssg.SsgConfig,
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
  if not(unresolved.is_empty()) {
    let errors = unresolved.map(@routes.format_duplicate_error)
    return Err("Unresolvable duplicate pages:\n" + errors.join("\n"))
  }

  // Step 2: Generate sidebar
  let sidebar = match config.sidebar {
    @ssg.SidebarConfig::Auto => @routes.generate_auto_sidebar(pages)
    @ssg.SidebarConfig::Manual(groups) => groups
  }

  // Step 3: Build document tree for navigation
  let doc_tree = Some(@tree.build_document_tree(config, pages, cwd))

  // Step 4: Create build context
  let ctx = @ssg.BuildContext::{
    config,
    pages,
    sidebar,
    cwd,
    doc_tree,
    is_dev,
  }

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
  config : @ssg.SsgConfig,
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
  if not(unresolved.is_empty()) {
    let errors = unresolved.map(@routes.format_duplicate_error)
    return Err("Unresolvable duplicate pages:\n" + errors.join("\n"))
  }

  // Step 2: Generate sidebar
  let sidebar = match config.sidebar {
    @ssg.SidebarConfig::Auto => @routes.generate_auto_sidebar(pages)
    @ssg.SidebarConfig::Manual(groups) => groups
  }

  // Step 3: Build document tree for navigation
  let doc_tree = Some(@tree.build_document_tree(config, pages, cwd))

  // Step 4: Create build context
  let ctx = @ssg.BuildContext::{
    config,
    pages,
    sidebar,
    cwd,
    doc_tree,
    is_dev,
  }

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

///|
/// Parse dynamic source path to extract actual file path and params
/// Format: "path/to/_slug_/index.md?slug=value" -> ("path/to/_slug_/index.md", {"slug": "value"})
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

      // Parse query params (simple key=value format)
      // Collect iterator to array for indexed access
      let parts : Array[StringView] = query.split("=").collect()
      if parts.length() == 2 {
        let key = parts[0].to_string()
        let value = parts[1].to_string()
        params[key] = value
      }
      (file_path, params)
    }
    None => (source_path, params)
  }
}

///|
/// Generate single page with optional syntax highlighting
fn generate_page_with_highlight(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
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
    @ssg.RendererType::MarkdownRenderer => {
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
      let locale_prefix = @ssg.get_locale_url_prefix(
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
    @ssg.RendererType::HtmlRenderer => {
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
    @ssg.RendererType::LunaRenderer => {
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
    @ssg.RendererType::ReactRenderer => {
      // TSX component pages - sync version shows placeholder (use async for SSR)
      let component_name = get_component_name_from_path(page.source_path)
      let placeholder_html = "<div data-tsx-component=\"\{component_name}\" data-ssr=\"pending\" class=\"tsx-component-placeholder\"><p>TSX Component: \{component_name}</p><p>Use async build for TSX SSR</p></div>"
      (page.frontmatter, @luna.raw_html(placeholder_html), [])
    }
    @ssg.RendererType::ClientOnlyRenderer => {
      // Client-only components - render placeholder that will be hydrated
      let component_name = get_component_name_from_path(page.source_path)
      let vnode = match page.content_type {
        @ssg.ContentType::Component => {
          let placeholder_html = "<div data-component=\"\{component_name}\" data-hydrate=\"true\" class=\"component-loading\"><p>Loading \{component_name}...</p></div>"
          @luna.raw_html(placeholder_html)
        }
        @ssg.ContentType::TsxComponent => {
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
    @ssg.RendererType::MdxRenderer => {
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
      let locale_prefix = @ssg.get_locale_url_prefix(
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
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
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
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
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
    @ssg.RendererType::MarkdownRenderer => {
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
      let locale_prefix = @ssg.get_locale_url_prefix(
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
    @ssg.RendererType::HtmlRenderer => {
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
    @ssg.RendererType::LunaRenderer => {
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
    @ssg.RendererType::ReactRenderer => {
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
    @ssg.RendererType::ClientOnlyRenderer => {
      // Client-only components - render placeholder that will be hydrated
      let component_name = get_component_name_from_path(page.source_path)
      let vnode = match page.content_type {
        @ssg.ContentType::Component => {
          let placeholder_html = "<div data-component=\"\{component_name}\" data-hydrate=\"true\" class=\"component-loading\"><p>Loading \{component_name}...</p></div>"
          @luna.raw_html(placeholder_html)
        }
        @ssg.ContentType::TsxComponent => {
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
    @ssg.RendererType::MdxRenderer => {
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
      let locale_prefix = @ssg.get_locale_url_prefix(
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

// =============================================================================
// CSS Utilities Extraction
// =============================================================================

///|
/// Extract CSS utilities from source files using static analysis
/// Returns the extracted CSS string or empty string on failure
async fn extract_css_utilities(
  cwd : String,
  source_dirs : Array[String],
) -> String {
  ffi_extract_css_utilities(cwd, source_dirs).wait()
}

///|
/// FFI to run CSS extraction script (async version for ESM)
/// Uses child_process.execSync to run node src/luna/css/extract.js
extern "js" fn ffi_extract_css_utilities(
  cwd : String,
  source_dirs : Array[String],
) -> @js.Promise[String] =
  #| async (cwd, sourceDirs) => {
  #|   try {
  #|     const cp = await import('child_process');
  #|     const path = await import('path');
  #|     const fs = await import('fs');
  #|
  #|     // Find extract.js script - try multiple locations
  #|     const possiblePaths = [
  #|       // Development: direct path in monorepo
  #|       path.join(cwd, 'src/luna/css/extract.js'),
  #|       // NPM package: bundled with astra
  #|       path.join(cwd, 'node_modules/@luna_ui/astra/css/extract.js'),
  #|       // Parent project (when running from examples/)
  #|       path.join(cwd, '../src/luna/css/extract.js'),
  #|       path.join(cwd, '../../src/luna/css/extract.js'),
  #|     ];
  #|
  #|     let extractScript = null;
  #|     for (const p of possiblePaths) {
  #|       if (fs.existsSync(p)) {
  #|         extractScript = p;
  #|         break;
  #|       }
  #|     }
  #|
  #|     if (!extractScript) {
  #|       // Script not found - silently return empty
  #|       return '';
  #|     }
  #|
  #|     // Build command with all source directories
  #|     const dirs = sourceDirs.filter(d => {
  #|       const fullPath = path.join(cwd, d);
  #|       return fs.existsSync(fullPath);
  #|     });
  #|
  #|     if (dirs.length === 0) {
  #|       return '';
  #|     }
  #|
  #|     // Run extraction for each directory and combine results
  #|     let allCss = '';
  #|     for (const dir of dirs) {
  #|       try {
  #|         const fullDir = path.join(cwd, dir);
  #|         const result = cp.execSync(`node "${extractScript}" "${fullDir}" --no-warn`, {
  #|           cwd: cwd,
  #|           encoding: 'utf-8',
  #|           stdio: ['pipe', 'pipe', 'pipe'],
  #|         });
  #|         if (result && result.trim()) {
  #|           allCss += result.trim() + '\n';
  #|         }
  #|       } catch (e) {
  #|         // Ignore errors for individual directories
  #|       }
  #|     }
  #|
  #|     return allCss.trim();
  #|   } catch (e) {
  #|     console.error('CSS extraction failed:', e.message);
  #|     return '';
  #|   }
  #| }

///|
/// CSS manifest entry from split extraction
pub(all) struct CssManifestEntry {
  css : String
  size : Int
} derive(FromJson, ToJson)

///|
/// CSS split manifest result
pub(all) struct CssSplitManifest {
  entries : Map[String, CssManifestEntry]
  shared_css : String
  shared_size : Int
} derive(FromJson, ToJson)

// =============================================================================
// HTML Building
// =============================================================================

///|
/// Build complete HTML page
fn build_page_html(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit],
  toc : Array[@markdown.TocItem],
) -> String {
  // Determine layout
  let layout = frontmatter.layout.unwrap_or("doc")

  // Build page VNode based on layout
  let page_vnode = match layout {
    "home" => build_home_layout(ctx, page, frontmatter, content)
    "default" => build_default_layout(ctx, page, frontmatter, content)
    "blog" => build_blog_layout(ctx, page, frontmatter, content)
    "blog-post" => build_blog_post_layout(ctx, page, frontmatter, content)
    _ => build_doc_layout(ctx, page, frontmatter, content, toc)
  }

  // Render to HTML string
  let result = @render.render_to_string(page_vnode, preload=true)

  // Wrap in full HTML document
  build_html_document(ctx, page, frontmatter, result)
}

///|
/// Build home layout (landing page)
fn build_home_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  _frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit],
) -> @luna.Node[Unit] {
  let nav = @components.build_nav(ctx, page)
  let main = h("main", [attr("class", "home-content")], [content])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-home")], [nav, main, footer])
}

///|
/// Build default layout (nav + content)
fn build_default_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  _frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit],
) -> @luna.Node[Unit] {
  let nav = @components.build_nav(ctx, page)
  let main = h("main", [attr("class", "main-content")], [content])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-default")], [nav, main, footer])
}

///|
/// Build blog layout (nav + post list)
/// Used for blog index pages that list all posts
fn build_blog_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  _frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit],
) -> @luna.Node[Unit] {
  let nav = @components.build_nav(ctx, page)

  // Page content (from markdown)
  let intro = h("div", [attr("class", "blog-intro")], [content])

  // Blog post list
  let post_list = @components.build_blog_post_list(ctx, None, false)

  // Tags cloud (collect all tags)
  let all_tags = collect_all_tags(ctx.pages)
  let tags_section = if not(all_tags.is_empty()) {
    h("aside", [attr("class", "blog-tags-section")], [
      h("h3", [], [@luna.text("Tags")]),
      @components.build_tag_list(all_tags),
    ])
  } else {
    @luna.fragment([])
  }
  let main = h("main", [attr("class", "blog-content")], [
    h("div", [attr("class", "blog-container")], [
      h("div", [attr("class", "blog-main")], [intro, post_list]),
      tags_section,
    ]),
  ])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-blog")], [nav, main, footer])
}

///|
/// Collect all unique tags from blog posts
fn collect_all_tags(pages : Array[@ssg.PageMeta]) -> Array[String] {
  let tags_set : Map[String, Bool] = {}
  for page in pages {
    let fm = page.frontmatter
    if fm.date is Some(_) && not(fm.draft) {
      for tag in fm.tags {
        tags_set[tag] = true
      }
    }
  }
  tags_set.keys().collect()
}

///|
/// Build blog post layout (nav + article with meta)
/// Used for individual blog posts
fn build_blog_post_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit],
) -> @luna.Node[Unit] {
  let nav = @components.build_nav(ctx, page)

  // Post header with meta
  let title = frontmatter.title.unwrap_or("Untitled")
  let date = frontmatter.date.unwrap_or("")
  let author = frontmatter.author.unwrap_or("")
  let header_children : Array[@luna.Node[Unit]] = []

  // Cover image
  if frontmatter.cover_image is Some(src) {
    header_children.push(
      h("div", [attr("class", "post-cover")], [
        h("img", [attr("src", src), attr("alt", title)], []),
      ]),
    )
  }

  // Title
  header_children.push(
    h("h1", [attr("class", "post-title")], [@luna.text(title)]),
  )

  // Meta (date, author)
  if not(date.is_empty()) || not(author.is_empty()) {
    header_children.push(@components.build_post_meta(date, author, None))
  }

  // Tags
  if not(frontmatter.tags.is_empty()) {
    header_children.push(@components.build_tag_list(frontmatter.tags))
  }
  let header = h("header", [attr("class", "post-header")], header_children)

  // Article content
  let article = h("article", [attr("class", "post-content markdown-body")], [
    content,
  ])

  // Prev/Next navigation
  let prev_next = @components.build_prev_next(ctx, page)
  let main = h("main", [attr("class", "blog-post-main")], [
    h("div", [attr("class", "blog-post-container")], [
      header, article, prev_next,
    ]),
  ])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-blog-post")], [nav, main, footer])
}

///|
/// Build doc layout (nav + sidebar + content + toc)
fn build_doc_layout(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  content : @luna.Node[Unit],
  toc : Array[@markdown.TocItem],
) -> @luna.Node[Unit] {
  let nav = @components.build_nav(ctx, page)

  // Sidebar (filtered by current locale)
  let sidebar_groups = @routes.get_sidebar_for_path(
    ctx.config,
    ctx.pages,
    page.url_path,
    locale=page.locale,
  )
  let sidebar = if frontmatter.sidebar {
    @routes.render_sidebar(sidebar_groups, page.url_path)
  } else {
    @luna.fragment([])
  }

  // Mobile sidebar dropdown
  let mobile_sidebar = if frontmatter.sidebar {
    @routes.render_mobile_sidebar(sidebar_groups, page.url_path)
  } else {
    @luna.fragment([])
  }

  // Breadcrumb
  let breadcrumb = @components.build_breadcrumb(ctx, page)

  // Main content
  let article = h("article", [attr("class", "doc-content markdown-body")], [
    content,
  ])

  // TOC (outline)
  let toc_vnode = if not(toc.is_empty()) {
    @components.build_toc(toc)
  } else {
    @luna.fragment([])
  }

  // Prev/Next navigation
  let prev_next = @components.build_prev_next(ctx, page)
  let main = h("main", [attr("class", "doc-main")], [
    mobile_sidebar, breadcrumb, article, prev_next,
  ])
  let content_wrapper = h("div", [attr("class", "doc-container")], [
    sidebar, main, toc_vnode,
  ])
  let footer = @components.build_footer(ctx)
  h("div", [attr("class", "layout layout-doc")], [nav, content_wrapper, footer])
}

// =============================================================================
// HTML Document
// =============================================================================

///|
/// Build complete HTML document
fn build_html_document(
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
  render_result : @render.SSRResult,
) -> String {
  let html = StringBuilder::new()
  let page_title = frontmatter.title.unwrap_or(ctx.config.title)
  let desc = frontmatter.description.unwrap_or("")
  let base = ctx.config.base_url
  let primary = ctx.config.theme.primary_color.unwrap_or("#3451b2")

  // === HEAD: Document metadata ===
  html.write_string("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n")
  html.write_string("  <meta charset=\"UTF-8\">\n")
  html.write_string("  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n")
  html.write_string("  <title>\{page_title}</title>\n")

  // Description meta tag
  if not(desc.is_empty()) {
    html.write_string("  <meta name=\"description\" content=\"\{desc}\">\n")
  }

  // Robots meta tag
  if frontmatter.noindex {
    html.write_string("  <meta name=\"robots\" content=\"noindex\">\n")
  }

  // OGP meta tags
  write_ogp_meta_tags(html, ctx, page, frontmatter)

  // Custom OGP text
  if ctx.config.ogp_text is Some(text) {
    html.write_string("  \{text}\n")
  }

  // === HEAD: Preload and prefetch ===
  html.write_string("  <link rel=\"modulepreload\" href=\"\{base}assets/loader.js\">\n")

  // Preload tags for islands
  if render_result.preload_urls.length() > 0 {
    html.write_string(@render.generate_preload_tags(render_result.preload_urls))
  }

  // Prefetch prev/next pages
  write_prefetch_tags(html, ctx.pages, page.url_path)

  // === HEAD: Critical inline scripts ===
  // Theme script (runs early to prevent flash of unstyled content)
  let theme_script = @assets.get_theme_script()
  html.write_string("  <script>\{theme_script}</script>\n")

  // === HEAD: Inline critical CSS ===
  let combined_css = build_combined_css(ctx.config, primary)
  html.write_string("  <style>\{combined_css}</style>\n")

  // Custom head snippets
  for snippet in ctx.config.head_snippets {
    html.write_string("  \{snippet}\n")
  }

  html.write_string("</head>\n")

  // === BODY: Content ===
  html.write_string("<body>\n")
  html.write_string("  <div id=\"app\">\{render_result.html}</div>\n")

  // === BODY: Deferred scripts ===
  // Island loader (module, async)
  html.write_string("  <script type=\"module\" async src=\"\{base}assets/loader.js\"></script>\n")

  // Web Components loader
  html.write_string(@assets.get_wc_loader_script())
  html.write_string("\n")

  // Navigation script (keyboard shortcuts, View Transitions)
  let page_order = get_page_order(ctx.pages, page.locale)
  html.write_string(@assets.build_navigation_script(page_order, ctx.config.navigation))
  html.write_string("\n")

  // Sidebar state persistence
  html.write_string(@assets.get_sidebar_script())
  html.write_string("\n")

  // TOC scroll spy
  html.write_string(@assets.get_toc_script())
  html.write_string("\n")

  // Custom body snippets
  for snippet in ctx.config.body_snippets {
    html.write_string("  \{snippet}\n")
  }

  // Production-only body snippets (analytics, etc.)
  if not(ctx.is_dev) {
    for snippet in ctx.config.prod_body_snippets {
      html.write_string("  \{snippet}\n")
    }
  }

  html.write_string("</body>\n</html>")
  html.to_string()
}

///|
/// Build combined CSS with minification
fn build_combined_css(config : @ssg.SsgConfig, primary : String) -> String {
  let main_css = @assets.get_default_css(config)
  let markdown_css = @assets.get_github_markdown_css()
  let shiki_css = @shiki.generate_shiki_css()
  let all_css = main_css + "\n" + markdown_css + "\n" + shiki_css
  let minified = minify_css(all_css)
  "\{minified}:root{--primary-color:\{primary};}"
}

///|
/// Write prefetch tags for prev/next pages
fn write_prefetch_tags(
  html : StringBuilder,
  pages : Array[@ssg.PageMeta],
  current_path : String,
) -> Unit {
  if @routes.find_prev_page(pages, current_path) is Some(link) {
    html.write_string("  <link rel=\"prefetch\" href=\"\{link.link}\">\n")
  }
  if @routes.find_next_page(pages, current_path) is Some(link) {
    html.write_string("  <link rel=\"prefetch\" href=\"\{link.link}\">\n")
  }
}

///|
/// Write OGP meta tags to StringBuilder
fn write_ogp_meta_tags(
  html : StringBuilder,
  ctx : @ssg.BuildContext,
  page : @ssg.PageMeta,
  frontmatter : @ssg.Frontmatter,
) -> Unit {
  let ogp = ctx.config.ogp
  let title = frontmatter.title.unwrap_or(ctx.config.title)
  let desc = frontmatter.description.unwrap_or("")

  // og:title (always include)
  html.write_string("  <meta property=\"og:title\" content=\"\{title}\">\n")

  // og:description
  if not(desc.is_empty()) {
    html.write_string("  <meta property=\"og:description\" content=\"\{desc}\">\n")
  }

  // og:type
  let og_type = frontmatter.og_type.unwrap_or("article")
  html.write_string("  <meta property=\"og:type\" content=\"\{og_type}\">\n")

  // og:url
  if ogp.site_url is Some(site_url) {
    html.write_string("  <meta property=\"og:url\" content=\"\{site_url}\{page.url_path}\">\n")
  }

  // og:image
  let image : String? = match frontmatter.image {
    Some(img) => Some(img)
    None => ogp.image
  }
  if image is Some(img) {
    let img_url = match ogp.site_url {
      Some(site_url) =>
        if img.has_prefix("http://") || img.has_prefix("https://") {
          img
        } else if img.has_prefix("/") {
          "\{site_url}\{img}"
        } else {
          "\{site_url}/\{img}"
        }
      None => img
    }
    html.write_string("  <meta property=\"og:image\" content=\"\{img_url}\">\n")
  }

  // og:site_name
  html.write_string("  <meta property=\"og:site_name\" content=\"\{ctx.config.title}\">\n")

  // Twitter Card
  let twitter_card = match frontmatter.twitter_card {
    Some(tc) => tc
    None => ogp.twitter_card.unwrap_or("summary")
  }
  html.write_string("  <meta name=\"twitter:card\" content=\"\{twitter_card}\">\n")
  html.write_string("  <meta name=\"twitter:title\" content=\"\{title}\">\n")

  if not(desc.is_empty()) {
    html.write_string("  <meta name=\"twitter:description\" content=\"\{desc}\">\n")
  }

  // Twitter image
  if image is Some(img) {
    let img_url = match ogp.site_url {
      Some(site_url) =>
        if img.has_prefix("http://") || img.has_prefix("https://") {
          img
        } else if img.has_prefix("/") {
          "\{site_url}\{img}"
        } else {
          "\{site_url}/\{img}"
        }
      None => img
    }
    html.write_string("  <meta name=\"twitter:image\" content=\"\{img_url}\">\n")
  }

  // Twitter site handle
  if ogp.twitter_handle is Some(handle) {
    html.write_string("  <meta name=\"twitter:site\" content=\"\{handle}\">\n")
  }
}

// =============================================================================
// Navigation Script
// =============================================================================

///|
/// Get page order (URL list) for a locale based on sidebar order
fn get_page_order(
  pages : Array[@ssg.PageMeta],
  locale : String,
) -> Array[String] {
  // Generate sidebar groups for this locale to get the correct order
  let sidebar_groups = @routes.generate_auto_sidebar(pages, locale~)
  @routes.get_sidebar_page_order(sidebar_groups)
}

// =============================================================================
// HTML Sanitization
// =============================================================================

///|
/// Sanitize HTML by removing potentially dangerous tags
/// Removes: <script>, <iframe>, <object>, <embed>, <form>, on* event handlers
fn sanitize_html(html : String) -> String {
  sanitize_html_js(html)
}

///|
/// JavaScript implementation of HTML sanitization
extern "js" fn sanitize_html_js(html : String) -> String =
  #| (html) => {
  #|   // Remove script tags and their content
  #|   let result = html.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '');
  #|   // Remove iframe, object, embed tags
  #|   result = result.replace(/<iframe\b[^>]*>.*?<\/iframe>/gi, '');
  #|   result = result.replace(/<object\b[^>]*>.*?<\/object>/gi, '');
  #|   result = result.replace(/<embed\b[^>]*\/?>/gi, '');
  #|   // Remove form tags (keep content)
  #|   result = result.replace(/<\/?form\b[^>]*>/gi, '');
  #|   // Remove on* event handlers from all tags
  #|   result = result.replace(/\s+on\w+\s*=\s*["'][^"']*["']/gi, '');
  #|   result = result.replace(/\s+on\w+\s*=\s*[^\s>]+/gi, '');
  #|   // Remove javascript: URLs
  #|   result = result.replace(/\bhref\s*=\s*["']javascript:[^"']*["']/gi, 'href="#"');
  #|   result = result.replace(/\bsrc\s*=\s*["']javascript:[^"']*["']/gi, 'src=""');
  #|   return result;
  #| }

// =============================================================================
// Utility Functions
// =============================================================================

///|
/// Apply syntax highlighting to code blocks in HTML
/// Finds <pre class="code-block" data-lang="xxx"> elements and highlights them
fn apply_syntax_highlighting(
  html : String,
  highlighter : @shiki.Highlighter,
) -> String {
  apply_syntax_highlighting_js(html, highlighter)
}

///|
/// JS implementation of syntax highlighting
extern "js" fn apply_syntax_highlighting_js(
  html : String,
  highlighter : @shiki.Highlighter,
) -> String =
  #| (html, h) => {
  #|   // Match <pre class="code-block" data-lang="xxx"><code ...>...</code></pre>
  #|   const codeBlockRegex = /<pre class="code-block"(?: data-lang="([^"]*)")?(?: data-filename="([^"]*)")?(?: data-meta="([^"]*)")?><code[^>]*>([\s\S]*?)<\/code><\/pre>/g;
  #|   const aliases = { js: "javascript", ts: "typescript", mbt: "rust", moonbit: "rust", sh: "bash", shell: "bash", yml: "yaml" };
  #|
  #|   let result = html;
  #|   let match;
  #|   const replacements = [];
  #|
  #|   while ((match = codeBlockRegex.exec(html)) !== null) {
  #|     const [fullMatch, lang, filename, meta, codeContent] = match;
  #|     if (!lang) continue;
  #|
  #|     // Decode HTML entities
  #|     const code = codeContent
  #|       .replace(/&lt;/g, '<')
  #|       .replace(/&gt;/g, '>')
  #|       .replace(/&quot;/g, '"')
  #|       .replace(/&#39;/g, "'")
  #|       .replace(/&amp;/g, '&');
  #|
  #|     const resolved = aliases[lang] || lang;
  #|
  #|     // Try to highlight (sync since we preloaded themes)
  #|     try {
  #|       const loaded = h.getLoadedLanguages();
  #|       if (!loaded.includes(resolved)) {
  #|         // Skip if language not loaded (will use fallback styling)
  #|         continue;
  #|       }
  #|       const highlighted = h.codeToHtml(code, {
  #|         lang: resolved,
  #|         themes: { light: "github-light", dark: "github-dark" },
  #|         defaultColor: false,
  #|       });
  #|       replacements.push({ original: fullMatch, replacement: highlighted });
  #|     } catch (e) {
  #|       // Keep original on error
  #|     }
  #|   }
  #|
  #|   // Apply replacements
  #|   for (const { original, replacement } of replacements) {
  #|     result = result.replace(original, replacement);
  #|   }
  #|
  #|   return result;
  #| }

///|
/// Ensure directory exists
fn ensure_dir(path : String) -> Unit {
  @fs.mkdirSync(path, recursive=true) catch {
    _ => ()
  }
}

///|
/// Copy static assets to output directory (sync version, no CSS extraction)
pub fn copy_static_assets(ctx : @ssg.BuildContext) -> Unit {
  copy_static_assets_internal(ctx, "")
}

///|
/// Copy static assets to output directory (async version with CSS extraction)
pub async fn copy_static_assets_async(ctx : @ssg.BuildContext) -> Unit {
  // Get CSS utilities config
  let css_config = ctx.config.css_utilities.unwrap_or(
    @ssg.CssUtilitiesConfig::default(),
  )

  // Get source directories to scan
  let source_dirs = if css_config.source_dirs.is_empty() {
    ["src/astra", "src/luna", ctx.config.docs_dir]
  } else {
    css_config.source_dirs
  }

  // Extract CSS utilities from source files
  let utility_css = if css_config.enabled {
    extract_css_utilities(ctx.cwd, source_dirs)
  } else {
    ""
  }

  // Determine if CSS should be inlined based on threshold
  let css_size = utility_css.length()
  let should_inline = css_size <= css_config.inline_threshold
  if should_inline {
    copy_static_assets_internal(ctx, utility_css)
  } else {
    // Write CSS to separate file and reference it
    let output_assets = @path.join2(
      @path.join2(ctx.cwd, ctx.config.output_dir),
      "assets",
    )
    ensure_dir(output_assets)
    let utility_css_path = @path.join2(output_assets, "utilities.css")
    @fs.writeFileSync(utility_css_path, @js.any(utility_css)) catch {
      _ => ()
    }
    println("  Extracted CSS utilities: \{css_size} bytes (external file)")
    copy_static_assets_internal(ctx, "")
  }
}

///|
/// Internal implementation of copy_static_assets
fn copy_static_assets_internal(
  ctx : @ssg.BuildContext,
  utility_css : String,
) -> Unit {
  let output_assets = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "assets",
  )
  ensure_dir(output_assets)

  // Write default CSS
  let css = @assets.get_default_css(ctx.config)

  // Combine with utility CSS if provided
  let full_css = if utility_css.is_empty() {
    css
  } else {
    println("  Extracted CSS utilities from source files")
    css + "\n/* === CSS Utilities (auto-extracted) === */\n" + utility_css
  }
  let css_path = @path.join2(output_assets, "style.css")
  @fs.writeFileSync(css_path, @js.any(full_css)) catch {
    _ => ()
  }

  // Write shiki CSS
  let shiki_css = @shiki.generate_shiki_css()
  let shiki_css_path = @path.join2(output_assets, "shiki.css")
  @fs.writeFileSync(shiki_css_path, @js.any(shiki_css)) catch {
    _ => ()
  }

  // Write github-markdown CSS
  let github_md_css = @assets.get_github_markdown_css()
  let github_md_css_path = @path.join2(output_assets, "github-markdown.css")
  @fs.writeFileSync(github_md_css_path, @js.any(github_md_css)) catch {
    _ => ()
  }

  // Write loader.js (for island hydration)
  let loader_js = @assets.get_island_loader_js()
  let loader_js_path = @path.join2(output_assets, "loader.js")
  @fs.writeFileSync(loader_js_path, @js.any(loader_js)) catch {
    _ => ()
  }

  // Copy public directory if it exists
  copy_public_dir(ctx)

  // Copy islands directory if configured
  copy_islands_dir(ctx)

  // Copy boot runtime files to _luna/
  copy_boot_runtime(ctx)
}

///|
/// Copy boot runtime files to _luna/ directory
fn copy_boot_runtime(ctx : @ssg.BuildContext) -> Unit {
  // Try to find boot files in various locations
  let possible_sources = [
    // Development: monorepo structure
    @path.join2(ctx.cwd, "js/loader/dist"),
    // NPM package: node_modules
    @path.join2(ctx.cwd, "node_modules/@luna_ui/luna-loader/dist"),
  ]

  // Find first existing source
  let mut boot_src : String? = None
  for src in possible_sources {
    let boot_file = @path.join2(src, "boot.iife.js")
    if @fs.existsSync(boot_file) {
      boot_src = Some(src)
      break
    }
  }

  // Skip if no boot files found
  guard boot_src is Some(src_dir) else { return }

  // Create _luna/ directory
  let luna_dir = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    "_luna",
  )
  ensure_dir(luna_dir)

  // Copy boot.iife.js (self-contained boot runtime)
  let boot_src_file = @path.join2(src_dir, "boot.iife.js")
  let boot_dest_file = @path.join2(luna_dir, "boot.js")
  @fs.copyFileSync(boot_src_file, boot_dest_file) catch {
    e => {
      println("  Warning: Failed to copy boot.js: \{e}")
      return
    }
  }
  println("  Copied: /_luna/boot.js")

  // Optionally copy modular boot files for advanced usage
  let boot_dir = @path.join2(src_dir, "boot")
  if @fs.existsSync(boot_dir) {
    let luna_boot_dir = @path.join2(luna_dir, "boot")
    ensure_dir(luna_boot_dir)
    @fs.cpSync(boot_dir, luna_boot_dir, recursive=true) catch {
      _ => ()
    }
    println("  Copied: /_luna/boot/ (modular)")
  }
}

///|
/// Copy components directory to output (convention: docs/components -> /components/)
fn copy_islands_dir(ctx : @ssg.BuildContext) -> Unit {
  // Use config if provided, otherwise use convention (docs/components)
  let (src_dir, base_path) = match ctx.config.islands {
    Some(islands_config) => (islands_config.dir, islands_config.base_path)
    None => {
      // Convention-based: look for docs/components
      let docs_components = @path.join2(ctx.config.docs_dir, "components")
      (docs_components, "/components/")
    }
  }
  let islands_src = @path.join2(ctx.cwd, src_dir)

  // Check if source directory exists
  if not(@fs.existsSync(islands_src)) {
    // Silently skip if using convention and directory doesn't exist
    return
  }

  // Output path: strip leading slash from base_path
  let output_subdir = if base_path.has_prefix("/") {
    base_path.unsafe_substring(start=1, end=base_path.length())
  } else {
    base_path
  }
  // Remove trailing slash for directory path
  let output_subdir_clean = if output_subdir.has_suffix("/") {
    output_subdir.unsafe_substring(start=0, end=output_subdir.length() - 1)
  } else {
    output_subdir
  }
  let islands_dest = @path.join2(
    @path.join2(ctx.cwd, ctx.config.output_dir),
    output_subdir_clean,
  )

  // Ensure destination directory exists
  ensure_dir(islands_dest)

  // Copy components directory
  println("  Copying components from \{src_dir}...")
  @fs.cpSync(islands_src, islands_dest, recursive=true) catch {
    e => println("  Warning: Failed to copy components directory: \{e}")
  }
}

///|
/// Copy docs/public directory to output root
fn copy_public_dir(ctx : @ssg.BuildContext) -> Unit {
  let public_dir = @path.join2(
    @path.join2(ctx.cwd, ctx.config.docs_dir),
    "public",
  )
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)

  // Check if public directory exists
  if not(@fs.existsSync(public_dir)) {
    return
  }

  // Copy entire public directory contents to output
  println("  Copying public assets...")
  @fs.cpSync(public_dir, output_dir, recursive=true) catch {
    e => println("  Warning: Failed to copy public directory: \{e}")
  }
}

///|
/// Generate meta files (sitemap.xml, feed.xml, llms.txt) using DocumentTree
/// Respects MetaFilesConfig settings - only generates enabled files
pub fn generate_meta_files(
  ctx : @ssg.BuildContext,
  doc_tree : @ssg.DocumentTree,
) -> Unit {
  let output_dir = @path.join2(ctx.cwd, ctx.config.output_dir)
  let meta_config = ctx.config.meta_files

  // Generate sitemap.xml (enabled by default)
  if meta_config.sitemap {
    let sitemap_content = @ssg.generate_sitemap(doc_tree)
    let sitemap_path = @path.join2(output_dir, "sitemap.xml")
    @fs.writeFileSync(sitemap_path, @js.any(sitemap_content)) catch {
      e => println("  Warning: Failed to generate sitemap.xml: \{e}")
    }
    println("  Generated: /sitemap.xml")
  }

  // Generate feed.xml (RSS) - disabled by default
  if meta_config.feed {
    let rss_content = @ssg.generate_rss(doc_tree)
    let rss_path = @path.join2(output_dir, "feed.xml")
    @fs.writeFileSync(rss_path, @js.any(rss_content)) catch {
      e => println("  Warning: Failed to generate feed.xml: \{e}")
    }
    println("  Generated: /feed.xml")
  }

  // Generate llms.txt - disabled by default
  if meta_config.llms_txt {
    let llms_content = @ssg.generate_llms_txt(doc_tree)
    let llms_path = @path.join2(output_dir, "llms.txt")
    @fs.writeFileSync(llms_path, @js.any(llms_content)) catch {
      e => println("  Warning: Failed to generate llms.txt: \{e}")
    }
    println("  Generated: /llms.txt")
  }
}

///|
/// Generate client manifest.json for chunk loading
/// This enables dynamic chunk loading in the client-side router
pub fn generate_client_manifest(ctx : @ssg.BuildContext) -> Unit {
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
  _ctx : @ssg.BuildContext,
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
  ctx : @ssg.BuildContext,
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

///|
/// Generate 404.html page
pub fn generate_404_page(ctx : @ssg.BuildContext) -> Unit {
  let base = ctx.config.base_url
  let title = "Page Not Found"
  let site_title = ctx.config.title
  let primary = ctx.config.theme.primary_color.unwrap_or("#3451b2")
  let theme_script = @assets.get_theme_script()

  // Build 404 page content
  let content =
    #|<div style="display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; text-align: center; padding: 2rem;">
    #|  <h1 style="font-size: 6rem; margin: 0; color: var(--text-muted);">404</h1>
    #|  <h2 style="font-size: 1.5rem; margin: 1rem 0; color: var(--text-color);">Page Not Found</h2>
    #|  <p style="color: var(--text-muted); margin-bottom: 2rem;">The page you're looking for doesn't exist or has been moved.</p>
    #|  <a href="/" style="color: var(--primary-color); text-decoration: none; padding: 0.75rem 1.5rem; border: 1px solid var(--primary-color); border-radius: 0.5rem;">Go to Home</a>
    #|</div>
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
    #|  <style>:root { --primary-color:
  let html5 =
    #|; }</style>
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
    primary +
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
