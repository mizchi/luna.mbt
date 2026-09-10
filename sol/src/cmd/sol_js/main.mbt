// Sol JS CLI process entry point. Parse argv via `mizchi/x/sys`, then hand the
// user-facing slice to the dispatcher in `mizchi/sol/cli`.

///|
async fn main {
  // mizchi/x/sys forwards the full Node argv: executable, script, user args.
  let argv = @sys.get_cli_args()
  let args : Array[String] = if argv.length() > 2 {
    argv[2:].to_owned()
  } else {
    []
  }
  @cli.run_main(args)
}
