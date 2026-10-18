// Tests for Render Mode, HttpMethod, and FileType

// =============================================================================
// HttpMethod Tests
// =============================================================================

///|
test "HttpMethod::to_string - all methods" {
  inspect(@routes.HttpMethod::Get.to_string(), content="GET")
  inspect(@routes.HttpMethod::Post.to_string(), content="POST")
  inspect(@routes.HttpMethod::Put.to_string(), content="PUT")
  inspect(@routes.HttpMethod::Delete.to_string(), content="DELETE")
  inspect(@routes.HttpMethod::Patch.to_string(), content="PATCH")
  inspect(@routes.HttpMethod::All.to_string(), content="ALL")
}

///|
test "HttpMethod::from_string - valid methods lowercase" {
  debug_inspect(@routes.HttpMethod::from_string("get"), content="Some(Get)")
  debug_inspect(@routes.HttpMethod::from_string("post"), content="Some(Post)")
  debug_inspect(@routes.HttpMethod::from_string("put"), content="Some(Put)")
  debug_inspect(
    @routes.HttpMethod::from_string("delete"),
    content="Some(Delete)",
  )
  debug_inspect(@routes.HttpMethod::from_string("patch"), content="Some(Patch)")
  debug_inspect(@routes.HttpMethod::from_string("all"), content="Some(All)")
}

///|
test "HttpMethod::from_string - valid methods uppercase" {
  debug_inspect(@routes.HttpMethod::from_string("GET"), content="Some(Get)")
  debug_inspect(@routes.HttpMethod::from_string("POST"), content="Some(Post)")
  debug_inspect(@routes.HttpMethod::from_string("PUT"), content="Some(Put)")
  debug_inspect(
    @routes.HttpMethod::from_string("DELETE"),
    content="Some(Delete)",
  )
  debug_inspect(@routes.HttpMethod::from_string("PATCH"), content="Some(Patch)")
  debug_inspect(@routes.HttpMethod::from_string("ALL"), content="Some(All)")
}

///|
test "HttpMethod::from_string - mixed case" {
  debug_inspect(@routes.HttpMethod::from_string("Get"), content="Some(Get)")
  debug_inspect(@routes.HttpMethod::from_string("PoSt"), content="Some(Post)")
}

///|
test "HttpMethod::from_string - invalid methods" {
  inspect(@routes.HttpMethod::from_string("HEAD") is None, content="true")
  inspect(@routes.HttpMethod::from_string("OPTIONS") is None, content="true")
  inspect(@routes.HttpMethod::from_string("CONNECT") is None, content="true")
  inspect(@routes.HttpMethod::from_string("") is None, content="true")
  inspect(@routes.HttpMethod::from_string("invalid") is None, content="true")
}

///|
test "HttpMethod - roundtrip" {
  let http_methods = [
    @routes.HttpMethod::Get,
    @routes.HttpMethod::Post,
    @routes.HttpMethod::Put,
    @routes.HttpMethod::Delete,
    @routes.HttpMethod::Patch,
    @routes.HttpMethod::All,
  ]
  for http_method in http_methods {
    let str = http_method.to_string()
    let parsed = @routes.HttpMethod::from_string(str)
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
  debug_inspect(@routes.FileType::from_extension(".mbt"), content="MoonBit")
  debug_inspect(@routes.FileType::from_extension(".MBT"), content="MoonBit")
}

///|
test "FileType::from_extension - markdown" {
  debug_inspect(@routes.FileType::from_extension(".md"), content="Markdown")
  debug_inspect(@routes.FileType::from_extension(".MD"), content="Markdown")
}

///|
test "FileType::from_extension - mdx" {
  debug_inspect(@routes.FileType::from_extension(".mdx"), content="Mdx")
  debug_inspect(@routes.FileType::from_extension(".MDX"), content="Mdx")
}

///|
test "FileType::from_extension - html" {
  debug_inspect(@routes.FileType::from_extension(".html"), content="Html")
  debug_inspect(@routes.FileType::from_extension(".htm"), content="Html")
  debug_inspect(@routes.FileType::from_extension(".HTML"), content="Html")
  debug_inspect(@routes.FileType::from_extension(".HTM"), content="Html")
}

///|
test "FileType::from_extension - unknown" {
  debug_inspect(@routes.FileType::from_extension(".js"), content="Unknown")
  debug_inspect(@routes.FileType::from_extension(".ts"), content="Unknown")
  debug_inspect(@routes.FileType::from_extension(".css"), content="Unknown")
  debug_inspect(@routes.FileType::from_extension(".json"), content="Unknown")
  debug_inspect(@routes.FileType::from_extension(""), content="Unknown")
}

///|
test "FileType::is_page - renderable types" {
  inspect(@routes.FileType::MoonBit.is_page(), content="true")
  inspect(@routes.FileType::Markdown.is_page(), content="true")
  inspect(@routes.FileType::Mdx.is_page(), content="true")
  inspect(@routes.FileType::Html.is_page(), content="true")
}

///|
test "FileType::is_page - unknown is not page" {
  inspect(@routes.FileType::Unknown.is_page(), content="false")
}

// =============================================================================
// FallbackConfig Tests
// =============================================================================

///|
test "FallbackConfig::default - returns NotFound" {
  let config = @routes.FallbackConfig::default()
  debug_inspect(
    config,
    content=(
      #|NotFound(path="/404.html")
    ),
  )
}

///|
test "FallbackConfig::is_spa - NotFound" {
  let config = @routes.FallbackConfig::NotFound(path="/404.html")
  inspect(config.is_spa(), content="false")
}

///|
test "FallbackConfig::is_spa - Spa" {
  let config = @routes.FallbackConfig::Spa(entry="/index.html")
  inspect(config.is_spa(), content="true")
}

///|
test "FallbackConfig::is_spa - SpaPrefix" {
  let config = @routes.FallbackConfig::SpaPrefix(
    prefix="/app",
    entry="/app/index.html",
  )
  inspect(config.is_spa(), content="true")
}

///|
test "FallbackConfig::spa_entry - NotFound returns None" {
  let config = @routes.FallbackConfig::NotFound(path="/404.html")
  debug_inspect(config.spa_entry(), content="None")
}

///|
test "FallbackConfig::spa_entry - Spa returns entry" {
  let config = @routes.FallbackConfig::Spa(entry="/index.html")
  debug_inspect(
    config.spa_entry(),
    content=(
      #|Some("/index.html")
    ),
  )
}

///|
test "FallbackConfig::spa_entry - SpaPrefix returns entry" {
  let config = @routes.FallbackConfig::SpaPrefix(
    prefix="/app",
    entry="/app/index.html",
  )
  debug_inspect(
    config.spa_entry(),
    content=(
      #|Some("/app/index.html")
    ),
  )
}

///|
test "FileType::from_filename - mbt.md is Markdown, not MoonBit" {
  debug_inspect(
    @routes.FileType::from_filename("intro.mbt.md"),
    content="Markdown",
  )
  debug_inspect(
    @routes.FileType::from_filename("component.mbt"),
    content="MoonBit",
  )
  debug_inspect(@routes.FileType::from_filename("intro.md"), content="Markdown")
  debug_inspect(@routes.FileType::from_filename("intro.mdx"), content="Mdx")
  debug_inspect(@routes.FileType::from_filename("page.html"), content="Html")
}
