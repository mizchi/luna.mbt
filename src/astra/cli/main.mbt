// Astra CLI - Static Site Generator for MoonBit
//

///|
fn show_help() -> Unit {
  let help =
    #|Astra - Static Site Generator
    #|
    #|Usage: astra <command> [options]
    #|
    #|Commands:
    #|  new <name>     Create a new Astra project
    #|  build          Build static site from docs/
    #|  dev            Start development server with HMR
    #|
    #|Options:
    #|  -h, --help     Show help
    #|  -v, --version  Show version
    #|
    #|Examples:
    #|  astra new my-docs              Create a new project
    #|  astra dev                      Start dev server
    #|  astra build                    Build static site
  println(help)
}

///|
fn show_version() -> Unit {
  println("astra 0.1.0")
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
  // Check for global flags first
  let first_arg = args[0]
  if first_arg == "--help" || first_arg == "-h" {
    show_help()
    return
  }
  if first_arg == "--version" || first_arg == "-v" {
    show_version()
    return
  }
  // Dispatch to command handlers
  let command = first_arg
  let command_args = if args.length() > 1 { args[1:].to_array() } else { [] }
  match command {
    "new" => run_new_command(command_args)
    "build" => run_build_command(command_args)
    "dev" => run_dev_command(command_args)
    _ => {
      console_error(@colorette.red("Error: Unknown command '\{command}'"))
      println("")
      show_help()
      @process.exit(1)
    }
  }
}
