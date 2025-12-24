// astra new command - Create a new Astra documentation project
//

///|
fn show_new_help() -> Unit {
  let help =
    #|Usage: astra new <name> [options]
    #|
    #|Arguments:
    #|  <name>              Project name (directory name)
    #|
    #|Options:
    #|  -t, --title <text>  Site title (default: project name)
    #|  -h, --help          Show help
    #|
    #|Examples:
    #|  astra new my-docs                Create ./my-docs with basic structure
    #|  astra new my-docs --title "My Docs"  Create with custom title
  println(help)
}

///|
fn run_new_command(args : Array[String]) -> Unit {
  let fs = @fs_adapter.NodeFsAdapter::new()
  run_new_command_with_fs(fs, args)
}

///|
fn[FS : @env.FileSystem] run_new_command_with_fs(
  fs : FS,
  args : Array[String],
) -> Unit {
  // Parse new command options
  let result = @util.parseArgs(
    args~,
    options=[
      @util.String(key="title", short="t", multiple=false, default=None),
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
  let title : String = if result.values.contains("title") {
    result.values["title"].cast()
  } else {
    project_name
  }
  // Get project directory path
  let cwd = @process.cwd()
  let project_dir = @path.join2(cwd, project_name)
  // Check if project directory already exists
  if fs.exists_sync(project_dir) {
    console_error(
      @colorette.red("Error: Directory '\{project_name}' already exists"),
    )
    @process.exit(1)
  }
  println(@colorette.cyan("Creating new Astra project: \{project_dir}"))
  println(@colorette.gray("  Title: \{title}"))
  // Generate project from templates
  let templates = generate_astra_templates(project_name, title)
  for tmpl in templates {
    let file_path = @path.join2(project_dir, tmpl.path)
    let dir_path = @path.dirname(file_path)
    // Create parent directories if needed
    try {
      fs.mkdir_sync(dir_path, true)
      fs.write_file_sync(file_path, tmpl.content)
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

///|
struct AstraTemplate {
  path : String
  content : String
}

///|
fn template_astra_json(title : String) -> String {
  let tmpl =
    #|{
    #|  "docs": "docs",
    #|  "output": "dist-docs",
    #|  "title": "{{TITLE}}",
    #|  "base": "/",
    #|  "trailingSlash": true,
    #|  "sidebar": "auto",
    #|  "theme": {
    #|    "primaryColor": "#3b82f6"
    #|  }
    #|}
  tmpl.replace(old="{{TITLE}}", new=title)
}

///|
fn template_index_md(project_name : String, title : String) -> String {
  let tmpl =
    #|---
    #|title: "{{TITLE}}"
    #|layout: home
    #|---
    #|
    #|# {{TITLE}}
    #|
    #|Welcome to {{PROJECT_NAME}}!
    #|
    #|---
    #|
    #|## Getting Started
    #|
    #|Check out the [Introduction](./introduction/) to learn more.
  tmpl
  .replace_all(old="{{TITLE}}", new=title)
  .replace_all(old="{{PROJECT_NAME}}", new=project_name)
}

///|
fn template_introduction_md(project_name : String) -> String {
  let tmpl =
    #|---
    #|title: Introduction
    #|---
    #|
    #|# Introduction
    #|
    #|Welcome to {{PROJECT_NAME}}.
    #|
    #|## Overview
    #|
    #|This is the introduction section. Add your documentation here.
    #|
    #|## Next Steps
    #|
    #|- Add more sections by creating directories like `01_getting-started/`
    #|- Each section should have an `index.md` file
    #|- Sub-pages can be numbered like `01_first-page.md`, `02_second-page.md`
  tmpl.replace(old="{{PROJECT_NAME}}", new=project_name)
}

///|
fn template_package_json(project_name : String) -> String {
  let tmpl =
    #|{
    #|  "name": "{{PROJECT_NAME}}",
    #|  "version": "0.1.0",
    #|  "private": true,
    #|  "type": "module",
    #|  "scripts": {
    #|    "dev": "astra dev",
    #|    "build": "astra build"
    #|  },
    #|  "devDependencies": {
    #|    "@mizchi/astra": "^0.0.1"
    #|  }
    #|}
  tmpl.replace(old="{{PROJECT_NAME}}", new=project_name)
}

///|
fn template_readme_md(project_name : String, title : String) -> String {
  let tmpl =
    #|# {{TITLE}}
    #|
    #|Documentation site powered by [Astra](https://github.com/aspect-build/luna).
    #|
    #|## Development
    #|
    #|```bash
    #|npm install
    #|npm run dev
    #|```
    #|
    #|Open http://localhost:3355 to preview your documentation.
    #|
    #|## Build
    #|
    #|```bash
    #|npm run build
    #|```
    #|
    #|Static files are generated in `dist-docs/` directory.
    #|
    #|## Publish
    #|
    #|The `dist-docs/` directory can be published as a static site:
    #|
    #|- **GitHub Pages**: Push `dist-docs/` to `gh-pages` branch
    #|- **Netlify/Vercel**: Set build output to `dist-docs/`
    #|- **Any static hosting**: Upload contents of `dist-docs/`
    #|
    #|## Project Structure
    #|
    #|```
    #|{{PROJECT_NAME}}/
    #|  astra.json      # Site configuration
    #|  docs/           # Markdown source files
    #|    index.md      # Home page
    #|    00_*/         # Sections (sorted by prefix)
    #|  dist-docs/      # Generated static site
    #|```
  tmpl
  .replace_all(old="{{TITLE}}", new=title)
  .replace_all(old="{{PROJECT_NAME}}", new=project_name)
}

///|
fn generate_astra_templates(
  project_name : String,
  title : String,
) -> Array[AstraTemplate] {
  [
    { path: "README.md", content: template_readme_md(project_name, title) },
    { path: "package.json", content: template_package_json(project_name) },
    { path: "astra.json", content: template_astra_json(title) },
    { path: "docs/index.md", content: template_index_md(project_name, title) },
    {
      path: "docs/00_introduction/index.md",
      content: template_introduction_md(project_name),
    },
  ]
}
