// Tests for File Scanner Path Utilities

// =============================================================================
// ScanOptions Tests
// =============================================================================

///|
test "ScanOptions::default - expected values" {
  let options = @routes.ScanOptions::default()
  inspect(options.exclude.length(), content="0")
  inspect(options.trailing_slash, content="true")
}

// =============================================================================
// join_path Tests
// =============================================================================

///|
test "join_path - empty base" {
  inspect(@routes.join_path("", "file.md"), content="file.md")
}

///|
test "join_path - base without trailing slash" {
  inspect(@routes.join_path("docs", "intro.md"), content="docs/intro.md")
}

///|
test "join_path - base with trailing slash" {
  inspect(@routes.join_path("docs/", "intro.md"), content="docs/intro.md")
}

///|
test "join_path - nested paths" {
  inspect(
    @routes.join_path("docs/guide", "setup.md"),
    content="docs/guide/setup.md",
  )
}

///|
test "join_path - root path" {
  inspect(@routes.join_path("/", "file.md"), content="/file.md")
}

// =============================================================================
// get_basename Tests
// =============================================================================

///|
test "get_basename - simple filename" {
  inspect(@routes.get_basename("file.md"), content="file.md")
}

///|
test "get_basename - path with directory" {
  inspect(@routes.get_basename("docs/intro.md"), content="intro.md")
}

///|
test "get_basename - nested path" {
  inspect(@routes.get_basename("docs/guide/setup.md"), content="setup.md")
}

///|
test "get_basename - absolute path" {
  inspect(@routes.get_basename("/home/user/docs/file.md"), content="file.md")
}

///|
test "get_basename - trailing slash returns original path" {
  // When path ends with /, there's no basename after it, so returns original
  inspect(@routes.get_basename("docs/guide/"), content="docs/guide/")
}

// =============================================================================
// get_parent_dir Tests
// =============================================================================

///|
test "get_parent_dir - simple path" {
  inspect(@routes.get_parent_dir("docs/file.md"), content="docs")
}

///|
test "get_parent_dir - nested path" {
  inspect(@routes.get_parent_dir("docs/guide/setup.md"), content="docs/guide")
}

///|
test "get_parent_dir - single filename" {
  inspect(@routes.get_parent_dir("file.md"), content="")
}

///|
test "get_parent_dir - absolute path" {
  inspect(
    @routes.get_parent_dir("/home/user/docs/file.md"),
    content="/home/user/docs",
  )
}

///|
test "get_parent_dir - root path" {
  inspect(@routes.get_parent_dir("/file.md"), content="")
}

// =============================================================================
// get_extension Tests
// =============================================================================

///|
test "get_extension - markdown" {
  inspect(@routes.get_extension("intro.md"), content=".md")
}

///|
test "get_extension - mdx" {
  inspect(@routes.get_extension("page.mdx"), content=".mdx")
}

///|
test "get_extension - html" {
  inspect(@routes.get_extension("index.html"), content=".html")
}

///|
test "get_extension - moonbit" {
  inspect(@routes.get_extension("component.mbt"), content=".mbt")
}

///|
test "get_extension - no extension" {
  inspect(@routes.get_extension("Makefile"), content="")
}

///|
test "get_extension - multiple dots" {
  inspect(@routes.get_extension("file.test.md"), content=".md")
}

///|
test "get_extension - hidden file" {
  inspect(@routes.get_extension(".gitignore"), content=".gitignore")
}

// =============================================================================
// is_content_file Tests
// =============================================================================

///|
test "is_content_file - markdown" {
  inspect(@routes.is_content_file("intro.md"), content="true")
}

///|
test "is_content_file - mdx" {
  inspect(@routes.is_content_file("page.mdx"), content="true")
}

///|
test "is_content_file - html" {
  inspect(@routes.is_content_file("index.html"), content="true")
}

///|
test "is_content_file - other extensions" {
  inspect(@routes.is_content_file("script.js"), content="false")
  inspect(@routes.is_content_file("styles.css"), content="false")
  inspect(@routes.is_content_file("data.json"), content="false")
  inspect(@routes.is_content_file("component.mbt"), content="false")
}

///|
test "is_content_file - no extension" {
  inspect(@routes.is_content_file("README"), content="false")
}

// =============================================================================
// is_moonbit_component Tests
// =============================================================================

///|
test "is_moonbit_component - moon.pkg.json" {
  inspect(@routes.is_moonbit_component("moon.pkg.json"), content="true")
}

///|
test "is_moonbit_component - other json files" {
  inspect(@routes.is_moonbit_component("package.json"), content="false")
  inspect(@routes.is_moonbit_component("tsconfig.json"), content="false")
}

///|
test "is_moonbit_component - similar names" {
  inspect(@routes.is_moonbit_component("moon.mod.json"), content="false")
}

// =============================================================================
// is_tsx_file Tests
// =============================================================================

///|
test "is_tsx_file - tsx files" {
  inspect(@routes.is_tsx_file("Component.tsx"), content="true")
  inspect(@routes.is_tsx_file("page.tsx"), content="true")
}

