// Native install entry point for `moon install mizchi/sol/cmd/sol`.
//
// `moon install` currently builds native binaries. The full Sol command
// implementation is JS-only, so subcommands generally delegate to the JS
// entry, which requires a host moon project with `mizchi/sol` resolved.
//
// EXCEPTION: `sol new <name> --user <ns>` (no extra flags) is scaffolded
// natively so it can run inside an empty directory — no host moon project
// required. Flagged variants like `--cloudflare` / `--doc` / `--dev`
// still delegate to the JS CLI (so they require a host project).

///|
async fn main {
  let argv = @sys.get_cli_args()
  let args : Array[String] = if argv.length() > 1 {
    argv[1:].to_owned()
  } else {
    []
  }
  if args.length() == 0 {
    print_help()
    return
  }
  match args[0] {
    "help" | "--help" | "-h" => print_help()
    "version" | "--version" | "-v" => println("sol 0.22.3")
    "new" => {
      let new_args : Array[String] = if args.length() > 1 {
        args[1:].to_owned()
      } else {
        []
      }
      let handled = try_native_new(new_args) catch {
        e => {
          println("Error: failed to scaffold project: \{e}")
          @sys.exit(1)
          false
        }
      }
      if !handled {
        let status = delegate_to_project_js_cli(args)
        @sys.exit(status)
      }
    }
    _ => {
      let status = delegate_to_project_js_cli(args)
      @sys.exit(status)
    }
  }
}

///|
fn print_help() -> Unit {
  println("Sol CLI - MoonBit SSR Framework")
  println("")
  println("Usage: sol <command> [options]")
  println("")
  println("Commands:")
  println(
    "  new <name>     Create a new Sol project (requires --user <namespace>)",
  )
  println("  dev            Start SSR development server")
  println("  build          Build SSR app for production")
  println("  serve          Serve production build")
  println("  deploy         Run deploy preflight and print deploy command")
  println("  doctor         Diagnose config and adapter wiring")
  println("  generate       Generate .sol directory from config")
  println(
    "  contract-ts    Generate sol.contract.json from TypeScript props interfaces",
  )
  println("  clean          Remove generated files and caches")
  println("")
  println("Options:")
  println("  -h, --help     Show help")
  println("  -v, --version  Show version")
  println("")
  println("Run `sol <command> --help` for command-specific options.")
}

///|
async fn delegate_to_project_js_cli(args : Array[String]) -> Int {
  let candidates = [
    "sol/src/cmd/sol_js", ".mooncakes/mizchi/sol/src/cmd/sol_js",
  ]
  for candidate in candidates {
    if @fs.exists(candidate) {
      return run_js_entry(candidate, args)
    }
  }
  run_js_entry("mizchi/sol/cmd/sol_js", args)
}

///|
async fn run_js_entry(entry : String, args : Array[String]) -> Int {
  let run_args : Array[String] = ["run", "--target", "js", entry, "--"]
  for arg in args {
    run_args.push(arg)
  }
  let status = @process.run_inherit("moon", run_args, inherit_env=true) catch {
    _ => {
      println("Error: failed to launch the Sol JS CLI through moon.")
      return 1
    }
  }
  if status != 0 {
    print_launch_failure_guidance()
  }
  status
}

///|
async fn print_launch_failure_guidance() -> Unit {
  println("")
  println("Error: failed to launch the Sol JS CLI.")
  if !@fs.exists("moon.mod.json") {
    println(
      "You're not inside a MoonBit project. `sol` subcommands need a host project that depends on `mizchi/sol`.",
    )
    println("")
    println("  moon new <name> --user <namespace>")
    println("  cd <name>")
    println("  moon add mizchi/sol")
    println("")
    println("Then re-run the sol command from inside that directory.")
  } else if !@fs.exists(".mooncakes/mizchi/sol") {
    println(
      "MoonBit dependencies are not installed. Run `moon install` to fetch `mizchi/sol` into `.mooncakes/`, then retry.",
    )
  } else {
    println(
      "Run this command inside a MoonBit project that depends on mizchi/sol.",
    )
  }
}

// ---------------------------------------------------------------------------
// Native `sol new` implementation
// ---------------------------------------------------------------------------

///|
fn show_new_help() -> Unit {
  println("Usage: sol new <name> --user <namespace> [options]")
  println("")
  println("Arguments:")
  println("  <name>              Project name (directory name)")
  println("")
  println("Options:")
  println("  -u, --user <name>   User/organization namespace (required)")
  println("  -d, --dev           Development mode (use local luna path)")
  println("  -c, --cloudflare    Create a Cloudflare Worker starter")
  println("  -h, --help          Show help")
  println("")
  println("Examples:")
  println(
    "  sol new myapp --user mizchi                Create ./myapp with package mizchi/myapp",
  )
  println(
    "  sol new myapp --user mizchi --cloudflare   Create a Worker starter",
  )
  println(
    "  sol new myapp --user mizchi --dev          Create with local luna dependency",
  )
}

///|
/// Parsed `sol new` invocation. Only the "minimal default-app" path is
/// handled natively; anything that requests cloudflare / doc / dev falls
/// back to the JS CLI delegate.
priv struct ParsedNewArgs {
  project_name : String?
  user_ns : String?
  needs_delegate : Bool
  show_help : Bool
}

