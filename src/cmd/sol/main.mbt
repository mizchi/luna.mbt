///| Sol CLI (native) — subset of commands that work without Node.js
///| Supports: new, clean, generate (JSON config only), build, help

async fn main {
  let args = @sys.get_cli_args()
  // Skip binary name
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
    "help" | "--help" | "-h" => print_help()
    "version" | "--version" | "-v" => println("sol 0.13.0 (native)")
    _ => {
      println("Unknown command: \{command}")
      print_help()
      @sys.exit(1)
    }
  }
}

///|
fn print_help() -> Unit {
  println("Sol CLI (native)")
  println("")
  println("Usage: sol <command> [options]")
  println("")
  println("Commands:")
  println("  new <name> --user <ns>  Create a new Sol project")
  println("  clean                   Remove generated files")
  println("  build                   Build (delegates to moon build)")
  println("  help                    Show this help")
  println("")
  println("For full features (dev, serve, generate), use the JS CLI:")
  println("  node _build/js/release/build/cli/cli.js <command>")
}
