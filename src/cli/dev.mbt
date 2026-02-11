// sol dev command - Start development server
//

///|
/// Generate inline JS script for rolldown build (dev mode, no minify)
fn generate_rolldown_build_script_dev(manifest_path : String) -> String {
  "import { readFileSync } from 'node:fs';\nimport { build } from 'rolldown';\nconst manifest = JSON.parse(readFileSync('\{manifest_path}', 'utf-8'));\nconst input = {};\nfor (const island of manifest.islands) { input[island.name] = island.entry_path; }\nawait build({ input, output: { dir: manifest.output_dir, format: 'esm', entryFileNames: '[name].js', chunkFileNames: '_shared/[name]-[hash].js' } });"
}

///|
fn show_dev_help() -> Unit {
  let help =
    #|Usage: sol dev [options]
    #|
    #|Options:
    #|  -p, --port <port>   Port to listen on (default: 7777)
    #|  --mode <mode>       Mode: auto | app | ssg (default: auto)
    #|  -n, --no-watch      Disable file watching (watch is enabled by default)
    #|  -f, --watch-framework  Watch sol framework source for hot reload
    #|  --clean             Clean target and .sol directories before build
    #|  -h, --help          Show help
  println(help)
}

///|
async fn run_dev_command(args : Array[String]) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_dev_command_with_fs(fs, args)
}

///|
async fn[FS : @env.FileSystem] run_dev_command_with_fs(
  fs : FS,
  args : Array[String],
) -> Unit {
  // Parse dev command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="port", short="p", multiple=false, default=Some("7777")),
      @util.String(key="mode", short="m", multiple=false, default=Some("auto")),
      @util.Boolean(key="no-watch", short="n"),
      @util.Boolean(key="watch-framework", short="f"),
      @util.Boolean(key="clean", short="c"),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  // Show help if requested
  if result.values.contains("help") && result.values["help"].cast() {
    show_dev_help()
    return
  }
  let port : String = if result.values.contains("port") {
    result.values["port"].cast()
  } else {
    "7777"
  }
  let mode : String = if result.values.contains("mode") {
    result.values["mode"].cast()
  } else {
    "auto"
  }
  // Watch is enabled by default, --no-watch disables it
  let watch : Bool = if result.values.contains("no-watch") {
    not(result.values["no-watch"].cast())
  } else {
    true
  }
  let clean : Bool = if result.values.contains("clean") {
    result.values["clean"].cast()
  } else {
    false
  }
  let watch_framework : Bool = if result.values.contains("watch-framework") {
    result.values["watch-framework"].cast()
  } else {
    false
  }
  let cwd = @process.cwd()
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  let has_moon_mod = fs.exists_sync(moon_mod_path)
  let has_ssg = has_ssg_config(cwd)
  let resolved_mode = if mode == "auto" {
    if has_ssg && not(has_moon_mod) {
      "ssg"
    } else {
      "app"
    }
  } else {
    mode
  }
  if resolved_mode != "auto" && resolved_mode != "app" && resolved_mode != "ssg" {
    @cli_common.console_error(
      @colorette.red("Invalid --mode: \{mode} (use auto|app|ssg)"),
    )
    @process.exit(1)
  }
  let mode_label = if resolved_mode == "ssg" { "SSG" } else { "App" }
  let mode_hint = if mode == "auto" { "auto" } else { "forced" }
  println(@colorette.gray("Mode: \{mode_label} (\{mode_hint})"))
  if has_ssg && has_moon_mod && resolved_mode == "app" {
    println(
      @colorette.gray(
        "Hybrid config detected (app + ssg). Use `sol dev --mode ssg` for docs preview.",
      ),
    )
  }
  if resolved_mode == "ssg" {
    if not(has_ssg) {
      @cli_common.console_error(
        @colorette.red(
          "SSG mode requires sol.config.json with ssg/docs configuration",
        ),
      )
      @process.exit(1)
    }
    println(@colorette.cyan("Running SSG dev server..."))
    let config_path = find_ssg_config_file(cwd)
    let full_config_path = @path.join2(cwd, config_path)
    let config_content = fs.read_file_sync(full_config_path) catch {
      _ => {
        @cli_common.console_error(@colorette.red("Failed to read SSG config"))
        @process.exit(1)
        ""
      }
    }
    match parse_ssg_config(config_content, config_path) {
      Some(ssg_config) => {
        let port_int = @ssg.parse_int_simple(port)
        // Use config directory as SSG working directory
        let ssg_cwd = @path.dirname(full_config_path)
        // Call async function and wait for completion
        run_ssg_dev(ssg_config, ssg_cwd, port_int)
      }
      None => {
        @cli_common.console_error(@colorette.red("Failed to parse SSG config"))
        @process.exit(1)
      }
    }
    return
  }
  // Check if this is a MoonBit project (required for app mode)
  if not(has_moon_mod) {
    @cli_common.console_error(
      @colorette.red("Error: Not a MoonBit project (moon.mod.json not found)"),
    )
    @process.exit(1)
  }
  println(@colorette.cyan("Starting Sol development server..."))
  // Step 1: Clean generated files if requested
  if clean {
    let sol_dir = @path.join2(cwd, ".sol")
    let gen_dir = @path.join2(cwd, "app/__gen__")
    let target_dir = @path.join2(cwd, "target")
    println(@colorette.gray("Cleaning generated files..."))
    if fs.exists_sync(sol_dir) {
      @cli_common.rm_rf_sync(fs, sol_dir)
    }
    if fs.exists_sync(gen_dir) {
      @cli_common.rm_rf_sync(fs, gen_dir)
    }
    if fs.exists_sync(target_dir) {
      @cli_common.rm_rf_sync(fs, target_dir)
    }
    println(@colorette.green("✓ Clean complete"))
  }
  // Step 2: Run initial build (includes sol generate)
  if not(run_initial_build_dev(cwd)) {
    @process.exit(1)
  }
  // Run server (watch mode or blocking mode)
  if watch {
    run_dev_watch_mode(cwd, port, watch_framework)
  } else {
    run_server(cwd, port, "dev")
  }
}

