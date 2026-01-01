// SSG (Static Site Generation) support for Sol CLI
// Handles markdown-based static site generation when ssg config is present

///|
/// Get worker script path from globalThis (set by npm package)
extern "js" fn ffi_get_worker_script() -> String =
  #| () => globalThis.__sol_worker_script || ""

///|
/// Check if SSG mode is enabled in config
pub fn has_ssg_config(cwd : String) -> Bool {
  let fs = @fs_adapter.NodeFsAdapter::new()
  has_ssg_config_with_fs(fs, cwd)
}

///|
fn[FS : @env.FileSystem] has_ssg_config_with_fs(fs : FS, cwd : String) -> Bool {
  // Check all SSG config candidates
  for candidate in @cli_common.ssg_config_candidates {
    let config_path = @path.join2(cwd, candidate)
    if fs.exists_sync(config_path) {
      // sol.config.json with ssg section
      let content = fs.read_file_sync(config_path) catch { _ => continue }
      if content.contains("\"ssg\"") || content.contains("\"docs\"") {
        return true
      }
    }
  }
  false
}

///|
/// Find SSG config file
pub fn find_ssg_config_file(cwd : String) -> String {
  let fs = @fs_adapter.NodeFsAdapter::new()
  @cli_common.find_config(
    fs, cwd, @cli_common.ssg_config_candidates, "sol.config.json",
  )
}

///|
/// Parse SSG config from file content
pub fn parse_ssg_config(
  content : String,
  config_path : String,
) -> @ssg.SsgConfig? {
  // All configs are now sol.config.json format
  if config_path.ends_with("sol.config.json") {
    @ssg.parse_ssg_config(content)
  } else {
    // Fallback to trying direct parse
    @ssg.parse_ssg_config(content)
  }
}

///|
/// Run SSG build (static site generation)
pub async fn run_ssg_build(
  config : @ssg.SsgConfig,
  cwd : String,
  use_parallel : Bool,
  num_workers : Int?,
  force_build : Bool,
) -> Result[Unit, String] {
  // Check for incremental build skip
  let cache_dir = @path.join2(cwd, ".sol-cache")
  if not(force_build) {
    match @ssg_cache.check_local_build_state(config, cwd, cache_dir) {
      @ssg_cache.BuildStateCheck::UpToDate(built_at) => {
        println(
          @colorette.green(
            "  SSG skipped (no changes detected since \{built_at})",
          ),
        )
        println(@colorette.gray("    Use --force to rebuild anyway"))
        return Ok(())
      }
      _ => ()
    }
  }
  println(@colorette.cyan("Building static site..."))
  println(@colorette.gray("  Docs: \{config.docs_dir}"))
  println(@colorette.gray("  Output: \{config.output_dir}"))

  // Determine if parallel build should be used
  let should_parallel = use_parallel || num_workers is Some(_)
  if should_parallel {
    let workers = num_workers.unwrap_or(4)
    println(@colorette.gray("  Mode: parallel (\{workers} workers)"))
    match run_parallel_ssg_build(config, cwd, workers) {
      Ok(_) => {
        @ssg_cache.save_manifest(cache_dir, config, cwd)
        println(@colorette.green("  SSG complete: \{config.output_dir}"))
        Ok(())
      }
      Err(e) => Err(e)
    }
  } else {
    match @ssg_gen.generate_site_async(config, cwd) {
      Ok(_) => {
        @ssg_cache.save_manifest(cache_dir, config, cwd)
        println(@colorette.green("  SSG complete: \{config.output_dir}"))
        Ok(())
      }
      Err(e) => Err(e)
    }
  }
}

