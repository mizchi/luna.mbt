// Sol CLI process entry point. Mirrors `mizchi/wite/cmd/wite`: parse
// argv via `mizchi/x/sys`, then hand the user-facing slice to the
// dispatcher in `mizchi/sol/cli`.

///|
async fn main {
  // mizchi/x/sys.get_cli_args() == process.argv.slice(1):
  //   args[0] = script path, args[1..] = user-supplied arguments.
  let argv = @sys.get_cli_args()
  let args : Array[String] = if argv.length() > 1 {
    argv[1:].to_array()
  } else {
    []
  }
  @cli.run_main(args)
}