///|
/// Run initial build steps for dev mode (includes sol generate)
/// Returns true on success, false on failure
async fn run_initial_build_dev(cwd : String) -> Bool {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_initial_build_dev_with_fs(fs, cwd)
}

///|
async fn[FS : @env.FileSystem] run_initial_build_dev_with_fs(
  fs : FS,
  cwd : String,
) -> Bool {
  // Clean stale static files before rebuild to avoid hash conflicts
  let static_dir = @path.join2(cwd, ".sol/dev/static")
  if fs.exists_sync(static_dir) {
    @cli_common.rm_rf_sync(fs, static_dir)
  }
  // Also remove .sol/prod to avoid serve_static priority issues
  let prod_dir = @path.join2(cwd, ".sol/prod")
  if fs.exists_sync(prod_dir) {
    @cli_common.rm_rf_sync(fs, prod_dir)
  }
  // Run generate if sol.config.json or sol.config.ts exists (only at startup)
  let sol_config_json_path = @path.join2(cwd, "sol.config.json")
  let sol_config_ts_path = @path.join2(cwd, "sol.config.ts")
  if fs.exists_sync(sol_config_json_path) || fs.exists_sync(sol_config_ts_path) {
    println(@colorette.gray("Generating .sol directory..."))
    run_generate_command(["--mode", "dev"])
    println(@colorette.green("✓ Generate complete"))
  }
  // Run incremental build
  run_incremental_build_dev(cwd)
}

///|
/// Run incremental build steps for dev mode (moon build + rolldown only)
/// Skips sol generate for faster rebuilds
/// Returns true on success, false on failure
fn run_incremental_build_dev(cwd : String) -> Bool {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_incremental_build_dev_with_fs(fs, cwd)
}

