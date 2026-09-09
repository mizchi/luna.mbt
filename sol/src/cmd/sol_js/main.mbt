// Sol JS CLI process entry point. Parse argv via `mizchi/x/sys`, then hand the
// user-facing slice to the dispatcher in `mizchi/sol/cli`.

///|
async fn main {
  // On the JS backend `@sys.get_cli_args()` is `process.argv` in full:
  //   [0] = node executable, [1] = script path, [2..] = user arguments.
  let argv = @sys.get_cli_args()
  let args : Array[String] = if argv.length() > 2 {
    argv[2:].to_owned()
  } else {
    []
  }
  @cli.run_main(args)
}
