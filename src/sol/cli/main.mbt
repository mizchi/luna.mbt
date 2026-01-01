// Sol CLI - MoonBit SSR Framework CLI
//

///|
fn show_help() -> Unit {
  let help =
    #|Sol CLI - MoonBit SSR/SSG Framework
    #|
    #|Usage: sol <command> [options]
    #|
    #|Commands:
    #|  new <name>     Create a new Sol project
    #|  dev            Start development server (SSR or SSG mode)
    #|  build          Build for production (SSR + SSG if configured)
    #|  serve          Serve production build
    #|  generate       Generate _sol directory from config
    #|  lint           Lint SSG documentation (requires ssg config)
    #|  clean          Remove generated files and caches
    #|
    #|Options:
    #|  -h, --help     Show help
    #|  -v, --version  Show version
    #|
    #|SSG Mode:
    #|  If sol.config.json with "ssg" section exists,
    #|  dev and build commands will include static site generation.
  println(help)
}

///|
fn show_version() -> Unit {
  println("sol 0.1.0")
}

///|
async fn main {
  let argv = @process.argv()
  // argv[0] = node, argv[1] = script path, argv[2..] = args
  let args : Array[String] = if argv.length() > 2 {
    argv[2:].to_array()
  } else {
    []
  }
  // If no args, show help
  if args.is_empty() {
    show_help()
    return
  }
  // Check for global flags first (before command)
  let first_arg = args[0]
  if first_arg == "--help" || first_arg == "-h" {
    show_help()
    return
  }
  if first_arg == "--version" || first_arg == "-v" {
    show_version()
    return
  }
  // First non-flag argument is the command
  let command = first_arg
  let command_args = if args.length() > 1 { args[1:].to_array() } else { [] }
  // Dispatch to command handlers
  match command {
    "new" => run_new_command(command_args)
    "dev" => run_dev_command(command_args)
    "build" => run_build_command(command_args)
    "serve" => run_serve_command(command_args)
    "generate" => run_generate_command(command_args)
    "lint" => run_ssg_lint(command_args)
    "clean" => run_clean_command(command_args)
    "ssg" => {
      // Redirect to sol build with ssg
      println(@colorette.yellow("Note: 'sol ssg' is now part of 'sol build'."))
      println("")
      println("SSG is automatically detected via sol.config.json")
      @process.exit(0)
    }
    _ => {
      @cli_common.console_error(
        @colorette.red("Error: Unknown command '\{command}'"),
      )
      println("")
      show_help()
      @process.exit(1)
    }
  }
}