///|
/// Internal parallel SSG build implementation
async fn run_parallel_ssg_build(
  config : @ssg.SsgConfig,
  cwd : String,
  num_workers : Int,
) -> Result[Unit, String] {
  // Step 1: Scan docs directory
  let pages = @ssg_routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
    trailing_slash=config.trailing_slash,
  )
  if pages.is_empty() {
    return Err("No markdown files found in \{config.docs_dir}")
  }
  println(@colorette.gray("    Found \{pages.length()} pages"))

  // Step 2: Generate sidebar
  let sidebar = match config.sidebar {
    @ssg.SidebarConfig::Auto => @ssg_routes.generate_auto_sidebar(pages)
    @ssg.SidebarConfig::Manual(groups) => groups
  }

  // Step 3: Create output directory
  let output_dir = @path.join2(cwd, config.output_dir)
  @fs.mkdirSync(output_dir, recursive=true) catch {
    _ => ()
  }

  // Step 4: Worker script path
  let worker_script = {
    let global_path = ffi_get_worker_script()
    if global_path.is_empty() {
      let target = @path.join2(cwd, "target")
      let js = @path.join2(target, "js")
      let release = @path.join2(js, "release")
      let build = @path.join2(release, "build")
      let sol = @path.join2(build, "sol")
      let worker_dir = @path.join2(sol, "worker")
      @path.join2(worker_dir, "worker.js")
    } else {
      global_path
    }
  }

  // Step 5: Run parallel build
  let results = @builder_pool.run_parallel_build(
    config,
    pages,
    sidebar,
    cwd,
    worker_script,
    num_workers~,
  )

  // Step 6: Report results
  for result in results {
    if not(result.success) {
      let error_msg = result.error.unwrap_or("Unknown error")
      println(@colorette.red("    Error: \{result.url_path}: \{error_msg}"))
    }
  }

  // Step 7: Build DocumentTree
  let doc_tree = @tree.build_document_tree(config, pages, cwd)

  // Step 8: Copy static assets
  let ctx = @ssg.BuildContext::{
    config,
    pages,
    sidebar,
    cwd,
    doc_tree: Some(doc_tree),
    is_dev: false, // Production: include prod_body_snippets
  }
  @ssg_gen.copy_static_assets_async(ctx)

  // Step 9: Generate meta files
  @ssg_gen.generate_meta_files(ctx, doc_tree)

  // Step 10: Generate 404 page
  @ssg_gen.generate_404_page(ctx)

  // Step 11: Generate client manifest
  @ssg_gen.generate_client_manifest(ctx)

  // Step 12: Run deploy adapter
  @adapters.run_adapter(ctx)
  Ok(())
}

