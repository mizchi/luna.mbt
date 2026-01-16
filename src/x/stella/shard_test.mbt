//

///|
/// Tests for shard module
test "escape_json_for_script - safe string passes through" {
  let safe = "{\"count\":0}"
  let result = @render.escape_json_for_script(safe)
  assert_eq(result, safe)
}

///|
test "escape_json_for_script - escapes script closing tag" {
  let dangerous = "{\"html\":\"</script><script>alert(1)</script>\"}"
  let result = @render.escape_json_for_script(dangerous)
  assert_true(result.contains("<\\/script>"))
  assert_true(not(result.contains("</script>")))
}

///|
test "escape_json_for_script - escapes lowercase script tag" {
  let dangerous = "<script>alert(1)</script>"
  let result = @render.escape_json_for_script(dangerous)
  assert_true(result.contains("<\\u0073cript>"))
}

///|
test "escape_json_for_script - escapes uppercase Script tag" {
  let dangerous = "<Script>alert(1)</Script>"
  let result = @render.escape_json_for_script(dangerous)
  assert_true(result.contains("<\\u0053cript>"))
}

///|
test "generate_state_script - generates script element" {
  let result = @stella.generate_state_script("my-state", "{\"count\":42}")
  assert_true(result.has_prefix("<script id=\"my-state\""))
  assert_true(result.contains("type=\"luna/json\""))
  assert_true(result.contains("{\"count\":42}"))
  assert_true(result.has_suffix("</script>"))
}

///|
test "TriggerType::to_string - converts to string" {
  assert_eq(@luna.TriggerType::Load.to_string(), "load")
  assert_eq(@luna.TriggerType::Idle.to_string(), "idle")
  assert_eq(@luna.TriggerType::Visible.to_string(), "visible")
  assert_eq(@luna.TriggerType::None.to_string(), "none")
  assert_eq(
    @luna.TriggerType::Media("(min-width: 768px)").to_string(),
    "media:(min-width: 768px)",
  )
}

///|
test "TriggerType::parse - parses from string" {
  assert_true(
    match @luna.TriggerType::parse("load") {
      Load => true
      _ => false
    },
  )
  assert_true(
    match @luna.TriggerType::parse("idle") {
      Idle => true
      _ => false
    },
  )
  assert_true(
    match @luna.TriggerType::parse("visible") {
      Visible => true
      _ => false
    },
  )
  assert_true(
    match @luna.TriggerType::parse("none") {
      None => true
      _ => false
    },
  )
  assert_true(
    match @luna.TriggerType::parse("media:(min-width: 768px)") {
      Media(_) => true
      _ => false
    },
  )
}

///|
test "format_state_attr - inline JSON" {
  let result = @stella.format_state_attr(
    @stella.StateConfig::Inline("{\"x\":1}"),
  )
  // " is escaped as &quot; for HTML attribute safety
  assert_eq(result, Some("{&quot;x&quot;:1}"))
}

///|
test "format_state_attr - script reference" {
  let result = @stella.format_state_attr(
    @stella.StateConfig::ScriptRef("my-state"),
  )
  assert_eq(result, Some("#my-state"))
}

///|
test "format_state_attr - URL reference" {
  let result = @stella.format_state_attr(
    @stella.StateConfig::Url("https://api.example.com/state"),
  )
  assert_eq(result, Some("url:https://api.example.com/state"))
}

///|
test "format_state_attr - empty returns None" {
  let result = @stella.format_state_attr(@stella.StateConfig::Empty)
  assert_eq(result, None)
}

///|
test "generate_shard - minimal config" {
  let config = @stella.ShardConfig::new("counter-1", "./counter.js")
  let output = @stella.generate_shard(config)
  assert_true(output.html.contains("luna:id=\"counter-1\""))
  assert_true(output.html.contains("luna:url=\"./counter.js\""))
  // load is default, should not be included
  assert_true(not(output.html.contains("luna:client-trigger")))
}

///|
test "generate_shard - with visible trigger" {
  let config = @stella.ShardConfig::new("lazy-1", "./lazy.js").with_trigger(
    @luna.TriggerType::Visible,
  )
  let output = @stella.generate_shard(config)
  assert_true(output.html.contains("luna:client-trigger=\"visible\""))
}

///|
test "generate_shard - with inline state" {
  let config = @stella.ShardConfig::new("stateful-1", "./stateful.js").with_state(
    "{\"count\":0}",
  )
  let output = @stella.generate_shard(config)
  // State is HTML-escaped for attribute safety
  assert_true(output.html.contains("luna:state=\"{&quot;count&quot;:0}\""))
}

///|
test "generate_shard - with SSR content" {
  let config = @stella.ShardConfig::new("ssr-1", "./ssr.js").with_ssr_content(
    "<span>Hello</span>",
  )
  let output = @stella.generate_shard(config)
  assert_true(output.html.contains("<span>Hello</span>"))
}

