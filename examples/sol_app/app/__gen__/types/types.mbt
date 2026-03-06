///| Auto-generated types for island props
///| Re-exports Props structs from client packages

///| Props type from @client
pub(all) struct CounterProps {
  initial_count : Int
} derive(ToJson, FromJson)

///| Props type from @client
pub(all) struct ContactFormProps {
  action : String
  initial_name : String
  initial_email : String
} derive(ToJson, FromJson)

///| Props type from @client
pub(all) struct WcCounterProps {
  initial_count : Int
} derive(ToJson, FromJson)

// =============================================================================
// ComponentRef Factory Functions
// =============================================================================

///|
///| Create ComponentRef for counter component
pub fn counter(
  props : CounterProps,
  trigger~ : @luna.Trigger = @luna.TriggerType::Load,
) -> @luna.ComponentRef[CounterProps] {
  { url: "/static/counter.js", props, wc: false, trigger }
}

///|
///| Create ComponentRef for contact_form component
pub fn contact_form(
  props : ContactFormProps,
  trigger~ : @luna.Trigger = @luna.TriggerType::Load,
) -> @luna.ComponentRef[ContactFormProps] {
  { url: "/static/contact_form.js", props, wc: false, trigger }
}

///|
///| Create ComponentRef for wc_counter component
pub fn wc_counter(
  props : WcCounterProps,
  trigger~ : @luna.Trigger = @luna.TriggerType::Load,
) -> @luna.ComponentRef[WcCounterProps] {
  { url: "/static/wc_counter.js", props, wc: true, trigger }
}

// =============================================================================
// Route Path Constants
// =============================================================================

///|
/// Route path: /
pub let route_root : String = "/"

///|
/// Route path: /about
pub let route_about : String = "/about"

///|
/// Route path: /form
pub let route_form : String = "/form"

///|
/// Route path: /wc-counter
pub let route_wc_counter : String = "/wc-counter"

///|
/// Route path: /wc-multiple
pub let route_wc_multiple : String = "/wc-multiple"

///|
/// Route path: /docs/[...slug]
pub let route_docs_slug : String = "/docs/[...slug]"

///|
/// Route path: /blog/[[...path]]
pub let route_blog_path : String = "/blog/[[...path]]"

///|
/// Route path: /middleware-test
pub let route_middleware_test : String = "/middleware-test"

///|
/// Route path: /settings
pub let route_settings : String = "/settings"

///|
/// Route path: /users
pub let route_users : String = "/users"

///|
/// Route path: /api/health
pub let route_api_health : String = "/api/health"

///|
/// Route path: /api/bench/ping
pub let route_api_bench_ping : String = "/api/bench/ping"

///|
/// Route path: /api/bench/test/[...path]
pub let route_api_bench_test_path : String = "/api/bench/test/[...path]"

///|
/// Route path: /api/middleware-test
pub let route_api_middleware_test : String = "/api/middleware-test"

///|
/// Route path: /api/test/[...path]
pub let route_api_test_path : String = "/api/test/[...path]"

///|
/// Route path: 
pub let route_ : String = ""

///|
/// Route path: /admin
pub let route_admin : String = "/admin"

// =============================================================================
// Param Name Constants
// =============================================================================

///|
/// Route parameter name: slug
pub let param_slug : String = "slug"

///|
/// Route parameter name: path
pub let param_path : String = "path"

// =============================================================================
// ActionRef Factory Functions
// =============================================================================

///|
/// ActionRef for "submit-contact" action
pub fn action_submit_contact() -> @action.ActionRef {
  { id: "submit-contact", base_path: "/_action" }
}

