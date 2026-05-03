// sol serve command - Serve pre-built production assets
//

///|
fn show_serve_help() -> Unit {
  let help =
    #|Usage: sol serve [options]
    #|
    #|Serves pre-built assets without rebuilding.
    #|Run 'sol build' first to create the production build.
    #|
    #|Options:
    #|  -p, --port <port>   Port to listen on (default: 7777)
    #|  -h, --help          Show help
  println(help)
}

///|
fn run_serve_command(args : Array[String]) -> Unit {
  // Parse serve command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="port", short="p", multiple=false, default=Some("7777")),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  // Show help if requested
  if result.values.contains("help") && result.values["help"].cast() {
    show_serve_help()
    return
  }
  let port : String = if result.values.contains("port") {
    result.values["port"].cast()
  } else {
    "7777"
  }
  let cwd = @process.cwd()
  // Check if this is a MoonBit project
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  if !(@fs.existsSync(moon_mod_path)) {
    @cli_common.console_error(
      @colorette.red("Error: Not a MoonBit project (moon.mod.json not found)"),
    )
    @process.exit(1)
  }
  // Check if build exists
  let target_dir = @path.join2(cwd, "_build/js/release/build")
  if !(@fs.existsSync(target_dir)) {
    @cli_common.console_error(
      @colorette.red("Error: No production build found. Run 'sol build' first."),
    )
    @process.exit(1)
  }
  println(@colorette.cyan("Starting Sol production server..."))
  // Run server (reuse from dev.mbt) - use prod mode
  run_server(cwd, port, "prod")
}
