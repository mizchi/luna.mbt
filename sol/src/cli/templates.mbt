// Sol CLI Templates - thin re-exports + JS-only variants.
//
// The default-app templates / `generate_templates` and the cloudflare
// starter / `generate_cloudflare_templates` live in
// `mizchi/sol/scaffold_templates` so that the native install shim
// (`mizchi/sol/cmd/sol`) can scaffold a project — including the
// cloudflare worker starter — from outside any moon project. The only
// piece that stays here is `template_ln_loader_js`, which depends on
// `@astra_assets` and is therefore JS-only.

// Re-export the shared scaffold types/fns so that downstream callers in
// this package (and the existing test surface) keep working unchanged.

///|
pub using @scaffold_templates {
  type TemplateFile,
  template_gitignore,
  template_moon_mod_json,
  template_package_json,
  template_sol_config_json,
  template_layout_mbt,
  template_layout_moon_pkg,
  template_server_using_mbt,
  template_routes_main_mbt,
  template_routes_mbt,
  template_routes_moon_pkg,
  template_routes_using_mbt,
  template_client_counter_mbt,
  template_client_api_tools_mbt,
  template_client_counter_moon_pkg,
  template_gen_types_moon_pkg,
  template_gen_types_mbt,
  template_cloudflare_routes_main_mbt,
  template_cloudflare_routes_moon_pkg,
  template_worker_entry_mjs,
  generate_templates,
  generate_cloudflare_templates,
}

// Note: For different runtimes, update sol.config.json:
// - "node"       - Node.js with @hono/node-server (default)
// - "cloudflare" - Cloudflare Workers (exports fetch handler)
// - "deno"       - Deno.serve
// - "bun"        - Bun.serve

///|
/// Generate template files for a documentation site project
pub fn generate_doc_templates(
  package_name : String,
  project_name : String,
) -> Array[TemplateFile] {
  let sol_config = "{\n  \"islands\": [],\n  \"routes\": \"app/server\",\n  \"output\": \"app/__gen__\",\n  \"runtime\": \"node\",\n  \"staticDirs\": [\n    {\n      \"pathPrefix\": \"/docs\",\n      \"sourceDir\": \"docs\",\n      \"title\": \"\{project_name}\",\n      \"sidebar\": \"auto\",\n      \"trailingSlash\": true,\n      \"theme\": {\n        \"primaryColor\": \"#3b82f6\",\n        \"socialLinks\": [],\n        \"header\": {\n          \"left\": [\"logo\"],\n          \"right\": [\"navLinks\", \"themeToggle\"],\n          \"sticky\": true\n        },\n        \"footer\": {\n          \"message\": \"Built with Sol\",\n          \"copyright\": \"2025\"\n        }\n      }\n    }\n  ]\n}"
  let gitignore = template_gitignore() + "\ndist\n.sol-cache"
  [
    { path: ".gitignore", content: gitignore },
    {
      path: "moon.mod.json",
      content: template_moon_mod_json(package_name, None),
    },
    { path: "package.json", content: template_package_json(project_name) },
    { path: "sol.config.json", content: sol_config },
    {
      path: "app/server/moon.pkg",
      content: "import {\n  \"mizchi/sol\" @sol,\n  \"moonbitlang/async\",\n}\n\nsupported_targets = \"js\"\nwarnings = \"-67-29\"\n\noptions(\n  \"is-main\": true,\n  link: { \"js\": { \"format\": \"esm\" } },\n)",
    },
    { path: "app/server/main.mbt", content: template_routes_main_mbt() },
    {
      path: "app/server/routes.mbt",
      content: "///| Route definitions\n\npub fn routes() -> Array[@sol.SolRoutes] {\n  [\n    @sol.api_get(\"/api/health\", api_health),\n  ]\n}\n\npub fn config() -> @sol.RouterConfig {\n  @sol.RouterConfig::default()\n}\n\npriv struct HealthResponse {\n  status : String\n} derive(ToJson)\n\nasync fn api_health(_props : @sol.PageProps) -> HealthResponse {\n  { status: \"ok\" }\n}",
    },
    {
      path: "docs/index.md",
      content: "---\nlayout: home\ntitle: \{project_name}\n---\n\n# \{project_name}\n\nWelcome to \{project_name} documentation.\n\n## Getting Started\n\nSee the [Guide](/docs/guide/) to get started.\n",
    },
    {
      path: "docs/guide/index.md",
      content: "---\ntitle: Guide\n---\n\n# Guide\n\nThis section covers the basics of \{project_name}.\n",
    },
    {
      path: "docs/guide/getting-started.md",
      content: "---\ntitle: Getting Started\n---\n\n# Getting Started\n\n## Prerequisites\n\n- [MoonBit](https://moonbitlang.com/) toolchain\n- Node.js 24+\n- pnpm\n\n## Installation\n\n```bash\nmoon update\npnpm install\n```\n\n## Development\n\nStart the dev server:\n\n```bash\nsol dev\n```\n\nOpen [http://localhost:7777/docs/](http://localhost:7777/docs/) in your browser.\n\n## Build\n\n```bash\nsol build\n```\n\nThe output will be in the `dist/` directory.\n",
    },
    {
      path: "docs/guide/configuration.md",
      content: "---\ntitle: Configuration\n---\n\n# Configuration\n\nSol uses `sol.config.json` for project configuration.\n\n## Example\n\n```json\n{\n  \"staticDirs\": [\n    {\n      \"pathPrefix\": \"/docs\",\n      \"sourceDir\": \"docs\",\n      \"title\": \"My Docs\",\n      \"sidebar\": \"auto\"\n    }\n  ]\n}\n```\n\n## Options\n\n| Key | Type | Description |\n|-----|------|-------------|\n| `pathPrefix` | string | URL prefix for docs |\n| `sourceDir` | string | Directory containing markdown files |\n| `title` | string | Site title |\n| `sidebar` | string/array | `\"auto\"` or manual sidebar config |\n| `theme` | object | Theme customization |\n",
    },
    {
      path: "docs/api/index.md",
      content: "---\ntitle: API Reference\n---\n\n# API Reference\n\nAPI documentation for \{project_name}.\n",
    },
    {
      path: "README.md",
      content: "# \{project_name}\n\nDocumentation site built with [Sol](https://github.com/mizchi/luna.mbt/tree/main/sol).\n\n## Quick Start\n\n```bash\nmoon update\npnpm install\nsol dev\n```\n\nOpen http://localhost:7777/docs/\n\n## Project Structure\n\n```\ndocs/                 # Markdown documentation\n  index.md            # Home page\n  guide/              # Guide section\n  api/                # API reference\napp/\n  server/             # Server routes\nsol.config.json       # Sol configuration\n```\n",
    },
  ]
}
