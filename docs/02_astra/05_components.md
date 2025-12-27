---
title: Components
description: Reusable UI components for Astra SSG
---

# Components

Astra provides a set of reusable, customizable components for building documentation sites, blogs, and landing pages.

## Overview

Components are located in `src/astra/components/` and cover common UI patterns:

| Component | File | Description |
|-----------|------|-------------|
| Header | `header.mbt` | Navigation bar with logo, links, search, theme toggle |
| Footer | `footer.mbt` | Site footer with columns, copyright, social links |
| TOC | `toc.mbt` | Table of contents sidebar |
| Navigation | `nav_*.mbt` | Sidebar navigation with collapsible sections |
| Blog | `blog.mbt` | PostCard, Hero, TagList for blog layouts |
| Registry | `registry.mbt` | Component override system |

## Header

The header component supports flexible element-based composition.

### Configuration

```json
{
  "theme": {
    "header": {
      "sticky": true,
      "left": ["logo", "nav-links"],
      "center": [],
      "right": ["search", "theme-toggle", "social-links"]
    }
  }
}
```

### Available Elements

| Element | Description |
|---------|-------------|
| `logo` | Site logo or title with link to home |
| `nav-links` | Navigation links from `nav` config |
| `search` | Search input box |
| `theme-toggle` | Dark/light mode toggle button |
| `social-links` | GitHub, Twitter icons |
| `lang-switcher` | Language selector dropdown |
| `spacer` | Flexible spacer element |
| `custom` | Custom HTML tag |

### Theme Toggle

Built-in dark/light mode support with:
- Sun/moon icons
- System preference detection
- Persisted user preference

## Footer

Element-based footer with flexible layout.

### Configuration

```json
{
  "theme": {
    "footer": {
      "top": ["columns"],
      "bottom": ["message", "copyright", "social-links"],
      "links": [
        {
          "title": "Documentation",
          "items": [
            { "label": "Getting Started", "href": "/guide/" },
            { "label": "API Reference", "href": "/api/" }
          ]
        }
      ],
      "message": "Released under the MIT License.",
      "copyright": "Copyright 2024 Your Name"
    }
  }
}
```

### Available Elements

| Element | Description |
|---------|-------------|
| `columns` | Link columns from `links` config |
| `message` | Footer message text |
| `copyright` | Copyright notice |
| `social-links` | Social media icons |
| `custom` | Custom HTML tag |

## Blog Components

Components for blog-style layouts.

### PostCard

Display blog posts in a card format:

```moonbit
build_blog_post_card(page : PageMeta) -> Node[Unit]
```

Features:
- Cover image (optional)
- Title with link
- Date and author
- Description excerpt
- Tags list
- Featured badge

### Hero Section

Full-width hero for landing pages:

```moonbit
build_blog_hero(
  title : String,
  subtitle : String?,
  cta_text : String?,
  cta_link : String?,
) -> Node[Unit]
```

### Post Lists

```moonbit
// All posts (optionally limited)
build_blog_post_list(ctx, limit : Int?, featured_only : Bool)

// Featured posts section
build_featured_posts(ctx, limit : Int)

// Recent posts with title
build_recent_posts(ctx, limit : Int, title : String)

// Posts by tag
get_posts_by_tag(pages, tag : String)
```

### Tag List

```moonbit
build_tag_list(tags : Array[String])      // With links
build_tag_list_inline(tags : Array[String]) // Display only
```

## Component Registry

Override default components with custom implementations.

### Basic Usage

```moonbit
let registry = ComponentRegistry::defaults()
  .with_header(my_custom_header)
  .with_footer(my_custom_footer)

// Use in rendering
registry.render_header(ctx, page)
registry.render_footer(ctx)
```

### Available Overrides

| Method | Signature |
|--------|-----------|
| `with_header` | `(BuildContext, PageMeta) -> Node[Unit]` |
| `with_footer` | `(BuildContext) -> Node[Unit]` |
| `with_toc` | `(Array[TocItem]) -> Node[Unit]` |
| `with_breadcrumb` | `(BuildContext, PageMeta) -> Node[Unit]` |
| `with_prev_next` | `(BuildContext, PageMeta) -> Node[Unit]` |

## Themes

CSS variable-based theming with light/dark mode support.

### Built-in Themes

| Theme | Layout | Description |
|-------|--------|-------------|
| `default` | Doc | Documentation site with sidebar |
| `blog` | Blog | Content-focused, wider main area |
| `minimal` | Home | Clean and simple |

### Theme Structure

```moonbit
pub struct Theme {
  name : String
  default_layout : ThemeLayout  // Doc | Home | Blog | Landing
  light_colors : ThemeColors
  dark_colors : ThemeColors
  custom_css : String?
}

pub struct ThemeColors {
  primary : String      // Accent color
  text : String         // Main text
  text_muted : String   // Secondary text
  background : String   // Page background
  sidebar_bg : String   // Sidebar background
  border : String       // Border color
  code_bg : String      // Code block background
}
```

### CSS Variables

Themes generate CSS custom properties:

```css
:root {
  --primary-color: #b45309;
  --text-color: #1f2937;
  --text-muted: #4b5563;
  --bg-color: #ffffff;
  --sidebar-bg: #fafafa;
  --border-color: #e5e7eb;
  --code-bg: #f3f4f6;
  --link-color: var(--primary-color);
}

html.dark {
  --primary-color: #fbbf24;
  --text-color: #f3f4f6;
  /* ... dark mode overrides */
}
```

### Creating Custom Theme

```moonbit
fn my_theme() -> Theme {
  {
    name: "custom",
    default_layout: Doc,
    light_colors: {
      primary: "#2563eb",
      text: "#111827",
      text_muted: "#6b7280",
      background: "#ffffff",
      sidebar_bg: "#f9fafb",
      border: "#e5e7eb",
      code_bg: "#f3f4f6",
    },
    dark_colors: {
      primary: "#60a5fa",
      text: "#f9fafb",
      text_muted: "#9ca3af",
      background: "#111827",
      sidebar_bg: "#1f2937",
      border: "#374151",
      code_bg: "#1f2937",
    },
    custom_css: Some(".my-class { ... }"),
  }
}
```

## Layout Types

| Layout | Use Case | Features |
|--------|----------|----------|
| `Doc` | Documentation | Sidebar + content + TOC |
| `Home` | Landing page | Full-width, no sidebar |
| `Blog` | Blog posts | Content-focused, optional sidebar |
| `Landing` | Marketing pages | Hero sections, CTAs |

## Component Discovery

Astra automatically discovers custom components in your project.

### Convention

Place component files in `docs/components/`:

```
docs/
└── components/
    ├── header.mbt      # Custom header
    ├── footer.mbt      # Custom footer
    └── toc.mbt         # Custom TOC
```

### Discovery Result

```moonbit
let result = discover_components(config, cwd)
// result.found: [Header, Footer]
// result.missing: [Toc, Breadcrumb, PrevNext]  // Using defaults
```
