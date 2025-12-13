///| Luna CLI - MoonBit Web Framework CLI

///|
extern "js" fn console_error(msg : String) -> Unit =
  #| (msg) => console.error(msg)

///|
fn show_help() -> Unit {
  let help =
    #|Luna CLI - MoonBit Web Framework
    #|
    #|Usage: luna <command> [options]
    #|
    #|Commands:
    #|  new <name>     Create a new Luna project
    #|  dev            Start development server
    #|  build          Build for production
    #|
    #|Options:
    #|  -h, --help     Show help
    #|  -v, --version  Show version
  println(help)
}

///|
fn show_version() -> Unit {
  println("luna 0.1.0")
}

///|
fn main {
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
    _ => {
      console_error(@colorette.red("Error: Unknown command '\{command}'"))
      println("")
      show_help()
      @process.exit(1)
    }
  }
}
