///|
using @test {assert_eq}

// Tests for HTML Parsing Utilities
// Covers: extract_tag_name, extract_attribute, extract_all_attributes,
//         extract_inner_content, parse_island_directive, parse_custom_element

// =============================================================================
// extract_tag_name
// =============================================================================

///|
test "extract_tag_name returns tag name for simple element" {
  let result = extract_tag_name("<div>")
  assert_eq(result, Some("div"))
}

///|
test "extract_tag_name returns tag name for self-closing element" {
  let result = extract_tag_name("<br/>")
  assert_eq(result, Some("br"))
}

///|
test "extract_tag_name returns tag name when attributes follow" {
  let result = extract_tag_name("<Island name=\"counter\" />")
  assert_eq(result, Some("Island"))
}

///|
test "extract_tag_name returns tag name for custom element with hyphen" {
  let result = extract_tag_name("<my-counter value=\"0\">")
  assert_eq(result, Some("my-counter"))
}

///|
test "extract_tag_name returns None for empty string" {
  let result = extract_tag_name("")
  assert_eq(result, None)
}

///|
test "extract_tag_name returns None for string not starting with <" {
  let result = extract_tag_name("not-a-tag")
  assert_eq(result, None)
}

///|
test "extract_tag_name returns None for lone <>" {
  let result = extract_tag_name("<>")
  assert_eq(result, None)
}

///|
test "extract_tag_name handles closing tag marker" {
  let result = extract_tag_name("<input/>")
  assert_eq(result, Some("input"))
}

///|
test "extract_tag_name handles tag with > immediately" {
  let result = extract_tag_name("<span>content</span>")
  assert_eq(result, Some("span"))
}

// =============================================================================
// extract_attribute
// =============================================================================

///|
test "extract_attribute returns value with double quotes" {
  let result = extract_attribute("<Island name=\"counter\" />", "name")
  assert_eq(result, Some("counter"))
}

///|
test "extract_attribute returns value with single quotes" {
  let result = extract_attribute("<Island name='counter' />", "name")
  assert_eq(result, Some("counter"))
}

///|
test "extract_attribute returns None for missing attribute" {
  let result = extract_attribute("<Island name=\"counter\" />", "trigger")
  assert_eq(result, None)
}

///|
test "extract_attribute extracts :props attribute" {
  let html = "<Island name=\"counter\" :props='{\"initial\": 0}' />"
  let result = extract_attribute(html, ":props")
  assert_eq(result, Some("{\"initial\": 0}"))
}

///|
test "extract_attribute extracts trigger attribute" {
  let html = "<Island name=\"counter\" trigger=\"visible\" />"
  let result = extract_attribute(html, "trigger")
  assert_eq(result, Some("visible"))
}

///|
test "extract_attribute returns empty string for empty value" {
  let html = "<my-tag class=\"\" />"
  let result = extract_attribute(html, "class")
  assert_eq(result, Some(""))
}

///|
test "extract_attribute returns None on empty html" {
  let result = extract_attribute("", "name")
  assert_eq(result, None)
}

///|
test "extract_attribute extracts luna:trigger attribute" {
  let html = "<my-widget luna:trigger=\"idle\" />"
  let result = extract_attribute(html, "luna:trigger")
  assert_eq(result, Some("idle"))
}

// =============================================================================
// extract_all_attributes
// =============================================================================

///|
test "extract_all_attributes returns empty for element without attributes" {
  let result = extract_all_attributes("<div>")
  assert_eq(result.length(), 0)
}

///|
test "extract_all_attributes returns empty for self-closing no attrs" {
  let result = extract_all_attributes("<br/>")
  assert_eq(result.length(), 0)
}

///|
test "extract_all_attributes extracts single attribute" {
  let result = extract_all_attributes("<div class=\"foo\">")
  assert_eq(result.length(), 1)
  assert_eq(result[0].0, "class")
  assert_eq(result[0].1, "foo")
}

///|
test "extract_all_attributes extracts multiple attributes" {
  let html = "<my-counter value=\"5\" label=\"Count\" />"
  let result = extract_all_attributes(html)
  assert_eq(result.length(), 2)
  assert_eq(result[0].0, "value")
  assert_eq(result[0].1, "5")
  assert_eq(result[1].0, "label")
  assert_eq(result[1].1, "Count")
}

