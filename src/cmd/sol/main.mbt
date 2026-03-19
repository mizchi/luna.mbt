///| Sol CLI — native MoonBit binary
///| Native commands: new, clean, build
///| Delegated to JS CLI: dev, serve, generate

async fn main {
  let args = @sys.get_cli_args()
  if args.length() <= 1 {
    print_help()
    return
  }
  let command = args[1]
  let rest : Array[String] = []
  for i = 2; i < args.length(); i = i + 1 {
    rest.push(args[i])
  }
  match command {
    "new" => run_new(rest)
    "clean" => run_clean(rest)
    "build" => run_build(rest)
    "dev" => run_dev(rest)
    "serve" => run_serve(rest)
    "generate" => run_generate(rest)
    "help" | "--help" | "-h" => print_help()
    "version" | "--version" | "-v" => println("sol 0.13.0")
    _ => {
      println("Unknown command: \{command}")
      print_help()
      @sys.exit(1)
    }
  }
}

///|
fn print_help() -> Unit {
  println("Sol CLI v0.13.0")
  println("")
  println("Usage: sol <command> [options]")
  println("")
  println("Commands:")
  println("  new <name> --user <ns>  Create a new Sol project")
  println("  dev                     Start dev server (watch + HMR)")
  println("  build                   Build for production")
  println("  serve                   Serve production build")
  println("  generate                Generate .sol directory")
  println("  clean [--all]           Remove generated files")
  println("  help                    Show this help")
}
