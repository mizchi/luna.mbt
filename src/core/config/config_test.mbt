// Tests for LunaConfig parsing

///|
test "parse empty config returns defaults" {
  let config = parse_luna_config("{}")
  assert_true(config.is_some())
  let c = config.unwrap()
  assert_eq(c.output, OutputMode::Static)
  assert_eq(c.routing.mode, RoutingMode::FileBased)
  assert_eq(c.layouts, "src/layouts")
  assert_eq(c.out_dir, "dist")
  assert_eq(c.dev.port, 3000)
  assert_eq(c.navigation.strategy, NavigationStrategy::Simple)
  assert_eq(c.performance.inline_threshold, 1024)
}

///|
test "parse full config" {
  let json =
    #|{
    #|  "output": "hybrid",
    #|  "routing": {
    #|    "mode": "hybrid",
    #|    "pages": "pages",
    #|    "explicit": "routes.mbt"
    #|  },
    #|  "layouts": "layouts",
    #|  "public": "static",
    #|  "outDir": "build",
    #|  "build": {
    #|    "minify": false,
    #|    "sourcemap": true
    #|  },
    #|  "dev": {
    #|    "port": 8080,
    #|    "hmr": false
    #|  },
    #|  "navigation": {
    #|    "strategy": "unified",
    #|    "prefetch": false,
    #|    "scrollRestoration": false
    #|  },
    #|  "performance": {
    #|    "inlineThreshold": 2048,
    #|    "prefetch": "visible",
    #|    "lazyIslands": true,
    #|    "modulePreload": false,
    #|    "bundler": "esbuild"
    #|  }
    #|}
  let config = parse_luna_config(json)
  assert_true(config.is_some())
  let c = config.unwrap()

  // Output
  assert_eq(c.output, OutputMode::Hybrid)

  // Routing
  assert_eq(c.routing.mode, RoutingMode::Hybrid)
  assert_eq(c.routing.pages, "pages")
  assert_eq(c.routing.explicit, Some("routes.mbt"))

  // Directories
  assert_eq(c.layouts, "layouts")
  assert_eq(c.public_dir, "static")
  assert_eq(c.out_dir, "build")

  // Build
  assert_eq(c.build.minify, false)
  assert_eq(c.build.sourcemap, true)

  // Dev
  assert_eq(c.dev.port, 8080)
  assert_eq(c.dev.hmr, false)

  // Navigation
  assert_eq(c.navigation.strategy, NavigationStrategy::Unified)
  assert_eq(c.navigation.prefetch, false)
  assert_eq(c.navigation.scroll_restoration, false)

  // Performance
  assert_eq(c.performance.inline_threshold, 2048)
  assert_eq(c.performance.prefetch, PrefetchStrategy::Visible)
  assert_eq(c.performance.lazy_islands, true)
  assert_eq(c.performance.module_preload, false)
  assert_eq(c.performance.bundler, Bundler::Esbuild)
}

///|
test "parse output modes" {
  let static_json =
    #|{"output": "static"}
  let hybrid_json =
    #|{"output": "hybrid"}
  let server_json =
    #|{"output": "server"}
  assert_eq(parse_luna_config(static_json).unwrap().output, OutputMode::Static)
  assert_eq(parse_luna_config(hybrid_json).unwrap().output, OutputMode::Hybrid)
  assert_eq(parse_luna_config(server_json).unwrap().output, OutputMode::Server)
}

///|
test "parse routing modes" {
  let file_based =
    #|{"routing": {"mode": "file-based"}}
  let explicit =
    #|{"routing": {"mode": "explicit"}}
  let hybrid =
    #|{"routing": {"mode": "hybrid"}}
  assert_eq(
    parse_luna_config(file_based).unwrap().routing.mode,
    RoutingMode::FileBased,
  )
  assert_eq(
    parse_luna_config(explicit).unwrap().routing.mode,
    RoutingMode::Explicit,
  )
  assert_eq(
    parse_luna_config(hybrid).unwrap().routing.mode,
    RoutingMode::Hybrid,
  )
}

///|
test "parse navigation strategies" {
  let simple =
    #|{"navigation": {"strategy": "simple"}}
  let hybrid =
    #|{"navigation": {"strategy": "hybrid"}}
  let unified =
    #|{"navigation": {"strategy": "unified"}}
  assert_eq(
    parse_luna_config(simple).unwrap().navigation.strategy,
    NavigationStrategy::Simple,
  )
  assert_eq(
    parse_luna_config(hybrid).unwrap().navigation.strategy,
    NavigationStrategy::Hybrid,
  )
  assert_eq(
    parse_luna_config(unified).unwrap().navigation.strategy,
    NavigationStrategy::Unified,
  )
}

///|
test "parse prefetch strategies" {
  let hover =
    #|{"performance": {"prefetch": "hover"}}
  let visible =
    #|{"performance": {"prefetch": "visible"}}
  let none =
    #|{"performance": {"prefetch": "none"}}
  assert_eq(
    parse_luna_config(hover).unwrap().performance.prefetch,
    PrefetchStrategy::Hover,
  )
  assert_eq(
    parse_luna_config(visible).unwrap().performance.prefetch,
    PrefetchStrategy::Visible,
  )
  assert_eq(
    parse_luna_config(none).unwrap().performance.prefetch,
    PrefetchStrategy::None,
  )
}

///|
test "output mode requires_server" {
  assert_eq(OutputMode::Static.requires_server(), false)
  assert_eq(OutputMode::Hybrid.requires_server(), true)
  assert_eq(OutputMode::Server.requires_server(), true)
}

///|
test "routing mode helpers" {
  assert_eq(RoutingMode::FileBased.is_file_based(), true)
  assert_eq(RoutingMode::FileBased.is_explicit(), false)
  assert_eq(RoutingMode::Explicit.is_file_based(), false)
  assert_eq(RoutingMode::Explicit.is_explicit(), true)
  assert_eq(RoutingMode::Hybrid.is_file_based(), true)
  assert_eq(RoutingMode::Hybrid.is_explicit(), true)
}
