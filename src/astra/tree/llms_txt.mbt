///|
/// llms.txt Generator
/// DocumentTree から llms.txt を生成する
/// 参考: https://llmstxt.org/
///
/// NOTE: Implementation moved to core/ssg/generators.mbt for sharing with Sol.
/// This file re-exports for backward compatibility.

///|
/// llms.txt を生成
pub fn generate_llms_txt(tree : @ssg.DocumentTree) -> String {
  @ssg.generate_llms_txt(tree)
}
