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
    #|  --parallel          Enable parallel SSG build
    #|  --workers <n>       Number of parallel workers (default: 4)
    #|  --force             Force rebuild (ignore cache)
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
  if not(content.contains(broken)) {
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
      @util.Boolean(key="parallel", short="p"),
      @util.String(key="workers", short="w", multiple=false, default=None),
      @util.Boolean(key="force", short="f"),
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
  let use_parallel : Bool = if result.values.contains("parallel") {
    result.values["parallel"].cast()
  } else {
    false
  }
  let num_workers : Int? = if result.values.contains("workers") {
    let workers_str : String = result.values["workers"].cast()
    Some(@strconv.parse_int(workers_str)) catch {
      _ => None
    }
  } else {
    None
  }
  let force_build : Bool = if result.values.contains("force") {
    result.values["force"].cast()
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
    Some(config) => not(config.static_dirs.is_empty())
    None => false
  }
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  let has_moon_mod = fs.exists_sync(moon_mod_path)
  let has_ssg = has_ssg_config(cwd)
  // Check if this is a pure SSG project (no moon.mod.json needed)
  let is_ssg_only = has_ssg && not(has_moon_mod)
  let mode_detail = if is_ssg_only {
    "SSG-only"
  } else if has_moon_mod && has_ssg && has_static_dirs {
    "Hybrid (app + ssg + staticDirs)"
  } else if has_moon_mod && has_ssg {
    "Hybrid (app + ssg)"
  } else if has_moon_mod && has_static_dirs {
    "Hybrid (app + staticDirs)"
  } else {
    "App"
  }
  println(@colorette.gray("Mode: \{mode_detail} (auto)"))
  if is_ssg_only {
    // Pure SSG mode - skip MoonBit checks and go directly to SSG build
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
        let ssg_cwd = @path.dirname(full_config_path)
        let cache_dir = @path.join2(ssg_cwd, ".sol-cache")
        if not(force_build) {
          match
            @ssg_cache.check_local_build_state(ssg_config, ssg_cwd, cache_dir) {
            @ssg_cache.BuildStateCheck::UpToDate(built_at) => {
              println(
                @colorette.green("SSG skipped (no changes since \{built_at})"),
              )
              println(@colorette.gray("  Use --force to rebuild anyway"))
            }
            _ =>
              execute_ssg_build(
                ssg_config, ssg_cwd, cache_dir, use_parallel, num_workers,
              )
          }
        } else {
          execute_ssg_build(
            ssg_config, ssg_cwd, cache_dir, use_parallel, num_workers,
          )
        }
        println(@colorette.gray("Output: \{ssg_config.output_dir}"))
        return
      }
      None => {
        @cli_common.console_error(@colorette.red("Failed to parse SSG config"))
        @process.exit(1)
      }
    }
  }
  // Check if this is a MoonBit project (required for non-SSG-only mode)
  if not(has_moon_mod) {
    @cli_common.console_error(
      @colorette.red("Error: Not a MoonBit project (moon.mod.json not found)"),
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
  if not(skip_generate) && has_sol_config {
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
  if not(skip_bundle) && fs.exists_sync(manifest_path) {
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
  // Build static directories (SSG) if configured via static_dirs
  match sol_config {
    Some(config) =>
      if not(config.static_dirs.is_empty()) {
        build_static_dirs(config.static_dirs, cwd)
      }
    None => ()
  }
  // Full SSG build if ssg section exists in sol.config.json
  if has_ssg_config(cwd) {
    let config_path = find_ssg_config_file(cwd)
    let full_config_path = @path.join2(cwd, config_path)
    let config_content = fs.read_file_sync(full_config_path) catch {
      _ => {
        @cli_common.console_error(@colorette.red("Failed to read SSG config"))
        @process.exit(1)
        "" // unreachable
      }
    }
    match parse_ssg_config(config_content, config_path) {
      Some(ssg_config) => {
        // Use config directory as SSG working directory
        let ssg_cwd = @path.dirname(full_config_path)
        let cache_dir = @path.join2(ssg_cwd, ".sol-cache")
        // Check cache unless force build
        if not(force_build) {
          match
            @ssg_cache.check_local_build_state(ssg_config, ssg_cwd, cache_dir) {
            @ssg_cache.BuildStateCheck::UpToDate(built_at) => {
              println(
                @colorette.green("SSG skipped (no changes since \{built_at})"),
              )
              println(@colorette.gray("  Use --force to rebuild anyway"))
            }
            _ =>
              execute_ssg_build(
                ssg_config, ssg_cwd, cache_dir, use_parallel, num_workers,
              )
          }
        } else {
          execute_ssg_build(
            ssg_config, ssg_cwd, cache_dir, use_parallel, num_workers,
          )
        }
      }
      None => {
        @cli_common.console_error(@colorette.red("Failed to parse SSG config"))
        @process.exit(1)
      }
    }
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

///|
/// Async SSG build for build command with syntax highlighting
async fn execute_ssg_build(
  config : @ssg.SsgConfig,
  cwd : String,
  cache_dir : String,
  _use_parallel : Bool,
  _num_workers : Int?,
) -> Unit {
  println(@colorette.cyan("Running SSG build..."))
  println(@colorette.gray("  Docs: \{config.docs_dir}"))
  println(@colorette.gray("  Output: \{config.output_dir}"))
  // Create highlighter for syntax highlighting
  let highlighter = @shiki.create_default_highlighter().wait()
  // Use sync version with pre-created highlighter
  match @ssg_gen.generate_site_with_highlighter(config, cwd, highlighter) {
    Ok(_) => {
      @ssg_cache.save_manifest(cache_dir, config, cwd)
      println(@colorette.green("✓ SSG build complete: \{config.output_dir}"))
    }
    Err(e) => {
      @cli_common.console_error(@colorette.red("SSG build failed: \{e}"))
      @process.exit(1)
    }
  }
}

///|
/// Build static directories using Sol SSG
fn build_static_dirs(static_dirs : Array[StaticDirEntry], cwd : String) -> Unit {
  for entry in static_dirs {
    println(
      @colorette.cyan(
        "Building static directory: \{entry.source_dir} -> \{entry.path_prefix}",
      ),
    )

    // Convert StaticDirEntry to SsgConfig
    let output_dir = ".sol/prod/static" +
      entry.path_prefix.trim_end(chars="/").to_string()
    let ssg_config = @ssg.SsgConfig::{
      docs_dir: entry.source_dir,
      output_dir,
      title: entry.title,
      base_url: entry.path_prefix,
      nav: entry.nav,
      sidebar: entry.sidebar,
      islands: None,
      theme: entry.theme,
      navigation: entry.navigation,
      i18n: entry.i18n,
      exclude: entry.exclude,
      trailing_slash: entry.trailing_slash,
      ogp: entry.ogp,
      ogp_text: entry.ogp_text,
      head_snippets: entry.head_snippets,
      body_snippets: entry.body_snippets,
      prod_body_snippets: entry.prod_body_snippets,
      sanitize_html: false,
      deploy_target: @ssg.DeployTarget::default(),
      spa_routes: [],
      components_dir: None,
      css_utilities: None,
      meta_files: @ssg.MetaFilesConfig::default(),
    }

    // Generate static site
    match @ssg_gen.generate_site(ssg_config, cwd) {
      Ok(_) =>
        println(
          @colorette.green("✓ Static directory \{entry.path_prefix} built"),
        )
      Err(e) =>
        println(
          @colorette.red("✗ Failed to build \{entry.path_prefix}: \{e}"),
        )
    }
  }
}
