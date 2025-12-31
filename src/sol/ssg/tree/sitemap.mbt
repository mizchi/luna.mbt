///|
/// Sitemap Generator
/// Generate sitemap.xml from DocumentTree
///
/// NOTE: Implementation moved to core/ssg/generators.mbt for sharing with Sol.
/// This file re-exports for backward compatibility.

///|
/// Generate sitemap.xml
pub fn generate_sitemap(tree : @ssg_core.DocumentTree) -> String {
  @ssg_core.generate_sitemap(tree)
}
