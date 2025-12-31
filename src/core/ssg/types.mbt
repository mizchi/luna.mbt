// SSG Core Types - Backend-independent type definitions
//
// These types are shared between Sol (SSR framework) and Sol SSG.
// They contain no runtime dependencies and can be used in any target.

// =============================================================================
// Internationalization (i18n)
// =============================================================================

///|
/// Internationalization configuration
pub(all) struct I18nConfig {
  /// Default locale code (e.g., "en")
  default_locale : String
  /// Available locales
  locales : Array[LocaleConfig]
}

///|
/// Default i18n configuration (English only)
pub fn I18nConfig::default() -> I18nConfig {
  {
    default_locale: "en",
    locales: [LocaleConfig::{ code: "en", label: "English", path: "" }],
  }
}

///|
/// Locale configuration
pub(all) struct LocaleConfig {
  /// Locale code (e.g., "en", "ja", "fr")
  code : String
  /// Display label (e.g., "English", "日本語")
  label : String
  /// URL path prefix (empty for default locale)
  path : String
} derive(ToJson, FromJson)

// =============================================================================
// Navigation Configuration
// =============================================================================

///|
/// Navigation configuration for SPA-like behavior
pub(all) struct NavigationConfig {
  /// Enable SPA-style navigation (fetch + content swap)
  spa : Bool
  /// Enable View Transitions API
  view_transitions : Bool
  /// Enable keyboard navigation (arrow keys)
  keyboard : Bool
} derive(ToJson, FromJson)

///|
/// Default navigation configuration
pub fn NavigationConfig::default() -> NavigationConfig {
  { spa: false, view_transitions: true, keyboard: true }
}