///|
/// Run SSG dev server with HMR
pub async fn run_ssg_dev(
  config : @ssg.SsgConfig,
  cwd : String,
  port : Int,
) -> Unit {
  // Keep Node.js event loop alive
  @cli_common.keep_alive()
  println(@colorette.cyan("Starting SSG development server..."))
  println("")

  // Create highlighter once for reuse
  let highlighter = @shiki.create_default_highlighter().wait()

  // Initial build
  run_ssg_initial_build(config, cwd, highlighter)

  // Start HMR WebSocket server
  let hmr_port = 24679
  let hmr_server = @hmr.HmrServer::start(hmr_port)

  // Start HTTP server
  let output_dir = @path.join2(cwd, config.output_dir)
  let spa_routes = config.spa_routes
  let server = @http.createServer(requestListener=fn(req, res) {
    serve_ssg_file(req, res, output_dir, hmr_port, spa_routes)
  })
  let _ = server.listen(port, callback=fn() {
    println("")
    println(@colorette.green("SSG dev server running at:"))
    println(@colorette.cyan("  http://localhost:\{port}"))
    println("")
  })

  // Watch docs directory
  let docs_dir = @path.join2(cwd, config.docs_dir)
  println(@colorette.gray("Watching for changes in: \{config.docs_dir}/"))
  println("")

  // Track known pages
  let known_pages : Map[String, Bool] = {}
  let pages = @ssg_routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
    trailing_slash=config.trailing_slash,
  )
  for page in pages {
    known_pages[page.source_path] = true
  }

  // Build context for incremental builds
  let sidebar = match config.sidebar {
    @ssg.SidebarConfig::Auto => @ssg_routes.generate_auto_sidebar(pages)
    @ssg.SidebarConfig::Manual(groups) => groups
  }
  let build_ctx : @ssg.BuildContext = {
    config,
    pages,
    sidebar,
    cwd,
    doc_tree: None,
    is_dev: true, // Dev mode: skip prod_body_snippets
  }

  // Watch for file changes (ignore output directory)
  // Use a flag to prevent concurrent builds and infinite loops
  let is_building : Ref[Bool] = { val: false }
  let last_build_time : Ref[Double] = { val: 0.0 }
  let debounce_ms = 100.0 // Minimum time between builds
  let output_prefix = config.output_dir + "/"
  let cache_prefix = ".sol-cache"
  let _ = @fs.watch(docs_dir, recursive=true, listener=fn(
    event_type,
    filename,
  ) {
    // Ignore changes in output directory to prevent infinite loops
    if filename.has_prefix(output_prefix) ||
      filename.has_prefix(config.output_dir) ||
      filename.has_prefix(cache_prefix) ||
      filename.has_prefix(".sol-cache") {
      return
    }

    // Prevent concurrent builds
    if is_building.val {
      return
    }

    // Debounce rapid changes
    let now = @cli_common.date_now()
    if now - last_build_time.val < debounce_ms {
      return
    }
    if filename.ends_with(".md") || filename.ends_with(".mdx") {
      let source_path = filename
      let full_path = @path.join2(docs_dir, filename)
      let file_exists = @fs.existsSync(full_path)
      let is_known = known_pages.contains(source_path)
      if file_exists && not(is_known) {
        println(
          @colorette.yellow(
            "[\{event_type}] \{filename} - new file, full rebuild...",
          ),
        )
        known_pages[source_path] = true
        is_building.val = true
        last_build_time.val = @cli_common.date_now()
        run_ssg_build_sync(config, cwd, highlighter)
        is_building.val = false
        hmr_server.notify_reload()
      } else if not(file_exists) && is_known {
        println(
          @colorette.yellow(
            "[\{event_type}] \{filename} - deleted, full rebuild...",
          ),
        )
        let _ = known_pages.remove(source_path)
        is_building.val = true
        last_build_time.val = @cli_common.date_now()
        run_ssg_build_sync(config, cwd, highlighter)
        is_building.val = false
        hmr_server.notify_reload()
      } else if file_exists && is_known {
        println(
          @colorette.yellow(
            "[\{event_type}] \{filename} - incremental rebuild...",
          ),
        )
        is_building.val = true
        last_build_time.val = @cli_common.date_now()
        rebuild_ssg_single_page(build_ctx, source_path, highlighter)
        is_building.val = false
        hmr_server.notify_reload()
      }
    } else if filename.ends_with(".json") {
      println(
        @colorette.yellow(
          "[\{event_type}] \{filename} - config change, full rebuild...",
        ),
      )
      is_building.val = true
      last_build_time.val = @cli_common.date_now()
      run_ssg_build_sync(config, cwd, highlighter)
      is_building.val = false
      hmr_server.notify_reload()
    } else if filename.ends_with(".js") {
      println(
        @colorette.yellow("[\{event_type}] \{filename} - copying components..."),
      )
      is_building.val = true
      last_build_time.val = @cli_common.date_now()
      copy_ssg_components(config, cwd)
      is_building.val = false
      hmr_server.notify_reload()
    }
  })

}

///|
fn run_ssg_initial_build(
  config : @ssg.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter,
) -> Unit {
  let cache_dir = @path.join2(cwd, ".sol-cache")
  match @ssg_cache.check_local_build_state(config, cwd, cache_dir) {
    @ssg_cache.BuildStateCheck::UpToDate(built_at) => {
      println(@colorette.green("Build skipped (no changes since \{built_at})"))
      return
    }
    _ => ()
  }
  match
    @ssg_gen.generate_site_with_highlighter(
      config,
      cwd,
      highlighter,
      is_dev=true,
    ) {
    Ok(_) => {
      @ssg_cache.save_manifest(cache_dir, config, cwd)
      println(@colorette.green("Build complete: \{config.output_dir}"))
    }
    Err(e) => @cli_common.console_error(@colorette.red("Build failed: \{e}"))
  }
}

///|
fn run_ssg_build_sync(
  config : @ssg.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter,
) -> Unit {
  match
    @ssg_gen.generate_site_with_highlighter(
      config,
      cwd,
      highlighter,
      is_dev=true,
    ) {
    Ok(_) => {
      let cache_dir = @path.join2(cwd, ".sol-cache")
      @ssg_cache.save_manifest(cache_dir, config, cwd)
      println(@colorette.green("Rebuild complete"))
      println("")
    }
    Err(e) => @cli_common.console_error(@colorette.red("Build failed: \{e}"))
  }
}