///|
test "extract_all_attributes skips luna:trigger attribute" {
  let html = "<my-widget value=\"1\" luna:trigger=\"visible\" />"
  let result = extract_all_attributes(html)
  // luna:trigger is excluded by the implementation
  assert_eq(result.length(), 1)
  assert_eq(result[0].0, "value")
}

///|
test "extract_all_attributes handles single-quoted values" {
  let html = "<my-el name='hello' />"
  let result = extract_all_attributes(html)
  assert_eq(result.length(), 1)
  assert_eq(result[0].0, "name")
  assert_eq(result[0].1, "hello")
}

///|
test "extract_all_attributes handles data attributes" {
  let html = "<div data-id=\"42\" data-label=\"item\">"
  let result = extract_all_attributes(html)
  assert_eq(result.length(), 2)
  assert_eq(result[0].0, "data-id")
  assert_eq(result[0].1, "42")
  assert_eq(result[1].0, "data-label")
  assert_eq(result[1].1, "item")
}

// =============================================================================
// extract_inner_content
// =============================================================================

///|
test "extract_inner_content returns empty for self-closing tag" {
  let result = extract_inner_content("<my-counter />", "my-counter")
  assert_eq(result, "")
}

///|
test "extract_inner_content returns content between open and close tags" {
  let html = "<my-widget>Hello World</my-widget>"
  let result = extract_inner_content(html, "my-widget")
  assert_eq(result, "Hello World")
}

///|
test "extract_inner_content returns empty when no closing tag" {
  let html = "<my-widget>content"
  let result = extract_inner_content(html, "my-widget")
  assert_eq(result, "")
}

///|
test "extract_inner_content handles nested HTML content" {
  let html = "<accordion-panel><div class=\"item\">text</div></accordion-panel>"
  let result = extract_inner_content(html, "accordion-panel")
  assert_eq(result, "<div class=\"item\">text</div>")
}

///|
test "extract_inner_content returns empty for element with no content" {
  let html = "<my-tag></my-tag>"
  let result = extract_inner_content(html, "my-tag")
  assert_eq(result, "")
}

///|
test "extract_inner_content returns empty for self-closing with attributes" {
  let html = "<my-counter value=\"0\" />"
  let result = extract_inner_content(html, "my-counter")
  assert_eq(result, "")
}

// =============================================================================
// parse_island_directive
// =============================================================================

///|
test "parse_island_directive returns None for non-Island element" {
  let result = parse_island_directive("<div class=\"foo\" />")
  assert_true(result is None)
}

///|
test "parse_island_directive returns None for element missing name" {
  let result = parse_island_directive("<Island trigger=\"visible\" />")
  assert_true(result is None)
}

///|
test "parse_island_directive parses basic Island with name" {
  let result = parse_island_directive("<Island name=\"counter\" />")
  match result {
    Some(embed) => {
      assert_eq(embed.name, "counter")
      assert_eq(embed.props, "{}")
      assert_eq(embed.ssr, false)
    }
    None => fail("Expected Some(IslandEmbed)")
  }
}

///|
test "parse_island_directive parses Island with props" {
  let html = "<Island name=\"counter\" props='{\"initial\": 5}' />"
  let result = parse_island_directive(html)
  match result {
    Some(embed) => {
      assert_eq(embed.name, "counter")
      assert_eq(embed.props, "{\"initial\": 5}")
    }
    None => fail("Expected Some(IslandEmbed)")
  }
}

///|
test "parse_island_directive uses :props over props" {
  let html = "<Island name=\"counter\" :props='{\"x\": 1}' props='{\"x\": 0}' />"
  let result = parse_island_directive(html)
  match result {
    Some(embed) => assert_eq(embed.props, "{\"x\": 1}")
    None => fail("Expected Some(IslandEmbed)")
  }
}

///|
test "parse_island_directive trigger visible" {
  let html = "<Island name=\"hero\" trigger=\"visible\" />"
  let result = parse_island_directive(html)
  match result {
    Some(embed) =>
      match embed.trigger {
        Visible => ()
        _ => fail("Expected TriggerType::Visible")
      }
    None => fail("Expected Some(IslandEmbed)")
  }
}

///|
test "parse_island_directive trigger idle" {
  let html = "<Island name=\"hero\" trigger=\"idle\" />"
  let result = parse_island_directive(html)
  match result {
    Some(embed) =>
      match embed.trigger {
        Idle => ()
        _ => fail("Expected TriggerType::Idle")
      }
    None => fail("Expected Some(IslandEmbed)")
  }
}

