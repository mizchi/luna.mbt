// sol build command - Build for production
//

///|
/// Generate inline JS script for rolldown build (avoids config file)
fn generate_rolldown_build_script(
  manifest_path : String,
  skip_minify : Bool,
) -> String {
  let minify_line = if skip_minify { "" } else { "minify: true," }
  // Inline node script that reads manifest and runs rolldown programmatically
  "import { readFileSync } from 'node:fs';\nimport { build } from 'rolldown';\nconst manifest = JSON.parse(readFileSync('\{manifest_path}', 'utf-8'));\nconst input = {};\nfor (const island of manifest.islands) { input[island.name] = island.entry_path; }\nawait build({ input, output: { dir: manifest.output_dir, format: 'esm', entryFileNames: '[name].js', chunkFileNames: '_shared/[name]-[hash].js', \{minify_line} } });"
}

///|
fn show_build_help() -> Unit {
  let help =
    #|Usage: sol build [options]
    #|
    #|Options:
    #|  --target <target>   Build target (js, wasm) (default: js)
    #|  --skip-bundle       Skip rolldown bundling
    #|  --skip-generate     Skip .sol directory generation
    #|  --skip-minify       Skip minification
    #|  --clean             Clean _build and .sol directories before build
    #|  --wasm-entrypoints  Build wasm entrypoints from config.wasmEntryPoints
    #|  --runtime <kind>    Override wasm runtime (wagi|wasi-cli|component)
    #|  --emit-spin-fragment  Emit .sol/wasm/spin.toml.fragment
    #|  -h, --help          Show help
  println(help)
}

///|
/// Patch generated server JS for MoonBit 0.8 async scheduler symbol mismatch.
/// This keeps request handling working until upstream codegen is fixed.
fn[FS : @env.FileSystem] patch_mars_reschedule_shim_with_fs(
  fs : FS,
  cwd : String,
  target : String,
  profile : String,
) -> Unit {
  // Try __gen__/server/server.js first, then server/server.js (user-managed mode)
  let gen_path = @path.join2(
    cwd,
    "_build/\{target}/\{profile}/build/__gen__/server/server.js",
  )
  let user_path = @path.join2(
    cwd,
    "_build/\{target}/\{profile}/build/server/server.js",
  )
  let server_js_path = if fs.exists_sync(gen_path) {
    gen_path
  } else if fs.exists_sync(user_path) {
    user_path
  } else {
    return
  }
  let content = fs.read_file_sync(server_js_path) catch { _ => return }
  let broken = "moonbitlang$async$internal$event_loop$$reschedule();"
  if !(content.contains(broken)) {
    return
  }
  let patched = content.replace_all(old=broken, new="void 0;")
  fs.write_file_sync(server_js_path, patched) catch {
    _ => return
  }
  println(
    @colorette.gray("Patched async reschedule shim in \{profile} server.js"),
  )
}

///|
async fn run_build_command(args : Array[String]) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_build_command_with_fs(fs, args)
}