///|
fn rebuild_ssg_single_page(
  ctx : @ssg.BuildContext,
  source_path : String,
  highlighter : @shiki.Highlighter,
) -> Unit {
  let page : @ssg.PageMeta? = ctx.pages
    .iter()
    .find_first(fn(p) { p.source_path == source_path })
  guard page is Some(page_meta) else {
    println(@colorette.red("  Page not found: \{source_path}"))
    return
  }
  match @ssg_gen.generate_single_page(ctx, page_meta, highlighter) {
    Ok(_) => {
      println(@colorette.green("Page rebuilt: \{page_meta.url_path}"))
      println("")
    }
    Err(e) => @cli_common.console_error(@colorette.red("Build failed: \{e}"))
  }
}

///|
fn copy_ssg_components(config : @ssg.SsgConfig, cwd : String) -> Unit {
  let (src_dir, base_path) = match config.islands {
    Some(islands_config) => (islands_config.dir, islands_config.base_path)
    None => {
      let docs_components = @path.join2(config.docs_dir, "components")
      (docs_components, "/components/")
    }
  }
  let src = @path.join2(cwd, src_dir)
  if not(@fs.existsSync(src)) {
    return
  }
  let output_subdir = if base_path.has_prefix("/") {
    base_path.substring(start=1)
  } else {
    base_path
  }
  let output_subdir_clean = if output_subdir.has_suffix("/") {
    output_subdir.substring(end=output_subdir.length() - 1)
  } else {
    output_subdir
  }
  let dest = @path.join2(
    @path.join2(cwd, config.output_dir),
    output_subdir_clean,
  )

  // Bundle components with rolldown instead of just copying
  bundle_ssg_components(src, dest, cwd)
}

///|
/// Find js/luna/src path by checking current and parent directories
fn find_luna_path(start_dir : String) -> String {
  // Check current directory and up to 3 parent levels
  let mut dir = start_dir
  for _ in 0..<4 {
    let luna_src = @path.join2(dir, "js/luna/src")
    if @fs.existsSync(luna_src) {
      return luna_src
    }
    // Go up one level
    let parent = @path.dirname(dir)
    if parent == dir {
      // Reached root
      break
    }
    dir = parent
  }
  // Fallback - assume it's in the current directory structure
  @path.join2(start_dir, "js/luna/src")
}

///|
/// Bundle SSG components using rolldown
fn bundle_ssg_components(src_dir : String, dest_dir : String, cwd : String) -> Unit {
  // Scan for JS/TS files in source directory
  let entries : Array[String] = @fs.readdirSync(src_dir) catch { _ => [] }

  // Filter for bundleable files
  let js_files : Array[String] = []
  for entry in entries {
    if entry.ends_with(".js") || entry.ends_with(".ts") {
      js_files.push(entry)
    }
  }

  if js_files.is_empty() {
    println(@colorette.gray("  No components to bundle"))
    return
  }

  // Create rolldown input object
  let input_entries : Array[String] = []
  for file in js_files {
    let name = if file.ends_with(".js") {
      file.substring(end=file.length() - 3)
    } else {
      file.substring(end=file.length() - 3) // .ts
    }
    let entry_path = @path.join2(src_dir, file)
    input_entries.push("\"\{name}\": \"\{entry_path}\"")
  }
  let input_obj = "{ " + input_entries.join(", ") + " }"

  // Generate rolldown build script
  // Find js/luna path by checking current and parent directories
  let luna_path = find_luna_path(cwd)
  let build_script =
    #|import { build } from 'rolldown';
    #|await build({
    #|  input: __INPUT__,
    #|  output: {
    #|    dir: '__OUTPUT__',
    #|    format: 'esm',
    #|    entryFileNames: '[name].js',
    #|    chunkFileNames: '_shared/[name]-[hash].js'
    #|  },
    #|  resolve: {
    #|    extensions: ['.ts', '.js', '.mjs'],
    #|    alias: {
    #|      '@luna': '__LUNA_PATH__'
    #|    }
    #|  }
    #|});
  let script = build_script
    .replace(old="__INPUT__", new=input_obj)
    .replace(old="__OUTPUT__", new=dest_dir)
    .replace(old="__LUNA_PATH__", new=luna_path)

  // Run rolldown
  try {
    let result = @child_process.spawnSync(
      "node",
      args=["--input-type=module", "-e", script],
      stdio="inherit",
      cwd~,
    )
    if result.status() != Some(0) {
      println(@colorette.red("  Failed to bundle components"))
      return
    }
    println(@colorette.green("Components bundled (\{js_files.length()} files)"))
    println("")
  } catch {
    e => {
      println(@colorette.red("  Bundle error: \{e}"))
    }
  }
}

