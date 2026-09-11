///|
fn pseudo_order(pseudo : String) -> Int {
  match pseudo {
    "" => 0
    ":link" => 1
    ":visited" => 2
    ":focus-within" => 3
    ":hover" => 4
    ":focus" => 5
    ":focus-visible" => 6
    ":active" => 7
    ":disabled" => 8
    _ => 9
  }
}

///|
fn compare_style_rules(a : StyleRule, b : StyleRule) -> Int {
  let a_media = if a.condition == "" { 0 } else { 1 }
  let b_media = if b.condition == "" { 0 } else { 1 }
  if a_media != b_media {
    return a_media - b_media
  }
  let condition = compare_conditions(a.condition, b.condition)
  if condition != 0 {
    return condition
  }
  let pseudo = pseudo_order(a.pseudo) - pseudo_order(b.pseudo)
  if pseudo != 0 {
    return pseudo
  }
  let selector = a.pseudo.lexical_compare(b.pseudo)
  if selector != 0 {
    return selector
  }
  let property = a.property.lexical_compare(b.property)
  if property != 0 {
    return property
  }
  match (a.value, b.value) {
    (Some(a), Some(b)) => a.lexical_compare(b)
    _ => 0
  }
}

///|
fn numeric_condition(condition : String) -> (String, String, Double)? {
  guard condition.find(":") is Some(colon) else { return None }
  let feature = condition[:colon].to_owned()
  match feature {
    "min-width" | "max-width" | "min-height" | "max-height" => ()
    _ => return None
  }
  let value = condition[colon + 1:].trim().to_owned()
  let unit = if value.has_suffix("rem") {
    "rem"
  } else if value.has_suffix("em") {
    "em"
  } else if value.has_suffix("px") {
    "px"
  } else {
    return None
  }
  let number = value[:value.length() - unit.length()]
  guard number.length() > 0 else { return None }
  for ch in number {
    match ch {
      '0'..='9' | '.' => ()
      _ => return None
    }
  }
  try @string.parse_double(number) catch {
    _ => None
  } noraise {
    size => Some((feature, unit, size))
  }
}

///|
fn compare_conditions(a : String, b : String) -> Int {
  if a == b {
    return 0
  }
  if a == "" {
    return -1
  }
  if b == "" {
    return 1
  }
  match (numeric_condition(a), numeric_condition(b)) {
    (Some((af, au, av)), Some((bf, bu, bv))) => {
      let feature = af.lexical_compare(bf)
      if feature != 0 {
        return feature
      }
      let unit = au.lexical_compare(bu)
      if unit != 0 {
        return unit
      }
      if av != bv {
        let order = av.compare(bv)
        return if af.has_prefix("min-") { order } else { -order }
      }
    }
    (Some(_), None) => return -1
    (None, Some(_)) => return 1
    _ => ()
  }
  // String::compare orders by length first; use lexical order to match JS.
  a.lexical_compare(b)
}

///|
/// Collect all possible styles for a document or one shadow root. Include every
/// variant, not only the currently selected variant. No request-global state is
/// read or mutated, so this also works before streaming starts and on native/Wasm.
pub fn stylesheet(styles : Array[Style]) -> String {
  let unique : Map[String, StyleRule] = Map([])
  for style in styles {
    for declaration in style.rules {
      if declaration.value is Some(value) {
        unique.set(declaration.hash_key(value), declaration)
      }
    }
  }
  let rules : Array[StyleRule] = unique.values().collect()
  rules.sort_by(compare_style_rules)
  let output = StringBuilder()
  for declaration in rules {
    if declaration.value is Some(value) {
      if declaration.condition != "" {
        output.write_string("@media(" + declaration.condition + "){")
      }
      output.write_string("." + declaration.class_name)
      let safe_value = value.replace(old="<", new="\\3c ")
      output.write_string(
        declaration.pseudo + "{" + declaration.property + ":" + safe_value + "}",
      )
      if declaration.condition != "" {
        output.write_char('}')
      }
    }
  }
  output.to_string()
}
