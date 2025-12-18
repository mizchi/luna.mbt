///| Astra build command

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
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="config", short="c", multiple=false, default=None),
      @util.String(key="output", short="o", multiple=false, default=None),
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
  let cwd = @process.cwd()

  // Find config file (astra.json > sol.config.json)
  let config_path = match config_path_override {
    Some(p) => p
    None => find_config_file(cwd)
  }
  let full_config_path = @path.join2(cwd, config_path)
  if not(@fs.existsSync(full_config_path)) {
    console_error(@colorette.red("Error: Config file not found: \{config_path}"))
    console_error(
      @colorette.gray("  Create astra.json or sol.config.json with ssg config"),
    )
    @process.exit(1)
  }

  // Read and parse config
  let config_content : String = @fs.readFileSync(full_config_path).to_string() catch {
    e => {
      console_error(@colorette.red("Error reading config: \{e}"))
      @process.exit(1)
      "" // unreachable
    }
  }
  let ssg_config = parse_config(config_content, config_path)
  guard ssg_config is Some(config) else {
    console_error(
      @colorette.red("Error: Invalid config file format"),
    )
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
  match @astra_gen.generate_site_async(final_config, cwd) {
    Ok(_) =>
      println(@colorette.green("✓ Build complete: \{final_config.output_dir}"))
    Err(e) => {
      console_error(@colorette.red("Build failed: \{e}"))
      @process.exit(1)
    }
  }
}

///|
fn find_config_file(cwd : String) -> String {
  // Try astra.json first
  let astra_path = @path.join2(cwd, "astra.json")
  if @fs.existsSync(astra_path) {
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
