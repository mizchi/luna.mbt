///|
/// llms.txt Generator
/// Generate llms.txt from DocumentTree
/// Reference: https://llmstxt.org/
///
/// NOTE: Implementation moved to core/ssg/generators.mbt for sharing with Sol.
/// This file re-exports for backward compatibility.

///|
/// Generate llms.txt
pub fn generate_llms_txt(tree : @ssg_core.DocumentTree) -> String {
  @ssg_core.generate_llms_txt(tree)
}
