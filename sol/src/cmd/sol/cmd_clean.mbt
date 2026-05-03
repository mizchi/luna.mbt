///| sol clean — remove generated files

///|
async fn run_clean(args : Array[String]) -> Unit {
  let mut all = false
  for arg in args {
    match arg {
      "--all" | "-a" => all = true
      "--help" | "-h" => {
        println("Usage: sol clean [--all]")
        println("  --all  Also remove _build/ and target/")
        return
      }
      _ => ()
    }
  }
  let dirs = if all {
    [".sol", "app/__gen__", "_build", "target"]
  } else {
    [".sol", "app/__gen__"]
  }
  let mut removed = 0
  for dir in dirs {
    if @fs.exists(dir) {
      @fs.rmdir(dir, recursive=true) catch {
        e => {
          println("Warning: failed to remove " + dir)
          continue
        }
      }
      println("  Removed \{dir}/")
      removed += 1
    }
  }
  if removed > 0 {
    println("✓ Clean complete")
  } else {
    println("Nothing to clean")
  }
}