///|
fn hmr_client_script(port : Int) -> String {
  let script =
    #|<script>
    #|(function() {
    #|  const ws = new WebSocket('ws://localhost:__HMR_PORT__');
    #|  ws.onmessage = (e) => {
    #|    const data = JSON.parse(e.data);
    #|    if (data.type === 'reload') {
    #|      console.log('[HMR] Reloading...');
    #|      location.reload();
    #|    }
    #|  };
    #|  ws.onopen = () => console.log('[HMR] Connected');
    #|  ws.onclose = () => console.log('[HMR] Disconnected');
    #|})();
    #|</script>
  script.replace(old="__HMR_PORT__", new=port.to_string())
}

///|
fn serve_ssg_file(
  req : @http.IncomingMessage,
  res : @http.ServerResponse,
  output_dir : String,
  hmr_port : Int,
  spa_routes : Array[String],
) -> Unit {
  let url = req.url.or("/")
  let parts : Array[String] = url
    .split("?")
    .map(fn(v) { v.to_string() })
    .collect()
  let path_part = if parts.length() > 0 { parts[0] } else { "/" }
  let base_path = @path.join2(output_dir, path_part)

  // Security: prevent directory traversal
  if not(base_path.starts_with(output_dir)) {
    res.writeHead(403) |> ignore
    res.end(data="Forbidden")
    return
  }

  // Try different file resolutions
  if @fs.existsSync(base_path) && path_part.contains(".") {
    serve_with_hmr(res, base_path, hmr_port)
    return
  }
  let index_path = @path.join2(base_path, "index.html")
  if @fs.existsSync(index_path) {
    serve_with_hmr(res, index_path, hmr_port)
    return
  }
  let html_path = base_path + ".html"
  if @fs.existsSync(html_path) {
    serve_with_hmr(res, html_path, hmr_port)
    return
  }
  if @fs.existsSync(base_path) {
    serve_with_hmr(res, base_path, hmr_port)
    return
  }

  // SPA fallback
  for spa_route in spa_routes {
    if path_part.starts_with(spa_route) {
      let spa_index = @path.join2(
        @path.join2(output_dir, spa_route),
        "index.html",
      )
      if @fs.existsSync(spa_index) {
        serve_with_hmr(res, spa_index, hmr_port)
        return
      }
    }
  }
  res.writeHead(404) |> ignore
  res.end(data="Not Found: \{path_part}")
}

///|
fn serve_with_hmr(
  res : @http.ServerResponse,
  file_path : String,
  hmr_port : Int,
) -> Unit {
  let content : String = @fs.readFileSync(file_path).to_string() catch {
    _ => {
      res.writeHead(500) |> ignore
      res.end(data="Internal Server Error")
      return
    }
  }
  let content_type = @cli_common.get_content_type(file_path)
  res.setHeader("Content-Type", content_type)
  res.setHeader("Cache-Control", "no-cache")
  res.writeHead(200) |> ignore
  if file_path.ends_with(".html") {
    let hmr_script = hmr_client_script(hmr_port)
    let injected = content.replace(old="</body>", new=hmr_script + "</body>")
    res.end(data=injected)
  } else {
    res.end(data=content)
  }
}

// =============================================================================
// SSG Lint
// =============================================================================

///|
/// Lint issue severity
pub(all) enum SsgLintSeverity {
  Error
  Warning
  Info
}

///|
/// Lint issue
pub(all) struct SsgLintIssue {
  severity : SsgLintSeverity
  file : String
  line : Int?
  message : String
  rule : String
}

///|
/// Lint result
pub(all) struct SsgLintResult {
  issues : Array[SsgLintIssue]
  files_checked : Int
  errors : Int
  warnings : Int
}

