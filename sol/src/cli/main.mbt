// Sol CLI - MoonBit SSR Framework CLI
//
// Library entry point. The JS process entry that calls into `run_main`
// lives in `mizchi/sol/cmd/sol_js`; `mizchi/sol/cmd/sol` is the native
// install shim for `moon install`.

///|
fn show_help() -> Unit {
  let help =
    #|Sol CLI - MoonBit SSR Framework
    #|
    #|Usage: sol <command> [options]
    #|
    #|Commands:
    #|  new <name>     Create a new Sol project
    #|  dev            Start SSR development server
    #|  build          Build SSR app for production
    #|  serve          Serve production build
    #|  deploy         Run deploy preflight and print deploy command
    #|  generate       Generate .sol directory from config
    #|  clean          Remove generated files and caches
    #|
    #|Options:
    #|  -h, --help     Show help
    #|  -v, --version  Show version
    #|
    #|For static-site (docs) projects, use the `astra` CLI instead:
    #|  astra dev / astra build
  println(help)
}

///|
fn show_version() -> Unit {
  println("sol 0.20.2")
}

///|
/// Sol CLI dispatcher. `args` is the user-facing argv slice (no node /
/// script-path prefix). Mirrors the previous `async fn main` body so
/// the existing per-command behaviour is preserved.
pub async fn run_main(args : Array[String]) -> Unit {
  // If no args, show help
  if args.is_empty() {
    show_help()
    return
  }
  // Check for global flags first (before command)
  let first_arg = args[0]
  if first_arg == "--help" || first_arg == "-h" {
    show_help()
    return
  }
  if first_arg == "--version" || first_arg == "-v" {
    show_version()
    return
  }
  // First non-flag argument is the command
  let command = first_arg
  let command_args = if args.length() > 1 { args[1:].to_array() } else { [] }
  // Dispatch to command handlers
  match command {
    "new" => run_new_command(command_args)
    "dev" => run_dev_command(command_args)
    "build" => run_build_command(command_args)
    "serve" => run_serve_command(command_args)
    "deploy" => run_deploy_command(command_args)
    "generate" => run_generate_command(command_args)
    "clean" => run_clean_command(command_args)
    "lint" | "ssg" => {
      @cli_common.console_error(
        @colorette.red(
          "Error: 'sol \{command}' has moved. Use `astra build` (static dump) or `astra dev` (dev server). See astra/README.md.",
        ),
      )
      @process.exit(2)
    }
    _ => {
      @cli_common.console_error(
        @colorette.red("Error: Unknown command '\{command}'"),
      )
      println("")
      show_help()
      @process.exit(1)
    }
  }
}
