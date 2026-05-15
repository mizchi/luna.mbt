// Native install entry point for `moon install mizchi/sol/cmd/sol`.
//
// `moon install` currently builds native binaries. The full Sol command
// implementation is JS-only, so this entry keeps install itself functional and
// delegates subcommands to the JS entry when it is available from a project
// checkout.

///|
async fn main {
  let argv = @sys.get_cli_args()
  let args : Array[String] = if argv.length() > 1 {
    argv[1:].to_owned()
  } else {
    []
  }
  if args.length() == 0 {
    print_help()
    return
  }
  match args[0] {
    "help" | "--help" | "-h" => print_help()
    "version" | "--version" | "-v" => println("sol 0.22.1")
    _ => {
      let status = delegate_to_project_js_cli(args)
      @sys.exit(status)
    }
  }
}

///|
fn print_help() -> Unit {
  println("Sol CLI - MoonBit SSR Framework")
  println("")
  println("Usage: sol <command> [options]")
  println("")
  println("Commands:")
  println("  new <name>     Create a new Sol project")
  println("  dev            Start SSR development server")
  println("  build          Build SSR app for production")
  println("  serve          Serve production build")
  println("  deploy         Run deploy preflight and print deploy command")
  println("  doctor         Diagnose config and adapter wiring")
  println("  generate       Generate .sol directory from config")
  println(
    "  contract-ts    Generate sol.contract.json from TypeScript props interfaces",
  )
  println("  clean          Remove generated files and caches")
  println("")
  println("Options:")
  println("  -h, --help     Show help")
  println("  -v, --version  Show version")
}

///|
async fn delegate_to_project_js_cli(args : Array[String]) -> Int {
  let candidates = [
    "sol/src/cmd/sol_js", ".mooncakes/mizchi/sol/src/cmd/sol_js",
  ]
  for candidate in candidates {
    if @fs.exists(candidate) {
      return run_js_entry(candidate, args)
    }
  }
  run_js_entry("mizchi/sol/cmd/sol_js", args)
}

///|
async fn run_js_entry(entry : String, args : Array[String]) -> Int {
  let run_args : Array[String] = ["run", "--target", "js", entry, "--"]
  for arg in args {
    run_args.push(arg)
  }
  let status = @process.run_inherit("moon", run_args, inherit_env=true) catch {
    _ => {
      println("Error: failed to launch the Sol JS CLI through moon.")
      return 1
    }
  }
  if status != 0 {
    print_launch_failure_guidance()
  }
  status
}

///|
async fn print_launch_failure_guidance() -> Unit {
  println("")
  println("Error: failed to launch the Sol JS CLI.")
  if !@fs.exists("moon.mod.json") {
    println(
      "You're not inside a MoonBit project. `sol` subcommands need a host project that depends on `mizchi/sol`.",
    )
    println("")
    println("  moon new <name> --user <namespace>")
    println("  cd <name>")
    println("  moon add mizchi/sol")
    println("")
    println("Then re-run the sol command from inside that directory.")
  } else if !@fs.exists(".mooncakes/mizchi/sol") {
    println(
      "MoonBit dependencies are not installed. Run `moon install` to fetch `mizchi/sol` into `.mooncakes/`, then retry.",
    )
  } else {
    println(
      "Run this command inside a MoonBit project that depends on mizchi/sol.",
    )
  }
}
