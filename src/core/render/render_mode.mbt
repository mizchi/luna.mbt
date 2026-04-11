// Render Mode Definitions
//
// Defines how a component should be rendered across server and client.

///|
/// Hydration trigger - when to hydrate a component on the client
pub(all) enum HydrationTrigger {
  /// Hydrate immediately on page load
  Load
  /// Hydrate when browser is idle (requestIdleCallback)
  Idle
  /// Hydrate when component enters viewport (IntersectionObserver)
  Visible
  /// Hydrate when media query matches
  Media(String)
} derive(Eq, Debug)

///|
impl Show for HydrationTrigger with output(self, logger) {
  match self {
    Load => logger.write_string("Load")
    Idle => logger.write_string("Idle")
    Visible => logger.write_string("Visible")
    Media(query) => {
      logger.write_string("Media(")
      logger.write_string(query)
      logger.write_string(")")
    }
  }
}

///|
/// Render mode for components
pub(all) enum RenderMode {
  /// Server-side only, no client JavaScript
  SSROnly
  /// Server-side render with client hydration
  Hydration(HydrationTrigger)
  /// Client-only rendering (placeholder on server)
  ClientOnly
  /// Server-side deferred rendering (Server Islands)
  ServerDefer
} derive(Eq, Debug)

///|
impl Show for RenderMode with output(self, logger) {
  match self {
    SSROnly => logger.write_string("SSROnly")
    Hydration(trigger) => {
      logger.write_string("Hydration(")
      logger.write_string(trigger.to_string())
      logger.write_string(")")
    }
    ClientOnly => logger.write_string("ClientOnly")
    ServerDefer => logger.write_string("ServerDefer")
  }
}

///|
/// Check if render mode requires client JavaScript
pub fn RenderMode::requires_client_js(self : RenderMode) -> Bool {
  match self {
    SSROnly => false
    ServerDefer => false
    Hydration(_) => true
    ClientOnly => true
  }
}

///|
/// Check if render mode requires server rendering
pub fn RenderMode::requires_ssr(self : RenderMode) -> Bool {
  match self {
    SSROnly => true
    Hydration(_) => true
    ServerDefer => true
    ClientOnly => false
  }
}

///|
/// Get hydration trigger if applicable
pub fn RenderMode::get_trigger(self : RenderMode) -> HydrationTrigger? {
  match self {
    Hydration(trigger) => Some(trigger)
    _ => None
  }
}

///|
/// Convert to string for serialization
pub fn HydrationTrigger::to_attr_string(self : HydrationTrigger) -> String {
  match self {
    Load => "load"
    Idle => "idle"
    Visible => "visible"
    Media(query) => "media:\{query}"
  }
}

///|
/// Parse from string
pub fn HydrationTrigger::parse(s : String) -> HydrationTrigger {
  if s == "load" {
    Load
  } else if s == "idle" {
    Idle
  } else if s == "visible" {
    Visible
  } else if s.has_prefix("media:") {
    let query = s[6:].to_string()
    Media(query)
  } else {
    Load // default
  }
}
