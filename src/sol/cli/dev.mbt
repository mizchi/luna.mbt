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
    #|  -p, --port <port>   Port to listen on (default: 3000)
    #|  -n, --no-watch      Disable file watching (watch is enabled by default)
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
      @util.String(key="port", short="p", multiple=false, default=Some("3000")),
      @util.Boolean(key="no-watch", short="n"),
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
    "3000"
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
  let cwd = @process.cwd()
  // Check if this is a MoonBit project
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  if not(fs.exists_sync(moon_mod_path)) {
    console_error(
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
      rm_rf_sync_with_fs(fs, sol_dir)
    }
    if fs.exists_sync(gen_dir) {
      rm_rf_sync_with_fs(fs, gen_dir)
    }
    if fs.exists_sync(target_dir) {
      rm_rf_sync_with_fs(fs, target_dir)
    }
    println(@colorette.green("✓ Clean complete"))
  }
  // Step 2: Run initial build (includes sol generate)
  if not(run_initial_build_dev(cwd)) {
    @process.exit(1)
  }
  // Run server (watch mode or blocking mode)
  if watch {
    run_dev_watch_mode(cwd, port)
  } else {
    run_server(cwd, port, "dev")
  }
}

///|
/// Run initial build steps for dev mode (includes sol generate)
/// Returns true on success, false on failure
fn run_initial_build_dev(cwd : String) -> Bool {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_initial_build_dev_with_fs(fs, cwd)
}

///|
fn[FS : @env.FileSystem] run_initial_build_dev_with_fs(
  fs : FS,
  cwd : String,
) -> Bool {
  // Clean stale static files before rebuild to avoid hash conflicts
  let static_dir = @path.join2(cwd, ".sol/dev/static")
  if fs.exists_sync(static_dir) {
    rm_rf_sync_with_fs(fs, static_dir)
  }
  // Also remove .sol/prod to avoid serve_static priority issues
  let prod_dir = @path.join2(cwd, ".sol/prod")
  if fs.exists_sync(prod_dir) {
    rm_rf_sync_with_fs(fs, prod_dir)
  }
  // Run generate if sol.config.json exists (only at startup)
  let sol_config_path = @path.join2(cwd, "sol.config.json")
  if fs.exists_sync(sol_config_path) {
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
    rm_rf_sync_with_fs(fs, static_dir)
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
      console_error(@colorette.red("Build failed"))
      return false
    }
  } catch {
    e => {
      console_error(@colorette.red("Build error: \{e}"))
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
        console_error(@colorette.red("Rolldown bundle failed"))
        return false
      }
      println(@colorette.green("✓ Client bundle complete"))
    } catch {
      e => {
        console_error(@colorette.red("Bundle error: \{e}"))
        return false
      }
    }
  }
  true
}

///|
/// Default HMR WebSocket port
let hmr_port : Int = 24678

///|
/// Run dev server with watch mode
async fn run_dev_watch_mode(cwd : String, port : String) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  // Find server entry point
  let entry = find_server_entry_with_fs(fs, cwd, "dev")
  match entry {
    None => {
      console_error(@colorette.red("Error: Could not find server entry point"))
      @process.exit(1)
    }
    Some(entry_path) => {
      // Set environment variables
      set_env("PORT", port)
      set_env("SOL_DEV", "1") // Enable HMR script injection
      // Start HMR WebSocket server
      let hmr_server = HmrServer::start(hmr_port)
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
              let now = date_now()
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
      // Keep process alive
      keep_alive()
    }
  }
}

///|
/// Find server entry point
fn[FS : @env.FileSystem] find_server_entry_with_fs(
  fs : FS,
  cwd : String,
  mode : String,
) -> String? {
  let possible_entries = [
    ".sol/\{mode}/server/main.js",
    "target/js/release/build/__gen__/server/server.js",
    "target/js/release/build/server/run/run.js",
    "target/js/release/build/examples/example_app/example_app.js",
    "target/js/release/build/main/main.js",
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
extern "js" fn date_now() -> Double =
  #| () => Date.now()

///|
extern "js" fn keep_alive() -> Unit =
  #| () => { setInterval(() => {}, 1000 * 60 * 60) }

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
  // For dev mode, prefer .sol/dev/server/main.js; for prod, .sol/prod/server/main.js
  let possible_entries = [
    ".sol/\{mode}/server/main.js",
    "target/js/release/build/__gen__/server/server.js",
    "target/js/release/build/server/run/run.js",
    "target/js/release/build/examples/example_app/example_app.js",
    "target/js/release/build/main/main.js",
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
      console_error(@colorette.red("Error: Could not find server entry point"))
      println(@colorette.gray("Expected one of:"))
      for entry in possible_entries {
        println(@colorette.gray("  - \{entry}"))
      }
      @process.exit(1)
    }
    Some(entry) => {
      println(@colorette.cyan("Running \{entry}..."))
      // Set PORT environment variable before starting server
      set_env("PORT", port)
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
          console_error(@colorette.red("Server error: \{e}"))
          @process.exit(1)
        }
      }
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
