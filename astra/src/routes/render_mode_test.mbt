// Tests for Render Mode, HttpMethod, and FileType

// =============================================================================
// HttpMethod Tests
// =============================================================================

///|
test "HttpMethod::to_string - all methods" {
  inspect(HttpMethod::Get.to_string(), content="GET")
  inspect(HttpMethod::Post.to_string(), content="POST")
  inspect(HttpMethod::Put.to_string(), content="PUT")
  inspect(HttpMethod::Delete.to_string(), content="DELETE")
  inspect(HttpMethod::Patch.to_string(), content="PATCH")
  inspect(HttpMethod::All.to_string(), content="ALL")
}

///|
test "HttpMethod::from_string - valid methods lowercase" {
  inspect(HttpMethod::from_string("get"), content="Some(Get)")
  inspect(HttpMethod::from_string("post"), content="Some(Post)")
  inspect(HttpMethod::from_string("put"), content="Some(Put)")
  inspect(HttpMethod::from_string("delete"), content="Some(Delete)")
  inspect(HttpMethod::from_string("patch"), content="Some(Patch)")
  inspect(HttpMethod::from_string("all"), content="Some(All)")
}

///|
test "HttpMethod::from_string - valid methods uppercase" {
  inspect(HttpMethod::from_string("GET"), content="Some(Get)")
  inspect(HttpMethod::from_string("POST"), content="Some(Post)")
  inspect(HttpMethod::from_string("PUT"), content="Some(Put)")
  inspect(HttpMethod::from_string("DELETE"), content="Some(Delete)")
  inspect(HttpMethod::from_string("PATCH"), content="Some(Patch)")
  inspect(HttpMethod::from_string("ALL"), content="Some(All)")
}

///|
test "HttpMethod::from_string - mixed case" {
  inspect(HttpMethod::from_string("Get"), content="Some(Get)")
  inspect(HttpMethod::from_string("PoSt"), content="Some(Post)")
}

///|
test "HttpMethod::from_string - invalid methods" {
  inspect(HttpMethod::from_string("HEAD") is None, content="true")
  inspect(HttpMethod::from_string("OPTIONS") is None, content="true")
  inspect(HttpMethod::from_string("CONNECT") is None, content="true")
  inspect(HttpMethod::from_string("") is None, content="true")
  inspect(HttpMethod::from_string("invalid") is None, content="true")
}

///|
test "HttpMethod - roundtrip" {
  let http_methods = [
    HttpMethod::Get,
    HttpMethod::Post,
    HttpMethod::Put,
    HttpMethod::Delete,
    HttpMethod::Patch,
    HttpMethod::All,
  ]
  for http_method in http_methods {
    let str = http_method.to_string()
    let parsed = HttpMethod::from_string(str)
    inspect(parsed is Some(_), content="true")
    guard parsed is Some(m) else { fail("Expected Some") }
    inspect(m == http_method, content="true")
  }
}

// =============================================================================
// FileType Tests
// =============================================================================

///|
test "FileType::from_extension - moonbit" {
  inspect(FileType::from_extension(".mbt"), content="MoonBit")
  inspect(FileType::from_extension(".MBT"), content="MoonBit")
}

///|
test "FileType::from_extension - markdown" {
  inspect(FileType::from_extension(".md"), content="Markdown")
  inspect(FileType::from_extension(".MD"), content="Markdown")
}

///|
test "FileType::from_extension - mdx" {
  inspect(FileType::from_extension(".mdx"), content="Mdx")
  inspect(FileType::from_extension(".MDX"), content="Mdx")
}

///|
test "FileType::from_extension - html" {
  inspect(FileType::from_extension(".html"), content="Html")
  inspect(FileType::from_extension(".htm"), content="Html")
  inspect(FileType::from_extension(".HTML"), content="Html")
  inspect(FileType::from_extension(".HTM"), content="Html")
}

///|
test "FileType::from_extension - unknown" {
  inspect(FileType::from_extension(".js"), content="Unknown")
  inspect(FileType::from_extension(".ts"), content="Unknown")
  inspect(FileType::from_extension(".css"), content="Unknown")
  inspect(FileType::from_extension(".json"), content="Unknown")
  inspect(FileType::from_extension(""), content="Unknown")
}

///|
test "FileType::is_page - renderable types" {
  inspect(FileType::MoonBit.is_page(), content="true")
  inspect(FileType::Markdown.is_page(), content="true")
  inspect(FileType::Mdx.is_page(), content="true")
  inspect(FileType::Html.is_page(), content="true")
}

///|
test "FileType::is_page - unknown is not page" {
  inspect(FileType::Unknown.is_page(), content="false")
}

// =============================================================================
// FallbackConfig Tests
// =============================================================================

///|
test "FallbackConfig::default - returns NotFound" {
  let config = FallbackConfig::default()
  inspect(config, content="NotFound(path=\"/404.html\")")
}

///|
test "FallbackConfig::is_spa - NotFound" {
  let config = FallbackConfig::NotFound(path="/404.html")
  inspect(config.is_spa(), content="false")
}

///|
test "FallbackConfig::is_spa - Spa" {
  let config = FallbackConfig::Spa(entry="/index.html")
  inspect(config.is_spa(), content="true")
}

///|
test "FallbackConfig::is_spa - SpaPrefix" {
  let config = FallbackConfig::SpaPrefix(prefix="/app", entry="/app/index.html")
  inspect(config.is_spa(), content="true")
}

///|
test "FallbackConfig::spa_entry - NotFound returns None" {
  let config = FallbackConfig::NotFound(path="/404.html")
  inspect(config.spa_entry(), content="None")
}

///|
test "FallbackConfig::spa_entry - Spa returns entry" {
  let config = FallbackConfig::Spa(entry="/index.html")
  inspect(config.spa_entry(), content="Some(\"/index.html\")")
}

///|
test "FallbackConfig::spa_entry - SpaPrefix returns entry" {
  let config = FallbackConfig::SpaPrefix(prefix="/app", entry="/app/index.html")
  inspect(config.spa_entry(), content="Some(\"/app/index.html\")")
}
