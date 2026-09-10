///|
/// One static declaration. Construct with rule, rule_on, rule_media, or rule_when.
pub struct StyleRule {
  priv property : String
  priv value : String?
  priv pseudo : String
  priv condition : String
  priv class_name : String
}

///|
/// An immutable, portable style. It does not use the global CSS registries.
pub struct Style {
  priv rules : Array[StyleRule]
  priv variables : Array[(String, String)]
}

///|
/// Attribute values shared by SSR and client rendering. Pass these through the
/// renderer's attribute API; they are not pre-escaped HTML.
pub(all) struct StyleAttrs {
  class_name : String
  style : String
} derive(Eq, Debug)

///|
pub suberror StyleError {
  InvalidCustomProperty(String)
}

///|
pub fn[P : PropertyName] rule(property : P, value : String) -> StyleRule {
  make_rule(property.css_name(), value, "", "")
}

///|
pub fn[S : PseudoSelector, P : PropertyName] rule_on(
  pseudo : S,
  property : P,
  value : String,
) -> StyleRule {
  make_rule(property.css_name(), value, pseudo.css_selector(), "")
}

///|
pub fn[P : PropertyName] rule_media(
  condition : String,
  property : P,
  value : String,
) -> StyleRule {
  make_rule(property.css_name(), value, "", condition)
}

///|
/// A pseudo selector inside a media query (condition excludes @media and its parentheses).
pub fn[S : PseudoSelector, P : PropertyName] rule_when(
  condition : String,
  pseudo : S,
  property : P,
  value : String,
) -> StyleRule {
  make_rule(property.css_name(), value, pseudo.css_selector(), condition)
}

///|
/// Remove an element property, including all its pseudo-class and media cases.
pub fn[P : PropertyName] unset(property : P) -> StyleRule {
  {
    property: property.css_name(),
    value: None,
    pseudo: "",
    condition: "",
    class_name: "",
  }
}

///|
fn make_rule(
  property : String,
  value : String,
  pseudo : String,
  condition : String,
) -> StyleRule {
  let declaration = {
    property,
    value: Some(value),
    pseudo,
    condition,
    class_name: "",
  }
  { ..declaration, class_name: hash_class_name(declaration.hash_key(value)) }
}

///|
/// Compiler output only: the class name must match the declaration's canonical
/// hash. Normal callers should use rule/rule_on/rule_media/rule_when.
pub fn precompiled_rule(
  property : String,
  value : String?,
  pseudo : String,
  condition : String,
  class_name : String,
) -> StyleRule {
  { property, value, pseudo, condition, class_name }
}

///|
/// Compiler output only: rules must already have create's slot normalization.
pub fn precompiled_style(rules : Array[StyleRule]) -> Style {
  { rules: rules.copy(), variables: [] }
}

///|
fn StyleRule::scope(self : StyleRule) -> String {
  // Pseudo-elements have independent property namespaces; pseudo-classes don't.
  match self.pseudo.find("::") {
    None => ""
    Some(start) => {
      let tail = self.pseudo[start + 2:].to_owned()
      match tail.find(":") {
        None => "::" + tail
        Some(end) => "::" + tail[:end].to_owned()
      }
    }
  }
}

///|
/// Group conditional declarations into a style. Repeated slots use the last
/// value. Keep declarations literal when using build-time extraction.
pub fn create(declarations : Array[StyleRule]) -> Style {
  let slots : Map[(String, String, String), StyleRule] = Map([])
  for declaration in declarations {
    if declaration.value is None {
      let removed : Array[(String, String, String)] = []
      for key, existing in slots {
        if existing.property == declaration.property &&
          existing.scope() == declaration.scope() {
          removed.push(key)
        }
      }
      for key in removed {
        slots.remove(key)
      }
    }
    let key = (declaration.property, declaration.pseudo, declaration.condition)
    slots.set(key, declaration)
  }
  { rules: slots.values().collect(), variables: [] }
}

///|
/// Later styles replace an entire property (including its conditions). Different
/// pseudo-elements remain independent. Shorthand/longhand overlaps follow CSS;
/// use explicit longhands when those properties need to be composed.
pub fn compose(styles : Array[Style]) -> Style {
  let groups : Map[(String, String), Array[StyleRule]] = Map([])
  let variables : Map[String, String] = Map([])
  for style in styles {
    let incoming : Map[(String, String), Array[StyleRule]] = Map([])
    for declaration in style.rules {
      let key = (declaration.scope(), declaration.property)
      match incoming.get(key) {
        Some(group) => group.push(declaration)
        None => incoming.set(key, [declaration])
      }
    }
    for key, group in incoming {
      groups.set(key, group)
    }
    for pair in style.variables {
      let (name, value) = pair
      variables.set(name, value)
    }
  }
  let rules : Array[StyleRule] = []
  for _, group in groups {
    for declaration in group {
      rules.push(declaration)
    }
  }
  { rules, variables: variables.iter().collect() }
}

///|
pub fn Style::when(self : Style, enabled : Bool) -> Style {
  if enabled {
    self
  } else {
    create([])
  }
}

///|
fn validate_custom_property(name : String) -> Unit raise StyleError {
  if !name.has_prefix("--") || name.length() <= 2 {
    raise InvalidCustomProperty(name)
  }
  for ch in name {
    match ch {
      'a'..='z' | 'A'..='Z' | '0'..='9' | '-' | '_' => ()
      _ => raise InvalidCustomProperty(name)
    }
  }
}

///|
/// A class-based theme with explicit CSS custom-property names. Apply to a
/// containing element or shadow host so descendants inherit the variables.
pub fn create_theme(
  variables : Array[(String, String)],
) -> Style raise StyleError {
  let declarations = []
  for pair in variables {
    let (name, value) = pair
    validate_custom_property(name)
    declarations.push(rule(name, value))
  }
  create(declarations)
}

///|
/// Bind runtime values to CSS custom properties without generating new classes
/// or stylesheet rules. Values use CSS syntax (e.g. "12px", not "12").
pub fn Style::with_vars(
  self : Style,
  variables : Array[(String, String)],
) -> Style raise StyleError {
  let values : Map[String, String] = Map([])
  for pair in self.variables {
    let (name, value) = pair
    values.set(name, value)
  }
  for pair in variables {
    let (name, value) = pair
    validate_custom_property(name)
    values.set(name, value)
  }
  { rules: self.rules, variables: values.iter().collect() }
}

///|
fn StyleRule::hash_key(self : StyleRule, value : String) -> String {
  let declaration = self.property + ":" + value
  let with_pseudo = if self.pseudo == "" {
    declaration
  } else {
    self.pseudo + ":" + declaration
  }
  if self.condition == "" {
    with_pseudo
  } else {
    "@media(" + self.condition + "):" + with_pseudo
  }
}

///|
/// Resolve styles to class and inline-style values for Luna attributes.
pub fn attrs(styles : Array[Style]) -> StyleAttrs {
  let resolved = compose(styles)
  let classes : Map[String, Bool] = Map([])
  for declaration in resolved.rules {
    if declaration.value is Some(_) {
      classes.set(declaration.class_name, true)
    }
  }
  let names : Array[String] = classes.keys().collect()
  names.sort_by(fn(a, b) { a.lexical_compare(b) })
  let variables = resolved.variables.copy()
  variables.sort_by(fn(a, b) { a.0.lexical_compare(b.0) })
  {
    class_name: names.join(" "),
    style: variables.map(fn(pair) { pair.0 + ":" + pair.1 }).join(";"),
  }
}
