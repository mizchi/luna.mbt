// sol new command - Create a new Sol project
//

///|
fn show_new_help() -> Unit {
  let help =
    #|Usage: sol new <name> --user <namespace> [options]
    #|
    #|Arguments:
    #|  <name>              Project name (directory name)
    #|
    #|Options:
    #|  -u, --user <name>   User/organization namespace (required)
    #|  -d, --dev           Development mode (use local luna path)
    #|  -h, --help          Show help
    #|
    #|Examples:
    #|  sol new myapp --user mizchi         Create ./myapp with package mizchi/myapp
    #|  sol new myapp --user mizchi --dev   Create with local luna dependency
  println(help)
}

///|
fn run_new_command(args : Array[String]) -> Unit {
  // Parse new command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="user", short="u", multiple=false, default=None),
      @util.Boolean(key="dev", short="d"),
      @util.Boolean(key="help", short="h"),
    ],
    allow_positionals=true,
  )
  // Show help if requested
  if result.values.contains("help") && result.values["help"].cast() {
    show_new_help()
    return
  }
  // Require project name
  if result.positionals.is_empty() {
    console_error(@colorette.red("Error: Project name is required"))
    println("")
    show_new_help()
    @process.exit(1)
  }
  let project_name = result.positionals[0]
  // Require --user option
  guard result.values.contains("user") else {
    console_error(@colorette.red("Error: --user option is required"))
    println("")
    show_new_help()
    @process.exit(1)
  }
  let user_ns : String = result.values["user"].cast()
  if user_ns.is_empty() {
    console_error(@colorette.red("Error: --user option value is required"))
    @process.exit(1)
  }
  let dev_mode : Bool = if result.values.contains("dev") {
    result.values["dev"].cast()
  } else {
    false
  }
  let package_name = "\{user_ns}/\{project_name}" // Full name for moon.mod.json
  // Calculate luna path for dev mode (based on project depth)
  let luna_path : String? = if dev_mode {
    // Count path depth (number of slashes + 1)
    let depth = project_name.split("/").to_array().length()
    let mut path = ".."
    for i = 1; i < depth; i = i + 1 {
      path = path + "/.."
    }
    Some(path)
  } else {
    None
  }
  // Get project directory path
  let cwd = @process.cwd()
  let project_dir = @path.join2(cwd, project_name)
  // Check if project directory already exists
  if @fs.existsSync(project_dir) {
    console_error(
      @colorette.red("Error: Directory '\{project_name}' already exists"),
    )
    @process.exit(1)
  }
  println(@colorette.cyan("Creating new Sol project: \{project_dir}"))
  println(@colorette.gray("  Package name: \{package_name}"))
  if dev_mode {
    println(@colorette.gray("  Mode: development (local luna)"))
  }
  // Generate project from embedded templates
  let templates = generate_templates(package_name, project_name, luna_path)
  for tmpl in templates {
    let file_path = @path.join2(project_dir, tmpl.path)
    let dir_path = @path.dirname(file_path)
    // Create parent directories if needed
    try {
      @fs.mkdirSync(dir_path, recursive=true)
      @fs.writeFileSync(file_path, @js.any(tmpl.content))
    } catch {
      e => {
        console_error(@colorette.red("Error creating file \{tmpl.path}: \{e}"))
        @process.exit(1)
      }
    }
  }
  println(@colorette.green("\n✓ Project created successfully!\n"))
  println("Next steps:")
  println(@colorette.cyan("  cd \{project_name}"))
  println(@colorette.cyan("  npm install"))
  println(@colorette.cyan("  npm run dev"))
}
