///|
/// SSG Simulation Test - Verifies FileSystem trait works for SSG-like operations
/// Simulate reading markdown and writing HTML (like SSG does)
test "SSG simulation: read markdown and write HTML" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()

  // Setup: Create docs directory with markdown file
  mem.mkdirSync("/project/docs", recursive=true)
  mem.writeFileSync(
    "/project/docs/index.md",
    (
      #|---
      #|title: Hello World
      #|---
      #|# Welcome
      #|
      #|This is a test page.
    ),
  )

  // Simulate SSG: Read markdown
  let content = mem.readFileSync("/project/docs/index.md")
  inspect(content.contains("title: Hello World"), content="true")
  inspect(content.contains("# Welcome"), content="true")

  // Simulate SSG: Create output directory
  mem.mkdirSync("/project/dist", recursive=true)

  // Simulate SSG: Write HTML output
  let html =
    #|<!DOCTYPE html>
    #|<html>
    #|<head><title>Hello World</title></head>
    #|<body><h1>Welcome</h1><p>This is a test page.</p></body>
    #|</html>
  mem.writeFileSync("/project/dist/index.html", html)

  // Verify output
  inspect(mem.existsSync("/project/dist/index.html"), content="true")
  let output = mem.readFileSync("/project/dist/index.html")
  inspect(output.contains("<title>Hello World</title>"), content="true")
}

///|
/// Simulate asset generation (CSS, JS files)
test "SSG simulation: generate assets" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()

  // Create assets directory
  mem.mkdirSync("/project/dist/assets", recursive=true)

  // Write CSS
  let css =
    #|body { margin: 0; }
    #|.container { max-width: 800px; }
  mem.writeFileSync("/project/dist/assets/style.css", css)

  // Write JS
  let js =
    #|console.log('Hello');
  mem.writeFileSync("/project/dist/assets/loader.js", js)

  // Verify
  let entries = mem.readdirSync("/project/dist/assets")
  inspect(entries.length(), content="2")
  inspect(mem.existsSync("/project/dist/assets/style.css"), content="true")
  inspect(mem.existsSync("/project/dist/assets/loader.js"), content="true")
}

///|
/// Simulate directory scanning (like file_router.mbt does)
test "SSG simulation: scan docs directory" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()

  // Setup: Create nested docs structure
  mem.mkdirSync("/docs/guide", recursive=true)
  mem.mkdirSync("/docs/api", recursive=true)
  mem.writeFileSync("/docs/index.md", "# Home")
  mem.writeFileSync("/docs/guide/getting-started.md", "# Getting Started")
  mem.writeFileSync("/docs/guide/advanced.md", "# Advanced")
  mem.writeFileSync("/docs/api/reference.md", "# API Reference")

  // Scan root
  let root_entries = mem.readdirSync("/docs")
  inspect(root_entries.length(), content="3") // index.md, guide/, api/

  // Check if entry is directory
  let guide_stat = mem.statSync("/docs/guide")
  inspect(guide_stat.isDirectory(), content="true")
  let index_stat = mem.statSync("/docs/index.md")
  inspect(index_stat.isFile(), content="true")

  // Scan subdirectory
  let guide_entries = mem.readdirSync("/docs/guide")
  inspect(guide_entries.length(), content="2")
}

///|
/// Simulate copying public directory (like cpSync does)
/// Note: Uses memfs directly since trait impl is not visible in blackbox tests
test "SSG simulation: copy public directory" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()

  // Setup: Create public directory with assets
  mem.mkdirSync("/project/public/images", recursive=true)
  mem.writeFileSync("/project/public/favicon.ico", "icon data")
  mem.writeFileSync("/project/public/robots.txt", "User-agent: *")
  mem.writeFileSync("/project/public/images/logo.png", "png data")

  // Manual copy simulation (memfs lacks cpSync)
  mem.mkdirSync("/project/dist/images", recursive=true)
  mem.writeFileSync(
    "/project/dist/favicon.ico",
    mem.readFileSync("/project/public/favicon.ico"),
  )
  mem.writeFileSync(
    "/project/dist/robots.txt",
    mem.readFileSync("/project/public/robots.txt"),
  )
  mem.writeFileSync(
    "/project/dist/images/logo.png",
    mem.readFileSync("/project/public/images/logo.png"),
  )

  // Verify copied files
  inspect(mem.existsSync("/project/dist/favicon.ico"), content="true")
  inspect(mem.existsSync("/project/dist/robots.txt"), content="true")
  inspect(mem.existsSync("/project/dist/images/logo.png"), content="true")

  // Verify content
  let favicon = mem.readFileSync("/project/dist/favicon.ico")
  inspect(favicon, content="icon data")
}

///|
/// Simulate sitemap generation
test "SSG simulation: generate sitemap" {
  let fs = MemFSAdapter::new()
  let mem = fs.memfs()

  // Create output directory
  mem.mkdirSync("/dist", recursive=true)

  // Generate sitemap XML
  let sitemap = StringBuilder::new()
  sitemap.write_string(
    (
      #|<?xml version="1.0" encoding="UTF-8"?>
      #|<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    ),
  )
  let urls = ["/", "/guide/", "/api/"]
  for url in urls {
    sitemap.write_string("  <url><loc>https://example.com")
    sitemap.write_string(url)
    sitemap.write_string("</loc></url>\n")
  }
  sitemap.write_string("</urlset>")
  mem.writeFileSync("/dist/sitemap.xml", sitemap.to_string())

  // Verify
  let content = mem.readFileSync("/dist/sitemap.xml")
  inspect(content.contains("<urlset"), content="true")
  inspect(content.contains("https://example.com/guide/"), content="true")
}
