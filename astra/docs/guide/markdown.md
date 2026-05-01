---
title: Markdown Features
description: Supported Markdown syntax
---

# Markdown Features

Luna SSG supports standard Markdown syntax.

## Frontmatter

Define metadata at the beginning of each Markdown file in YAML format:

```yaml
---
title: Page Title
description: Page description
layout: doc
sidebar: true
---
```

### Frontmatter Options

| Option | Type | Description |
|--------|------|-------------|
| `title` | string | Page title (used in `<title>` tag) |
| `description` | string | Meta description |
| `layout` | string | Layout type (`doc`, `home`, `default`) |
| `sidebar` | boolean | Show sidebar (default: true) |

## Headings

```markdown
# Heading 1
## Heading 2
### Heading 3
```

Headings automatically get IDs and appear in the table of contents (TOC).

## Code Blocks

Specify language for syntax highlighting:

````markdown
```javascript
function hello() {
  console.log("Hello, World!");
}
```
````

Result:

```javascript
function hello() {
  console.log("Hello, World!");
}
```

## Links

```markdown
[Internal link](/guide/configuration)
[External link](https://example.com)
```

## Lists

```markdown
- Item 1
- Item 2
  - Nested item

1. Numbered 1
2. Numbered 2
```

## Tables

```markdown
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| A        | B        | C        |
```

## Blockquotes

```markdown
> This is a quote.
> Multiple lines are supported.
```

> This is a quote.
> Multiple lines are supported.
