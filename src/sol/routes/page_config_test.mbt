// Tests for Page Configuration (page.json)

// =============================================================================
// PageConfig Defaults
// =============================================================================

///|
test "PageConfig::default - all fields have expected defaults" {
  let config = PageConfig::default()
  inspect(config.mode is None, content="true")
  inspect(config.revalidate is None, content="true")
  inspect(config.title is None, content="true")
  inspect(config.description is None, content="true")
  inspect(config.layout is None, content="true")
  inspect(config.islands.length(), content="0")
  inspect(config.generate_params, content="false")
  inspect(config.static_params.length(), content="0")
  inspect(config.fallback, content="false")
  inspect(config.spa, content="false")
  inspect(config.fallback_behavior is None, content="true")
  inspect(config.extends is None, content="true")
  inspect(config.handlers.length(), content="0")
  inspect(config.component is None, content="true")
}

///|
test "FileHandlerConfig::default - expected defaults" {
  let config = FileHandlerConfig::default()
  inspect(config.layout is None, content="true")
  inspect(config.islands.length(), content="0")
  inspect(config.passthrough, content="false")
}

///|
test "ComponentConfig::default - expected defaults" {
  let config = ComponentConfig::default()
  inspect(config.ssr, content="false")
  inspect(config.props_type is None, content="true")
  inspect(config.client_export is None, content="true")
  inspect(config.server_export is None, content="true")
}

// =============================================================================
// parse_page_config Tests
// =============================================================================

///|
test "parse_page_config - empty object" {
  let result = parse_page_config("{}")
  inspect(result is Some(_), content="true")
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.mode is None, content="true")
}

///|
test "parse_page_config - mode field" {
  let result = parse_page_config("{\"mode\": \"ssr\"}")
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.mode, content="Some(\"ssr\")")
}

///|
test "parse_page_config - all mode values" {
  let ssr_result = parse_page_config("{\"mode\": \"ssr\"}")
  guard ssr_result is Some(ssr_config) else { fail("Expected Some") }
  inspect(ssr_config.mode, content="Some(\"ssr\")")
  let isr_result = parse_page_config("{\"mode\": \"isr\"}")
  guard isr_result is Some(isr_config) else { fail("Expected Some") }
  inspect(isr_config.mode, content="Some(\"isr\")")
  let spa_result = parse_page_config("{\"mode\": \"spa\"}")
  guard spa_result is Some(spa_config) else { fail("Expected Some") }
  inspect(spa_config.mode, content="Some(\"spa\")")
  let static_result = parse_page_config("{\"mode\": \"static\"}")
  guard static_result is Some(static_config) else { fail("Expected Some") }
  inspect(static_config.mode, content="Some(\"static\")")
}

///|
test "parse_page_config - revalidate field" {
  let result = parse_page_config("{\"mode\": \"isr\", \"revalidate\": 3600}")
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.revalidate, content="Some(3600)")
}

///|
test "parse_page_config - title and description" {
  let result = parse_page_config(
    "{\"title\": \"My Page\", \"description\": \"Page description\"}",
  )
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.title, content="Some(\"My Page\")")
  inspect(config.description, content="Some(\"Page description\")")
}

///|
test "parse_page_config - layout field" {
  let result = parse_page_config("{\"layout\": \"docs\"}")
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.layout, content="Some(\"docs\")")
}

///|
test "parse_page_config - islands array" {
  let result = parse_page_config("{\"islands\": [\"counter\", \"toggle\"]}")
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.islands.length(), content="2")
  inspect(config.islands[0], content="counter")
  inspect(config.islands[1], content="toggle")
}

///|
test "parse_page_config - boolean flags" {
  let result = parse_page_config(
    "{\"generateParams\": true, \"fallback\": true, \"spa\": true}",
  )
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.generate_params, content="true")
  inspect(config.fallback, content="true")
  inspect(config.spa, content="true")
}

///|
test "parse_page_config - staticParams array" {
  let result = parse_page_config(
    "{\"staticParams\": [{\"slug\": \"hello\"}, {\"slug\": \"world\"}]}",
  )
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.static_params.length(), content="2")
  inspect(config.static_params[0].get("slug"), content="Some(\"hello\")")
  inspect(config.static_params[1].get("slug"), content="Some(\"world\")")
}

///|
test "parse_page_config - extends field" {
  let result = parse_page_config("{\"extends\": \"base\"}")
  guard result is Some(config) else { fail("Expected Some") }
  inspect(config.extends, content="Some(\"base\")")
}

///|
test "parse_page_config - invalid json returns None" {
  let result = parse_page_config("not valid json")
  inspect(result is None, content="true")
}