///|
test "generate_shard - with loader" {
  let config = @stella.ShardConfig::new("standalone-1", "./standalone.js").with_loader(
    "https://cdn.example.com/loader.min.js",
  )
  let output = @stella.generate_shard(config)
  assert_true(
    output.html.contains(
      "<script type=\"module\" src=\"https://cdn.example.com/loader.min.js\">",
    ),
  )
  assert_eq(output.head_scripts.length(), 1)
}

///|
test "recommend_state_format - small state" {
  assert_eq(@stella.recommend_state_format(500), "inline")
}

///|
test "recommend_state_format - medium state" {
  assert_eq(@stella.recommend_state_format(5000), "script_ref")
}

///|
test "recommend_state_format - large state" {
  assert_eq(@stella.recommend_state_format(200000), "url")
}

// ============================================================================
// html_builder.mbt tests
// ============================================================================

///|
test "generate_shard_with_state_script - creates script and reference" {
  let config = @stella.ShardConfig::new("big-1", "./big.js")
  let output = @stella.generate_shard_with_state_script(
    config, "{\"data\":[1,2,3]}",
  )
  // Should have script reference in attributes
  assert_true(output.html.contains("luna:state=\"#luna-state-big-1\""))
  // Should have state script element
  assert_true(output.html.contains("<script id=\"luna-state-big-1\""))
  assert_true(output.html.contains("type=\"luna/json\""))
  assert_true(output.state_scripts.length() == 1)
}

///|
test "generate_minimal_shard - creates minimal HTML" {
  let html = @stella.generate_minimal_shard(
    "min-1", "./min.js", "{\"x\":1}", "<span>Content</span>",
  )
  assert_true(html.contains("luna:id=\"min-1\""))
  assert_true(html.contains("luna:url=\"./min.js\""))
  assert_true(html.contains("<span>Content</span>"))
  // Should not have trigger (default load is omitted)
  assert_true(not(html.contains("luna:client-trigger")))
  // Should not have loader script
  assert_true(not(html.contains("<script type=\"module\"")))
}

///|
test "generate_standalone_shard - includes loader" {
  let html = @stella.generate_standalone_shard(
    "standalone-1", "./standalone.js", "https://cdn.example.com/loader.js", "{\"y\":2}",
    "<div>SSR</div>",
  )
  assert_true(
    html.contains(
      "<script type=\"module\" src=\"https://cdn.example.com/loader.js\">",
    ),
  )
  assert_true(html.contains("luna:id=\"standalone-1\""))
  assert_true(html.contains("<div>SSR</div>"))
}

///|
test "generate_lazy_shard - uses visible trigger" {
  let html = @stella.generate_lazy_shard(
    "lazy-1", "./lazy.js", "{\"z\":3}", "<p>Lazy</p>",
  )
  assert_true(html.contains("luna:client-trigger=\"visible\""))
  assert_true(html.contains("<p>Lazy</p>"))
}

///|
test "generate_shard_group - single loader for multiple shards" {
  let configs = [
    @stella.ShardConfig::new("s1", "./s1.js"),
    @stella.ShardConfig::new("s2", "./s2.js"),
  ]
  let html = @stella.generate_shard_group(
    "https://cdn.example.com/loader.js", configs,
  )
  // Should have single loader script at start
  assert_true(
    html.has_prefix(
      "<script type=\"module\" src=\"https://cdn.example.com/loader.js\">",
    ),
  )
  // Should have both shards
  assert_true(html.contains("luna:id=\"s1\""))
  assert_true(html.contains("luna:id=\"s2\""))
}

///|
test "auto_select_state_format - small state uses inline" {
  let base = @stella.ShardConfig::new("test-1", "./test.js")
  let small_json = "{\"x\":1}"
  let config = @stella.auto_select_state_format(small_json, base)
  match config.state {
    Inline(json) => assert_eq(json, small_json)
    _ => fail("Expected Inline for small state")
  }
}

///|
test "auto_select_state_format - medium state uses script ref" {
  let base = @stella.ShardConfig::new("test-2", "./test.js")
  // Create a string larger than 1KB but smaller than 100KB
  let sb = StringBuilder::new()
  sb.write_string("{\"data\":\"")
  for _ in 0..<2000 {
    sb.write_char('x')
  }
  sb.write_string("\"}")
  let medium_json = sb.to_string()
  let config = @stella.auto_select_state_format(medium_json, base)
  match config.state {
    ScriptRef(id) => assert_eq(id, "luna-state-test-2")
    _ => fail("Expected ScriptRef for medium state")
  }
}

///|
test "generate_shard - with media trigger" {
  let config = @stella.ShardConfig::new("media-1", "./media.js").with_trigger(
    @luna.TriggerType::Media("(min-width: 768px)"),
  )
  let output = @stella.generate_shard(config)
  assert_true(
    output.html.contains("luna:client-trigger=\"media:(min-width: 768px)\""),
  )
}
