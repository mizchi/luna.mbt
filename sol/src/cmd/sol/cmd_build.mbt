///| sol build — delegates to moon build + sol generate (via JS CLI)

///|
async fn run_build(args : Array[String]) -> Unit {
  // Run moon build --target js --release
  println("Building...")
  let mut target = "js"
  let mut release = true
  for arg in args {
    match arg {
      "--target" => ()
      "js" | "native" | "wasm" => target = arg
      "--debug" => release = false
      _ => ()
    }
  }
  let build_args = if release {
    ["build", "--target", target, "--release"]
  } else {
    ["build", "--target", target]
  }
  let status = @process.run("moon", build_args) catch {
    _ => {
      println("Error: moon build failed")
      @sys.exit(1)
      -1
    }
  }
  if status != 0 {
    println("moon build failed (exit code \{status})")
    @sys.exit(status)
  }
  println("✓ Build complete")
}