///|
fn[FS : @env.FileSystem] run_incremental_build_dev_with_fs(
  fs : FS,
  cwd : String,
) -> Bool {
  // Clean stale static files before rebuild to avoid hash conflicts
  let static_dir = @path.join2(cwd, ".sol/dev/static")
  if fs.exists_sync(static_dir) {
    @cli_common.rm_rf_sync(fs, static_dir)
  }
  // Build MoonBit project
  println(@colorette.gray("Building MoonBit project..."))
  try {
    let build_result = @child_process.spawnSync(
      "moon",
      args=["build", "--target", "js"],
      stdio="inherit",
    )
    if build_result.status() != Some(0) {
      @cli_common.console_error(@colorette.red("Build failed"))
      return false
    }
  } catch {
    e => {
      @cli_common.console_error(@colorette.red("Build error: \{e}"))
      return false
    }
  }
  println(@colorette.green("✓ Build complete"))
  // Bundle client code with rolldown if manifest exists
  let manifest_path = @path.join2(cwd, ".sol/dev/manifest.json")
  if fs.exists_sync(manifest_path) {
    println(
      @colorette.gray("Bundling client code with rolldown -> .sol/dev/static/"),
    )
    let build_script = generate_rolldown_build_script_dev(manifest_path)
    try {
      let bundle_result = @child_process.spawnSync(
        "node",
        args=["--input-type=module", "-e", build_script],
        stdio="inherit",
        cwd~,
      )
      if bundle_result.status() != Some(0) {
        @cli_common.console_error(@colorette.red("Rolldown bundle failed"))
        return false
      }
      println(@colorette.green("✓ Client bundle complete"))
    } catch {
      e => {
        @cli_common.console_error(@colorette.red("Bundle error: \{e}"))
        return false
      }
    }
  }
  true
}

///|
/// Calculate HMR WebSocket port (main port + 100)
fn get_hmr_port(port : String) -> Int {
  let main_port = @strconv.parse_int(port) catch { _ => 7777 }
  main_port + 100
}

