///|
/// Sitemap Generator
/// DocumentTree から sitemap.xml を生成する
///
/// NOTE: Implementation moved to core/ssg/generators.mbt for sharing with Sol.
/// This file re-exports for backward compatibility.

///|
/// sitemap.xml を生成
pub fn generate_sitemap(tree : @ssg.DocumentTree) -> String {
  @ssg.generate_sitemap(tree)
}