///|
test "parse_page_config - non-object returns None" {
  let result = parse_page_config("[]")
  inspect(result is None, content="true")
  let result2 = parse_page_config("\"string\"")
  inspect(result2 is None, content="true")
  let result3 = parse_page_config("123")
  inspect(result3 is None, content="true")
}

///|
test "parse_page_config - component config" {
  let json_str =
    #|{"component": {"ssr": true, "propsType": "CounterProps", "clientExport": "counter", "serverExport": "render_ssr"}}
  let result = parse_page_config(json_str)
  guard result is Some(config) else { fail("Expected Some") }
  guard config.component is Some(comp) else {
    fail("Expected component config")
  }
  inspect(comp.ssr, content="true")
  inspect(comp.props_type, content="Some(\"CounterProps\")")
  inspect(comp.client_export, content="Some(\"counter\")")
  inspect(comp.server_export, content="Some(\"render_ssr\")")
}

///|
test "parse_page_config - handlers config" {
  let json_str =
    #|{"handlers": {".md": {"layout": "docs", "islands": ["toc"]}}}
  let result = parse_page_config(json_str)
  guard result is Some(config) else { fail("Expected Some") }
  guard config.handlers.get(".md") is Some(handler) else {
    fail("Expected handler config")
  }
  inspect(handler.layout, content="Some(\"docs\")")
  inspect(handler.islands.length(), content="1")
  inspect(handler.islands[0], content="toc")
}

// =============================================================================
// PageConfig::merge Tests
// =============================================================================

///|
test "PageConfig::merge - child overrides base mode" {
  let base = PageConfig::{ ..PageConfig::default(), mode: Some("ssr") }
  let child = PageConfig::{ ..PageConfig::default(), mode: Some("isr") }
  let merged = PageConfig::merge(base, child)
  inspect(merged.mode, content="Some(\"isr\")")
}

///|
test "PageConfig::merge - child inherits base mode when None" {
  let base = PageConfig::{ ..PageConfig::default(), mode: Some("ssr") }
  let child = PageConfig::default()
  let merged = PageConfig::merge(base, child)
  inspect(merged.mode, content="Some(\"ssr\")")
}

///|
test "PageConfig::merge - title and description override" {
  let base = PageConfig::{
    ..PageConfig::default(),
    title: Some("Base Title"),
    description: Some("Base Desc"),
  }
  let child = PageConfig::{
    ..PageConfig::default(),
    title: Some("Child Title"),
    description: None,
  }
  let merged = PageConfig::merge(base, child)
  inspect(merged.title, content="Some(\"Child Title\")")
  inspect(merged.description, content="Some(\"Base Desc\")")
}

///|
test "PageConfig::merge - islands override when non-empty" {
  let base = PageConfig::{
    ..PageConfig::default(),
    islands: ["counter", "toggle"],
  }
  let child = PageConfig::{ ..PageConfig::default(), islands: ["custom"] }
  let merged = PageConfig::merge(base, child)
  inspect(merged.islands.length(), content="1")
  inspect(merged.islands[0], content="custom")
}

///|
test "PageConfig::merge - islands inherit when empty" {
  let base = PageConfig::{
    ..PageConfig::default(),
    islands: ["counter", "toggle"],
  }
  let child = PageConfig::default()
  let merged = PageConfig::merge(base, child)
  inspect(merged.islands.length(), content="2")
}

///|
test "PageConfig::merge - boolean OR" {
  let base = PageConfig::{
    ..PageConfig::default(),
    generate_params: true,
    fallback: false,
    spa: false,
  }
  let child = PageConfig::{
    ..PageConfig::default(),
    generate_params: false,
    fallback: true,
    spa: false,
  }
  let merged = PageConfig::merge(base, child)
  inspect(merged.generate_params, content="true")
  inspect(merged.fallback, content="true")
  inspect(merged.spa, content="false")
}

///|
test "PageConfig::merge - handlers merge with child override" {
  let base_handlers : Map[String, FileHandlerConfig] = {}
  base_handlers[".md"] = FileHandlerConfig::{
    ..FileHandlerConfig::default(),
    layout: Some("docs"),
  }
  let base = PageConfig::{ ..PageConfig::default(), handlers: base_handlers }
  let child_handlers : Map[String, FileHandlerConfig] = {}
  child_handlers[".md"] = FileHandlerConfig::{
    ..FileHandlerConfig::default(),
    layout: Some("blog"),
  }
  child_handlers[".mdx"] = FileHandlerConfig::{
    ..FileHandlerConfig::default(),
    layout: Some("mdx"),
  }
  let child = PageConfig::{ ..PageConfig::default(), handlers: child_handlers }
  let merged = PageConfig::merge(base, child)
  inspect(merged.handlers.length(), content="2")
  guard merged.handlers.get(".md") is Some(md_handler) else {
    fail("Expected .md handler")
  }
  inspect(md_handler.layout, content="Some(\"blog\")") // child overrides
}

