// Astra dev command - Development server with watch mode
//

// HMR WebSocket port

///|
let hmr_port : Int = 24679

///|
/// HMR WebSocket server handle
struct HmrServer {
  inner : @js.Any
}

///|
extern "js" fn import_ws() -> @js.Promise[@js.Any] =
  #| () => import("ws")

///|
fn HmrServer::start(wss_class : @js.Any, port : Int) -> HmrServer {
  let inner = create_wss_instance(wss_class, port)
  let server = HmrServer::{ inner, }
  inner._call("on", [
    @js.any("connection"),
    @js.any(fn(_ws : @js.Any) {
      println(@colorette.gray("[HMR] Client connected"))
    }),
  ])
  |> ignore
  inner._call("on", [
    @js.any("error"),
    @js.any(fn(err : @js.Any) {
      console_error(@colorette.red("[HMR] Server error: \{err}"))
    }),
  ])
  |> ignore
  println(@colorette.cyan("[HMR] WebSocket server on port \{port}"))
  server
}

///|
extern "js" fn create_wss_instance(wss_class : @js.Any, port : Int) -> @js.Any =
  #| (WSSClass, port) => new WSSClass({ port })

///|
fn HmrServer::broadcast(self : HmrServer, message : String) -> Unit {
  // clients is a property (Set), not a method
  let clients = self.inner["clients"]
  clients._call("forEach", [
    @js.any(fn(client : @js.Any) {
      let ready_state : Int = client["readyState"].cast()
      if ready_state == 1 {
        // WebSocket.OPEN
        client._call("send", [@js.any(message)]) |> ignore
      }
    }),
  ])
  |> ignore
}

///|
fn HmrServer::notify_reload(self : HmrServer) -> Unit {
  self.broadcast("{\"type\":\"reload\"}")
  println(@colorette.green("[HMR] Sent reload"))
}

///|
/// HMR client script to inject into HTML
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
fn show_dev_help() -> Unit {
  let help =
    #|Usage: astra dev [options]
    #|
    #|Start development server with file watching
    #|
    #|Options:
    #|  -p, --port <port>    Port to listen on (default: 3355)
    #|  -c, --config <path>  Config file path
    #|  -h, --help           Show help
  println(help)
}

///|
async fn run_dev_command(args : Array[String]) -> Unit {
  // Keep Node.js event loop alive first
  keep_alive()
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="port", short="p", multiple=false, default=Some("3355")),
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
      _ => 3355
    }
  } else {
    3355
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
    console_error(
      @colorette.red("Error: Config file not found: \{config_path}"),
    )
    console_error(
      @colorette.gray("  Create astra.json or sol.config.json with ssg config"),
    )
    @process.exit(1)
  }
  let config_content : String = @fs.readFileSync(full_config_path).to_string() catch {
    e => {
      console_error(@colorette.red("Error reading config: \{e}"))
      @process.exit(1)
      ""
    }
  }
  let ssg_config = parse_config(config_content, config_path)
  guard ssg_config is Some(parsed_config) else {
    console_error(@colorette.red("Error: Invalid config file format"))
    @process.exit(1)
  }

  // Resolve docs_dir relative to config file location
  let config_dir = @path.dirname(config_path)
  let resolved_docs_dir = if config_dir.is_empty() || config_dir == "." {
    parsed_config.docs_dir
    // Config is in a subdirectory, resolve docs_dir relative to it
  } else if parsed_config.docs_dir == "." {
    config_dir
  } else {
    @path.join2(config_dir, parsed_config.docs_dir)
  }
  let config = @astra.SsgConfig::{
    ..parsed_config,
    docs_dir: resolved_docs_dir,
  }

  // Create highlighter once for reuse (before initial build)
  println(@colorette.cyan("Starting development server..."))
  println("")
  let highlighter = @shiki.create_default_highlighter().wait()

  // Initial build with highlighter
  run_initial_build(config, cwd, highlighter)

  // Start HMR WebSocket server
  let ws_module = import_ws().wait()
  let wss_class = ws_module["WebSocketServer"]
  let hmr_server = HmrServer::start(wss_class, hmr_port)

  // Start HTTP server
  let output_dir = @path.join2(cwd, config.output_dir)
  let spa_routes = config.spa_routes
  let server = @http.createServer(requestListener=fn(req, res) {
    serve_file_with_hmr(req, res, output_dir, hmr_port, spa_routes)
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
    doc_tree: None,
  }
  let _ = @fs.watch(docs_dir, recursive=true, listener=fn(
    event_type,
    filename,
  ) {
    if filename.ends_with(".md") || filename.ends_with(".mdx") {
      let source_path = filename
      let full_path = @path.join2(docs_dir, filename)
      let file_exists = @fs.existsSync(full_path)

      // Detect if this is a new file, deleted file, or update
      let is_known = known_pages.contains(source_path)
      if file_exists && not(is_known) {
        // New file added - need full rebuild for sidebar
        println(
          @colorette.yellow(
            "[\{event_type}] \{filename} - new file, full rebuild...",
          ),
        )
        known_pages[source_path] = true
        run_build_sync(config, cwd, highlighter)
        hmr_server.notify_reload()
      } else if not(file_exists) && is_known {
        // File deleted - need full rebuild for sidebar
        println(
          @colorette.yellow(
            "[\{event_type}] \{filename} - deleted, full rebuild...",
          ),
        )
        let _ = known_pages.remove(source_path)
        run_build_sync(config, cwd, highlighter)
        hmr_server.notify_reload()
      } else if file_exists && is_known {
        // Existing file updated - incremental build
        println(
          @colorette.yellow(
            "[\{event_type}] \{filename} - incremental rebuild...",
          ),
        )
        rebuild_single_page(build_ctx, source_path, highlighter)
        hmr_server.notify_reload()
      }
    } else if filename.ends_with(".json") {
      // Config change - full rebuild
      println(
        @colorette.yellow(
          "[\{event_type}] \{filename} - config change, full rebuild...",
        ),
      )
      run_build_sync(config, cwd, highlighter)
      hmr_server.notify_reload()
    } else if filename.ends_with(".js") {
      // Component change - just copy components
      println(
        @colorette.yellow("[\{event_type}] \{filename} - copying components..."),
      )
      copy_components_only(config, cwd)
      hmr_server.notify_reload()
    }
  })

}

