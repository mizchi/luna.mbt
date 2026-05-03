// CORS Middleware
//
// Cross-Origin Resource Sharing middleware with flexible configuration.

// ============================================================================
// CORS Configuration
// ============================================================================

///|
/// Origin configuration
pub enum CorsOrigin {
  /// Allow all origins (*)
  All
  /// Allow single origin
  Single(String)
  /// Allow multiple origins
  List(Array[String])
  /// Dynamic origin validation
  Dynamic((String) -> Bool)
}

///|
/// CORS configuration
pub struct CorsConfig {
  /// Allowed origins
  origin : CorsOrigin
  /// Allowed methods
  methods : Array[String]
  /// Allowed headers
  allowed_headers : Array[String]
  /// Exposed headers
  exposed_headers : Array[String]
  /// Allow credentials
  credentials : Bool
  /// Max age for preflight cache (seconds)
  max_age : Int?
}

///|
/// Default CORS configuration (permissive)
pub fn CorsConfig::default() -> CorsConfig {
  {
    origin: CorsOrigin::All,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowed_headers: ["Content-Type", "Authorization", "X-Requested-With"],
    exposed_headers: [],
    credentials: false,
    max_age: Some(86400), // 24 hours
  }
}

///|
/// Strict CORS configuration (same origin only)
pub fn CorsConfig::strict() -> CorsConfig {
  {
    origin: CorsOrigin::List([]),
    methods: ["GET", "POST"],
    allowed_headers: ["Content-Type"],
    exposed_headers: [],
    credentials: false,
    max_age: None,
  }
}

///|
/// Set allowed origin
pub fn CorsConfig::with_origin(
  self : CorsConfig,
  origin : CorsOrigin,
) -> CorsConfig {
  { ..self, origin, }
}

///|
/// Set single origin
pub fn CorsConfig::with_origin_single(
  self : CorsConfig,
  origin : String,
) -> CorsConfig {
  { ..self, origin: CorsOrigin::Single(origin) }
}

///|
/// Set allowed methods
pub fn CorsConfig::with_methods(
  self : CorsConfig,
  methods : Array[String],
) -> CorsConfig {
  { ..self, methods, }
}

///|
/// Set allowed headers
pub fn CorsConfig::with_allowed_headers(
  self : CorsConfig,
  headers : Array[String],
) -> CorsConfig {
  { ..self, allowed_headers: headers }
}

///|
/// Set exposed headers
pub fn CorsConfig::with_exposed_headers(
  self : CorsConfig,
  headers : Array[String],
) -> CorsConfig {
  { ..self, exposed_headers: headers }
}

///|
/// Enable credentials
pub fn CorsConfig::with_credentials(self : CorsConfig) -> CorsConfig {
  { ..self, credentials: true }
}

///|
/// Set max age
pub fn CorsConfig::with_max_age(self : CorsConfig, max_age : Int) -> CorsConfig {
  { ..self, max_age: Some(max_age) }
}

// ============================================================================
// CORS Middleware
// ============================================================================

///|
/// Create CORS middleware with default config
pub fn cors() -> Middleware {
  cors_with_config(CorsConfig::default())
}

///|
/// Create CORS middleware with custom config
pub fn cors_with_config(config : CorsConfig) -> Middleware {
  match static_mars_cors_handler(config) {
    Some(base_handler) => Middleware(base_handler)
    None =>
      Middleware(
        @mars.Handler(async fn(ctx) {
          let request_origin = match ctx.header("Origin") {
            Some(o) => o
            None => return // Continue
          }
          let response_origin = match
            resolve_response_origin(request_origin, config.origin) {
            Some(origin) => origin
            None => return
          }
          let options = to_mars_cors_options(config, response_origin)
          let @mars.Handler(base_handler) = @mars_mw.cors(options~)
          base_handler(ctx)
        }),
      )
  }
}

///|
fn static_mars_cors_handler(config : CorsConfig) -> @mars.Handler? {
  let response_origin = match config.origin {
    All => Some("*")
    Single(origin) => Some(origin)
    List(_) | Dynamic(_) => None
  }
  match response_origin {
    Some(origin) => {
      let options = to_mars_cors_options(config, origin)
      Some(@mars_mw.cors(options~))
    }
    None => None
  }
}

///|
fn resolve_response_origin(
  request_origin : String,
  allowed : CorsOrigin,
) -> String? {
  match allowed {
    All => Some("*")
    Single(allowed_origin) =>
      if request_origin == allowed_origin {
        Some(allowed_origin)
      } else {
        None
      }
    List(origins) =>
      if origins.contains(request_origin) {
        Some(request_origin)
      } else {
        None
      }
    Dynamic(check) =>
      if check(request_origin) {
        Some(request_origin)
      } else {
        None
      }
  }
}

///|
fn to_mars_cors_options(
  config : CorsConfig,
  response_origin : String,
) -> @mars_mw.CorsOptions {
  let max_age = match config.max_age {
    Some(age) => age
    None => 0
  }
  {
    origin: response_origin,
    methods: config.methods,
    allowed_headers: config.allowed_headers,
    exposed_headers: config.exposed_headers,
    credentials: config.credentials,
    max_age,
  }
}
