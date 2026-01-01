# ADR-002: Optional Meta File Generation

## Status

Accepted

## Context

Static sites often need supplementary files for various purposes:

1. **sitemap.xml**: SEO - helps search engines discover pages
2. **feed.xml (RSS)**: Content syndication for readers
3. **llms.txt**: LLM-friendly content format (llmstxt.org)

Not all sites need all files:
- Documentation sites need sitemap
- Blogs need RSS feeds
- AI-focused sites need llms.txt

## Decision

Make meta file generation configurable via `MetaFilesConfig`:

### Configuration

```moonbit
pub struct MetaFilesConfig {
  sitemap: Bool     // Generate sitemap.xml (default: true)
  feed: Bool        // Generate feed.xml RSS 2.0 (default: false)
  llms_txt: Bool    // Generate llms.txt (default: false)
}
```

### JSON Configuration

```json
{
  "metaFiles": {
    "sitemap": true,
    "feed": true,
    "llmsTxt": true
  }
}
```

### Generation Functions

```moonbit
pub fn generate_sitemap(tree: DocumentTree) -> String
pub fn generate_rss(tree: DocumentTree, limit?: Int) -> String
pub fn generate_llms_txt(tree: DocumentTree) -> String
```

### DocumentTree

Shared data structure for all generators:

```moonbit
pub struct DocumentTree {
  site: SiteInfo              // Site metadata
  pages: Array[PageInfo]      // All pages
  root: TreeNode              // Hierarchical structure
}
```

## Consequences

### Positive

- **Flexible**: Only generate what's needed
- **Smaller output**: No unused files
- **Unified data**: All generators use same DocumentTree
- **Extensible**: Easy to add new meta file types

### Negative

- **Configuration complexity**: More options to understand
- **Defaults may surprise**: RSS disabled by default

### Neutral

- sitemap enabled by default (most common need)
- feed/llms.txt opt-in (specialized use cases)
