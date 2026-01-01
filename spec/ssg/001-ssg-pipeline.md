# ADR-001: Static Site Generation Pipeline

## Status

Accepted

## Context

Documentation sites and content-heavy applications benefit from static generation:

1. **Fast delivery**: Pre-rendered HTML served from CDN
2. **SEO optimized**: Full content available to crawlers
3. **Low cost**: No server required for hosting
4. **Security**: No dynamic attack surface

Requirements for Astra SSG:
- Markdown/MDX to HTML conversion
- Automatic navigation generation
- Multi-language support
- Web Component integration

## Decision

Implement a multi-phase build pipeline:

### Phase 1: Discovery

```moonbit
pub fn scan_docs_dir(config: SsgConfig) -> Array[PageMeta]
```

- Scan `docs_dir` for .md, .mdx, .html files
- Extract frontmatter metadata
- Determine URL paths (strip numeric prefixes)
- Identify locale from path

### Phase 2: Parsing

```moonbit
pub fn parse_markdown(content: String) -> Array[MdNode]
```

- Parse Markdown to AST
- Extract headings for TOC
- Identify code blocks for syntax highlighting
- Detect custom components

### Phase 3: Rendering

```moonbit
pub fn render_page(page: PageMeta, ctx: BuildContext) -> String
```

- Convert AST to HTML
- Apply page template (header, sidebar, footer)
- Inject navigation links
- Generate OGP meta tags

### Phase 4: Output

- Write HTML files to `output_dir`
- Copy static assets from `public/`
- Generate meta files (sitemap, feed, llms.txt)
- Generate client manifest for SPA mode

### Configuration

```moonbit
pub struct SsgConfig {
  docs_dir: String           // Input directory
  output_dir: String         // Output directory
  title: String              // Site title
  base_url: String           // Base URL for links
  i18n: I18nConfig           // Internationalization
  meta_files: MetaFilesConfig // sitemap/feed/llms.txt
  // ... more options
}
```

## Consequences

### Positive

- **Predictable builds**: Same input always produces same output
- **Incremental possible**: Can cache intermediate results
- **Debuggable**: Each phase can be inspected
- **Extensible**: New phases can be added

### Negative

- **Build time**: Large sites take longer to build
- **No dynamic content**: Must rebuild for changes
- **Memory usage**: Entire site in memory during build

### Neutral

- Similar architecture to Astro, VitePress
- Can be parallelized per-page in Phase 3
