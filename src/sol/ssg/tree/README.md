# Astra DocumentTree

Astra の中間表現。ファイルシステムからスキャンしたドキュメント構造を表現し、
複数の出力形式（HTML, RSS, sitemap.xml, llms.txt）に変換できる。

## 設計思想

```
FileSystem (docs/)
     │
     ▼
┌─────────────────┐
│  DocumentTree   │  ← 中間表現（この層を追加）
│  ├─ SiteInfo    │
│  ├─ pages[]     │
│  └─ tree        │
└────────┬────────┘
         │
    ┌────┴────┬──────────┬──────────┐
    ▼         ▼          ▼          ▼
  HTML      RSS      sitemap    llms.txt
 (SSG)    (feed)     (.xml)    (for LLM)
```

## 主要な型

### DocumentTree

サイト全体を表現するルート構造。

```moonbit
pub struct DocumentTree {
  site : SiteInfo           // サイト全体のメタ情報
  pages : Array[PageInfo]   // 全ページのフラットリスト
  root : TreeNode           // 階層構造のルート
}
```

### SiteInfo

サイト全体のメタデータ。

```moonbit
pub struct SiteInfo {
  title : String
  description : String?
  base_url : String         // "https://example.com"
  language : String         // デフォルト言語
  updated_at : String?      // 最終更新日時（ISO 8601）
}
```

### PageInfo

1ページの完全な情報。

```moonbit
pub struct PageInfo {
  // 識別子
  id : String               // ユニークID（URLパスから生成）
  url_path : String         // "/guide/intro/"
  canonical_url : String    // "https://example.com/guide/intro/"

  // メタデータ
  title : String
  description : String?
  locale : String

  // 日時
  created_at : String?      // ISO 8601
  updated_at : String?      // ISO 8601 (last_modified)

  // コンテンツ
  content_md : String       // 生のMarkdown
  content_html : String?    // 変換後のHTML（遅延生成可）

  // 構造
  headings : Array[Heading] // 見出し一覧（TOC用）

  // 分類
  tags : Array[String]?
  category : String?
}
```

### TreeNode

階層構造を表現するノード。

```moonbit
pub enum TreeNode {
  Section(
    name~ : String,
    path~ : String,
    children~ : Array[TreeNode]
  )
  Page(
    page_id~ : String       // PageInfo.id への参照
  )
}
```

### Heading

見出し情報（TOC、llms.txt用）。

```moonbit
pub struct Heading {
  level : Int               // 1-6
  text : String
  id : String               // アンカーID
}
```

## 生成フロー

### 1. DocumentTree の構築

```
scan_to_document_tree(config, cwd) -> DocumentTree
  │
  ├─ ファイルスキャン
  ├─ Markdown パース（frontmatter + 見出し抽出）
  ├─ PageInfo 生成
  ├─ TreeNode 階層構築
  └─ SiteInfo 設定から抽出
```

### 2. 各形式への変換

```moonbit
// HTML生成（既存SSG）
fn generate_html(tree : DocumentTree, config : SsgConfig) -> Unit

// RSS生成
fn generate_rss(tree : DocumentTree, limit? : Int = 20) -> String

// sitemap.xml生成
fn generate_sitemap(tree : DocumentTree) -> String

// llms.txt生成
fn generate_llms_txt(tree : DocumentTree) -> String
```

## 出力形式

### RSS (feed.xml)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Site Title</title>
    <link>https://example.com</link>
    <description>Site description</description>
    <lastBuildDate>Wed, 22 Dec 2024 12:00:00 GMT</lastBuildDate>
    <item>
      <title>Page Title</title>
      <link>https://example.com/guide/intro/</link>
      <description>Page description</description>
      <pubDate>Mon, 20 Dec 2024 10:00:00 GMT</pubDate>
    </item>
  </channel>
</rss>
```

### sitemap.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-12-22</lastmod>
  </url>
  <url>
    <loc>https://example.com/guide/</loc>
    <lastmod>2024-12-21</lastmod>
  </url>
</urlset>
```

### llms.txt

LLM向けのプレーンテキスト形式。
参考: https://llmstxt.org/

```
# Site Title

> Site description

## Table of Contents

- [Guide](/guide/)
  - [Introduction](/guide/intro/)
  - [Getting Started](/guide/getting-started/)
- [API Reference](/api/)

---

# Guide

## Introduction

[Full content of the page in markdown...]

---

## Getting Started

[Full content of the page in markdown...]
```

## ファイル構成

```
src/astra/tree/
├── README.md           # このファイル
├── moon.pkg.json
├── types.mbt           # DocumentTree, PageInfo, TreeNode など
├── builder.mbt         # scan_to_document_tree
├── rss.mbt             # generate_rss
├── sitemap.mbt         # generate_sitemap
├── llms_txt.mbt        # generate_llms_txt
└── tree_test.mbt       # テスト
```
