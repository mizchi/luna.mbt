///|
/// Explicit wrapper for trusted inline script content.
pub(all) struct TrustedScript {
  content : String
}

///|
/// Explicit wrapper for trusted inline style content.
pub(all) struct TrustedStyle {
  content : String
}

///|
pub fn unsafe_trusted_script(content : String) -> TrustedScript {
  { content, }
}

///|
pub fn unsafe_trusted_style(content : String) -> TrustedStyle {
  { content, }
}

///|
pub fn TrustedScript::to_string(self : TrustedScript) -> String {
  self.content
}

///|
pub fn TrustedStyle::to_string(self : TrustedStyle) -> String {
  self.content
}

///|
pub fn script_trusted(
  content : TrustedScript,
  type_? : String,
  id? : String,
  class? : String,
  style? : String,
  attrs? : Array[(String, @luna.Attr[Unit, String])],
) -> @luna.Node[Unit, String] {
  script(content=content.to_string(), type_?, id?, class?, style?, attrs?)
}

///|
pub fn style_trusted(
  content : TrustedStyle,
  type_? : String,
  id? : String,
  class? : String,
  style? : String,
  attrs? : Array[(String, @luna.Attr[Unit, String])],
) -> @luna.Node[Unit, String] {
  style_(content.to_string(), type_?, id?, class?, style?, attrs?)
}
