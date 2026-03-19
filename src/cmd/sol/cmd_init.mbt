///| sol init — add sol to an existing MoonBit project

///|
async fn run_init(args : Array[String]) -> Unit {
  let mut user_ns = ""
  let mut i = 0
  while i < args.length() {
    match args[i] {
      "--user" | "-u" =>
        if i + 1 < args.length() {
          user_ns = args[i + 1]
          i += 2
        } else {
          i += 1
        }
      "--help" | "-h" => {
        println("Usage: sol init --user <namespace>")
        println("  Adds sol config and server entry to current directory")
        return
      }
      _ => i += 1
    }
  }
  // Check moon.mod.json exists
  if not(@fs.exists("moon.mod.json")) {
    println("Error: moon.mod.json not found. Run `moon init` first.")
    @sys.exit(1)
  }
  // Check sol.config.json doesn't exist
  if @fs.exists("sol.config.json") {
    println("Error: sol.config.json already exists. Project already initialized.")
    @sys.exit(1)
  }
  println("Initializing Sol in current directory...")
  // Create sol.config.json
  @fs.write_file("sol.config.json", "{\n  \"islands\": [\"app/client\"],\n  \"routes\": \"app/server\",\n  \"output\": \"app/__gen__\",\n  \"runtime\": \"node\"\n}") catch {
    _ => {
      println("Error: failed to write sol.config.json")
      @sys.exit(1)
    }
  }
  println("  Created sol.config.json")
  // Create app/server/main.mbt
  @fs.mkdir("app/server", permission=0o755, recursive=true) catch { _ => () }
  @fs.write_file("app/server/main.mbt", "///| Server entry point\n\nasync fn main {\n  @sol.run_app(fn() {\n    @sol.create_app(routes(), config=config())\n  })\n}") catch { _ => () }
  println("  Created app/server/main.mbt")
  // Create app/server/routes.mbt
  @fs.write_file("app/server/routes.mbt", "///| Route definitions\n\npub fn routes() -> Array[@sol.SolRoutes] {\n  [\n    @sol.api_get(\"/api/health\", api_health),\n  ]\n}\n\npub fn config() -> @sol.RouterConfig {\n  @sol.RouterConfig::default()\n}\n\npriv struct HealthResponse {\n  status : String\n} derive(ToJson)\n\nasync fn api_health(_props : @sol.PageProps) -> HealthResponse {\n  { status: \"ok\" }\n}") catch { _ => () }
  println("  Created app/server/routes.mbt")
  // Create app/server/moon.pkg
  @fs.write_file("app/server/moon.pkg", "import {\n  \"mizchi/sol\" @sol,\n  \"moonbitlang/async\",\n}\n\noptions(\n  \"is-main\": true,\n  \"supported-targets\": \"js\",\n  link: { \"js\": { \"format\": \"esm\" } },\n)") catch { _ => () }
  println("  Created app/server/moon.pkg")
  println("")
  println("✓ Sol initialized!")
  println("")
  println("Next steps:")
  println("  1. Add to moon.mod.json deps:")
  println("     \"mizchi/sol\": \"0.13.1\"")
  println("     \"mizchi/mars\": \"0.3.10\"")
  println("     \"moonbitlang/async\": \"0.16.6\"")
  println("  2. Run: moon update")
  println("  3. Run: sol build")
}
