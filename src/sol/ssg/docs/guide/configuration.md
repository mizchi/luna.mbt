---
title: Configuration
description: SSG configuration reference for sol.config.json
---

# Configuration Reference

Configure SSG in the `ssg` field of `sol.config.json`.

## Basic Settings

```json
{
  "ssg": {
    "docs": "docs",
    "output": "dist",
    "title": "My Documentation",
    "description": "Site description",
    "base": "/"
  }
}
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `docs` | string | `"docs"` | Markdown files directory |
| `output` | string | `"dist"` | Output directory |
| `title` | string | `"Documentation"` | Site title |
| `description` | string | `""` | Site description |
| `base` | string | `"/"` | Base path |

## Navigation

Configure top navbar links:

```json
{
  "ssg": {
    "nav": [
      { "text": "Guide", "link": "/guide/" },
      { "text": "API", "link": "/api/" },
      { "text": "GitHub", "link": "https://github.com/example/repo" }
    ]
  }
}
```

## Sidebar

Sidebar can be auto-generated or manually configured:

### Auto-generate

```json
{
  "ssg": {
    "sidebar": "auto"
  }
}
```

### Manual Configuration

```json
{
  "ssg": {
    "sidebar": [
      {
        "text": "Getting Started",
        "items": [
          { "text": "Introduction", "link": "/guide/" },
          { "text": "Configuration", "link": "/guide/configuration" }
        ]
      }
    ]
  }
}
```

## Theme

```json
{
  "ssg": {
    "theme": {
      "primaryColor": "#3451b2",
      "logo": "/logo.svg"
    }
  }
}
```

| Option | Description |
|--------|-------------|
| `primaryColor` | Primary color (used for links, etc.) |
| `logo` | Logo image path for navbar |

## i18n (Internationalization)

```json
{
  "ssg": {
    "i18n": {
      "defaultLocale": "en",
      "locales": [
        { "code": "en", "label": "English", "path": "" },
        { "code": "ja", "label": "Japanese", "path": "ja" }
      ]
    }
  }
}
```

## Footer

```json
{
  "ssg": {
    "footer": {
      "message": "Released under the MIT License.",
      "copyright": "Copyright 2024"
    }
  }
}
```
