///| Shard Types

///| Types for generating portable, resumable UI snippets (shards)

///|
/// When to hydrate the component
pub(all) enum TriggerType {
  /// Hydrate on page load (DOMContentLoaded)
  Load
  /// Hydrate when browser is idle (requestIdleCallback)
  Idle
  /// Hydrate when element enters viewport (IntersectionObserver)
  Visible
  /// Hydrate when media query matches
  Media(String)
  /// Never auto-hydrate (manual only)
  None
}

///|
/// How state is provided
pub(all) enum StateConfig {
  /// No state
  Empty
  /// Inline JSON in ln:state attribute
  Inline(String)
  /// Reference to a <script id="..."> element
  ScriptRef(String)
  /// URL to fetch state from
  Url(String)
}

///|
/// Configuration for generating a shard snippet
pub struct ShardConfig {
  /// Unique identifier for the component
  id : String
  /// ES module URL to load for hydration
  script_url : String
  /// When to trigger hydration
  trigger : TriggerType
  /// Initial state configuration
  state : StateConfig
  /// Pre-rendered HTML content (SSR output)
  ssr_content : String?
  /// Whether to include the loader script tag
  include_loader : Bool
  /// URL for the loader script
  loader_url : String
}

///|
/// Output from shard generation
pub struct ShardOutput {
  /// Complete HTML snippet
  html : String
  /// Scripts to inject in <head> (for SSR environments)
  head_scripts : Array[String]
  /// State <script> tags (when using ScriptRef)
  state_scripts : Array[String]
}

///|
/// Default loader URL
pub let default_loader_url : String = "loader.min.js"

///|
/// Create a minimal shard config
pub fn ShardConfig::new(id : String, script_url : String) -> ShardConfig {
  {
    id,
    script_url,
    trigger: Load,
    state: Empty,
    ssr_content: None,
    include_loader: false,
    loader_url: default_loader_url,
  }
}

///|
/// Builder pattern: set trigger
pub fn ShardConfig::with_trigger(
  self : ShardConfig,
  trigger : TriggerType,
) -> ShardConfig {
  { ..self, trigger, }
}

///|
/// Builder pattern: set inline state from JSON string
pub fn ShardConfig::with_state(
  self : ShardConfig,
  json : String,
) -> ShardConfig {
  { ..self, state: Inline(json) }
}

///|
/// Builder pattern: set state from script reference
pub fn ShardConfig::with_state_ref(
  self : ShardConfig,
  script_id : String,
) -> ShardConfig {
  { ..self, state: ScriptRef(script_id) }
}

///|
/// Builder pattern: set state from URL
pub fn ShardConfig::with_state_url(
  self : ShardConfig,
  url : String,
) -> ShardConfig {
  { ..self, state: Url(url) }
}

///|
/// Builder pattern: set SSR content
pub fn ShardConfig::with_ssr_content(
  self : ShardConfig,
  content : String,
) -> ShardConfig {
  { ..self, ssr_content: Some(content) }
}

///|
/// Builder pattern: include loader script
pub fn ShardConfig::with_loader(
  self : ShardConfig,
  url : String,
) -> ShardConfig {
  { ..self, include_loader: true, loader_url: url }
}

///|
/// Builder pattern: include loader script with default URL
pub fn ShardConfig::with_default_loader(self : ShardConfig) -> ShardConfig {
  { ..self, include_loader: true }
}

///|
/// Convert TriggerType to attribute value
pub fn TriggerType::to_string(self : TriggerType) -> String {
  match self {
    Load => "load"
    Idle => "idle"
    Visible => "visible"
    Media(query) => "media:" + query
    None => "none"
  }
}

///|
/// Parse TriggerType from string
pub fn TriggerType::parse(s : String) -> TriggerType {
  match s {
    "load" => Load
    "idle" => Idle
    "visible" => Visible
    "none" => None
    _ =>
      if s.has_prefix("media:") {
        // Extract substring after "media:" prefix
        let sb = StringBuilder::new()
        for i = 6; i < s.length(); i = i + 1 {
          sb.write_char(s.iter().nth(i).unwrap())
        }
        Media(sb.to_string())
      } else {
        Load // default
      }
  }
}
