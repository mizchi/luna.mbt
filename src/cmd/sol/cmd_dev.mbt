///| sol dev — delegates to JS CLI for full dev server with watch + HMR

///|
async fn run_dev(args : Array[String]) -> Unit {
  let status = delegate_to_js_cli("dev", args)
  @sys.exit(status)
}

///|
async fn run_serve(args : Array[String]) -> Unit {
  let status = delegate_to_js_cli("serve", args)
  @sys.exit(status)
}

///|
async fn run_generate(args : Array[String]) -> Unit {
  let status = delegate_to_js_cli("generate", args)
  @sys.exit(status)
}

///|
/// Delegate a command to the JS CLI.
/// Note: moonbitlang/async process API captures stdout/stderr,
/// so long-running commands (dev/serve) don't show real-time output.
/// Use `node _build/js/release/build/cli/cli.js dev` directly for
/// real-time output until native process stdio inheritance is supported.
async fn delegate_to_js_cli(command : String, args : Array[String]) -> Int {
  let cli_path = ensure_js_cli()
  let full_args : Array[String] = [cli_path, command]
  for a in args {
    full_args.push(a)
  }
  let (exit_code, stdout, stderr) = @process.collect_output(
    "node", full_args, inherit_env=true,
  ) catch {
    _ => {
      println("Error: failed to run node \{cli_path} \{command}")
      return 1
    }
  }
  let out = try { stdout.text() } catch { _ => "" }
  let err = try { stderr.text() } catch { _ => "" }
  if out.length() > 0 {
    println(out)
  }
  if err.length() > 0 {
    println(err)
  }
  exit_code
}

///|
/// Find or build the JS CLI, return its path.
async fn ensure_js_cli() -> String {
  // Walk up from cwd to find sol's JS CLI
  // Check cwd, then parent dirs (for examples/sol_app style layout)
  let prefixes = [".", "..", "../..", "../../.."]
  for prefix in prefixes {
    let candidate = prefix + "/_build/js/release/build/cli/cli.js"
    if @fs.exists(candidate) {
      return candidate
    }
    let debug = prefix + "/_build/js/debug/build/cli/cli.js"
    if @fs.exists(debug) {
      return debug
    }
  }
  // Not found — try building from current dir
  println("Building JS CLI (moon build --target js --release)...")
  let status = @process.run(
    "moon",
    ["build", "--target", "js", "--release"],
    inherit_env=true,
  ) catch {
    _ => {
      println("Error: moon build failed. Is this a sol project?")
      @sys.exit(1)
      -1
    }
  }
  if status != 0 {
    println("Error: moon build failed (exit \{status})")
    @sys.exit(status)
  }
  "_build/js/release/build/cli/cli.js"
}
