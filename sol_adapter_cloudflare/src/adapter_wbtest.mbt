///|
using @test {assert_eq}

///| Tests for Cloudflare adapter utilities.

///|
extern "js" fn ffi_clear_exported_sol_app() -> Unit =
  #| () => {
  #|   delete globalThis.__SOL_APP__;
  #|   delete globalThis.__SOL_RUNTIME__;
  #|   delete globalThis.__SOL_ADAPTER_MODE__;
  #| }

///|
extern "js" fn ffi_test_env() -> @mars.JsEnv =
  #| () => ({
  #|   API_TOKEN: "secret-token",
  #|   CACHE: { get() {}, put() {} },
  #|   MEDIA: { get() {}, put() {} },
  #| })

///|
extern "js" fn ffi_fetch_exported_app_text(
  path : String,
  env : @mars.JsEnv,
) -> @js_async.Promise[String] =
  #| async (path, env) => {
  #|   const app = globalThis.__SOL_APP__;
  #|   if (!app || typeof app.fetch !== "function") {
  #|     throw new Error("missing exported Sol app");
  #|   }
  #|   const ctx = { waitUntil(promise) { Promise.resolve(promise).catch(() => {}); } };
  #|   const response = await app.fetch(new Request("https://example.test" + path), env, ctx);
  #|   return await response.text();
  #| }

///|
async test "export_app exposes Cloudflare fetch with env and execution context" {
  ffi_clear_exported_sol_app()
  let app = @mars.Server::new()
  app.get(
    "/secret",
    @mars.handler(async fn(ctx) {
      let token = ctx.env_var("API_TOKEN").unwrap_or("missing")
      ctx.text(token)
    }),
  )
  export_app(app)
  let body = ffi_fetch_exported_app_text("/secret", ffi_test_env()).wait()
  assert_eq(body, "secret-token")
}

///|
test "missing_required_bindings reports absent non-optional bindings" {
  let missing = missing_required_bindings(ffi_test_env(), [
    env_var("API_TOKEN"),
    kv_namespace("CACHE"),
    r2_bucket("MISSING_MEDIA"),
    service_binding("OPTIONAL_SERVICE", optional=true),
  ])
  assert_eq(missing.length(), 1)
  assert_eq(missing[0].name, "MISSING_MEDIA")
  assert_eq(missing[0].kind.label(), "r2")
  assert_true(describe_missing_bindings(missing).contains("MISSING_MEDIA"))
}

///|
test "binding keys and TypeScript env declaration preserve binding kinds" {
  let token : BindingKey[String] = env_var_key("API_TOKEN")
  assert_eq(token.name(), "API_TOKEN")
  assert_eq(token.kind().label(), "var")
  let dts = bindings_typescript_decl([
    env_var("API_TOKEN"),
    secret("SESSION_SECRET"),
    kv_namespace("CACHE"),
    r2_bucket("MEDIA", optional=true),
    d1_database("DB"),
    durable_object("COUNTER"),
    service_binding("AUTH"),
    ai_binding("AI"),
    queue_binding("JOBS"),
    env_var("FEATURE-FLAG", optional=true),
  ])
  assert_true(dts.contains("export interface CloudflareEnv {"))
  assert_true(dts.contains("  API_TOKEN: string;"))
  assert_true(dts.contains("  SESSION_SECRET: string;"))
  assert_true(dts.contains("  CACHE: KVNamespace;"))
  assert_true(dts.contains("  MEDIA?: R2Bucket;"))
  assert_true(dts.contains("  DB: D1Database;"))
  assert_true(dts.contains("  COUNTER: DurableObjectNamespace;"))
  assert_true(dts.contains("  AUTH: Fetcher;"))
  assert_true(dts.contains("  AI: Ai;"))
  assert_true(dts.contains("  JOBS: Queue;"))
  assert_true(dts.contains("  \"FEATURE-FLAG\"?: string;"))
}