// =============================================================================
// PageConfig Conversion Tests
// =============================================================================

///|
test "PageConfig::to_render_mode - ssr" {
  let config = PageConfig::{ ..PageConfig::default(), mode: Some("ssr") }
  inspect(config.to_render_mode(), content="Ssr")
}

///|
test "PageConfig::to_render_mode - isr with revalidate" {
  let config = PageConfig::{
    ..PageConfig::default(),
    mode: Some("isr"),
    revalidate: Some(1800),
  }
  let mode = config.to_render_mode()
  guard mode is RenderMode::Isr(revalidate~) else { fail("Expected ISR") }
  inspect(revalidate, content="1800")
}

///|
test "PageConfig::to_render_mode - isr default revalidate" {
  let config = PageConfig::{ ..PageConfig::default(), mode: Some("isr") }
  let mode = config.to_render_mode()
  guard mode is RenderMode::Isr(revalidate~) else { fail("Expected ISR") }
  inspect(revalidate, content="3600") // default
}

///|
test "PageConfig::to_render_mode - spa" {
  let config = PageConfig::{ ..PageConfig::default(), mode: Some("spa") }
  inspect(config.to_render_mode(), content="Spa")
}

///|
test "PageConfig::to_render_mode - static defaults to ssr" {
  let config = PageConfig::{ ..PageConfig::default(), mode: Some("static") }
  inspect(config.to_render_mode(), content="Ssr")
}

///|
test "PageConfig::to_render_mode - None defaults to ssr" {
  let config = PageConfig::default()
  inspect(config.to_render_mode(), content="Ssr")
}

// =============================================================================
// PageConfig Predicate Tests
// =============================================================================

///|
test "PageConfig::is_static - static mode" {
  let config = PageConfig::{ ..PageConfig::default(), mode: Some("static") }
  inspect(config.is_static(), content="true")
}

///|
test "PageConfig::is_static - None mode (default is static)" {
  let config = PageConfig::default()
  inspect(config.is_static(), content="true")
}

///|
test "PageConfig::is_static - other modes" {
  let ssr_config = PageConfig::{ ..PageConfig::default(), mode: Some("ssr") }
  inspect(ssr_config.is_static(), content="false")
  let isr_config = PageConfig::{ ..PageConfig::default(), mode: Some("isr") }
  inspect(isr_config.is_static(), content="false")
}

///|
test "PageConfig::is_dynamic - ssr and isr" {
  let ssr_config = PageConfig::{ ..PageConfig::default(), mode: Some("ssr") }
  inspect(ssr_config.is_dynamic(), content="true")
  let isr_config = PageConfig::{ ..PageConfig::default(), mode: Some("isr") }
  inspect(isr_config.is_dynamic(), content="true")
}

///|
test "PageConfig::is_dynamic - other modes" {
  let static_config = PageConfig::{
    ..PageConfig::default(),
    mode: Some("static"),
  }
  inspect(static_config.is_dynamic(), content="false")
  let spa_config = PageConfig::{ ..PageConfig::default(), mode: Some("spa") }
  inspect(spa_config.is_dynamic(), content="false")
}

///|
test "PageConfig::is_spa - spa mode" {
  let config = PageConfig::{ ..PageConfig::default(), mode: Some("spa") }
  inspect(config.is_spa(), content="true")
}

///|
test "PageConfig::is_spa - other modes" {
  let ssr_config = PageConfig::{ ..PageConfig::default(), mode: Some("ssr") }
  inspect(ssr_config.is_spa(), content="false")
}

///|
test "PageConfig::is_isr - isr mode" {
  let config = PageConfig::{ ..PageConfig::default(), mode: Some("isr") }
  inspect(config.is_isr(), content="true")
}

///|
test "PageConfig::is_isr - other modes" {
  let ssr_config = PageConfig::{ ..PageConfig::default(), mode: Some("ssr") }
  inspect(ssr_config.is_isr(), content="false")
}

///|
test "PageConfig::has_static_params - with params" {
  let params : Map[String, String] = {}
  params["slug"] = "hello"
  let config = PageConfig::{ ..PageConfig::default(), static_params: [params] }
  inspect(config.has_static_params(), content="true")
}

///|
test "PageConfig::has_static_params - empty" {
  let config = PageConfig::default()
  inspect(config.has_static_params(), content="false")
}

///|
test "PageConfig::is_component - with component" {
  let config = PageConfig::{
    ..PageConfig::default(),
    component: Some(ComponentConfig::default()),
  }
  inspect(config.is_component(), content="true")
}

///|
test "PageConfig::is_component - without component" {
  let config = PageConfig::default()
  inspect(config.is_component(), content="false")
}
