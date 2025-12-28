// SSG i18n Path Utilities
//
// Path manipulation for internationalized (i18n) routes.
// Shared between Sol (SSR framework) and Astra (SSG).

// =============================================================================
// Locale Detection from Filename
// =============================================================================

///|
/// Detect locale from file path using filename suffix
/// e.g., "guide/intro.ja.md" -> ("ja", "/guide/intro/")
///       "guide/intro.md" -> ("en", "/guide/intro/")
pub fn detect_locale_from_path(
  path : String,
  i18n : I18nConfig,
  trailing_slash? : Bool = true,
) -> (String, String) {
  // Get locale codes from config
  let locale_codes : Array[String] = []
  for locale in i18n.locales {
    locale_codes.push(locale.code)
  }
  // Extract filename and check for locale suffix
  let filename = get_filename(path)
  match extract_locale_suffix(filename, locale_codes) {
    Some((locale_code, clean_filename)) => {
      // Replace filename in path with clean filename
      let clean_path = replace_filename(path, clean_filename)
      let canonical = file_to_url_path(clean_path, trailing_slash~)
      (locale_code, canonical)
    }
    None =>
      // No locale suffix found, use default locale
      (i18n.default_locale, file_to_url_path(path, trailing_slash~))
  }
}

// =============================================================================
// Localized URL Building
// =============================================================================

///|
/// Build localized URL path from canonical path and locale
/// e.g., ("/guide/intro", "ja", config) -> "/ja/guide/intro"
///       ("/guide/intro", "en", config) -> "/guide/intro"
pub fn build_localized_url(
  canonical_path : String,
  locale : String,
  i18n : I18nConfig,
) -> String {
  // Find locale config
  for loc in i18n.locales {
    if loc.code == locale {
      if loc.path.is_empty() {
        return canonical_path
      } else if canonical_path == "/" {
        return "/" + loc.path + "/"
      } else {
        return "/" + loc.path + canonical_path
      }
    }
  }
  // Fallback to canonical path
  canonical_path
}

// =============================================================================
// Locale Helpers
// =============================================================================

///|
/// Get locale config by code
pub fn get_locale_config(
  i18n : I18nConfig,
  locale_code : String,
) -> LocaleConfig? {
  for locale in i18n.locales {
    if locale.code == locale_code {
      return Some(locale)
    }
  }
  None
}

///|
/// Check if a locale is the default locale
pub fn is_default_locale(i18n : I18nConfig, locale_code : String) -> Bool {
  i18n.default_locale == locale_code
}

///|
/// Get URL prefix for a locale
/// Returns empty string for default locale, or the locale path otherwise
pub fn get_locale_url_prefix(i18n : I18nConfig, locale_code : String) -> String {
  for locale in i18n.locales {
    if locale.code == locale_code {
      if locale.path.is_empty() {
        return ""
      } else {
        return "/" + locale.path
      }
    }
  }
  ""
}

///|
/// Strip locale prefix from URL path
/// e.g., "/ja/guide/intro/" with i18n config -> "/guide/intro/"
pub fn strip_locale_from_url(
  url_path : String,
  i18n : I18nConfig,
) -> (String, String) {
  for locale in i18n.locales {
    if locale.path.is_empty() {
      continue
    }
    let prefix = "/" + locale.path + "/"
    if url_path.has_prefix(prefix) {
      let canonical = "/" + @utils.slice_from(url_path, prefix.length())
      return (locale.code, canonical)
    }
    // Handle exact match (e.g., "/ja/")
    let exact = "/" + locale.path + "/"
    if url_path == exact {
      return (locale.code, "/")
    }
  }
  // No locale prefix found, use default locale
  (i18n.default_locale, url_path)
}
