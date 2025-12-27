---
title: Building Fast Websites
description: Tips for creating performant static websites
date: "2024-12-25"
author: Luna Team
tags:
  - performance
  - optimization
  - web
layout: blog-post
---

# Building Fast Websites

Static site generation provides excellent performance by default. Here are additional tips to make your site even faster.

## Why Static Sites are Fast

1. **No server processing** - HTML is pre-generated
2. **CDN-friendly** - Easy to cache globally
3. **Minimal JavaScript** - Only what you need

## Optimization Tips

### Image Optimization

Use optimized image formats:

- WebP for photos
- SVG for icons
- Lazy loading for below-the-fold images

### Minimize Bundle Size

Keep your JavaScript minimal:

```javascript
// Only import what you need
import { signal } from '@luna_ui/luna'
```

### Leverage Caching

Configure proper cache headers:

```json
{
  "headers": {
    "Cache-Control": "public, max-age=31536000"
  }
}
```

## Measuring Performance

Use tools like:

- Lighthouse
- WebPageTest
- Core Web Vitals

## Conclusion

Static sites provide excellent baseline performance. With these optimizations, you can achieve sub-second load times consistently.
