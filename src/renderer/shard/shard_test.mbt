///|
/// Tests for shard module
test "escape_json_for_html - safe string passes through" {
  let safe = "{\"count\":0}"
  let result = @shard.escape_json_for_html(safe)
  assert_eq(result, safe)
}

///|
test "escape_json_for_html - escapes script closing tag" {
  let dangerous = "{\"html\":\"</script><script>alert(1)</script>\"}"
  let result = @shard.escape_json_for_html(dangerous)
  assert_true(result.contains("<\\/script>"))
  assert_true(not(result.contains("</script>")))
}

///|
test "escape_json_for_html - escapes lowercase script tag" {
  let dangerous = "<script>alert(1)</script>"
  let result = @shard.escape_json_for_html(dangerous)
  assert_true(result.contains("<\\u0073cript>"))
}

///|
test "escape_json_for_html - escapes uppercase Script tag" {
  let dangerous = "<Script>alert(1)</Script>"
  let result = @shard.escape_json_for_html(dangerous)
  assert_true(result.contains("<\\u0053cript>"))
}

///|
test "generate_state_script - generates script element" {
  let result = @shard.generate_state_script("my-state", "{\"count\":42}")
  assert_true(result.has_prefix("<script id=\"my-state\""))
  assert_true(result.contains("type=\"ln/json\""))
  assert_true(result.contains("{\"count\":42}"))
  assert_true(result.has_suffix("</script>"))
}

///|
test "TriggerType::to_string - converts to string" {
  assert_eq(@shard.TriggerType::Load.to_string(), "load")
  assert_eq(@shard.TriggerType::Idle.to_string(), "idle")
  assert_eq(@shard.TriggerType::Visible.to_string(), "visible")
  assert_eq(@shard.TriggerType::None.to_string(), "none")
  assert_eq(
    @shard.TriggerType::Media("(min-width: 768px)").to_string(),
    "media:(min-width: 768px)",
  )
}

///|
test "TriggerType::parse - parses from string" {
  assert_true(
    match @shard.TriggerType::parse("load") {
      Load => true
      _ => false
    },
  )
  assert_true(
    match @shard.TriggerType::parse("idle") {
      Idle => true
      _ => false
    },
  )
  assert_true(
    match @shard.TriggerType::parse("visible") {
      Visible => true
      _ => false
    },
  )
  assert_true(
    match @shard.TriggerType::parse("none") {
      None => true
      _ => false
    },
  )
  assert_true(
    match @shard.TriggerType::parse("media:(min-width: 768px)") {
      Media(_) => true
      _ => false
    },
  )
}

///|
test "format_state_attr - inline JSON" {
  let result = @shard.format_state_attr(@shard.StateConfig::Inline("{\"x\":1}"))
  // " is escaped as &quot; for HTML attribute safety
  assert_eq(result, Some("{&quot;x&quot;:1}"))
}

///|
test "format_state_attr - script reference" {
  let result = @shard.format_state_attr(
    @shard.StateConfig::ScriptRef("my-state"),
  )
  assert_eq(result, Some("#my-state"))
}

///|
test "format_state_attr - URL reference" {
  let result = @shard.format_state_attr(
    @shard.StateConfig::Url("https://api.example.com/state"),
  )
  assert_eq(result, Some("url:https://api.example.com/state"))
}

///|
test "format_state_attr - empty returns None" {
  let result = @shard.format_state_attr(@shard.StateConfig::Empty)
  assert_eq(result, None)
}

///|
test "generate_shard - minimal config" {
  let config = @shard.ShardConfig::new("counter-1", "./counter.js")
  let output = @shard.generate_shard(config)
  assert_true(output.html.contains("ln:id=\"counter-1\""))
  assert_true(output.html.contains("ln:url=\"./counter.js\""))
  // load is default, should not be included
  assert_true(not(output.html.contains("ln:trigger")))
}

///|
test "generate_shard - with visible trigger" {
  let config = @shard.ShardConfig::new("lazy-1", "./lazy.js").with_trigger(
    @shard.TriggerType::Visible,
  )
  let output = @shard.generate_shard(config)
  assert_true(output.html.contains("ln:trigger=\"visible\""))
}

///|
test "generate_shard - with inline state" {
  let config = @shard.ShardConfig::new("stateful-1", "./stateful.js").with_state(
    "{\"count\":0}",
  )
  let output = @shard.generate_shard(config)
  // State is HTML-escaped for attribute safety
  assert_true(output.html.contains("ln:state=\"{&quot;count&quot;:0}\""))
}

///|
test "generate_shard - with SSR content" {
  let config = @shard.ShardConfig::new("ssr-1", "./ssr.js").with_ssr_content(
    "<span>Hello</span>",
  )
  let output = @shard.generate_shard(config)
  assert_true(output.html.contains("<span>Hello</span>"))
}

///|
test "generate_shard - with loader" {
  let config = @shard.ShardConfig::new("standalone-1", "./standalone.js").with_loader(
    "https://cdn.example.com/ln-loader-v1.js",
  )
  let output = @shard.generate_shard(config)
  assert_true(
    output.html.contains(
      "<script type=\"module\" src=\"https://cdn.example.com/ln-loader-v1.js\">",
    ),
  )
  assert_eq(output.head_scripts.length(), 1)
}

///|
test "recommend_state_format - small state" {
  assert_eq(@shard.recommend_state_format(500), "inline")
}

///|
test "recommend_state_format - medium state" {
  assert_eq(@shard.recommend_state_format(5000), "script_ref")
}

///|
test "recommend_state_format - large state" {
  assert_eq(@shard.recommend_state_format(200000), "url")
}