///|
/// Run SSG lint command (optimized: single-pass file reading)
pub fn run_ssg_lint(args : Array[String]) -> Unit {
  let cwd = @process.cwd()
  let fs = @fs_adapter.NodeFsAdapter::new()

  // Parse args for --fix flag (reserved for future)
  let _ = args
  println(@colorette.cyan("Linting SSG documentation..."))
  println("")

  // Find config
  let config_path = find_ssg_config_file(cwd)
  let full_config_path = @path.join2(cwd, config_path)

  // Collect issues
  let issues : Array[SsgLintIssue] = []

  // Check config file exists
  if not(fs.exists_sync(full_config_path)) {
    issues.push(SsgLintIssue::{
      severity: Warning,
      file: config_path,
      line: None,
      message: "Config file not found (using defaults)",
      rule: "missing-config",
    })
  }

  // Load and validate config
  let config = if fs.exists_sync(full_config_path) {
    let content = fs.read_file_sync(full_config_path) catch {
      _ => {
        issues.push(SsgLintIssue::{
          severity: Error,
          file: config_path,
          line: None,
          message: "Failed to read config file",
          rule: "config-read-error",
        })
        ""
      }
    }
    if content.is_empty() {
      @ssg.SsgConfig::default()
    } else {
      match parse_ssg_config(content, config_path) {
        Some(c) => c
        None => {
          issues.push(SsgLintIssue::{
            severity: Error,
            file: config_path,
            line: None,
            message: "Invalid config file format",
            rule: "invalid-config",
          })
          @ssg.SsgConfig::default()
        }
      }
    }
  } else {
    @ssg.SsgConfig::default()
  }

  // Get config directory for resolving relative paths
  let config_dir = @path.dirname(full_config_path)

  // Check docs directory exists (relative to config file location)
  let docs_dir = @path.join2(config_dir, config.docs_dir)
  if not(fs.exists_sync(docs_dir)) {
    issues.push(SsgLintIssue::{
      severity: Error,
      file: config.docs_dir,
      line: None,
      message: "Docs directory not found",
      rule: "missing-docs-dir",
    })
  }

  // Optimized: single-pass scanning and linting
  let mut files_checked = 0
  if fs.exists_sync(docs_dir) {
    // Use lightweight scan that only collects file paths (no content reading)
    let file_paths = lint_scan_files(fs, docs_dir, config.exclude)
    files_checked = file_paths.length()

    // Track URL paths for duplicate detection
    let url_to_sources : Map[String, Array[String]] = {}

    // Single pass: read file, detect URL, lint content
    for file_path in file_paths {
      let relative_path = file_path.substring(start=docs_dir.length() + 1)
      let full_path = file_path

      // Read file once
      let content = fs.read_file_sync(full_path) catch { _ => continue }

      // Compute URL path for duplicate detection
      let url_path = @ssg.file_to_url_path(
        relative_path,
        trailing_slash=config.trailing_slash,
      )

      // Track for duplicates
      match url_to_sources.get(url_path) {
        Some(sources) => sources.push(relative_path)
        None => url_to_sources[url_path] = [relative_path]
      }

      // Lint content in same pass
      lint_markdown_content(relative_path, content, issues)
    }

    // Check for duplicates
    for url in url_to_sources.keys() {
      let sources = url_to_sources.get(url).unwrap()
      if sources.length() > 1 {
        let sources_str = sources.join(", ")
        issues.push(SsgLintIssue::{
          severity: Error,
          file: sources[0],
          line: None,
          message: "Duplicate content for URL '\{url}': [\{sources_str}]",
          rule: "duplicate-page",
        })
      }
    }
  }

  // Print results
  print_ssg_lint_results(issues, files_checked)

  // Exit with error if any errors found
  let error_count = issues.filter(fn(i) { i.severity is Error }).length()
  if error_count > 0 {
    @process.exit(1)
  }
}

///|
/// Simple exclusion check for lint (inline to avoid dependency)
fn lint_is_excluded(
  entry : String,
  relative_path : String,
  exclude : Array[String],
) -> Bool {
  // Always exclude hidden files/directories
  if entry.starts_with(".") {
    return true
  }
  // Check against exclude patterns
  for pattern in exclude {
    if entry == pattern || relative_path == pattern {
      return true
    }
    // Simple glob support: pattern/* matches anything in that directory
    if pattern.ends_with("/*") {
      let prefix = pattern.substring(end=pattern.length() - 2)
      if relative_path.starts_with(prefix + "/") || entry == prefix {
        return true
      }
    }
  }
  false
}

///|
/// Lightweight file scan - only collects file paths without reading content
fn[FS : @env.FileSystem] lint_scan_files(
  fs : FS,
  dir_path : String,
  exclude : Array[String],
) -> Array[String] {
  let files : Array[String] = []
  lint_scan_recursive(fs, dir_path, dir_path, exclude, files)
  files
}

