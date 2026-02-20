// sol clean command - Remove generated files and caches
//

///|
fn show_clean_help() -> Unit {
  let help =
    #|Usage: sol clean [options]
    #|
    #|Remove generated files and caches:
    #|  - .sol/          (manifest and config cache)
    #|  - app/__gen__/   (generated server/client code)
    #|  - _build/        (MoonBit build output, with --all)
    #|
    #|Options:
    #|  -a, --all        Also remove _build/ directory
    #|  -h, --help       Show help
  println(help)
}

///|
fn run_clean_command(args : Array[String]) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_clean_command_with_fs(fs, args)
}

///|
fn[FS : @env.FileSystem] run_clean_command_with_fs(
  fs : FS,
  args : Array[String],
) -> Unit {
  // Parse clean command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.Boolean(key="help", short="h"),
      @util.Boolean(key="all", short="a"),
    ],
    allow_positionals=false,
  )
  // Show help if requested
  if result.values.contains("help") && result.values["help"].cast() {
    show_clean_help()
    return
  }
  let clean_all : Bool = result.values.contains("all") &&
    result.values["all"].cast()
  let cwd = @process.cwd()
  // Directories to clean
  let dirs_to_clean = [".sol", "app/__gen__"]
  let mut cleaned = 0
  for dir in dirs_to_clean {
    let dir_path = @path.join2(cwd, dir)
    if fs.exists_sync(dir_path) {
      println(@colorette.gray("Removing \{dir}/..."))
      @cli_common.rm_rf_sync(fs, dir_path)
      cleaned = cleaned + 1
    }
  }
  // Clean build output if --all flag is set
  if clean_all {
    // Cleanup legacy symlink/directory if present
    let legacy_target_path = @path.join2(cwd, "target")
    if fs.exists_sync(legacy_target_path) {
      println(@colorette.gray("Removing target/..."))
      @cli_common.rm_rf_sync(fs, legacy_target_path)
      cleaned = cleaned + 1
    }
    let build_path = @path.join2(cwd, "_build")
    if fs.exists_sync(build_path) {
      println(@colorette.gray("Removing _build/..."))
      @cli_common.rm_rf_sync(fs, build_path)
      cleaned = cleaned + 1
    }
  }
  if cleaned > 0 {
    println(@colorette.green("✓ Cleaned \{cleaned} directories"))
  } else {
    println(@colorette.gray("Nothing to clean"))
  }
}
