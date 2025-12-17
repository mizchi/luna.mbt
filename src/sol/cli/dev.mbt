///| sol dev command - Start development server

///|
/// Generate inline JS script for rolldown build (dev mode, no minify)
fn generate_rolldown_build_script_dev(manifest_path : String) -> String {
  // manifest: true generates .vite/manifest.json with chunk dependencies
  "import { readFileSync } from 'node:fs';\nimport { build } from 'rolldown';\nconst manifest = JSON.parse(readFileSync('\{manifest_path}', 'utf-8'));\nconst input = {};\nfor (const island of manifest.islands) { input[island.name] = island.entry_path; }\nawait build({ input, output: { dir: manifest.output_dir, format: 'esm', entryFileNames: '[name].js', chunkFileNames: '_shared/[name]-[hash].js', manifest: true } });"
}

///|
fn show_dev_help() -> Unit {
  let help =
    #|Usage: sol dev [options]
    #|
    #|Options:
    #|  -p, --port <port>   Port to listen on (default: 3000)
    #|  --clean             Clean target and .sol directories before build
    #|  -h, --help          Show help
  println(help)
}

///|
fn run_dev_command(args : Array[String]) -> Unit {
  // Parse dev command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="port", short="p", multiple=false, default=Some("3000")),
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
  let clean : Bool = if result.values.contains("clean") {
    result.values["clean"].cast()
  } else {
    false
  }
  let cwd = @process.cwd()
  // Check if this is a MoonBit project
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  if not(@fs.existsSync(moon_mod_path)) {
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
    if @fs.existsSync(sol_dir) {
      rm_rf_sync(sol_dir)
    }
    if @fs.existsSync(gen_dir) {
      rm_rf_sync(gen_dir)
    }
    if @fs.existsSync(target_dir) {
      rm_rf_sync(target_dir)
    }
    println(@colorette.green("✓ Clean complete"))
  }
  // Step 2: Run generate if sol.config.json exists
  let sol_config_path = @path.join2(cwd, "sol.config.json")
  if @fs.existsSync(sol_config_path) {
    println(@colorette.gray("Generating .sol directory..."))
    run_generate_command(["--mode", "dev"])
    println(@colorette.green("✓ Generate complete"))
  }
  // Step 3: Build MoonBit project
  println(@colorette.gray("Building MoonBit project..."))
  try {
    let build_result = @child_process.spawnSync(
      "moon",
      args=["build", "--target", "js"],
      stdio="inherit",
    )
    if build_result.status() != Some(0) {
      console_error(@colorette.red("Build failed"))
      @process.exit(1)
    }
  } catch {
    e => {
      console_error(@colorette.red("Build error: \{e}"))
      @process.exit(1)
    }
  }
  println(@colorette.green("✓ Build complete"))
  // Step 4: Bundle client code with rolldown if manifest exists
  let manifest_path = @path.join2(cwd, ".sol/dev/manifest.json")
  if @fs.existsSync(manifest_path) {
    println(@colorette.gray("Bundling client code with rolldown -> .sol/dev/static/"))
    // Use node to run programmatic rolldown build (no minify for dev)
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
        @process.exit(1)
      }
      println(@colorette.green("✓ Client bundle complete"))
    } catch {
      e => {
        console_error(@colorette.red("Bundle error: \{e}"))
        @process.exit(1)
      }
    }
  }
  // Run server
  run_server(cwd, port, "dev")
}

///|
fn run_server(cwd : String, port : String, mode : String) -> Unit {
  // Step 5: Find and run the server entry point
  // For dev mode, prefer .sol/dev/server/main.js; for prod, .sol/prod/server/main.js
  let possible_entries = [
    ".sol/\{mode}/server/main.js", "target/js/release/build/__gen__/server/server.js",
    "target/js/release/build/server/run/run.js", "target/js/release/build/examples/example_app/example_app.js",
    "target/js/release/build/main/main.js",
  ]
  let mut entry_point : String? = None
  for entry in possible_entries {
    let entry_path = @path.join2(cwd, entry)
    if @fs.existsSync(entry_path) {
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