///|
/// Run dev server with watch mode
async fn run_dev_watch_mode(
  cwd : String,
  port : String,
  watch_framework : Bool,
) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  // Find server entry point
  let entry = find_server_entry_with_fs(fs, cwd, "dev")
  match entry {
    None => {
      @cli_common.console_error(
        @colorette.red("Error: Could not find server entry point"),
      )
      @process.exit(1)
    }
    Some(entry_path) => {
      // Set environment variables
      set_env("PORT", port)
      set_env("SOL_DEV", "1") // Enable HMR script injection
      // Start HMR WebSocket server
      let hmr_port = get_hmr_port(port)
      set_env("HMR_PORT", hmr_port.to_string())
      let hmr_server = @hmr.HmrServer::start(hmr_port).wait()
      // Start server process (non-blocking)
      let server_proc : Ref[@child_process.ChildProcess?] = { val: None }
      fn start_server() -> Unit {
        println(@colorette.cyan("Starting server: \{entry_path}..."))
        let proc = @child_process.spawn("node", args=[entry_path], cwd~)
        // Pipe stdout/stderr to console
        proc
        .stdout()
        .as_any()
        ._call("on", [
          @js.any("data"),
          @js.any(fn(data : @js.Any) {
            let s : String = data._call("toString", []).cast()
            print_string(s)
          }),
        ])
        |> ignore
        proc
        .stderr()
        .as_any()
        ._call("on", [
          @js.any("data"),
          @js.any(fn(data : @js.Any) {
            let s : String = data._call("toString", []).cast()
            print_string_stderr(s)
          }),
        ])
        |> ignore
        server_proc.val = Some(proc)
      }

      fn stop_server() -> Unit {
        if server_proc.val is Some(proc) {
          println(@colorette.gray("Stopping server..."))
          proc.kill() |> ignore
          server_proc.val = None
        }
      }

      fn restart_server() -> Unit {
        stop_server()
        start_server()
      }

      // Start initial server
      start_server()
      // Setup file watcher for .mbt files
      println(
        @colorette.cyan("Watching for .mbt file changes... (Ctrl+C to stop)"),
      )
      // Debounce mechanism
      let last_rebuild : Ref[Double] = { val: 0.0 }
      let debounce_ms = 300.0
      // Watch src directory (and app if exists)
      // Note: @fs.watch is kept as-is since file watching is not part of FileSystem trait
      let watch_dirs = ["src", "app"]
      for dir in watch_dirs {
        let watch_path = @path.join2(cwd, dir)
        if fs.exists_sync(watch_path) {
          let _watcher = @fs.watch(watch_path, recursive=true, listener=fn(
            event : String,
            filename : String,
          ) {
            // Only rebuild for .mbt files, excluding auto-generated files
            let is_generated = filename.contains("__gen__")
            if filename.ends_with(".mbt") &&
              event == "change" &&
              not(is_generated) {
              let now = @cli_common.date_now()
              // Debounce rapid changes
              if now - last_rebuild.val > debounce_ms {
                last_rebuild.val = now
                println(
                  @colorette.yellow(
                    "\n[watch] File changed: \{filename}, rebuilding...",
                  ),
                )
                stop_server()
                if run_incremental_build_dev(cwd) {
                  // Determine if this is a client-side change (Island)
                  let is_client_change = filename.contains("client/") ||
                    filename.contains("islands/")
                  // Restart server first
                  restart_server()
                  // Wait for server to start, then send HMR notification
                  set_timeout(
                    fn() {
                      if is_client_change {
                        // HMR: notify clients to reload islands
                        hmr_server.notify_update(["*"])
                      } else {
                        // Server-side change: full reload
                        hmr_server.notify_full_reload()
                      }
                    },
                    500,
                  )
                } else {
                  // Build failed: notify error
                  hmr_server.notify_error(
                    "Build failed. Check console for details.",
                  )
                  println(
                    @colorette.red(
                      "[watch] Build failed. Waiting for changes...",
                    ),
                  )
                }
              }
            }
          })
        }
      }
      // Watch framework source if --watch-framework is enabled
      if watch_framework {
        match find_framework_root(cwd) {
          Some(framework_root) => {
            let framework_src = @path.join2(framework_root, "src")
            println(
              @colorette.cyan(
                "Also watching framework source: \{framework_src}",
              ),
            )
            let _fw_watcher = @fs.watch(framework_src, recursive=true, listener=fn(
              event : String,
              filename : String,
            ) {
              let is_generated = filename.contains("__gen__")
              if filename.ends_with(".mbt") &&
                event == "change" &&
                not(is_generated) {
                let now = @cli_common.date_now()
                if now - last_rebuild.val > debounce_ms {
                  last_rebuild.val = now
                  println(
                    @colorette.yellow(
                      "\n[watch] Framework changed: \{filename}, rebuilding...",
                    ),
                  )
                  stop_server()
                  // First rebuild framework
                  if rebuild_framework(framework_root) {
                    // Then rebuild app
                    if run_incremental_build_dev(cwd) {
                      restart_server()
                      set_timeout(fn() { hmr_server.notify_full_reload() }, 500)
                    } else {
                      hmr_server.notify_error(
                        "App build failed after framework rebuild",
                      )
                      println(
                        @colorette.red(
                          "[watch] App build failed. Waiting for changes...",
                        ),
                      )
                    }
                  } else {
                    hmr_server.notify_error("Framework rebuild failed")
                    println(
                      @colorette.red(
                        "[watch] Framework rebuild failed. Waiting for changes...",
                      ),
                    )
                  }
                }
              }
            })
          }
          None =>
            println(
              @colorette.yellow(
                "Warning: --watch-framework specified but framework root not found",
              ),
            )
        }
      }
      // Keep process alive
      @cli_common.keep_alive()
    }
  }
}

///|
/// Find server entry point
/// Prefers serve.js (adapter wrapper) over main.js for local serving
fn[FS : @env.FileSystem] find_server_entry_with_fs(
  fs : FS,
  cwd : String,
  mode : String,
) -> String? {
  let possible_entries = [
    ".sol/\{mode}/server/serve.js", // adapter wrapper (preferred for local serving)
    ".sol/\{mode}/server/main.js",
    "_build/js/release/build/__gen__/server/server.js",
    "_build/js/release/build/server/run/run.js",
    "_build/js/release/build/examples/example_app/example_app.js",
    "_build/js/release/build/main/main.js",
  ]
  for entry in possible_entries {
    let entry_path = @path.join2(cwd, entry)
    if fs.exists_sync(entry_path) {
      return Some(entry)
    }
  }
  None
}

