// Astra CLI process entry point. Dispatches the subcommand to the
// runners in `mizchi/astra/cli`.

///|
fn show_help() -> Unit {
  let help =
    #|astra - Mountable Mars middleware for static site generation.
    #|
    #|Usage: astra <command> [options]
    #|
    #|Commands:
    #|  build       Crawl every URL the middleware can serve and dump the
    #|              responses to disk (--out <dir>, default from config).
    #|  dev         Start a node:http dev server (--port <n>, default 7777).
    #|  -h, --help  Show this help.
  println(help)
}

///|
async fn main {
  // mizchi/x/sys forwards the full Node argv: executable, script, user args.
  let argv = @sys.get_cli_args()
  let args : Array[String] = if argv.length() > 2 {
    argv[2:].to_owned()
  } else {
    []
  }
  if args.is_empty() {
    show_help()
    return
  }
  let cmd = args[0]
  let rest : Array[String] = if args.length() > 1 {
    args[1:].to_owned()
  } else {
    []
  }
  match cmd {
    "build" => @cli.run_build(rest, ".")
    "dev" => @cli.run_dev(rest, ".")
    "-h" | "--help" | "help" => show_help()
    _ => {
      println("astra: unknown command '\{cmd}'")
      show_help()
      @sys.exit(1)
    }
  }
}
