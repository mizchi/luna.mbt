///| sol new — create a new Sol project (native, no Node.js required)

///|
async fn run_new(args : Array[String]) -> Unit {
  // Parse args
  let mut project_name = ""
  let mut user_ns = ""
  let mut is_doc = false
  let mut i = 0
  while i < args.length() {
    match args[i] {
      "--user" | "-u" =>
        if i + 1 < args.length() {
          user_ns = args[i + 1]
          i += 2
        } else {
          println("Error: --user requires a value")
          @sys.exit(1)
        }
      "--doc" | "--docs" => {
        is_doc = true
        i += 1
      }
      "--help" | "-h" => {
        println("Usage: sol new <name> --user <namespace> [--doc]")
        println("")
        println("Options:")
        println("  --user, -u <ns>  MoonBit package namespace (required)")
        println("  --doc            Generate documentation site template")
        return
      }
      _ =>
        if project_name == "" {
          project_name = args[i]
          i += 1
        } else {
          println("Error: unexpected argument: \{args[i]}")
          @sys.exit(1)
        }
    }
  }
  if project_name == "" {
    println("Error: project name is required")
    println("Usage: sol new <name> --user <namespace> [--doc]")
    @sys.exit(1)
  }
  if user_ns == "" {
    println("Error: --user is required")
    @sys.exit(1)
  }
  // Derive package name
  let parts = project_name.split("/").collect()
  let base_name = parts[parts.length() - 1].to_string()
  let package_name = "\{user_ns}/\{base_name}"
  // Check if directory exists
  if @fs.exists(project_name) {
    println("Error: directory '\{project_name}' already exists")
    @sys.exit(1)
  }
  let template_type = if is_doc { "doc" } else { "app" }
  println("Creating new Sol project: \{project_name} (template: \{template_type})")
  println("  Package: \{package_name}")
  // Generate files
  let files = if is_doc {
    new_doc_project_files(package_name, base_name)
  } else {
    new_project_files(package_name, base_name)
  }
  for file in files {
    let path = project_name + "/" + file.0
    let dir = dirname(path)
    @fs.mkdir(dir, permission=0o755, recursive=true) catch { _ => () }
    @fs.write_file(path, file.1) catch {
      e => {
        println("Error writing " + path)
        @sys.exit(1)
      }
    }
  }
  println("")
  println("✓ Project created!")
  println("")
  println("Next steps:")
  println("  cd \{project_name}")
  println("  moon update")
  if is_doc {
    println("  pnpm install")
    println("  sol dev")
  } else {
    println("  sol build")
  }
}

///|
fn dirname(path : String) -> String {
  let mut last_slash = -1
  for i, c in path {
    if c == '/' {
      last_slash = i
    }
  }
  if last_slash <= 0 {
    "."
  } else {
    path.substring(end=last_slash)
  }
}

// =============================================================================
// Documentation Site Template
// =============================================================================