///|
test "parse_island_directive defaults to Load trigger" {
  let html = "<Island name=\"hero\" />"
  let result = parse_island_directive(html)
  match result {
    Some(embed) =>
      match embed.trigger {
        Load => ()
        _ => fail("Expected TriggerType::Load as default")
      }
    None => fail("Expected Some(IslandEmbed)")
  }
}

///|
test "parse_island_directive handles lowercase island tag" {
  let html = "<island name=\"counter\" />"
  let result = parse_island_directive(html)
  match result {
    Some(embed) => assert_eq(embed.name, "counter")
    None => fail("Expected Some(IslandEmbed) for lowercase island tag")
  }
}

///|
test "parse_island_directive returns None for empty string" {
  let result = parse_island_directive("")
  assert_true(result is None)
}

// =============================================================================
// parse_custom_element
// =============================================================================

///|
test "parse_custom_element returns None for non-tag string" {
  let result = parse_custom_element("not a tag")
  assert_true(result is None)
}

///|
test "parse_custom_element returns None for regular HTML element" {
  let result = parse_custom_element("<div class=\"foo\">")
  assert_true(result is None)
}

///|
test "parse_custom_element parses basic custom element" {
  let result = parse_custom_element("<my-counter />")
  match result {
    Some(embed) => {
      assert_eq(embed.tag, "my-counter")
      assert_eq(embed.attrs.length(), 0)
      assert_eq(embed.content, "")
    }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element parses custom element with attributes" {
  let html = "<my-counter value=\"10\" label=\"Count\" />"
  let result = parse_custom_element(html)
  match result {
    Some(embed) => {
      assert_eq(embed.tag, "my-counter")
      assert_eq(embed.attrs.length(), 2)
      assert_eq(embed.attrs[0].0, "value")
      assert_eq(embed.attrs[0].1, "10")
      assert_eq(embed.attrs[1].0, "label")
      assert_eq(embed.attrs[1].1, "Count")
    }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element parses inner content" {
  let html = "<accordion-panel><p>Hello</p></accordion-panel>"
  let result = parse_custom_element(html)
  match result {
    Some(embed) => {
      assert_eq(embed.tag, "accordion-panel")
      assert_eq(embed.content, "<p>Hello</p>")
    }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element trigger via luna:trigger attribute" {
  let html = "<my-widget luna:trigger=\"visible\" />"
  let result = parse_custom_element(html)
  match result {
    Some(embed) =>
      match embed.trigger {
        Visible => ()
        _ => fail("Expected TriggerType::Visible")
      }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element trigger via trigger attribute" {
  let html = "<my-widget trigger=\"idle\" />"
  let result = parse_custom_element(html)
  match result {
    Some(embed) =>
      match embed.trigger {
        Idle => ()
        _ => fail("Expected TriggerType::Idle")
      }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element trigger none" {
  let html = "<my-widget trigger=\"none\" />"
  let result = parse_custom_element(html)
  match result {
    Some(embed) =>
      match embed.trigger {
        None => ()
        _ => fail("Expected TriggerType::None")
      }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element defaults to Load trigger" {
  let html = "<my-widget />"
  let result = parse_custom_element(html)
  match result {
    Some(embed) =>
      match embed.trigger {
        Load => ()
        _ => fail("Expected TriggerType::Load as default")
      }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element excludes trigger from attrs" {
  let html = "<my-widget trigger=\"visible\" value=\"1\" />"
  let result = parse_custom_element(html)
  match result {
    Some(embed) => {
      // trigger attribute should be excluded from attrs
      for pair in embed.attrs {
        if pair.0 == "trigger" {
          fail("trigger should not appear in attrs")
        }
      }
      assert_eq(embed.attrs.length(), 1)
      assert_eq(embed.attrs[0].0, "value")
    }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element excludes luna:trigger from attrs" {
  let html = "<my-widget luna:trigger=\"idle\" value=\"2\" />"
  let result = parse_custom_element(html)
  match result {
    Some(embed) => {
      // luna:trigger is excluded from attrs by extract_all_attributes
      assert_eq(embed.attrs.length(), 1)
      assert_eq(embed.attrs[0].0, "value")
    }
    None => fail("Expected Some(ComponentEmbed)")
  }
}

///|
test "parse_custom_element returns None for empty string" {
  let result = parse_custom_element("")
  assert_true(result is None)
}
