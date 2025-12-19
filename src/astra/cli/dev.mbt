// Astra dev command - Development server with watch mode
//

///|
fn show_dev_help() -> Unit {
  let help =
    #|Usage: astra dev [options]
    #|
    #|Start development server with file watching
    #|
    #|Options:
    #|  -p, --port <port>    Port to listen on (default: 3000)
    #|  -c, --config <path>  Config file path
    #|  -h, --help           Show help
  println(help)
}

///|
async fn run_dev_command(args : Array[String]) -> Unit {
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="port", short="p", multiple=false, default=Some("3000")),
      @util.String(key="config", short="c", multiple=false, default=None),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  if result.values.contains("help") && result.values["help"].cast() {
    show_dev_help()
    return
  }
  let port : Int = if result.values.contains("port") {
    let port_str : String = result.values["port"].cast()
    @strconv.parse_int(port_str) catch {
      _ => 3000
    }
  } else {
    3000
  }
  let config_path_override : String? = if result.values.contains("config") {
    Some(result.values["config"].cast())
  } else {
    None
  }
  let cwd = @process.cwd()

  // Find and load config
  let config_path = match config_path_override {
    Some(p) => p
    None => find_config_file(cwd)
  }
  let full_config_path = @path.join2(cwd, config_path)
  if not(@fs.existsSync(full_config_path)) {
    @cli_utils.console_error(
      @colorette.red("Error: Config file not found: \{config_path}"),
    )
    @cli_utils.console_error(
      @colorette.gray("  Create astra.json or sol.config.json with ssg config"),
    )
    @process.exit(1)
  }
  let config_content : String = @fs.readFileSync(full_config_path).to_string() catch {
    e => {
      @cli_utils.console_error(@colorette.red("Error reading config: \{e}"))
      @process.exit(1)
      ""
    }
  }
  let ssg_config = parse_config(config_content, config_path)
  guard ssg_config is Some(config) else {
    @cli_utils.console_error(
      @colorette.red("Error: Invalid config file format"),
    )
    @process.exit(1)
  }

  // Initial build
  println(@colorette.cyan("Starting development server..."))
  println("")
  run_build_async(config, cwd)

  // Start server
  let output_dir = @path.join2(cwd, config.output_dir)
  let server = @http.createServer(requestListener=fn(req, res) {
    serve_file(req, res, output_dir)
  })
  let _ = server.listen(port, callback=fn() {
    println("")
    println(@colorette.green("✓ Dev server running at:"))
    println(@colorette.cyan("  http://localhost:\{port}"))
    println("")
  })

  // Watch docs directory
  let docs_dir = @path.join2(cwd, config.docs_dir)
  println(@colorette.gray("Watching for changes in: \{config.docs_dir}/"))
  println("")

  // Create highlighter once for reuse
  let highlighter = @shiki.create_default_highlighter().wait()

  // Track known pages for detecting add/remove
  let known_pages : Map[String, Bool] = {}
  let pages = @routes.scan_docs_dir(
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
    @astra.SidebarConfig::Auto => @routes.generate_auto_sidebar(pages)
    @astra.SidebarConfig::Manual(groups) => groups
  }
  let build_ctx : @astra.BuildContext = {
    config,
    pages,
    sidebar,
    cwd,
  }

  let _ = @fs.watch(docs_dir, recursive=true, listener=fn(
    event_type,
    filename,
  ) {
    if filename.ends_with(".md") {
      let source_path = filename
      let full_path = @path.join2(docs_dir, filename)
      let file_exists = @fs.existsSync(full_path)

      // Detect if this is a new file, deleted file, or update
      let is_known = known_pages.contains(source_path)

      if file_exists && not(is_known) {
        // New file added - need full rebuild for sidebar
        println(
          @colorette.yellow("[\{event_type}] \{filename} - new file, full rebuild..."),
        )
        known_pages[source_path] = true
        run_build_sync(config, cwd, highlighter)
      } else if not(file_exists) && is_known {
        // File deleted - need full rebuild for sidebar
        println(
          @colorette.yellow("[\{event_type}] \{filename} - deleted, full rebuild..."),
        )
        let _ = known_pages.remove(source_path)
        run_build_sync(config, cwd, highlighter)
      } else if file_exists && is_known {
        // Existing file updated - incremental build
        println(
          @colorette.yellow("[\{event_type}] \{filename} - incremental rebuild..."),
        )
        rebuild_single_page(build_ctx, source_path, highlighter)
      }
    } else if filename.ends_with(".json") {
      // Config change - full rebuild
      println(@colorette.yellow("[\{event_type}] \{filename} - config change, full rebuild..."))
      run_build_sync(config, cwd, highlighter)
    } else if filename.ends_with(".js") {
      // Component change - just copy components
      println(@colorette.yellow("[\{event_type}] \{filename} - copying components..."))
      copy_components_only(config, cwd)
    }
  })

}