///|
extern "js" fn keep_alive() -> Unit =
  #| () => { setInterval(() => {}, 1000 * 60 * 60) }

///|
/// Rebuild using highlighter (sync call with pre-created highlighter)
fn run_build_sync(
  config : @astra.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter,
) -> Unit {
  match @astra_gen.generate_site_with_highlighter(config, cwd, highlighter) {
    Ok(_) => {
      // Update build manifest
      let cache_dir = @path.join2(cwd, ".astra-cache")
      @astra_cache.save_manifest(cache_dir, config, cwd)
      println(@colorette.green("✓ Rebuild complete"))
      println("")
    }
    Err(e) => console_error(@colorette.red("Build failed: \{e}"))
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
    Err(e) => console_error(@colorette.red("Build failed: \{e}"))
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
  let dest = @path.join2(
    @path.join2(cwd, config.output_dir),
    output_subdir_clean,
  )
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
fn run_initial_build(
  config : @astra.SsgConfig,
  cwd : String,
  highlighter : @shiki.Highlighter,
) -> Unit {
  // Check for incremental build skip using provider pattern
  let cache_dir = @path.join2(cwd, ".astra-cache")
  match @astra_cache.check_local_build_state(config, cwd, cache_dir) {
    @core_cache.BuildStateCheck::UpToDate(built_at) => {
      println(
        @colorette.green("✓ Build skipped (no changes since \{built_at})"),
      )
      return
    }
    _ => ()
  }

  // Run build
  match @astra_gen.generate_site_with_highlighter(config, cwd, highlighter) {
    Ok(_) => {
      // Save build manifest on success
      @astra_cache.save_manifest(cache_dir, config, cwd)
      println(@colorette.green("✓ Build complete: \{config.output_dir}"))
    }
    Err(e) => console_error(@colorette.red("Build failed: \{e}"))
    // Don't exit in dev mode, just report the error
  }
}

///|
fn serve_file_with_hmr(
  req : @http.IncomingMessage,
  res : @http.ServerResponse,
  output_dir : String,
  hmr_port : Int,
  spa_routes : Array[String],
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
    serve_with_hmr_injection(res, base_path, hmr_port)
    return
  }

  // 2. path/index.html (directory index)
  let index_path = @path.join2(base_path, "index.html")
  if @fs.existsSync(index_path) {
    serve_with_hmr_injection(res, index_path, hmr_port)
    return
  }

  // 3. path.html (clean URLs without trailing slash)
  let html_path = base_path + ".html"
  if @fs.existsSync(html_path) {
    serve_with_hmr_injection(res, html_path, hmr_port)
    return
  }

  // 4. Exact path without extension check
  if @fs.existsSync(base_path) {
    serve_with_hmr_injection(res, base_path, hmr_port)
    return
  }

  // 5. SPA fallback - check if path matches any SPA route prefix
  for spa_route in spa_routes {
    if path_part.starts_with(spa_route) {
      // Fallback to the SPA route's index.html
      let spa_index = @path.join2(
        @path.join2(output_dir, spa_route),
        "index.html",
      )
      if @fs.existsSync(spa_index) {
        serve_with_hmr_injection(res, spa_index, hmr_port)
        return
      }
    }
  }
  res.writeHead(404) |> ignore
  res.end(data="Not Found: \{path_part}")
}

///|
/// Serve file with HMR script injection for HTML files
fn serve_with_hmr_injection(
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
  let content_type = get_content_type(file_path)
  res.setHeader("Content-Type", content_type)
  res.setHeader("Cache-Control", "no-cache")
  res.writeHead(200) |> ignore

  // Inject HMR script into HTML files
  if file_path.ends_with(".html") {
    let hmr_script = hmr_client_script(hmr_port)
    let injected = content.replace(old="</body>", new=hmr_script + "</body>")
    res.end(data=injected)
  } else {
    res.end(data=content)
  }
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
  } else if file_path.ends_with(".wasm") {
    "application/wasm"
  } else if file_path.ends_with(".pf_meta") || file_path.ends_with(".pf_index") {
    "application/octet-stream"
  } else {
    "application/octet-stream"
  }
}