///|
test "generate_cloudflare_server_entry_js is edge-safe and escaped" {
  let js = generate_cloudflare_server_entry_js(
    "./server.js';globalThis.__SOL_PWNED__=true;//",
  )
  assert_true(
    js.contains(
      "await import(\"./server.js';globalThis.__SOL_PWNED__=true;//\")",
    ),
  )
  assert_true(js.contains("globalThis.__SOL_RUNTIME__ = 'cloudflare'"))
  assert_true(js.contains("export default app"))
  assert_false(js.contains("setInterval"))
  assert_false(js.contains("@hono/node-server"))
  assert_false(js.contains("node:fs"))
}

///|
test "generate_worker_entry_js composes Worker APIs before Sol routes" {
  let js = generate_worker_entry_js("./.sol/prod/server/main.js")
  assert_true(js.contains("import solApp from \"./.sol/prod/server/main.js\""))
  assert_true(js.contains("url.pathname.startsWith(\"/api/\")"))
  assert_true(js.contains("solApp.fetch(request, env, ctx)"))
  assert_false(js.contains("__SOL_APP__"))
  assert_false(js.contains("_build/js"))
}

///|
test "generate_wrangler_toml documents default bundled Worker entry" {
  let toml = generate_wrangler_toml("myapp")
  assert_true(toml.contains("name = \"myapp\""))
  assert_true(toml.contains("main = \"worker.entry.mjs\""))
  assert_true(toml.contains("compatibility_date = \"2025-01-01\""))
  assert_false(toml.contains("no_bundle"))
}

///|
fn test_page(path : String, revalidate? : Int? = None) -> @router.SolRoutes {
  @router.SolRoutes::Page(
    path~,
    handler=@router.PageHandler(async fn(_) { @router.server_nodes([]) }),
    title="",
    meta=[],
    revalidate~,
    cache=None,
  )
}

///|
fn test_get(path : String) -> @router.SolRoutes {
  @router.SolRoutes::Get(
    path~,
    handler=@router.ApiHandler(async fn(_) { Json::null() }),
  )
}

///|
test "route_pattern_to_worker_glob converts Sol params to Cloudflare wildcards" {
  assert_eq(route_pattern_to_worker_glob("/users/:id"), "/users/*")
  assert_eq(route_pattern_to_worker_glob("/docs/[...slug]"), "/docs/*")
  assert_eq(route_pattern_to_worker_glob("/docs/[[...path]]"), "/docs/*")
  assert_eq(route_pattern_to_worker_glob("/"), "/")
}

///|
test "extract_worker_first_patterns uses Sol route analysis without core owning Cloudflare conversion" {
  let routes : Array[@router.SolRoutes] = [
    test_page("/"),
    test_page("/blog/:slug", revalidate=Some(60)),
    test_get("/api/health"),
  ]
  let patterns = extract_worker_first_patterns(routes)
  assert_eq(patterns.length(), 2)
  assert_eq(patterns[0], "/api/health")
  assert_eq(patterns[1], "/blog/*")
}

///|
test "generate_wrangler_assets_config omits worker-first list for static-only routes" {
  let config = generate_wrangler_assets_config([test_page("/")], "./dist")
  assert_true(config.contains("\"directory\": \"./dist\""))
  assert_true(config.contains("\"not_found_handling\": \"404-page\""))
  assert_false(config.contains("run_worker_first"))
}

///|
test "generate_wrangler_assets_config includes worker-first list for hybrid routes" {
  let config = generate_wrangler_assets_config(
    [test_page("/"), test_get("/api/health")],
    "./dist",
  )
  assert_true(config.contains("\"run_worker_first\""))
  assert_true(config.contains("\"/api/health\""))
}

///|
test "generate_wrangler_assets_config escapes string values" {
  let config = generate_wrangler_assets_config(
    [test_get("/api/quote\"path")],
    "./dist\";bad",
  )
  assert_true(config.contains("\"directory\": \"./dist\\\";bad\""))
  assert_true(config.contains("\"/api/quote\\\"path\""))
  assert_false(config.contains("\"directory\": \"./dist\";bad\""))
}