///|
/// Recursive directory scan for lint (lightweight, no content reading)
fn[FS : @env.FileSystem] lint_scan_recursive(
  fs : FS,
  base_dir : String,
  dir_path : String,
  exclude : Array[String],
  files : Array[String],
) -> Unit {
  let entries : Array[String] = @env.FileSystem::readdir_sync(fs, dir_path) catch {
    _ => return
  }
  for entry in entries {
    let entry_path = @path.join2(dir_path, entry)
    let relative = entry_path.substring(start=base_dir.length() + 1)

    // Check exclusion (simple pattern check)
    if lint_is_excluded(entry, relative, exclude) {
      continue
    }

    // Check if directory
    let is_dir = @env.FileSystem::is_directory_sync(fs, entry_path) catch {
      _ => false
    }
    if is_dir {
      // Skip component directories (moon.pkg.json or tsx files)
      let moon_pkg = @path.join2(entry_path, "moon.pkg.json")
      if @env.FileSystem::exists_sync(fs, moon_pkg) {
        continue
      }
      // Recurse
      lint_scan_recursive(fs, base_dir, entry_path, exclude, files)
    } else if entry.has_suffix(".md") || entry.has_suffix(".mdx") {
      files.push(entry_path)
    }
  }
}

///|
/// Lint markdown content for common issues
fn lint_markdown_content(
  file : String,
  content : String,
  issues : Array[SsgLintIssue],
) -> Unit {
  let lines = content.split("\n").collect()
  let mut line_num = 1

  // Check for frontmatter
  if not(content.starts_with("---")) {
    issues.push(SsgLintIssue::{
      severity: Warning,
      file,
      line: Some(1),
      message: "Missing frontmatter",
      rule: "missing-frontmatter",
    })
  }

  // Check for empty title
  let mut has_title = false
  let mut in_frontmatter = false
  for line in lines {
    let line_str = line.to_string()
    if line_str == "---" {
      if not(in_frontmatter) {
        in_frontmatter = true
      } else {
        in_frontmatter = false
      }
    } else if in_frontmatter && line_str.starts_with("title:") {
      has_title = true
      let title_value = line_str.substring(start=6).trim(chars=" ").to_string()
      if title_value.is_empty() || title_value == "\"\"" || title_value == "''" {
        issues.push(SsgLintIssue::{
          severity: Warning,
          file,
          line: Some(line_num),
          message: "Empty title in frontmatter",
          rule: "empty-title",
        })
      }
    }
    line_num += 1
  }

  // Only warn about missing title if frontmatter exists
  if content.starts_with("---") && not(has_title) {
    issues.push(SsgLintIssue::{
      severity: Info,
      file,
      line: Some(1),
      message: "No title in frontmatter (will use filename)",
      rule: "no-title",
    })
  }
}

///|
/// Print lint results
fn print_ssg_lint_results(
  issues : Array[SsgLintIssue],
  files_checked : Int,
) -> Unit {
  let errors = issues.filter(fn(i) { i.severity is Error }).length()
  let warnings = issues.filter(fn(i) { i.severity is Warning }).length()
  let infos = issues.filter(fn(i) { i.severity is Info }).length()

  // Print issues grouped by file
  let files : Map[String, Array[SsgLintIssue]] = {}
  for issue in issues {
    if not(files.contains(issue.file)) {
      files[issue.file] = []
    }
    match files.get(issue.file) {
      Some(arr) => arr.push(issue)
      None => ()
    }
  }
  for file, file_issues in files {
    println(@colorette.cyan(file))
    for issue in file_issues {
      let severity_color = match issue.severity {
        Error => @colorette.red("error")
        Warning => @colorette.yellow("warning")
        Info => @colorette.gray("info")
      }
      let line_str = match issue.line {
        Some(l) => ":\{l}"
        None => ""
      }
      println(
        "  \{severity_color}\{line_str}: \{issue.message} [\{issue.rule}]",
      )
    }
    println("")
  }

  // Summary
  println(
    @colorette.gray(
      "─────────────────────────────────────────────",
    ),
  )
  println(
    "Files checked: \{files_checked}, Errors: \{errors}, Warnings: \{warnings}, Info: \{infos}",
  )
  println("")
  if errors == 0 && warnings == 0 {
    println(@colorette.green("✓ No issues found"))
  } else if errors == 0 {
    println(@colorette.yellow("⚠ \{warnings} warning(s) found"))
  } else {
    println(
      @colorette.red("✗ \{errors} error(s), \{warnings} warning(s) found"),
    )
  }
}