///|
test "is_tsx_file - other files" {
  inspect(@routes.is_tsx_file("Component.ts"), content="false")
  inspect(@routes.is_tsx_file("Component.jsx"), content="false")
  inspect(@routes.is_tsx_file("Component.js"), content="false")
}

// =============================================================================
// is_excluded Tests
// =============================================================================

///|
test "is_excluded - public directory always excluded" {
  let exclude : Array[String] = []
  inspect(@routes.is_excluded("public", "public", exclude), content="true")
  inspect(
    @routes.is_excluded("assets", "public/assets", exclude),
    content="true",
  )
}

///|
test "is_excluded - by directory name" {
  let exclude = ["internal", "drafts"]
  inspect(
    @routes.is_excluded("internal", "docs/internal", exclude),
    content="true",
  )
  inspect(@routes.is_excluded("drafts", "blog/drafts", exclude), content="true")
  inspect(
    @routes.is_excluded("published", "blog/published", exclude),
    content="false",
  )
}

///|
test "is_excluded - by exact relative path" {
  let exclude = ["internal/drafts"]
  inspect(
    @routes.is_excluded("drafts", "internal/drafts", exclude),
    content="true",
  )
  inspect(
    @routes.is_excluded("drafts", "other/drafts", exclude),
    content="false",
  )
}

///|
test "is_excluded - by path prefix" {
  let exclude = ["internal"]
  inspect(@routes.is_excluded("wip", "internal/wip", exclude), content="true") // internal/wip has prefix internal/
  inspect(@routes.is_excluded("external", "external", exclude), content="false")
}

///|
test "is_excluded - empty exclude list" {
  let exclude : Array[String] = []
  inspect(@routes.is_excluded("docs", "docs", exclude), content="false")
  inspect(@routes.is_excluded("internal", "internal", exclude), content="false")
}

///|
test "is_excluded - multiple patterns" {
  let exclude = ["node_modules", ".git", "__pycache__"]
  inspect(
    @routes.is_excluded("node_modules", "node_modules", exclude),
    content="true",
  )
  inspect(@routes.is_excluded(".git", ".git", exclude), content="true")
  inspect(
    @routes.is_excluded("__pycache__", "__pycache__", exclude),
    content="true",
  )
  inspect(@routes.is_excluded("src", "src", exclude), content="false")
}

// =============================================================================
// FileEntry Tests
// =============================================================================

///|
test "FileEntry - construction" {
  let entry = @routes.FileEntry::{
    relative_path: "docs/intro.md",
    absolute_path: "/home/user/project/docs/intro.md",
    extension: ".md",
    is_directory: false,
  }
  inspect(entry.relative_path, content="docs/intro.md")
  inspect(entry.extension, content=".md")
  inspect(entry.is_directory, content="false")
}

///|
test "FileEntry - directory entry" {
  let entry = @routes.FileEntry::{
    relative_path: "docs/guide",
    absolute_path: "/home/user/project/docs/guide",
    extension: "",
    is_directory: true,
  }
  inspect(entry.is_directory, content="true")
  inspect(entry.extension, content="")
}

// =============================================================================
// Filesystem Helper Tests
// =============================================================================

///|
test "read_dir_entries - missing directory returns empty list" {
  let fs = @fs_adapter.MemFSAdapter::new()
  let entries = @routes.read_dir_entries(fs, "/missing")
  assert_eq(entries.length(), 0)
}

///|
test "is_directory - distinguishes file and directory" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  fs.memfs().writeFileSync("/project/docs/intro.md", "# Intro")

  assert_true(@routes.is_directory(fs, "/project/docs"))
  assert_false(@routes.is_directory(fs, "/project/docs/intro.md"))
  assert_false(@routes.is_directory(fs, "/project/missing"))
}

// =============================================================================
// MoonBit Literate Markdown (.mbt.md)
// =============================================================================

///|
test "is_content_file - mbt.md is a page source" {
  inspect(@routes.is_content_file("intro.mbt.md"), content="true")
  inspect(@routes.is_content_file("intro.md"), content="true")
  inspect(@routes.is_content_file("intro.mbt"), content="false")
  inspect(@routes.is_content_file("moon.pkg"), content="false")
}

///|
test "is_moonbit_markdown - only the compound extension" {
  inspect(@routes.is_moonbit_markdown("intro.mbt.md"), content="true")
  inspect(@routes.is_moonbit_markdown("intro.md"), content="false")
  inspect(@routes.is_moonbit_markdown("intro.mbt"), content="false")
}

///|
test "is_excluded - MoonBit build artifacts are always skipped" {
  inspect(@routes.is_excluded("_build", "_build", []), content="true")
  inspect(@routes.is_excluded("target", "guide/target", []), content="true")
  inspect(@routes.is_excluded(".mooncakes", ".mooncakes", []), content="true")
  inspect(@routes.is_excluded("guide", "guide", []), content="false")
}
