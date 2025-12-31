# Astra

Static Site Generator (SSG). Markdown → HTML conversion.

## Overview

An SSG specialized for documentation site generation.
Generates multi-language static sites from Markdown files.

## Module Structure

| Submodule | Responsibility |
|-----------|----------------|
| `cli/` | CLI entry point |
| `generator/` | HTML generation logic |
| `markdown/` | Markdown parsing |
| `routes/` | Route generation |
| `shiki/` | Syntax highlighting (Shiki integration) |
| `config.mbt` | Config parser |
| `types.mbt` | Type definitions |

## Config File (astra.json)

```json
{
  "docs": "docs",
  "output": "dist",
  "title": "My Site",
  "base": "/",
  "trailingSlash": true,
  "i18n": {
    "defaultLocale": "en",
    "locales": [
      { "code": "en", "label": "English", "path": "" },
      { "code": "ja", "label": "日本語", "path": "ja" }
    ]
  },
  "nav": [...],
  "sidebar": "auto"
}
```

## Main Types

### SsgConfig

```moonbit
pub struct SsgConfig {
  docs_dir : String       // Source directory
  output_dir : String     // Output directory
  title : String          // Site title
  base_url : String       // Base URL
  nav : Array[NavItem]    // Navigation
  sidebar : SidebarConfig // Sidebar config
  i18n : I18nConfig       // Multi-language config
  // ...
}
```

## Features

- Static HTML generation from Markdown
- Multi-language support (i18n)
- Auto sidebar generation
- Syntax highlighting (Shiki)
- OGP support

## Usage

```bash
# Run from CLI
moon run src/astra/cli -- build
```

## References

- [Luna Core](../core/README.md) - VNode generation
- [Sol](../sol/README.md) - SSR framework