///|
async fn[FS : @env.FileSystem] run_build_command_with_fs(
  fs : FS,
  args : Array[String],
) -> Unit {
  // Parse build command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="target", short="t", multiple=false, default=Some("js")),
      @util.Boolean(key="skip-bundle", short="s"),
      @util.Boolean(key="skip-generate", short="g"),
      @util.Boolean(key="skip-minify", short="m"),
      @util.Boolean(key="clean", short="c"),
      @util.Boolean(key="wasm-entrypoints", short="x"),
      @util.String(key="runtime", short="r", multiple=false, default=None),
      @util.Boolean(key="emit-spin-fragment", short="e"),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  // Show help if requested
  if result.values.contains("help") && result.values["help"].cast() {
    show_build_help()
    return
  }
  let target : String = if result.values.contains("target") {
    result.values["target"].cast()
  } else {
    "js"
  }
  let skip_bundle : Bool = if result.values.contains("skip-bundle") {
    result.values["skip-bundle"].cast()
  } else {
    false
  }
  let skip_generate : Bool = if result.values.contains("skip-generate") {
    result.values["skip-generate"].cast()
  } else {
    false
  }
  let skip_minify : Bool = if result.values.contains("skip-minify") {
    result.values["skip-minify"].cast()
  } else {
    false
  }
  let clean : Bool = if result.values.contains("clean") {
    result.values["clean"].cast()
  } else {
    false
  }
  let build_wasm_flag : Bool = if result.values.contains("wasm-entrypoints") {
    result.values["wasm-entrypoints"].cast()
  } else {
    false
  }
  let emit_spin_fragment : Bool = if result.values.contains(
      "emit-spin-fragment",
    ) {
    result.values["emit-spin-fragment"].cast()
  } else {
    false
  }
  let wasm_runtime_override_raw : String? = if result.values.contains("runtime") {
    let value : String = result.values["runtime"].cast()
    if value.trim_space().length() == 0 {
      None
    } else {
      Some(value)
    }
  } else {
    None
  }
  let build_wasm = build_wasm_flag || emit_spin_fragment
  let wasm_runtime_override = match wasm_runtime_override_raw {
    Some(raw) =>
      match parse_wasm_entrypoint_runtime_opt(raw) {
        Some(rt) => Some(rt)
        None => {
          @cli_common.console_error(
            @colorette.red(
              "Invalid --runtime value for wasm entrypoints: \{raw} (use wagi|wasi-cli|component)",
            ),
          )
          @process.exit(1)
          None
        }
      }
    None => None
  }
  let cwd = @process.cwd()
  let (sol_config, sol_config_path) = load_config_with_fs(fs, cwd)
  let has_sol_config = sol_config_path.length() > 0
  let has_static_dirs = match sol_config {
    Some(config) => !(config.static_dirs.is_empty())
    None => false
  }
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  let has_moon_mod = fs.exists_sync(moon_mod_path)
  let mode_detail = if has_moon_mod && has_static_dirs {
    "App (with staticDirs)"
  } else {
    "App"
  }
  println(@colorette.gray("Mode: \{mode_detail}"))
  // Check if this is a MoonBit project (required for SSR build)
  if !(has_moon_mod) {
    @cli_common.console_error(
      @colorette.red(
        "Error: Not a MoonBit project (moon.mod.json not found). Use `astra build` for SSG-only projects.",
      ),
    )
    @process.exit(1)
  }
  // Clean if requested
  if clean {
    println(@colorette.cyan("Cleaning generated files..."))
    let sol_dir = @path.join2(cwd, ".sol")
    let gen_dir = @path.join2(cwd, "app/__gen__")
    let target_dir = @path.join2(cwd, "target")
    let build_dir = @path.join2(cwd, "_build")
    if fs.exists_sync(sol_dir) {
      @cli_common.rm_rf_sync(fs, sol_dir)
    }
    if fs.exists_sync(gen_dir) {
      @cli_common.rm_rf_sync(fs, gen_dir)
    }
    if fs.exists_sync(target_dir) {
      @cli_common.rm_rf_sync(fs, target_dir)
    }
    if fs.exists_sync(build_dir) {
      @cli_common.rm_rf_sync(fs, build_dir)
    }
    println(@colorette.green("✓ Clean complete"))
  }
  // Run generate if sol.config.json exists
  if !(skip_generate) && has_sol_config {
    println(@colorette.cyan("Generating .sol directory..."))
    run_generate_command(["--mode", "prod"])
  }
  println(@colorette.cyan("Building for production (target: \{target})..."))
  // Run moon build
  try {
    let build_result = @child_process.spawnSync(
      "moon",
      args=["build", "--target", target, "--release"],
      stdio="inherit",
    )
    if build_result.status() != Some(0) {
      @cli_common.console_error(@colorette.red("Moon build failed"))
      println(@colorette.gray("Hints:"))
      println(
        @colorette.gray(
          "  - Props type changed? Run `sol generate` to regenerate types",
        ),
      )
      println(
        @colorette.gray(
          "  - Missing dependency? Run `moon update` to fetch packages",
        ),
      )
      println(
        @colorette.gray(
          "  - New island? Ensure Props struct has derive(ToJson, FromJson)",
        ),
      )
      @process.exit(1)
    }
  } catch {
    e => {
      @cli_common.console_error(@colorette.red("Build error: \{e}"))
      @process.exit(1)
    }
  }
  println(@colorette.green("✓ Moon build complete"))
  patch_mars_reschedule_shim_with_fs(fs, cwd, target, "release")
  // Bundle client code with rolldown if manifest exists
  let manifest_path = @path.join2(cwd, ".sol/prod/manifest.json")
  if !(skip_bundle) && fs.exists_sync(manifest_path) {
    let minify_msg = if skip_minify { "" } else { " (minified)" }
    println(
      @colorette.cyan(
        "Bundling client code with rolldown -> .sol/prod/static/\{minify_msg}",
      ),
    )
    // Use node to run programmatic rolldown build
    let build_script = generate_rolldown_build_script(
      manifest_path, skip_minify,
    )
    try {
      let bundle_result = @child_process.spawnSync(
        "node",
        args=["--input-type=module", "-e", build_script],
        stdio="inherit",
        cwd~,
      )
      if bundle_result.status() != Some(0) {
        @cli_common.console_error(@colorette.red("Rolldown bundle failed"))
        @process.exit(1)
      }
    } catch {
      e => {
        @cli_common.console_error(@colorette.red("Bundle error: \{e}"))
        @process.exit(1)
      }
    }
    println(@colorette.green("✓ Client bundle complete"))
  }
  // Note: static_dirs / ssg sections of sol.config.json are no longer
  // built by `sol build`. Run `astra build` for SSG output.
  if has_static_dirs {
    println(
      @colorette.gray(
        "  staticDirs entries detected; run `astra build` to generate them.",
      ),
    )
  }
  if build_wasm {
    let wasm_entries = match sol_config {
      Some(config) => config.wasm_entrypoints
      None => []
    }
    if wasm_entries.is_empty() {
      println(
        @colorette.yellow(
          "No wasmEntryPoints found in config. Skipping wasm entrypoint build.",
        ),
      )
    } else {
      println(@colorette.cyan("Building wasm entrypoints (.mbtx/.wasm)..."))
      let wasm_build_options = WasmEntrypointBuildOptions::for_cli(
        runtime_override=wasm_runtime_override,
        emit_spin_fragment~,
      )
      match
        build_wasm_entrypoints_with_options(
          cwd,
          wasm_entries,
          options=wasm_build_options,
        ) {
        Ok(result) => {
          println(
            @colorette.green(
              "✓ Wasm entrypoints built: \{result.mounts.length()} entries -> .sol/wasm/",
            ),
          )
          if result.artifacts.env_path is Some(env_path) {
            println(@colorette.gray("  env map: \{env_path}"))
          }
          if result.artifacts.spin_fragment_path is Some(spin_path) {
            println(@colorette.gray("  spin fragment: \{spin_path}"))
          }
          if result.artifacts.mars_hints_path is Some(hints_path) {
            println(@colorette.gray("  mars hints: \{hints_path}"))
          }
        }
        Err(e) => {
          @cli_common.console_error(
            @colorette.red("Wasm entrypoint build failed: \{e}"),
          )
          @process.exit(1)
        }
      }
    }
  }
  println(@colorette.gray("Output: _build/\{target}/release/build/"))
}
