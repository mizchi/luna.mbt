// Tests for scan_docs_dir_with_fs using MemFSAdapter

///|
test "scan_docs_dir_with_fs - empty directory" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="0")
}

///|
test "scan_docs_dir_with_fs - single markdown file" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let content =
    #|---
    #|title: Introduction
    #|---
    #|# Hello World
    #|
  fs.memfs().writeFileSync("/project/docs/intro.md", content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="1")
  inspect(pages[0].url_path, content="/intro/")
  inspect(pages[0].frontmatter.title, content="Some(\"Introduction\")")
}

///|
test "scan_docs_dir_with_fs - nested directories" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs/guide", recursive=true)
  let index_content =
    #|---
    #|title: Home
    #|---
    #|Welcome
    #|
  let guide_content =
    #|---
    #|title: Guide Intro
    #|---
    #|Guide content
    #|
  fs.memfs().writeFileSync("/project/docs/index.md", index_content)
  fs.memfs().writeFileSync("/project/docs/guide/intro.md", guide_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  inspect(pages.length(), content="2")
}

///|
test "scan_docs_dir_with_fs - i18n with locale directories" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  fs.memfs().mkdirSync("/project/docs/ja", recursive=true)
  // English (default locale)
  let en_content =
    #|---
    #|title: Introduction
    #|---
    #|English content
    #|
  // Japanese translation
  let ja_content =
    #|---
    #|title: はじめに
    #|---
    #|日本語コンテンツ
    #|
  fs.memfs().writeFileSync("/project/docs/intro.md", en_content)
  fs.memfs().writeFileSync("/project/docs/ja/intro.md", ja_content)
  // I18n config with en as default and ja as additional locale
  let i18n = @astra.I18nConfig::{
    default_locale: "en",
    locales: [
      @astra.LocaleConfig::{ code: "en", label: "English", path: "" },
      @astra.LocaleConfig::{ code: "ja", label: "日本語", path: "ja" },
    ],
  }
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project", i18n~)
  inspect(pages.length(), content="2")
  // Find pages by locale
  let en_page = pages.iter().find_first(fn(p) { p.locale == "en" })
  let ja_page = pages.iter().find_first(fn(p) { p.locale == "ja" })
  inspect(en_page.unwrap().url_path, content="/intro/")
  inspect(ja_page.unwrap().url_path, content="/ja/intro/")
}

///|
test "scan_docs_dir_with_fs - exclude directories" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  fs.memfs().mkdirSync("/project/docs/internal", recursive=true)
  let public_content =
    #|---
    #|title: Public
    #|---
    #|Public content
    #|
  let secret_content =
    #|---
    #|title: Secret
    #|---
    #|Secret content
    #|
  fs.memfs().writeFileSync("/project/docs/public.md", public_content)
  fs.memfs().writeFileSync("/project/docs/internal/secret.md", secret_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project", exclude=["internal"])
  inspect(pages.length(), content="1")
  inspect(pages[0].frontmatter.title, content="Some(\"Public\")")
}

///|
test "scan_docs_dir_with_fs - numeric prefix sorting" {
  let fs = @fs_adapter.MemFSAdapter::new()
  fs.memfs().mkdirSync("/project/docs", recursive=true)
  let second_content =
    #|---
    #|title: Second
    #|---
    #|Second
    #|
  let first_content =
    #|---
    #|title: First
    #|---
    #|First
    #|
  let tenth_content =
    #|---
    #|title: Tenth
    #|---
    #|Tenth
    #|
  fs.memfs().writeFileSync("/project/docs/02_second.md", second_content)
  fs.memfs().writeFileSync("/project/docs/01_first.md", first_content)
  fs.memfs().writeFileSync("/project/docs/10_tenth.md", tenth_content)
  let pages = scan_docs_dir_with_fs(fs, "docs", "/project")
  let sorted = sort_pages(pages)
  inspect(sorted.length(), content="3")
  // Numeric prefixes should be stripped from URL but preserved for sorting
  inspect(sorted[0].url_path, content="/first/")
  inspect(sorted[1].url_path, content="/second/")
  inspect(sorted[2].url_path, content="/tenth/")
}
