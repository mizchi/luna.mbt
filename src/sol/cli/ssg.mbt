///| SSG CLI Commands - sol ssg subcommand

// =============================================================================
// Help
// =============================================================================

///|
fn show_ssg_help() -> Unit {
  let help =
    #|Usage: sol ssg <command> [options]
    #|
    #|Static Site Generator for documentation
    #|
    #|Commands:
    #|  build          Build static site from docs/
    #|
    #|Options:
    #|  -c, --config   Config file path (default: sol.config.json)
    #|  -o, --output   Output directory (default: dist)
    #|  -h, --help     Show help
    #|
    #|Examples:
    #|  sol ssg build                    Build with default config
    #|  sol ssg build -o public          Build to public/ directory
    #|  sol ssg build -c custom.json     Use custom config file
  println(help)
}

// =============================================================================
// Command Dispatcher
// =============================================================================

///| Main entry point for ssg subcommand
pub fn run_ssg_command(args : Array[String]) -> Unit {
  if args.is_empty() {
    show_ssg_help()
    return
  }

  let first_arg = args[0]
  if first_arg == "--help" || first_arg == "-h" {
    show_ssg_help()
    return
  }

  let command = first_arg
  let command_args = if args.length() > 1 {
    args[1:].to_array()
  } else {
    []
  }

  match command {
    "build" => run_ssg_build(command_args)
    _ => {
      console_error(@colorette.red("Error: Unknown ssg command '\{command}'"))
      println("")
      show_ssg_help()
      @process.exit(1)
    }
  }
}

// =============================================================================
// Build Command
// =============================================================================

///| Run ssg build command
fn run_ssg_build(args : Array[String]) -> Unit {
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(
        key="config",
        short="c",
        multiple=false,
        default=Some("sol.config.json"),
      ),
      @util.String(
        key="output",
        short="o",
        multiple=false,
        default=None,
      ),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )

  if result.values.contains("help") && result.values["help"].cast() {
    show_ssg_build_help()
    return
  }

  let config_path : String = if result.values.contains("config") {
    result.values["config"].cast()
  } else {
    "sol.config.json"
  }

  let output_override : String? = if result.values.contains("output") {
    Some(result.values["output"].cast())
  } else {
    None
  }

  let cwd = @process.cwd()

  // Read config file
  let full_config_path = @path.join2(cwd, config_path)
  if not(@fs.existsSync(full_config_path)) {
    console_error(@colorette.red("Error: Config file not found: \{config_path}"))
    @process.exit(1)
  }

  let config_content : String = @fs.readFileSync(full_config_path).to_string() catch {
    e => {
      console_error(@colorette.red("Error reading config: \{e}"))
      @process.exit(1)
      "" // unreachable
    }
  }

  guard @ssg.parse_ssg_from_sol_config(config_content) is Some(ssg_config) else {
    console_error(@colorette.red("Error: Invalid config file format or missing ssg section"))
    @process.exit(1)
  }

  // Apply output override if provided
  let final_config = match output_override {
    Some(output) => @ssg.SsgConfig::{ ..ssg_config, output_dir: output }
    None => ssg_config
  }

  println(@colorette.cyan("Building static site..."))
  println(@colorette.gray("  Docs: \{final_config.docs_dir}"))
  println(@colorette.gray("  Output: \{final_config.output_dir}"))

  match @ssg_gen.generate_site(final_config, cwd) {
    Ok(_) => println(@colorette.green("✓ Build complete: \{final_config.output_dir}"))
    Err(e) => {
      console_error(@colorette.red("Build failed: \{e}"))
      @process.exit(1)
    }
  }
}

///|
fn show_ssg_build_help() -> Unit {
  let help =
    #|Usage: sol ssg build [options]
    #|
    #|Build static site from markdown files
    #|
    #|Options:
    #|  -c, --config <path>  Config file path (default: sol.config.json)
    #|  -o, --output <dir>   Output directory (overrides config)
    #|  -h, --help           Show help
    #|
    #|Configuration (in sol.config.json):
    #|  {
    #|    "ssg": {
    #|      "docs": "docs",           // Source directory
    #|      "output": "dist",         // Output directory
    #|      "title": "My Docs",       // Site title
    #|      "base": "/",              // Base URL
    #|      "nav": [...],             // Navigation items
    #|      "sidebar": "auto",        // Sidebar config
    #|      "theme": {...}            // Theme settings
    #|    }
    #|  }
  println(help)
}
