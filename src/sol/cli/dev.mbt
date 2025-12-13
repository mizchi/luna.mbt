///| sol dev command - Start development server

///|
fn show_dev_help() -> Unit {
  let help =
    #|Usage: sol dev [options]
    #|
    #|Options:
    #|  -p, --port <port>   Port to listen on (default: 3000)
    #|  -h, --help          Show help
  println(help)
}

///|
fn run_dev_command(args : Array[String]) -> Unit {
  // Parse dev command options
  let result = @util.parseArgs(
    args=args,
    options=[
      @util.String(
        key="port", short="p", multiple=false, default=Some("3000"),
      ),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  // Show help if requested
  if result.values.contains("help") && result.values["help"].cast() {
    show_dev_help()
    return
  }
  let port : String = if result.values.contains("port") {
    result.values["port"].cast()
  } else {
    "3000"
  }
  let cwd = @process.cwd()
  // Check if this is a MoonBit project
  let moon_mod_path = @path.join2(cwd, "moon.mod.json")
  if not(@fs.existsSync(moon_mod_path)) {
    console_error(
      @colorette.red("Error: Not a MoonBit project (moon.mod.json not found)"),
    )
    @process.exit(1)
  }
  println(@colorette.cyan("Starting Sol development server..."))
  // Step 1: Build MoonBit project
  println(@colorette.gray("Building MoonBit project..."))
  try {
    let build_result = @child_process.spawnSync(
      "moon", args=["build", "--target", "js"], stdio="inherit",
    )
    if build_result.status() != Some(0) {
      console_error(@colorette.red("Build failed"))
      @process.exit(1)
    }
  } catch {
    e => {
      console_error(@colorette.red("Build error: \{e}"))
      @process.exit(1)
    }
  }
  println(@colorette.green("✓ Build complete"))
  // Step 2: Find and run the server entry point
  let possible_entries = [
    "target/js/release/build/server/run/run.js",
    "target/js/release/build/examples/example_app/example_app.js",
    "target/js/release/build/main/main.js",
  ]
  let mut entry_point : String? = None
  for entry in possible_entries {
    let entry_path = @path.join2(cwd, entry)
    if @fs.existsSync(entry_path) {
      entry_point = Some(entry)
      break
    }
  }
  match entry_point {
    None => {
      console_error(@colorette.red("Error: Could not find server entry point"))
      println(@colorette.gray("Expected one of:"))
      for entry in possible_entries {
        println(@colorette.gray("  - \{entry}"))
      }
      @process.exit(1)
    }
    Some(entry) => {
      println(@colorette.cyan("Running \{entry}..."))
      // Run the server with inherited stdio
      let server = @child_process.spawn("node", args=[entry], cwd=cwd)
      // Set PORT environment variable
      set_env("PORT", port)
      // Handle server exit
      server.to_event_emitter().on(
        "exit",
        fn(code : @js.Any) {
          let exit_code : Int = code.cast()
          @process.exit(exit_code)
        },
      )
      server.to_event_emitter().on(
        "error",
        fn(err : @js.Any) {
          console_error(@colorette.red("Server error: " + err.to_string()))
          @process.exit(1)
        },
      )
    }
  }
}

///|
extern "js" fn set_env(key : String, value : String) -> Unit =
  #| (key, value) => { process.env[key] = value }
