///|
/// Tests for Radix-style DSD components
/// Verifies SSR output with data-* attributes for styling

///|
test "radix_button - basic" {
  let node = radix_button([@luna.text("Click me")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="radix-button")
  // Should have template + text child
  inspect(el.children.length(), content="2")
}

///|
test "radix_button - has data-variant attribute" {
  let node = radix_button(variant=Destructive, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Get template
  guard el.children[0] is @luna.Element(template) else {
    fail("expected template")
  }

  // Find button inside template and check data-variant
  fn find_button_variant(nodes : Array[@luna.Node[Unit]]) -> String {
    for node in nodes {
      match node {
        @luna.Element(e) => {
          if e.tag == "button" {
            for attr in e.attrs {
              let (name, value) = attr
              if name == "data-variant" {
                match value {
                  @luna.VStatic(v) => return v
                  _ => ()
                }
              }
            }
          }
          let result = find_button_variant(e.children)
          if result != "" {
            return result
          }
        }
        _ => ()
      }
    }
    ""
  }

  inspect(find_button_variant(template.children), content="destructive")
}

///|
test "radix_button - disabled has data-disabled" {
  let node = radix_button(disabled=true, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Get template
  guard el.children[0] is @luna.Element(template) else {
    fail("expected template")
  }

  // Find button inside template and check data-disabled
  fn has_data_disabled(nodes : Array[@luna.Node[Unit]]) -> Bool {
    for node in nodes {
      match node {
        @luna.Element(e) => {
          if e.tag == "button" {
            for attr in e.attrs {
              let (name, _) = attr
              if name == "data-disabled" {
                return true
              }
            }
          }
          if has_data_disabled(e.children) {
            return true
          }
        }
        _ => ()
      }
    }
    false
  }

  inspect(has_data_disabled(template.children), content="true")
}

///|
test "radix_checkbox - basic" {
  let node = radix_checkbox([@luna.text("Accept terms")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="radix-checkbox")
}

///|
test "radix_checkbox - has data-state on host" {
  let node = radix_checkbox(checked=Checked, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-state on host element
  let has_state = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("checked")
    })
  inspect(has_state, content="true")
}

///|
test "radix_checkbox - indeterminate state" {
  let node = radix_checkbox(checked=Indeterminate, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-state on host element
  let has_state = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("indeterminate")
    })
  inspect(has_state, content="true")
}

///|
test "radix_checkbox - has aria-checked" {
  let node = radix_checkbox(checked=Checked, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Get template
  guard el.children[0] is @luna.Element(template) else {
    fail("expected template")
  }

  // Find button with role=checkbox and check aria-checked
  fn find_aria_checked(nodes : Array[@luna.Node[Unit]]) -> String {
    for node in nodes {
      match node {
        @luna.Element(e) => {
          if e.tag == "button" {
            for attr in e.attrs {
              let (name, value) = attr
              if name == "aria-checked" {
                match value {
                  @luna.VStatic(v) => return v
                  _ => ()
                }
              }
            }
          }
          let result = find_aria_checked(e.children)
          if result != "" {
            return result
          }
        }
        _ => ()
      }
    }
    ""
  }

  inspect(find_aria_checked(template.children), content="true")
}

///|
test "radix_switch - basic" {
  let node = radix_switch([@luna.text("Enable")])
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="radix-switch")
}

///|
test "radix_switch - checked state" {
  let node = radix_switch(checked=true, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-state on host element
  let has_state = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("checked")
    })
  inspect(has_state, content="true")
}

///|
test "radix_switch - unchecked state" {
  let node = radix_switch(checked=false, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-state on host element
  let has_state = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, value) = attr
      name == "data-state" && value is @luna.VStatic("unchecked")
    })
  inspect(has_state, content="true")
}

///|
test "radix_switch - has role=switch" {
  let node = radix_switch([])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Get template
  guard el.children[0] is @luna.Element(template) else {
    fail("expected template")
  }

  // Find button with role=switch
  fn has_role_switch(nodes : Array[@luna.Node[Unit]]) -> Bool {
    for node in nodes {
      match node {
        @luna.Element(e) => {
          if e.tag == "button" {
            for attr in e.attrs {
              let (name, value) = attr
              if name == "role" {
                match value {
                  @luna.VStatic("switch") => return true
                  _ => ()
                }
              }
            }
          }
          if has_role_switch(e.children) {
            return true
          }
        }
        _ => ()
      }
    }
    false
  }

  inspect(has_role_switch(template.children), content="true")
}

///|
test "radix_switch - with size" {
  let node = radix_switch(size=Small, [])
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Get template
  guard el.children[0] is @luna.Element(template) else {
    fail("expected template")
  }

  // Find button and check data-size
  fn find_size(nodes : Array[@luna.Node[Unit]]) -> String {
    for node in nodes {
      match node {
        @luna.Element(e) => {
          if e.tag == "button" {
            for attr in e.attrs {
              let (name, value) = attr
              if name == "data-size" {
                match value {
                  @luna.VStatic(v) => return v
                  _ => ()
                }
              }
            }
          }
          let result = find_size(e.children)
          if result != "" {
            return result
          }
        }
        _ => ()
      }
    }
    ""
  }

  inspect(find_size(template.children), content="small")
}

///|
test "radix_input - basic" {
  let node = radix_input(label="Username", placeholder="Enter username")
  guard node is @luna.Element(el) else { fail("expected Element") }
  inspect(el.tag, content="radix-input")

  // Should have template child
  guard el.children[0] is @luna.Element(template) else {
    fail("expected template")
  }
  inspect(template.tag, content="template")
}

///|
test "radix_input - has data-size" {
  let node = radix_input(size=Large)
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Get template
  guard el.children[0] is @luna.Element(template) else {
    fail("expected template")
  }

  // Find input and check data-size
  fn find_input_size(nodes : Array[@luna.Node[Unit]]) -> String {
    for node in nodes {
      match node {
        @luna.Element(e) => {
          if e.tag == "input" {
            for attr in e.attrs {
              let (name, value) = attr
              if name == "data-size" {
                match value {
                  @luna.VStatic(v) => return v
                  _ => ()
                }
              }
            }
          }
          let result = find_input_size(e.children)
          if result != "" {
            return result
          }
        }
        _ => ()
      }
    }
    ""
  }

  inspect(find_input_size(template.children), content="large")
}

///|
test "radix_input - password type" {
  let node = radix_input(type_=Password)
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Get template
  guard el.children[0] is @luna.Element(template) else {
    fail("expected template")
  }

  // Find input and check type
  fn find_input_type(nodes : Array[@luna.Node[Unit]]) -> String {
    for node in nodes {
      match node {
        @luna.Element(e) => {
          if e.tag == "input" {
            for attr in e.attrs {
              let (name, value) = attr
              if name == "type" {
                match value {
                  @luna.VStatic(v) => return v
                  _ => ()
                }
              }
            }
          }
          let result = find_input_type(e.children)
          if result != "" {
            return result
          }
        }
        _ => ()
      }
    }
    ""
  }

  inspect(find_input_type(template.children), content="password")
}

///|
test "radix_input - disabled" {
  let node = radix_input(disabled=true)
  guard node is @luna.Element(el) else { fail("expected Element") }

  // Check data-disabled on host element
  let has_disabled = el.attrs
    .iter()
    .any(fn(attr) {
      let (name, _) = attr
      name == "data-disabled"
    })
  inspect(has_disabled, content="true")
}
