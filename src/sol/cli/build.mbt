///| sol build command - Build for production

///|
fn show_build_help() -> Unit {
  let help =
    #|Usage: sol build [options]
    #|
    #|Options:
    #|  --target <target>   Build target (js, wasm) (default: js)
    #|  --skip-bundle       Skip rolldown bundling
    #|  -h, --help          Show help
  println(help)
}

///|
fn run_build_command(args : Array[String]) -> Unit {
  // Parse build command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="target", short="t", multiple=false, default=Some("js")),
      @util.Boolean(key="skip-bundle", short="s"),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=false,
  )
  // Show help if requested
  if result.values.contains("help") && result.values["help"].cast() {
    show_build_help()
    return
  }
  let target : String = if result.values.contains("target") {
    result.values["target"].cast()
  } else {
    "js"
  }
  let skip_bundle : Bool = if result.values.contains("skip-bundle") {
    result.values["skip-bundle"].cast()
  } else {
    false
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
  println(@colorette.cyan("Building for production (target: \{target})..."))
  // Run moon build
  try {
    let build_result = @child_process.spawnSync(
      "moon",
      args=["build", "--target", target],
      stdio="inherit",
    )
    if build_result.status() != Some(0) {
      console_error(@colorette.red("Moon build failed"))
      @process.exit(1)
    }
  } catch {
    e => {
      console_error(@colorette.red("Build error: \{e}"))
      @process.exit(1)
    }
  }
  println(@colorette.green("✓ Moon build complete"))
  // Bundle client code with rolldown if config exists
  let rolldown_config = @path.join2(cwd, "rolldown.config.mjs")
  if not(skip_bundle) && @fs.existsSync(rolldown_config) {
    println(@colorette.cyan("Bundling client code with rolldown..."))
    try {
      let bundle_result = @child_process.spawnSync(
        "npx",
        args=["rolldown", "-c", "rolldown.config.mjs"],
        stdio="inherit",
      )
      if bundle_result.status() != Some(0) {
        console_error(@colorette.red("Rolldown bundle failed"))
        @process.exit(1)
      }
    } catch {
      e => {
        console_error(@colorette.red("Bundle error: \{e}"))
        @process.exit(1)
      }
    }
    println(@colorette.green("✓ Client bundle complete"))
  }
  println(@colorette.gray("Output: target/\{target}/release/build/"))
}
