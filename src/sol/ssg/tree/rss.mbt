///|
/// RSS Feed Generator
/// Generate RSS 2.0 feed from DocumentTree
///
/// NOTE: Implementation moved to core/ssg/generators.mbt for sharing with Sol.
/// This file re-exports for backward compatibility.

///|
/// Generate RSS 2.0 feed
pub fn generate_rss(tree : @ssg_core.DocumentTree, limit? : Int = 20) -> String {
  @ssg_core.generate_rss(tree, limit~)
}
