///| sol check — type check with sol-specific diagnostics

///|
async fn run_check(args : Array[String]) -> Unit {
  let mut target = "js"
  for arg in args {
    match arg {
      "--target" => ()
      "js" | "native" | "wasm" | "wasm-gc" => target = arg
      "--help" | "-h" => {
        println("Usage: sol check [--target js|native]")
        return
      }
      _ => ()
    }
  }
  println("Checking (target: \{target})...")
  let status = @process.run(
    "moon", ["check", "--target", target],
    inherit_env=true,
  ) catch {
    _ => {
      println("Error: moon check failed")
      @sys.exit(1)
      -1
    }
  }
  if status != 0 {
    println("")
    println("Hints:")
    println("  - Props type changed? Run `sol generate`")
    println("  - Missing imports? Check moon.pkg imports")
    println("  - New island? Add derive(ToJson, FromJson) to Props struct")
    @sys.exit(status)
  }
  println("✓ Check passed")
}
