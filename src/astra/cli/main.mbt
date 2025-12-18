///| Astra CLI - Static Site Generator for MoonBit

///|
extern "js" fn console_error(msg : String) -> Unit =
  #| (msg) => console.error(msg)

///|
fn show_help() -> Unit {
  let help =
    #|Astra - Static Site Generator
    #|
    #|Usage: astra <command> [options]
    #|
    #|Commands:
    #|  build          Build static site from docs/
    #|  dev            Start development server with watch (planned)
    #|
    #|Options:
    #|  -h, --help     Show help
    #|  -v, --version  Show version
    #|
    #|Examples:
    #|  astra build                    Build with default config
    #|  astra build -o public          Build to public/ directory
    #|  astra build -c astra.json      Use custom config file
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
