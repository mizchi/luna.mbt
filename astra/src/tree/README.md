# Sol SSG - Document Tree Builder

Module for building the intermediate representation of Sol SSG. Generates a DocumentTree from PageMeta to represent document structure. Output generation (RSS, sitemap.xml, llms.txt) is provided in `core/ssg/generators.mbt`.

## Design

```
FileSystem (docs/)
     │
     ▼
┌─────────────────┐
│  DocumentTree   │  ← Intermediate representation (this layer)
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

## Key Types

### DocumentTree

Root structure representing the entire site.

```moonbit
pub struct DocumentTree {
  site : SiteInfo           // Site-wide metadata
  pages : Array[PageInfo]   // Flat list of all pages
  root : TreeNode           // Hierarchical tree root
}
```

### SiteInfo

Site-wide metadata.

```moonbit
pub struct SiteInfo {
  title : String
  description : String?
  base_url : String         // "https://example.com"
  language : String         // Default language
  updated_at : String?      // Last updated (ISO 8601)
}
```

### PageInfo

Complete information for a single page.

```moonbit
pub struct PageInfo {
  // Identifiers
  id : String               // Unique ID (generated from URL path)
  url_path : String         // "/guide/intro/"
  canonical_url : String    // "https://example.com/guide/intro/"

  // Metadata
  title : String
  description : String?
  locale : String

  // Timestamps
  created_at : String?      // ISO 8601
  updated_at : String?      // ISO 8601 (last_modified)

  // Content
  content_md : String       // Raw Markdown
  content_html : String?    // Converted HTML (can be lazily generated)

  // Structure
  headings : Array[Heading] // Heading list (for TOC)

  // Classification
  tags : Array[String]?
  category : String?
}
```

### TreeNode

Node representing a hierarchical structure.

```moonbit
pub enum TreeNode {
  Section(
    name~ : String,
    path~ : String,
    children~ : Array[TreeNode]
  )
  Page(
    page_id~ : String       // Reference to PageInfo.id
  )
}
```

### Heading

Heading information (for TOC, llms.txt).

```moonbit
pub struct Heading {
  level : Int               // 1-6
  text : String
  id : String               // Anchor ID
}
```

## Generation Flow

### 1. Building a DocumentTree

```
scan_to_document_tree(config, cwd) -> DocumentTree
  │
  ├─ File scanning
  ├─ Markdown parsing (frontmatter + heading extraction)
  ├─ PageInfo generation
  ├─ TreeNode hierarchy construction
  └─ SiteInfo extraction from config
```

### 2. Conversion to Each Format

```moonbit
// HTML generation (existing SSG)
fn generate_html(tree : DocumentTree, config : SsgConfig) -> Unit

// RSS generation
fn generate_rss(tree : DocumentTree, limit? : Int = 20) -> String

// sitemap.xml generation
fn generate_sitemap(tree : DocumentTree) -> String

// llms.txt generation
fn generate_llms_txt(tree : DocumentTree) -> String
```

## Output Formats

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

Plain text format for LLMs.
Reference: https://llmstxt.org/

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

## File Structure

```
src/sol/ssg/tree/
├── README.md           # This file
├── moon.pkg.json
├── builder.mbt         # build_document_tree
└── *_test.mbt          # Tests

sol/ssg/
├── document_tree.mbt   # DocumentTree, PageInfo, TreeNode type definitions
└── generators.mbt      # generate_rss, generate_sitemap, generate_llms_txt
```
