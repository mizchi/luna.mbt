///|
/// Convert TriggerType to attribute value.
/// ```mbt check
/// test {
///   inspect(TriggerType::Load.to_string(), content="load")
///   inspect(TriggerType::Idle.to_string(), content="idle")
///   inspect(TriggerType::Visible.to_string(), content="visible")
///   inspect(
///     TriggerType::Media("(max-width: 768px)").to_string(),
///     content="media:(max-width: 768px)",
///   )
///   inspect(TriggerType::None.to_string(), content="none")
/// }
/// ```
pub fn TriggerType::to_string(self : TriggerType) -> String {
  match self {
    Load => "load"
    Idle => "idle"
    Visible => "visible"
    Media(query) => "media:" + query
    None => "none"
  }
}

///|
/// Parse TriggerType from string.
/// ```mbt check
/// test {
///   // Round-trip test: parse then to_string
///   inspect(TriggerType::parse("load").to_string(), content="load")
///   inspect(TriggerType::parse("idle").to_string(), content="idle")
///   inspect(TriggerType::parse("visible").to_string(), content="visible")
///   inspect(TriggerType::parse("none").to_string(), content="none")
///   inspect(
///     TriggerType::parse("media:(min-width: 1024px)").to_string(),
///     content="media:(min-width: 1024px)",
///   )
/// }
/// ```
pub fn TriggerType::parse(s : String) -> TriggerType {
  match s {
    "load" => Load
    "idle" => Idle
    "visible" => Visible
    "none" => None
    _ =>
      if s.has_prefix("media:") {
        let sb = StringBuilder::new()
        for i in 6..<s.length() {
          sb.write_char(s.iter().nth(i).unwrap())
        }
        Media(sb.to_string())
      } else {
        Load // default
      }
  }
}
