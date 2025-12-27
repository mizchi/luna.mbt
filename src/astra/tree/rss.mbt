///|
/// RSS Feed Generator
/// DocumentTree から RSS 2.0 フィードを生成する
///
/// NOTE: Implementation moved to core/ssg/generators.mbt for sharing with Sol.
/// This file re-exports for backward compatibility.

///|
/// RSS 2.0 フィードを生成
pub fn generate_rss(tree : @ssg.DocumentTree, limit? : Int = 20) -> String {
  @ssg.generate_rss(tree, limit~)
}
