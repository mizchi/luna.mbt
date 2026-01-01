// Tests for File Scanner Path Utilities

// =============================================================================
// ScanOptions Tests
// =============================================================================

///|
test "ScanOptions::default - expected values" {
  let options = ScanOptions::default()
  inspect(options.exclude.length(), content="0")
  inspect(options.trailing_slash, content="true")
}

// =============================================================================
// join_path Tests
// =============================================================================

///|
test "join_path - empty base" {
  inspect(join_path("", "file.md"), content="file.md")
}

///|
test "join_path - base without trailing slash" {
  inspect(join_path("docs", "intro.md"), content="docs/intro.md")
}

///|
test "join_path - base with trailing slash" {
  inspect(join_path("docs/", "intro.md"), content="docs/intro.md")
}

///|
test "join_path - nested paths" {
  inspect(join_path("docs/guide", "setup.md"), content="docs/guide/setup.md")
}

///|
test "join_path - root path" {
  inspect(join_path("/", "file.md"), content="/file.md")
}

// =============================================================================
// get_basename Tests
// =============================================================================

///|
test "get_basename - simple filename" {
  inspect(get_basename("file.md"), content="file.md")
}

///|
test "get_basename - path with directory" {
  inspect(get_basename("docs/intro.md"), content="intro.md")
}

///|
test "get_basename - nested path" {
  inspect(get_basename("docs/guide/setup.md"), content="setup.md")
}

///|
test "get_basename - absolute path" {
  inspect(get_basename("/home/user/docs/file.md"), content="file.md")
}

///|
test "get_basename - trailing slash returns original path" {
  // When path ends with /, there's no basename after it, so returns original
  inspect(get_basename("docs/guide/"), content="docs/guide/")
}

// =============================================================================
// get_parent_dir Tests
// =============================================================================

///|
test "get_parent_dir - simple path" {
  inspect(get_parent_dir("docs/file.md"), content="docs")
}

///|
test "get_parent_dir - nested path" {
  inspect(get_parent_dir("docs/guide/setup.md"), content="docs/guide")
}

///|
test "get_parent_dir - single filename" {
  inspect(get_parent_dir("file.md"), content="")
}

///|
test "get_parent_dir - absolute path" {
  inspect(get_parent_dir("/home/user/docs/file.md"), content="/home/user/docs")
}

///|
test "get_parent_dir - root path" {
  inspect(get_parent_dir("/file.md"), content="")
}

// =============================================================================
// get_extension Tests
// =============================================================================

///|
test "get_extension - markdown" {
  inspect(get_extension("intro.md"), content=".md")
}

///|
test "get_extension - mdx" {
  inspect(get_extension("page.mdx"), content=".mdx")
}

///|
test "get_extension - html" {
  inspect(get_extension("index.html"), content=".html")
}

///|
test "get_extension - moonbit" {
  inspect(get_extension("component.mbt"), content=".mbt")
}

///|
test "get_extension - no extension" {
  inspect(get_extension("Makefile"), content="")
}

///|
test "get_extension - multiple dots" {
  inspect(get_extension("file.test.md"), content=".md")
}

///|
test "get_extension - hidden file" {
  inspect(get_extension(".gitignore"), content=".gitignore")
}

// =============================================================================
// is_content_file Tests
// =============================================================================

///|
test "is_content_file - markdown" {
  inspect(is_content_file("intro.md"), content="true")
}

///|
test "is_content_file - mdx" {
  inspect(is_content_file("page.mdx"), content="true")
}

///|
test "is_content_file - html" {
  inspect(is_content_file("index.html"), content="true")
}

///|
test "is_content_file - other extensions" {
  inspect(is_content_file("script.js"), content="false")
  inspect(is_content_file("styles.css"), content="false")
  inspect(is_content_file("data.json"), content="false")
  inspect(is_content_file("component.mbt"), content="false")
}

///|
test "is_content_file - no extension" {
  inspect(is_content_file("README"), content="false")
}

// =============================================================================
// is_moonbit_component Tests
// =============================================================================

///|
test "is_moonbit_component - moon.pkg.json" {
  inspect(is_moonbit_component("moon.pkg.json"), content="true")
}

///|
test "is_moonbit_component - other json files" {
  inspect(is_moonbit_component("package.json"), content="false")
  inspect(is_moonbit_component("tsconfig.json"), content="false")
}

///|
test "is_moonbit_component - similar names" {
  inspect(is_moonbit_component("moon.mod.json"), content="false")
}

// =============================================================================
// is_tsx_file Tests
// =============================================================================

///|
test "is_tsx_file - tsx files" {
  inspect(is_tsx_file("Component.tsx"), content="true")
  inspect(is_tsx_file("page.tsx"), content="true")
}

///|
test "is_tsx_file - other files" {
  inspect(is_tsx_file("Component.ts"), content="false")
  inspect(is_tsx_file("Component.jsx"), content="false")
  inspect(is_tsx_file("Component.js"), content="false")
}

// =============================================================================
// is_excluded Tests
// =============================================================================

///|
test "is_excluded - public directory always excluded" {
  let exclude : Array[String] = []
  inspect(is_excluded("public", "public", exclude), content="true")
  inspect(is_excluded("assets", "public/assets", exclude), content="true")
}

///|
test "is_excluded - by directory name" {
  let exclude = ["internal", "drafts"]
  inspect(is_excluded("internal", "docs/internal", exclude), content="true")
  inspect(is_excluded("drafts", "blog/drafts", exclude), content="true")
  inspect(is_excluded("published", "blog/published", exclude), content="false")
}

///|
test "is_excluded - by exact relative path" {
  let exclude = ["internal/drafts"]
  inspect(is_excluded("drafts", "internal/drafts", exclude), content="true")
  inspect(is_excluded("drafts", "other/drafts", exclude), content="false")
}

///|
test "is_excluded - by path prefix" {
  let exclude = ["internal"]
  inspect(
    is_excluded("wip", "internal/wip", exclude),
    content="true",
  ) // internal/wip has prefix internal/
  inspect(is_excluded("external", "external", exclude), content="false")
}

///|
test "is_excluded - empty exclude list" {
  let exclude : Array[String] = []
  inspect(is_excluded("docs", "docs", exclude), content="false")
  inspect(is_excluded("internal", "internal", exclude), content="false")
}

///|
test "is_excluded - multiple patterns" {
  let exclude = ["node_modules", ".git", "__pycache__"]
  inspect(is_excluded("node_modules", "node_modules", exclude), content="true")
  inspect(is_excluded(".git", ".git", exclude), content="true")
  inspect(is_excluded("__pycache__", "__pycache__", exclude), content="true")
  inspect(is_excluded("src", "src", exclude), content="false")
}

// =============================================================================
// FileEntry Tests
// =============================================================================

///|
test "FileEntry - construction" {
  let entry = FileEntry::{
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
  let entry = FileEntry::{
    relative_path: "docs/guide",
    absolute_path: "/home/user/project/docs/guide",
    extension: "",
    is_directory: true,
  }
  inspect(entry.is_directory, content="true")
  inspect(entry.extension, content="")
}
