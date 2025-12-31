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
    #|  --skip-generate     Skip _sol directory generation
    #|  --skip-minify       Skip minification
    #|  --clean             Clean target and .sol directories before build
    #|  --parallel          Enable parallel SSG build
    #|  --workers <n>       Number of parallel workers (default: 4)
    #|  --force             Force rebuild (ignore cache)
    #|  -h, --help          Show help
  println(help)
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
  let cwd = @process.cwd()
  // Check if this is a MoonBit project
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  if not(fs.exists_sync(moon_mod_path)) {
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
  // Run generate if sol.config.json exists
  let sol_config_path = @path.join2(cwd, "sol.config.json")
  if not(skip_generate) && fs.exists_sync(sol_config_path) {
    println(@colorette.cyan("Generating _sol directory..."))
    run_generate_command(["--mode", "prod"])
  }
  println(@colorette.cyan("Building for production (target: \{target})..."))
  // Run moon build
  try {
    let build_result = @child_process.spawnSync(
      "moon",
      args=["build", "--target", target],
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
  if fs.exists_sync(sol_config_path) {
    let config_content = fs.read_file_sync(sol_config_path) catch { _ => "" }
    if not(config_content.is_empty()) {
      match parse_sol_config(config_content) {
        Some(config) =>
          if not(config.static_dirs.is_empty()) {
            build_static_dirs(config.static_dirs, cwd)
          }
        None => ()
      }
    }
  }
  // Full SSG build if ssg section exists in config or astra.json
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
        let cache_dir = @path.join2(ssg_cwd, ".astra-cache")
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
  println(@colorette.gray("Output: target/\{target}/release/build/"))
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
