// Unit tests for i18n.mbt
// Tests for locale detection from file paths

// Helper to create i18n config for tests

///|
fn test_i18n_config() -> I18nConfig {
  I18nConfig::{
    default_locale: "en",
    locales: [
      LocaleConfig::{ code: "en", label: "English", path: "" },
      LocaleConfig::{ code: "ja", label: "日本語", path: "ja" },
      LocaleConfig::{ code: "fr", label: "Français", path: "fr" },
    ],
  }
}

// =============================================================================
// Locale Detection from Path
// =============================================================================

///|
test "detect_locale_from_path - suffix-based markdown" {
  let config = test_i18n_config()
  // Japanese locale detected from .ja.md suffix
  let (locale, canonical) = detect_locale_from_path("guide/intro.ja.md", config)
  inspect(locale, content="ja")
  inspect(canonical, content="/guide/intro/")
}

///|
test "detect_locale_from_path - suffix-based html" {
  let config = test_i18n_config()
  // Japanese locale detected from .ja.html suffix
  let (locale, canonical) = detect_locale_from_path(
    "search/index.ja.html", config,
  )
  inspect(locale, content="ja")
  inspect(canonical, content="/search/")
}

///|
test "detect_locale_from_path - default locale (no suffix)" {
  let config = test_i18n_config()
  // Default locale when no suffix
  let (locale, canonical) = detect_locale_from_path("guide/intro.md", config)
  inspect(locale, content="en")
  inspect(canonical, content="/guide/intro/")
}

///|
test "detect_locale_from_path - index files" {
  let config = test_i18n_config()
  // index.ja.md -> locale "ja", canonical "/folder/"
  let (locale, canonical) = detect_locale_from_path(
    "introduction/index.ja.md", config,
  )
  inspect(locale, content="ja")
  inspect(canonical, content="/introduction/")
}

///|
test "detect_locale_from_path - root index" {
  let config = test_i18n_config()
  let (locale, canonical) = detect_locale_from_path("index.ja.md", config)
  inspect(locale, content="ja")
  inspect(canonical, content="/")
}

///|
test "detect_locale_from_path - multiple dots in filename" {
  let config = test_i18n_config()
  // file.name.ja.md -> should detect ja
  let (locale, canonical) = detect_locale_from_path(
    "docs/file.name.ja.md", config,
  )
  inspect(locale, content="ja")
  inspect(canonical, content="/docs/file.name/")
}

///|
test "detect_locale_from_path - french locale" {
  let config = test_i18n_config()
  let (locale, canonical) = detect_locale_from_path("guide/intro.fr.md", config)
  inspect(locale, content="fr")
  inspect(canonical, content="/guide/intro/")
}

///|
test "detect_locale_from_path - unknown locale suffix" {
  let config = test_i18n_config()
  // .de is not in config, should use default
  let (locale, canonical) = detect_locale_from_path("guide/intro.de.md", config)
  inspect(locale, content="en")
  inspect(canonical, content="/guide/intro.de/")
}

// =============================================================================
// Localized URL Building
// =============================================================================

///|
test "build_localized_url - default locale" {
  let config = test_i18n_config()
  // Default locale (en) has empty path, so URL stays as-is
  inspect(
    build_localized_url("/guide/intro/", "en", config),
    content="/guide/intro/",
  )
}

///|
test "build_localized_url - non-default locale" {
  let config = test_i18n_config()
  // Japanese locale has path "ja", so URL gets /ja/ prefix
  inspect(
    build_localized_url("/guide/intro/", "ja", config),
    content="/ja/guide/intro/",
  )
}

///|
test "build_localized_url - root path" {
  let config = test_i18n_config()
  inspect(build_localized_url("/", "ja", config), content="/ja/")
  inspect(build_localized_url("/", "en", config), content="/")
}

///|
test "build_localized_url - french locale" {
  let config = test_i18n_config()
  inspect(
    build_localized_url("/docs/api/", "fr", config),
    content="/fr/docs/api/",
  )
}

// =============================================================================
// URL Locale Stripping
// =============================================================================

///|
test "strip_locale_from_url - with locale prefix" {
  let config = test_i18n_config()
  let (locale, canonical) = strip_locale_from_url("/ja/guide/intro/", config)
  inspect(locale, content="ja")
  inspect(canonical, content="/guide/intro/")
}

///|
test "strip_locale_from_url - without locale prefix" {
  let config = test_i18n_config()
  let (locale, canonical) = strip_locale_from_url("/guide/intro/", config)
  inspect(locale, content="en")
  inspect(canonical, content="/guide/intro/")
}

///|
test "strip_locale_from_url - root with locale" {
  let config = test_i18n_config()
  let (locale, canonical) = strip_locale_from_url("/ja/", config)
  inspect(locale, content="ja")
  inspect(canonical, content="/")
}

// =============================================================================
// Locale Helpers
// =============================================================================

///|
test "is_default_locale - true" {
  let config = test_i18n_config()
  inspect(is_default_locale(config, "en"), content="true")
}

///|
test "is_default_locale - false" {
  let config = test_i18n_config()
  inspect(is_default_locale(config, "ja"), content="false")
}

///|
test "get_locale_url_prefix - default locale" {
  let config = test_i18n_config()
  inspect(get_locale_url_prefix(config, "en"), content="")
}

///|
test "get_locale_url_prefix - non-default locale" {
  let config = test_i18n_config()
  inspect(get_locale_url_prefix(config, "ja"), content="/ja")
  inspect(get_locale_url_prefix(config, "fr"), content="/fr")
}