///|
fn new_doc_project_files(
  package_name : String,
  project_name : String,
) -> Array[(String, String)] {
  [
    (
      "moon.mod.json",
      "{\n  \"name\": \"\{package_name}\",\n  \"version\": \"0.1.0\",\n  \"deps\": {\n    \"mizchi/sol\": \"0.14.1\",\n    \"mizchi/mars\": \"0.3.10\",\n    \"mizchi/luna\": \"0.18.3\",\n    \"mizchi/js\": \"0.10.15\",\n    \"mizchi/npm_typed\": \"0.1.11\",\n    \"moonbitlang/async\": \"0.17.0\"\n  },\n  \"source\": \"app\",\n  \"preferred-target\": \"js\"\n}",
    ),
    (
      "package.json",
      "{\n  \"name\": \"\{project_name}\",\n  \"version\": \"0.1.0\",\n  \"type\": \"module\",\n  \"scripts\": {\n    \"dev\": \"sol dev\",\n    \"build\": \"sol build\",\n    \"serve\": \"sol serve\"\n  },\n  \"dependencies\": {\n    \"hono\": \"^4.12.12\",\n    \"@hono/node-server\": \"^1.19.13\"\n  },\n  \"devDependencies\": {\n    \"rolldown\": \"1.0.0-rc.13\"\n  }\n}",
    ),
    (
      "sol.config.json",
      "{\n  \"islands\": [],\n  \"routes\": \"app/server\",\n  \"output\": \"app/__gen__\",\n  \"runtime\": \"node\",\n  \"staticDirs\": [\n    {\n      \"pathPrefix\": \"/docs\",\n      \"sourceDir\": \"docs\",\n      \"title\": \"\{project_name}\",\n      \"sidebar\": \"auto\",\n      \"trailingSlash\": true,\n      \"theme\": {\n        \"primaryColor\": \"#3b82f6\",\n        \"socialLinks\": [],\n        \"header\": {\n          \"left\": [\"logo\"],\n          \"right\": [\"navLinks\", \"themeToggle\"],\n          \"sticky\": true\n        },\n        \"footer\": {\n          \"message\": \"Built with Sol\",\n          \"copyright\": \"2025\"\n        }\n      }\n    }\n  ]\n}",
    ),
    (
      ".gitignore",
      ".mooncakes\n_build\ntarget\nnode_modules\napp/__gen__/client\napp/__gen__/server\n.sol\ndist\n.sol-cache",
    ),
    (
      "app/server/moon.pkg",
      "import {\n  \"mizchi/sol\" @sol,\n  \"moonbitlang/async\",\n}\n\noptions(\n  \"is-main\": true,\n  \"supported-targets\": \"js\",\n  \"warn-list\": \"-67-29\",\n  link: { \"js\": { \"format\": \"esm\" } },\n)",
    ),
    (
      "app/server/main.mbt",
      "///| Server entry point\n\nasync fn main {\n  @sol.run_app(fn() {\n    @sol.create_app(routes(), config=config())\n  })\n}",
    ),
    (
      "app/server/routes.mbt",
      "///| Route definitions\n\npub fn routes() -> Array[@sol.SolRoutes] {\n  [\n    @sol.api_get(\"/api/health\", api_health),\n  ]\n}\n\npub fn config() -> @sol.RouterConfig {\n  @sol.RouterConfig::default()\n}\n\npriv struct HealthResponse {\n  status : String\n} derive(ToJson)\n\nasync fn api_health(_props : @sol.PageProps) -> HealthResponse {\n  { status: \"ok\" }\n}",
    ),
    // Documentation content
    (
      "docs/index.md",
      "---\nlayout: home\ntitle: \{project_name}\n---\n\n# \{project_name}\n\nWelcome to \{project_name} documentation.\n\n## Getting Started\n\nSee the [Guide](/docs/guide/) to get started.\n",
    ),
    (
      "docs/guide/index.md",
      "---\ntitle: Guide\n---\n\n# Guide\n\nThis section covers the basics of \{project_name}.\n",
    ),
    (
      "docs/guide/getting-started.md",
      "---\ntitle: Getting Started\n---\n\n# Getting Started\n\n## Prerequisites\n\n- [MoonBit](https://moonbitlang.com/) toolchain\n- Node.js 24+\n- pnpm\n\n## Installation\n\n```bash\nmoon update\npnpm install\n```\n\n## Development\n\nStart the dev server:\n\n```bash\nsol dev\n```\n\nOpen [http://localhost:7777/docs/](http://localhost:7777/docs/) in your browser.\n\n## Build\n\n```bash\nsol build\n```\n\nThe output will be in the `dist/` directory.\n",
    ),
    (
      "docs/guide/configuration.md",
      "---\ntitle: Configuration\n---\n\n# Configuration\n\nSol uses `sol.config.json` for project configuration.\n\n## Example\n\n```json\n{\n  \"staticDirs\": [\n    {\n      \"pathPrefix\": \"/docs\",\n      \"sourceDir\": \"docs\",\n      \"title\": \"My Docs\",\n      \"sidebar\": \"auto\"\n    }\n  ]\n}\n```\n\n## Options\n\n| Key | Type | Description |\n|-----|------|-------------|\n| `pathPrefix` | string | URL prefix for docs |\n| `sourceDir` | string | Directory containing markdown files |\n| `title` | string | Site title |\n| `sidebar` | string/array | `\"auto\"` or manual sidebar config |\n| `theme` | object | Theme customization |\n",
    ),
    (
      "docs/api/index.md",
      "---\ntitle: API Reference\n---\n\n# API Reference\n\nAPI documentation for \{project_name}.\n",
    ),
    (
      "README.md",
      "# \{project_name}\n\nDocumentation site built with [Sol](https://github.com/mizchi/sol.mbt).\n\n## Quick Start\n\n```bash\nmoon update\npnpm install\nsol dev\n```\n\nOpen http://localhost:7777/docs/\n\n## Project Structure\n\n```\ndocs/                 # Markdown documentation\n  index.md            # Home page\n  guide/              # Guide section\n    index.md\n    getting-started.md\n    configuration.md\n  api/                # API reference section\n    index.md\napp/\n  server/             # Server routes\nsol.config.json       # Sol configuration\n```\n\n## Commands\n\n| Command | Description |\n|---------|-------------|\n| `sol dev` | Start dev server with HMR |\n| `sol build` | Build for production |\n| `sol serve` | Serve production build |\n",
    ),
  ]
}

// =============================================================================
// App Template
// =============================================================================