///|
fn run_server(cwd : String, port : String, mode : String) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_server_with_fs(fs, cwd, port, mode)
}

///|
fn[FS : @env.FileSystem] run_server_with_fs(
  fs : FS,
  cwd : String,
  port : String,
  mode : String,
) -> Unit {
  // Step 5: Find and run the server entry point
  // Prefer serve.js (adapter wrapper) over main.js for local serving
  let possible_entries = [
    ".sol/\{mode}/server/serve.js", // adapter wrapper (preferred for local serving)
    ".sol/\{mode}/server/main.js",
    "_build/js/release/build/__gen__/server/server.js",
    "_build/js/release/build/server/run/run.js",
    "_build/js/release/build/examples/example_app/example_app.js",
    "_build/js/release/build/main/main.js",
  ]
  let mut entry_point : String? = None
  for entry in possible_entries {
    let entry_path = @path.join2(cwd, entry)
    if fs.exists_sync(entry_path) {
      entry_point = Some(entry)
      break
    }
  }
  match entry_point {
    None => {
      @cli_common.console_error(
        @colorette.red("Error: Could not find server entry point"),
      )
      println(@colorette.gray("Expected one of:"))
      for entry in possible_entries {
        println(@colorette.gray("  - \{entry}"))
      }
      @process.exit(1)
    }
    Some(entry) => {
      println(@colorette.cyan("Running \{entry}..."))
      // Set environment variables before starting server
      set_env("PORT", port)
      set_env("SOL_DEV", "1") // Enable dev mode cache control
      // Run the server with inherited stdio (blocking)
      try {
        let result = @child_process.spawnSync(
          "node",
          args=[entry],
          cwd~,
          stdio="inherit",
        )
        let exit_code = result.status().unwrap_or(1)
        @process.exit(exit_code)
      } catch {
        e => {
          @cli_common.console_error(@colorette.red("Server error: \{e}"))
          @process.exit(1)
        }
      }
    }
  }
}

///|
/// Find sol framework root by walking up directories
/// Looks for src/cli/dev.mbt as a marker file
fn find_framework_root(start_dir : String) -> String? {
  let fs = @fs_adapter.NodeFsAdapter::new()
  let mut current = start_dir
  for _ in 0..<10 {
    // Max 10 levels up
    let marker = @path.join2(current, "src/cli/dev.mbt")
    if fs.exists_sync(marker) {
      return Some(current)
    }
    let parent = @path.dirname(current)
    if parent == current {
      break
    } // Reached root
    current = parent
  }
  None
}

///|
/// Rebuild sol framework at the given root
fn rebuild_framework(framework_root : String) -> Bool {
  println(@colorette.cyan("[watch] Rebuilding sol framework..."))
  try {
    let result = @child_process.spawnSync(
      "moon",
      args=["build", "--target", "js"],
      cwd=framework_root,
      stdio="inherit",
    )
    if result.status() == Some(0) {
      println(@colorette.green("[watch] Framework rebuild complete"))
      true
    } else {
      println(@colorette.red("[watch] Framework rebuild failed"))
      false
    }
  } catch {
    e => {
      println(@colorette.red("[watch] Framework rebuild error: \{e}"))
      false
    }
  }
}

///|
extern "js" fn set_env(key : String, value : String) -> Unit =
  #| (key, value) => { process.env[key] = value }

///|
/// Print string to stdout without adding newline
extern "js" fn print_string(s : String) -> Unit =
  #| (s) => process.stdout.write(s)

///|
/// Print string to stderr without adding newline
extern "js" fn print_string_stderr(s : String) -> Unit =
  #| (s) => process.stderr.write(s)

///|
/// Set timeout for delayed execution
extern "js" fn set_timeout(callback : () -> Unit, ms : Int) -> Unit =
  #| (callback, ms) => setTimeout(callback, ms)
