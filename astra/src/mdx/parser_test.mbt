///|
/// MDX Parser tests

///|
test "parse mdx with custom element containing BEM classes" {
  let content =
    #|<styled-checkbox-demo>
    #|  <div class="checkbox__control">
    #|    <span class="checkbox__icon--check"></span>
    #|  </div>
    #|</styled-checkbox-demo>
  let (_, nodes) = parse_mdx(content)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    @astra.MdNode::JsxComponent(embed) => {
      inspect(embed.tag, content="styled-checkbox-demo")
      // Check that children contains the BEM class names with __
      inspect(embed.children.contains("checkbox__control"), content="true")
      inspect(embed.children.contains("checkbox__icon--check"), content="true")
    }
    _ => fail("Expected JsxComponent node")
  }
}

///|
test "parse mdx single line with BEM classes" {
  let content = "<my-demo><span class=\"switch__thumb\"></span></my-demo>\n"
  let (_, nodes) = parse_mdx(content)
  inspect(nodes.length(), content="1")
  match nodes[0] {
    @astra.MdNode::JsxComponent(embed) => {
      inspect(embed.tag, content="my-demo")
      // __ must be preserved
      inspect(embed.children.contains("switch__thumb"), content="true")
    }
    _ => fail("Expected JsxComponent node")
  }
}

///|
test "parse mdx with markdown content before custom element" {
  // This simulates actual MDX file structure
  let content =
    #|# Checkbox
    #|
    #|Some description.
    #|
    #|## Demo
    #|
    #|<styled-checkbox-demo><div class="checkbox__control"><span class="checkbox__icon"></span></div></styled-checkbox-demo>
  let (_, nodes) = parse_mdx(content)
  // Find the JsxComponent node
  let mut found_jsx = false
  let mut children_has_bem = false
  for node in nodes {
    match node {
      @astra.MdNode::JsxComponent(embed) => {
        found_jsx = true
        children_has_bem = embed.children.contains("checkbox__control") &&
          embed.children.contains("checkbox__icon")
      }
      _ => ()
    }
  }
  inspect(found_jsx, content="true")
  inspect(children_has_bem, content="true")
}

///|
test "parse actual checkbox mdx content" {
  // Actual content from checkbox.mdx (simplified)
  let content = "---\ntitle: Checkbox\n---\n\n# Checkbox\n\nCheckbox input.\n\nBased on [APG Checkbox Pattern](https://www.w3.org/WAI/ARIA/apg/patterns/checkbox/).\n\n## Demo\n\n<styled-checkbox-demo luna:trigger=\"visible\"><div class=\"checkbox-group\" role=\"group\"><div class=\"checkbox\" data-checked=\"true\"><input type=\"checkbox\" class=\"checkbox__input\"><span class=\"checkbox__control\"><span class=\"checkbox__icon checkbox__icon--check\"></span></span><span class=\"checkbox__label\">Checked option</span></div></div></styled-checkbox-demo>\n"
  let (_, nodes) = parse_mdx(content)
  // Find and check the JsxComponent
  for node in nodes {
    match node {
      @astra.MdNode::JsxComponent(embed) => {
        println("Tag: \{embed.tag}")
        println("Children preview: \{embed.children[:200].to_string()}")
        // Check BEM classes are preserved
        assert_true(embed.children.contains("checkbox__input"))
        assert_true(embed.children.contains("checkbox__control"))
        assert_true(embed.children.contains("checkbox__icon"))
        assert_true(embed.children.contains("checkbox__label"))
      }
      _ => ()
    }
  }
}

///|
test "parse mdx with plain div HTML block (alert style)" {
  // Alert uses plain div, not a custom element
  let content =
    #|# Alert
    #|
    #|## Demo
    #|
    #|<div class="alert-demo">
    #|  <div class="alert alert--error" role="alert">
    #|    <div class="alert__title">Error</div>
    #|  </div>
    #|</div>
  let (_, nodes) = parse_mdx(content)
  println("Total nodes: \{nodes.length()}")
  let mut found_html = false
  for i, node in nodes {
    match node {
      @astra.MdNode::Html(html) => {
        println("Node \{i}: Html")
        let preview = if html.length() > 100 {
          html[:100].to_string()
        } else {
          html
        }
        println("  Content: \{preview}")
        // BEM classes should be preserved
        found_html = true
        assert_true(html.contains("alert__title"))
        assert_true(html.contains("alert--error"))
      }
      @astra.MdNode::Heading(level~, id~, ..) =>
        println("Node \{i}: Heading level=\{level} id=\{id}")
      _ => println("Node \{i}: other")
    }
  }
  assert_true(found_html)
}

///|
test "parse actual alert.mdx content" {
  // Exact content from alert.mdx
  let content =
    #|---
    #|title: Alert
    #|---
    #|
    #|# Alert
    #|
    #|Status messages for important information.
    #|
    #|## Demo
    #|
    #|<div class="alert-demo" style="display: flex; flex-direction: column; gap: 0.75rem;">
    #|  <div class="alert alert--status" role="alert" aria-live="polite" data-variant="status">
    #|    <div class="alert__title">Information</div>
    #|    <div class="alert__description">This is a status alert.</div>
    #|  </div>
    #|</div>
    #|
    #|## Usage
  let (_, nodes) = parse_mdx(content)
  println("=== Alert MDX Parse Result ===")
  println("Total nodes: \{nodes.length()}")
  let mut found_html_with_alert = false
  for i, node in nodes {
    match node {
      @astra.MdNode::Html(html) => {
        println("Node \{i}: Html (len=\{html.length()})")
        let preview = if html.length() > 80 {
          html[:80].to_string()
        } else {
          html
        }
        println("  \{preview}")
        if html.contains("alert-demo") {
          found_html_with_alert = true
          assert_true(html.contains("alert__title"))
        }
      }
      @astra.MdNode::Heading(level~, id~, ..) =>
        println("Node \{i}: Heading level=\{level} id=\{id}")
      @astra.MdNode::Paragraph(..) => println("Node \{i}: Paragraph")
      _ => println("Node \{i}: other")
    }
  }
  println("Found HTML with alert-demo: \{found_html_with_alert}")
  assert_true(found_html_with_alert)
}