///|
fn new_project_files(
  package_name : String,
  project_name : String,
) -> Array[(String, String)] {
  [
    (
      "moon.mod.json",
      "{\n  \"name\": \"\{package_name}\",\n  \"version\": \"0.1.0\",\n  \"deps\": {\n    \"mizchi/sol\": \"0.14.1\",\n    \"mizchi/mars\": \"0.3.10\",\n    \"mizchi/luna\": \"0.18.3\",\n    \"mizchi/signals\": \"0.6.4\",\n    \"mizchi/js\": \"0.10.15\",\n    \"mizchi/npm_typed\": \"0.1.11\",\n    \"moonbitlang/async\": \"0.17.0\"\n  },\n  \"source\": \"app\",\n  \"preferred-target\": \"js\"\n}",
    ),
    (
      "package.json",
      "{\n  \"name\": \"\{project_name}\",\n  \"version\": \"0.1.0\",\n  \"type\": \"module\",\n  \"scripts\": {\n    \"dev\": \"sol dev\",\n    \"build\": \"sol build\",\n    \"serve\": \"sol serve\"\n  },\n  \"dependencies\": {\n    \"hono\": \"^4.12.12\",\n    \"@hono/node-server\": \"^1.19.13\"\n  },\n  \"devDependencies\": {\n    \"rolldown\": \"1.0.0-rc.13\"\n  }\n}",
    ),
    (
      "sol.config.json",
      "{\n  \"islands\": [\"app/client\"],\n  \"routes\": \"app/server\",\n  \"output\": \"app/__gen__\",\n  \"runtime\": \"node\"\n}",
    ),
    (
      ".gitignore",
      ".mooncakes\n_build\ntarget\nnode_modules\napp/__gen__/client\napp/__gen__/server\n.sol",
    ),
    (
      "app/server/moon.pkg",
      "import {\n  \"mizchi/sol\" @sol,\n  \"mizchi/luna/dom/static\" @server_dom,\n  \"\{package_name}/__gen__/types\" @types,\n  \"moonbitlang/async\",\n}\n\noptions(\n  \"is-main\": true,\n  \"supported-targets\": \"js\",\n  \"warn-list\": \"-67-29\",\n  link: { \"js\": { \"format\": \"esm\" } },\n)",
    ),
    (
      "app/server/main.mbt",
      "///| Server entry point\n\nasync fn main {\n  @sol.run_app(fn() {\n    @sol.create_app(routes(), config=config())\n  })\n}",
    ),
    (
      "app/server/routes.mbt",
      "///| Route definitions\n\npub fn routes() -> Array[@sol.SolRoutes] {\n  [\n    @sol.api_get(\"/api/health\", api_health),\n  ]\n}\n\npub fn config() -> @sol.RouterConfig {\n  @sol.RouterConfig::default()\n}\n\npriv struct HealthResponse {\n  status : String\n} derive(ToJson)\n\nasync fn api_health(_props : @sol.PageProps) -> HealthResponse {\n  { status: \"ok\" }\n}",
    ),
    (
      "README.md",
      "# \{project_name}\n\nBuilt with [Sol](https://github.com/mizchi/sol.mbt) — SSR web framework for MoonBit.\n\n## Quick Start\n\n```bash\nmoon update\npnpm install\nsol dev\n```\n\nOpen http://localhost:7777\n\n## Commands\n\n| Command | Description |\n|---------|-------------|\n| `sol dev` | Start dev server with watch + HMR |\n| `sol build` | Build for production |\n| `sol serve` | Serve production build |\n| `sol generate` | Regenerate .sol directory |\n| `sol clean` | Remove generated files |\n\n## Project Structure\n\n```\napp/\n  server/\n    main.mbt      # Server entry point\n    routes.mbt    # Route definitions + handlers\n    moon.pkg      # Server package config\n  client/         # Client islands (optional)\n  __gen__/        # Auto-generated (sol generate)\nsol.config.json   # Sol configuration\nmoon.mod.json     # MoonBit module config\n```\n\n## Adding an API Endpoint\n\n```moonbit\n// Define response type\npriv struct UserResponse {\n  name : String\n  email : String\n} derive(ToJson)\n\n// Handler returns typed struct\nasync fn get_user(_props : @sol.PageProps) -> UserResponse {\n  { name: \"Alice\", email: \"alice@example.com\" }\n}\n\n// Register in routes()\n@sol.api_get(\"/api/user\", get_user)\n```\n\n## Adding a Page\n\n```moonbit\nasync fn about(_props : @sol.PageProps) -> @server_dom.ServerNode {\n  @sol.nodes([\n    h1([text(\"About\")]),\n    p([text(\"Hello from Sol!\")]),\n  ])\n}\n\n// Register in routes()\n@sol.route(\"/about\", about, title=\"About\")\n```\n",
    ),
  ]
}