///|
fn parse_new_args(args : Array[String]) -> ParsedNewArgs {
  let mut project_name : String? = None
  let mut user_ns : String? = None
  let mut needs_delegate = false
  let mut show_help = false
  let mut i = 0
  while i < args.length() {
    let a = args[i]
    if a == "-h" || a == "--help" {
      show_help = true
      i = i + 1
    } else if a == "-u" || a == "--user" {
      if i + 1 < args.length() {
        user_ns = Some(args[i + 1])
        i = i + 2
      } else {
        i = i + 1
      }
    } else if a.has_prefix("--user=") {
      user_ns = Some(a[7:].to_owned())
      i = i + 1
    } else if a == "-d" ||
      a == "--dev" ||
      a == "-c" ||
      a == "--cloudflare" ||
      a == "-D" ||
      a == "--doc" {
      // Any of these flags require the JS CLI (cloudflare / doc starter,
      // dev path resolution via the existing JS implementation).
      needs_delegate = true
      i = i + 1
    } else if a.has_prefix("-") {
      // Unknown flag: defer to JS CLI for a consistent error message.
      needs_delegate = true
      i = i + 1
    } else if project_name is None {
      project_name = Some(a)
      i = i + 1
    } else {
      // Extra positional: defer.
      needs_delegate = true
      i = i + 1
    }
  }
  { project_name, user_ns, needs_delegate, show_help }
}

///|
/// Try to handle `sol new` natively. Returns `true` if it took the
/// request (success or non-recoverable error → exits). Returns `false`
/// when the caller should delegate to the JS CLI instead (flagged
/// variants etc.).
async fn try_native_new(args : Array[String]) -> Bool {
  let parsed = parse_new_args(args)
  if parsed.show_help {
    show_new_help()
    return true
  }
  if parsed.needs_delegate {
    return false
  }
  let project_name = match parsed.project_name {
    Some(name) => name
    None => {
      println("Error: Project name is required")
      println("")
      show_new_help()
      @sys.exit(1)
      return true
    }
  }
  let user_ns = match parsed.user_ns {
    Some(ns) => ns
    None => {
      println("Error: --user option is required")
      println("")
      show_new_help()
      @sys.exit(1)
      return true
    }
  }
  if user_ns.length() == 0 {
    println("Error: --user option value is required")
    @sys.exit(1)
    return true
  }
  let project_base = extract_basename(project_name)
  let package_name = "\{user_ns}/\{project_base}"
  let cwd = match @env.current_dir() {
    Some(c) => c
    None => "."
  }
  let project_dir = if project_name.has_prefix("/") {
    project_name
  } else {
    join_path(cwd, project_name)
  }
  if @fs.exists(project_dir) {
    println("Error: Directory '\{project_name}' already exists")
    @sys.exit(1)
    return true
  }
  println("Creating new Sol project: \{project_dir}")
  println("  Package name: \{package_name}")
  println("  Template: app")
  let templates = @scaffold_templates.generate_templates(
    package_name,
    project_base,
    None,
  )
  for tmpl in templates {
    let file_path = join_path(project_dir, tmpl.path)
    let dir_path = dirname(file_path)
    try {
      if dir_path.length() > 0 && !@fs.exists(dir_path) {
        @fs.mkdir(dir_path, recursive=true)
      }
      @fs.write_file(file_path, tmpl.content)
    } catch {
      e => {
        println("Error creating file \{tmpl.path}: \{e}")
        @sys.exit(1)
        return true
      }
    }
  }
  println("")
  println("Project created successfully!")
  println("")
  println("Next steps:")
  println("  cd \{project_name}")
  println("  pnpm install")
  println("  moon install")
  println("  pnpm dev")
  println("")
  println(
    "Note: `moon install` is required even after `pnpm install` — it fetches",
  )
  println(
    "MoonBit deps into .mooncakes/. Without it, `sol dev` fails to resolve",
  )
  println("`mizchi/sol/cmd/sol_js`.")
  true
}

///|
/// Strip trailing slash and take the last `/`-separated segment.
fn extract_basename(project_name : String) -> String {
  let trimmed : String = if project_name.length() > 1 &&
    project_name.has_suffix("/") {
    project_name[:project_name.length() - 1].to_owned()
  } else {
    project_name
  }
  match trimmed.rev_find("/") {
    None => trimmed
    Some(idx) => {
      let base = trimmed[idx + 1:].to_owned()
      if base.length() == 0 {
        project_name
      } else {
        base
      }
    }
  }
}

///|
/// Join two path segments with a single `/`. Mirrors `path.join2` from the
/// JS CLI; assumes POSIX-style separators (sol install targets are POSIX
/// in practice, Windows is not currently supported by the JS CLI either).
fn join_path(base : String, rel : String) -> String {
  if rel.length() == 0 {
    base
  } else if rel.has_prefix("/") {
    rel
  } else if base.length() == 0 {
    rel
  } else if base.has_suffix("/") {
    base + rel
  } else {
    base + "/" + rel
  }
}

///|
/// Return the directory portion of a path (POSIX). Returns "" when there
/// is no separator (i.e. the caller is creating a file at the root of the
/// project dir, which already exists).
fn dirname(path : String) -> String {
  match path.rev_find("/") {
    None => ""
    Some(idx) => if idx == 0 { "/" } else { path[:idx].to_owned() }
  }
}
