// Unit tests for i18n path utilities

// =============================================================================
// Test Helpers
// =============================================================================

///|
/// Create i18n config with multiple locales
fn create_multi_locale_config() -> I18nConfig {
  {
    default_locale: "en",
    locales: [
      LocaleConfig::{ code: "en", label: "English", path: "" },
      LocaleConfig::{ code: "ja", label: "日本語", path: "ja" },
      LocaleConfig::{ code: "fr", label: "Français", path: "fr" },
    ],
  }
}

///|
/// Create i18n config with single locale (English only)
fn create_single_locale_config() -> I18nConfig {
  I18nConfig::default()
}

// =============================================================================
// detect_locale_from_path Tests (Filename-based i18n)
// =============================================================================

///|
test "detect_locale_from_path - default locale (no suffix)" {
  let config = create_multi_locale_config()
  let (locale, url) = detect_locale_from_path("guide/intro.md", config)
  inspect(locale, content="en")
  inspect(url, content="/guide/intro/")
}

///|
test "detect_locale_from_path - ja locale via filename suffix" {
  let config = create_multi_locale_config()
  let (locale, url) = detect_locale_from_path("guide/intro.ja.md", config)
  inspect(locale, content="ja")
  inspect(url, content="/guide/intro/")
}

///|
test "detect_locale_from_path - fr locale via filename suffix" {
  let config = create_multi_locale_config()
  let (locale, url) = detect_locale_from_path("guide/intro.fr.md", config)
  inspect(locale, content="fr")
  inspect(url, content="/guide/intro/")
}

///|
test "detect_locale_from_path - index file" {
  let config = create_multi_locale_config()
  let (locale, url) = detect_locale_from_path("index.md", config)
  inspect(locale, content="en")
  inspect(url, content="/")
}

///|
test "detect_locale_from_path - ja index file via filename suffix" {
  let config = create_multi_locale_config()
  let (locale, url) = detect_locale_from_path("index.ja.md", config)
  inspect(locale, content="ja")
  inspect(url, content="/")
}

///|
test "detect_locale_from_path - without trailing slash" {
  let config = create_multi_locale_config()
  let (locale, url) = detect_locale_from_path(
    "guide/intro.md",
    config,
    trailing_slash=false,
  )
  inspect(locale, content="en")
  inspect(url, content="/guide/intro")
}

///|
test "detect_locale_from_path - single locale config" {
  let config = create_single_locale_config()
  let (locale, url) = detect_locale_from_path("guide/intro.md", config)
  inspect(locale, content="en")
  inspect(url, content="/guide/intro/")
}

///|
test "detect_locale_from_path - nested path with locale suffix" {
  let config = create_multi_locale_config()
  let (locale, url) = detect_locale_from_path(
    "docs/api/reference.ja.md", config,
  )
  inspect(locale, content="ja")
  inspect(url, content="/docs/api/reference/")
}

// =============================================================================
// build_localized_url Tests
// =============================================================================

///|
test "build_localized_url - default locale (no prefix)" {
  let config = create_multi_locale_config()
  let url = build_localized_url("/guide/intro/", "en", config)
  inspect(url, content="/guide/intro/")
}

///|
test "build_localized_url - ja locale" {
  let config = create_multi_locale_config()
  let url = build_localized_url("/guide/intro/", "ja", config)
  inspect(url, content="/ja/guide/intro/")
}

///|
test "build_localized_url - fr locale" {
  let config = create_multi_locale_config()
  let url = build_localized_url("/guide/intro/", "fr", config)
  inspect(url, content="/fr/guide/intro/")
}

///|
test "build_localized_url - root path default locale" {
  let config = create_multi_locale_config()
  let url = build_localized_url("/", "en", config)
  inspect(url, content="/")
}

///|
test "build_localized_url - root path ja locale" {
  let config = create_multi_locale_config()
  let url = build_localized_url("/", "ja", config)
  inspect(url, content="/ja/")
}

///|
test "build_localized_url - unknown locale fallback" {
  let config = create_multi_locale_config()
  let url = build_localized_url("/guide/intro/", "de", config)
  inspect(url, content="/guide/intro/")
}

// =============================================================================
// get_locale_config Tests
// =============================================================================

///|
test "get_locale_config - existing locale" {
  let config = create_multi_locale_config()
  let locale = get_locale_config(config, "ja")
  inspect(locale is Some(_), content="true")
  inspect(locale.unwrap().label, content="日本語")
}

///|
test "get_locale_config - default locale" {
  let config = create_multi_locale_config()
  let locale = get_locale_config(config, "en")
  inspect(locale is Some(_), content="true")
  inspect(locale.unwrap().path, content="")
}

///|
test "get_locale_config - non-existing locale" {
  let config = create_multi_locale_config()
  let locale = get_locale_config(config, "de")
  inspect(locale is None, content="true")
}

// =============================================================================
// is_default_locale Tests
// =============================================================================

///|
test "is_default_locale - true" {
  let config = create_multi_locale_config()
  inspect(is_default_locale(config, "en"), content="true")
}

///|
test "is_default_locale - false" {
  let config = create_multi_locale_config()
  inspect(is_default_locale(config, "ja"), content="false")
}

// =============================================================================
// get_locale_url_prefix Tests
// =============================================================================

///|
test "get_locale_url_prefix - default locale (empty)" {
  let config = create_multi_locale_config()
  let prefix = get_locale_url_prefix(config, "en")
  inspect(prefix, content="")
}

///|
test "get_locale_url_prefix - ja locale" {
  let config = create_multi_locale_config()
  let prefix = get_locale_url_prefix(config, "ja")
  inspect(prefix, content="/ja")
}

///|
test "get_locale_url_prefix - non-existing locale" {
  let config = create_multi_locale_config()
  let prefix = get_locale_url_prefix(config, "de")
  inspect(prefix, content="")
}

// =============================================================================
// strip_locale_from_url Tests
// =============================================================================

///|
test "strip_locale_from_url - no prefix (default locale)" {
  let config = create_multi_locale_config()
  let (locale, canonical) = strip_locale_from_url("/guide/intro/", config)
  inspect(locale, content="en")
  inspect(canonical, content="/guide/intro/")
}

///|
test "strip_locale_from_url - ja prefix" {
  let config = create_multi_locale_config()
  let (locale, canonical) = strip_locale_from_url("/ja/guide/intro/", config)
  inspect(locale, content="ja")
  inspect(canonical, content="/guide/intro/")
}

///|
test "strip_locale_from_url - fr prefix" {
  let config = create_multi_locale_config()
  let (locale, canonical) = strip_locale_from_url("/fr/guide/intro/", config)
  inspect(locale, content="fr")
  inspect(canonical, content="/guide/intro/")
}

///|
test "strip_locale_from_url - root path" {
  let config = create_multi_locale_config()
  let (locale, canonical) = strip_locale_from_url("/", config)
  inspect(locale, content="en")
  inspect(canonical, content="/")
}

///|
test "strip_locale_from_url - ja root path" {
  let config = create_multi_locale_config()
  let (locale, canonical) = strip_locale_from_url("/ja/", config)
  inspect(locale, content="ja")
  inspect(canonical, content="/")
}