///|
/// Rebuild using highlighter (sync call with pre-created highlighter)
fn run_build_sync(
  config : @astra.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter,
) -> Unit {
  match @astra_gen.generate_site_with_highlighter(config, cwd, highlighter) {
    Ok(_) => {
      println(@colorette.green("✓ Rebuild complete"))
      println("")
    }
    Err(e) => @cli_utils.console_error(@colorette.red("Build failed: \{e}"))
  }
}

///|
/// Rebuild a single page (incremental build)
fn rebuild_single_page(
  ctx : @astra.BuildContext,
  source_path : String,
  highlighter : @shiki.Highlighter,
) -> Unit {
  // Find the page in context
  let page : @astra.PageMeta? = ctx.pages
    .iter()
    .find_first(fn(p) { p.source_path == source_path })
  guard page is Some(page_meta) else {
    println(@colorette.red("  Page not found in context: \{source_path}"))
    return
  }

  // Generate single page
  match @astra_gen.generate_single_page(ctx, page_meta, highlighter) {
    Ok(_) => {
      println(@colorette.green("✓ Page rebuilt: \{page_meta.url_path}"))
      println("")
    }
    Err(e) => @cli_utils.console_error(@colorette.red("Build failed: \{e}"))
  }
}

///|
/// Copy components directory only (for JS file changes)
fn copy_components_only(config : @astra.SsgConfig, cwd : String) -> Unit {
  // Determine source directory (convention: docs/components)
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

  // Output path
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
  let dest = @path.join2(@path.join2(cwd, config.output_dir), output_subdir_clean)

  @fs.cpSync(src, dest, recursive=true) catch {
    e => {
      println(@colorette.red("  Failed to copy components: \{e}"))
      return
    }
  }
  println(@colorette.green("✓ Components copied"))
  println("")
}

///|
async fn run_build_async(config : @astra.SsgConfig, cwd : String) -> Unit {
  match @astra_gen.generate_site_async(config, cwd) {
    Ok(_) =>
      println(@colorette.green("✓ Build complete: \{config.output_dir}"))
    Err(e) => @cli_utils.console_error(@colorette.red("Build failed: \{e}"))
    // Don't exit in dev mode, just report the error
  }
}

///|
fn serve_file(
  req : @http.IncomingMessage,
  res : @http.ServerResponse,
  output_dir : String,
) -> Unit {
  let url = req.url.or("/")
  // Parse URL path (strip query string)
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

  // Try different file resolutions in order:
  // 1. Exact path (for files with extensions)
  if @fs.existsSync(base_path) && path_part.contains(".") {
    serve_static_file(res, base_path)
    return
  }

  // 2. path/index.html (directory index)
  let index_path = @path.join2(base_path, "index.html")
  if @fs.existsSync(index_path) {
    serve_static_file(res, index_path)
    return
  }

  // 3. path.html (clean URLs without trailing slash)
  let html_path = base_path + ".html"
  if @fs.existsSync(html_path) {
    serve_static_file(res, html_path)
    return
  }

  // 4. Exact path without extension check
  if @fs.existsSync(base_path) {
    serve_static_file(res, base_path)
    return
  }
  res.writeHead(404) |> ignore
  res.end(data="Not Found: \{path_part}")
}

///|
fn serve_static_file(res : @http.ServerResponse, file_path : String) -> Unit {
  let content : String = @fs.readFileSync(file_path).to_string() catch {
    _ => {
      res.writeHead(500) |> ignore
      res.end(data="Internal Server Error")
      return
    }
  }
  let content_type = get_content_type(file_path)
  res.setHeader("Content-Type", content_type)
  res.setHeader("Cache-Control", "no-cache")
  res.writeHead(200) |> ignore
  res.end(data=content)
}

///|
fn get_content_type(file_path : String) -> String {
  if file_path.ends_with(".html") {
    "text/html; charset=utf-8"
  } else if file_path.ends_with(".css") {
    "text/css; charset=utf-8"
  } else if file_path.ends_with(".js") {
    "application/javascript; charset=utf-8"
  } else if file_path.ends_with(".json") {
    "application/json; charset=utf-8"
  } else if file_path.ends_with(".svg") {
    "image/svg+xml"
  } else if file_path.ends_with(".png") {
    "image/png"
  } else if file_path.ends_with(".jpg") || file_path.ends_with(".jpeg") {
    "image/jpeg"
  } else if file_path.ends_with(".gif") {
    "image/gif"
  } else if file_path.ends_with(".ico") {
    "image/x-icon"
  } else if file_path.ends_with(".woff") {
    "font/woff"
  } else if file_path.ends_with(".woff2") {
    "font/woff2"
  } else if file_path.ends_with(".ttf") {
    "font/ttf"
  } else if file_path.ends_with(".xml") {
    "application/xml"
  } else if file_path.ends_with(".txt") {
    "text/plain; charset=utf-8"
  } else {
    "application/octet-stream"
  }
}
