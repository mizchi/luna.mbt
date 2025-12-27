// Astra build command
//

///|
/// Get worker script path from globalThis (set by npm package)
/// Returns empty string if not set
extern "js" fn ffi_get_worker_script() -> String =
  #| () => globalThis.__astra_worker_script || ""

///|
fn show_build_help() -> Unit {
  let help =
    #|Usage: astra build [options]
    #|
    #|Build static site from markdown files
    #|
    #|Options:
    #|  -c, --config <path>  Config file path (default: astra.json, sol.config.json)
    #|  -o, --output <dir>   Output directory (overrides config)
    #|  -p, --parallel       Enable parallel build with worker processes
    #|  -j, --jobs <n>       Number of worker processes (default: 4, implies --parallel)
    #|  -h, --help           Show help
    #|
    #|Configuration file format:
    #|  {
    #|    "docs": "docs",           // Source directory
    #|    "output": "dist",         // Output directory
    #|    "title": "My Docs",       // Site title
    #|    "base": "/",              // Base URL
    #|    "exclude": ["internal"],  // Directories to exclude
    #|    "nav": [...],             // Navigation items
    #|    "sidebar": "auto",        // Sidebar config
    #|    "theme": {...},           // Theme settings
    #|    "i18n": {...}             // Internationalization
    #|  }
    #|
    #|For sol.config.json, wrap config in "ssg" key:
    #|  { "ssg": { ... } }
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
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="config", short="c", multiple=false, default=None),
      @util.String(key="output", short="o", multiple=false, default=None),
      @util.Boolean(key="parallel", short="p"),
      @util.String(key="jobs", short="j", multiple=false, default=None),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  if result.values.contains("help") && result.values["help"].cast() {
    show_build_help()
    return
  }
  let config_path_override : String? = if result.values.contains("config") {
    Some(result.values["config"].cast())
  } else {
    None
  }
  let output_override : String? = if result.values.contains("output") {
    Some(result.values["output"].cast())
  } else {
    None
  }
  let use_parallel = if result.values.contains("parallel") {
    result.values["parallel"].cast()
  } else {
    false
  }
  let num_workers : Int? = if result.values.contains("jobs") {
    let jobs_str : String = result.values["jobs"].cast()
    Some(@ssg.parse_int_simple(jobs_str))
  } else {
    None
  }
  let cwd = @process.cwd()

  // Find config file (astra.json > sol.config.json)
  let config_path = match config_path_override {
    Some(p) => p
    None => find_config_file_with_fs(fs, cwd)
  }
  let full_config_path = @path.join2(cwd, config_path)
  if not(fs.exists_sync(full_config_path)) {
    console_error(
      @colorette.red("Error: Config file not found: \{config_path}"),
    )
    console_error(
      @colorette.gray("  Create astra.json or sol.config.json with ssg config"),
    )
    @process.exit(1)
  }

  // Read and parse config
  let config_content : String = fs.read_file_sync(full_config_path) catch {
    e => {
      console_error(@colorette.red("Error reading config: \{e}"))
      @process.exit(1)
      "" // unreachable
    }
  }
  let ssg_config = parse_config(config_content, config_path)
  guard ssg_config is Some(config) else {
    console_error(@colorette.red("Error: Invalid config file format"))
    @process.exit(1)
  }

  // Apply output override if provided
  let final_config = match output_override {
    Some(output) => @astra.SsgConfig::{ ..config, output_dir: output }
    None => config
  }
  println(@colorette.cyan("Building static site..."))
  println(@colorette.gray("  Docs: \{final_config.docs_dir}"))
  println(@colorette.gray("  Output: \{final_config.output_dir}"))

  // Determine if parallel build should be used
  let should_parallel = use_parallel || num_workers is Some(_)
  if should_parallel {
    // Parallel build with worker processes
    let workers = num_workers.unwrap_or(4)
    println(@colorette.gray("  Mode: parallel (\{workers} workers)"))
    match run_parallel_build_internal(final_config, cwd, workers) {
      Ok(_) =>
        println(
          @colorette.green("✓ Build complete: \{final_config.output_dir}"),
        )
      Err(e) => {
        console_error(@colorette.red("Build failed: \{e}"))
        @process.exit(1)
      }
    }
  } else {
    // Sequential build (default)
    match @astra_gen.generate_site_async(final_config, cwd) {
      Ok(_) =>
        println(
          @colorette.green("✓ Build complete: \{final_config.output_dir}"),
        )
      Err(e) => {
        console_error(@colorette.red("Build failed: \{e}"))
        @process.exit(1)
      }
    }
  }
}

