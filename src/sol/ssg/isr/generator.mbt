// Astra ISR Metadata Generator
//
// Generates ISR manifest at build time.
// Uses shared types from sol/isr.

// =============================================================================
// Manifest Generation
// =============================================================================

///|
/// Build ISR manifest from pages
pub fn build_manifest(pages : Array[@ssg.PageMeta]) -> @sol_isr.ISRManifest {
  let manifest = @sol_isr.ISRManifest::new()
  for page in pages {
    // Only include pages with revalidate set
    match page.frontmatter.revalidate {
      Some(revalidate) =>
        if revalidate > 0 {
          let renderer = match page.renderer_type {
            @ssg.RendererType::MarkdownRenderer => "markdown"
            @ssg.RendererType::HtmlRenderer => "html"
            @ssg.RendererType::LunaRenderer => "luna"
            @ssg.RendererType::ReactRenderer => "react"
            @ssg.RendererType::ClientOnlyRenderer => "client"
            @ssg.RendererType::MdxRenderer => "mdx"
          }
          let entry : @sol_isr.ISRPageMeta = {
            revalidate,
            renderer,
            source: page.source_path,
          }
          manifest.add(page.url_path, entry)
        }
      None => ()
    }
  }
  manifest
}

///|
/// Write ISR manifest to file
pub fn write_manifest(
  manifest : @sol_isr.ISRManifest,
  output_dir : String,
) -> Unit {
  // Only write if there are ISR pages
  if manifest.is_empty() {
    return
  }

  // Create _luna directory
  let luna_dir = @path.join2(output_dir, "_luna")
  @fs.mkdirSync(luna_dir, recursive=true) catch {
    _ => ()
  }

  // Write manifest
  let manifest_path = @path.join2(luna_dir, "isr.json")
  let json = manifest.to_json()
  @fs.writeFileSync(manifest_path, @js.any(json)) catch {
    e => println("  Warning: Failed to write isr.json: \{e}")
  }
  println("  Generated: /_luna/isr.json (\{manifest.len()} ISR pages)")
}