///|
/// Internal parallel build implementation
async fn run_parallel_build_internal(
  config : @astra.SsgConfig,
  cwd : String,
  num_workers : Int,
) -> Result[Unit, String] {
  println("Scanning docs directory: \{config.docs_dir}")

  // Step 1: Scan docs directory
  let pages = @routes.scan_docs_dir(
    config.docs_dir,
    cwd,
    i18n=config.i18n,
    exclude=config.exclude,
    trailing_slash=config.trailing_slash,
  )
  if pages.is_empty() {
    return Err("No markdown files found in \{config.docs_dir}")
  }
  println("Found \{pages.length()} pages")

  // Step 2: Generate sidebar
  let sidebar = match config.sidebar {
    @astra.SidebarConfig::Auto => @routes.generate_auto_sidebar(pages)
    @astra.SidebarConfig::Manual(groups) => groups
  }

  // Step 3: Create output directory
  let output_dir = @path.join2(cwd, config.output_dir)
  @fs.mkdirSync(output_dir, recursive=true) catch {
    _ => ()
  }

  // Step 4: Worker script path
  // First check if running from npm package (globalThis.__astra_worker_script)
  // Otherwise fall back to local development path
  let worker_script = {
    let global_path = ffi_get_worker_script()
    if global_path.is_empty() {
      // Development mode: use target directory
      let target = @path.join2(cwd, "target")
      let js = @path.join2(target, "js")
      let release = @path.join2(js, "release")
      let build = @path.join2(release, "build")
      let astra = @path.join2(build, "astra")
      let worker_dir = @path.join2(astra, "astra_worker")
      @path.join2(worker_dir, "astra_worker.js")
    } else {
      // NPM package mode: use bundled worker
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
    if result.success {
      println("  Generated: \{result.url_path}")
    } else {
      let error_msg = result.error.unwrap_or("Unknown error")
      println("  Error generating \{result.url_path}: \{error_msg}")
    }
  }

  // Step 7: Build DocumentTree for navigation
  let doc_tree = @tree.build_document_tree(config, pages, cwd)

  // Step 8: Copy static assets
  let ctx = @astra.BuildContext::{
    config,
    pages,
    sidebar,
    cwd,
    doc_tree: Some(doc_tree),
  }
  @astra_gen.copy_static_assets(ctx)

  // Step 9: Generate meta files
  @astra_gen.generate_meta_files(ctx, doc_tree)

  // Step 9: Generate 404 page
  @astra_gen.generate_404_page(ctx)

  // Step 10: Generate client manifest for chunk loading
  @astra_gen.generate_client_manifest(ctx)

  // Step 11: Run deploy adapter (generates platform-specific files)
  @adapters.run_adapter(ctx)
  Ok(())
}

///|
fn find_config_file(cwd : String) -> String {
  let fs = @fs_adapter.NodeFsAdapter::new()
  find_config_file_with_fs(fs, cwd)
}

///|
fn[FS : @env.FileSystem] find_config_file_with_fs(
  fs : FS,
  cwd : String,
) -> String {
  // Try astra.json first
  let astra_path = @path.join2(cwd, "astra.json")
  if fs.exists_sync(astra_path) {
    return "astra.json"
  }
  // Fall back to sol.config.json
  "sol.config.json"
}

///|
fn parse_config(content : String, config_path : String) -> @astra.SsgConfig? {
  // If config is astra.json, parse directly
  // If config is sol.config.json, extract ssg section
  if config_path.ends_with("astra.json") {
    @astra.parse_ssg_config(content)
  } else {
    // sol.config.json format - extract ssg section
    @astra.parse_ssg_from_sol_config(content)
  }
}
