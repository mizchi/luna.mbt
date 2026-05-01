// Blog post data layer
// In a real app, this could be loaded from markdown files or a CMS

export interface BlogPost {
  slug: string;
  title: string;
  date: string;
  author: string;
  tags: string[];
  excerpt: string;
  content: string;
}

export interface BlogConfig {
  title: string;
  description: string;
  author: string;
  url: string;
  postsPerPage: number;
}

export const blogConfig: BlogConfig = {
  title: 'Sol Blog',
  description: 'A blog built with Sol Framework - TypeScript SSR',
  author: 'Sol Developer',
  url: 'https://sol-blog.example.com',
  postsPerPage: 5,
};

// Sample blog posts
export const posts: BlogPost[] = [
  {
    slug: 'getting-started-with-sol',
    title: 'Getting Started with Sol Framework',
    date: '2024-03-15',
    author: 'Sol Developer',
    tags: ['sol', 'typescript', 'tutorial'],
    excerpt: 'Learn how to build your first web application with Sol Framework.',
    content: `
Sol Framework is a modern SSR framework that combines the power of MoonBit and TypeScript.

## Why Sol?

Sol provides a unique approach to web development:

- **Type Safety**: Full TypeScript support for server-side code
- **Performance**: Optimized SSR with minimal overhead
- **Flexibility**: Use pure TypeScript or hybrid MoonBit mode
- **Developer Experience**: Hot reload, intuitive API

## Quick Start

Create a new Sol project:

\`\`\`bash
mkdir my-sol-app
cd my-sol-app
npm init -y
npm install @sol/core hono @hono/node-server
\`\`\`

## Your First Route

\`\`\`typescript
import { SolRoutes } from '@sol/core/routes';
import { div, h1, p, renderToString } from '@sol/core/html';

async function home() {
  return renderToString(
    div({}, [
      h1(null, ['Hello, Sol!']),
      p(null, ['Welcome to your first Sol app.']),
    ])
  );
}

export function routes() {
  return [
    SolRoutes.Page({ path: '/', handler: home, title: 'Home' }),
  ];
}
\`\`\`

Start building amazing things with Sol!
    `.trim(),
  },
  {
    slug: 'typescript-server-mode',
    title: 'Understanding TypeScript Server Mode',
    date: '2024-03-10',
    author: 'Sol Developer',
    tags: ['sol', 'typescript', 'server'],
    excerpt: 'Deep dive into Sol\'s TypeScript server mode and how it works.',
    content: `
Sol's TypeScript server mode allows you to write your entire backend in pure TypeScript.

## How It Works

When you create routes in TypeScript, Sol:

1. Parses your route definitions
2. Registers handlers with Hono
3. Renders VNodes to HTML strings
4. Serves the response

## VNode System

The VNode system is simple but powerful:

\`\`\`typescript
interface VNode {
  tag: string;
  attrs: Record<string, string> | null;
  children: (VNode | string)[];
}
\`\`\`

## Layout System

Nested layouts work seamlessly:

\`\`\`typescript
async function blogLayout(props, children) {
  return renderToString(
    div({ class: 'blog-layout' }, [
      nav({}, [...]),
      main({}, [raw(children)]),
      footer({}, [...]),
    ])
  );
}
\`\`\`

The \`raw()\` helper prevents double-escaping of child HTML.
    `.trim(),
  },
  {
    slug: 'building-a-blog',
    title: 'Building a Blog with Sol',
    date: '2024-03-05',
    author: 'Sol Developer',
    tags: ['sol', 'blog', 'tutorial'],
    excerpt: 'Step-by-step guide to building a blog with Sol Framework.',
    content: `
This blog itself is built with Sol! Let's see how.

## Project Structure

\`\`\`
sol_blog/
├── app/
│   ├── data/
│   │   └── posts.ts      # Blog post data
│   └── server/
│       └── routes.ts     # Route definitions
├── server.ts             # Entry point
├── sol.config.ts         # Configuration
└── package.json
\`\`\`

## Key Features

### 1. Static Data Layer

Posts are stored as TypeScript objects. In production, you could:
- Load from Markdown files
- Fetch from a CMS
- Query a database

### 2. Dynamic Routes

\`\`\`typescript
SolRoutes.Page({
  path: '/blog/:slug',
  handler: blogPostPage,
  title: 'Blog Post',
}),
\`\`\`

### 3. Tag Pages

Filter posts by tag with dynamic routes.

### 4. RSS Feed

\`\`\`typescript
SolRoutes.Get({
  path: '/rss.xml',
  handler: rssFeed,
}),
\`\`\`

## Performance

Sol blogs are fast:
- No client-side JavaScript required
- Minimal HTML output
- Fast SSR with TypeScript
    `.trim(),
  },
  {
    slug: 'performance-tips',
    title: 'Sol Performance Optimization Tips',
    date: '2024-02-28',
    author: 'Sol Developer',
    tags: ['sol', 'performance'],
    excerpt: 'Tips and tricks for optimizing your Sol application performance.',
    content: `
Sol is already fast, but here are ways to make it even faster.

## 1. Minimize VNode Depth

Flatten your component tree where possible:

\`\`\`typescript
// Instead of deeply nested divs
div({}, [div({}, [div({}, [content])])])

// Prefer flat structure
div({ class: 'wrapper' }, [content])
\`\`\`

## 2. Use Static Strings for Simple Content

\`\`\`typescript
// For static content, raw HTML can be faster
raw('<p>Static content here</p>')
\`\`\`

## 3. Cache Expensive Computations

\`\`\`typescript
const cachedNavigation = renderToString(nav({}, [...]))

function layout(props, children) {
  return div({}, [
    raw(cachedNavigation),  // Reuse cached HTML
    children,
  ])
}
\`\`\`

## 4. Benchmark Your Routes

Use k6 to identify bottlenecks:

\`\`\`bash
k6 run bench.js
\`\`\`

## Results

With these optimizations, Sol can handle:
- 4,000+ requests/second
- Sub-2ms p95 latency
- 100+ concurrent users
    `.trim(),
  },
  {
    slug: 'moonbit-vs-typescript',
    title: 'MoonBit vs TypeScript Mode: When to Use Each',
    date: '2024-02-20',
    author: 'Sol Developer',
    tags: ['sol', 'moonbit', 'typescript'],
    excerpt: 'Comparing Sol\'s MoonBit and TypeScript modes.',
    content: `
Sol supports two server modes. Here's when to use each.

## TypeScript Mode

**Best for:**
- Rapid prototyping
- Teams familiar with TypeScript
- Simple to medium complexity apps
- When you want hot reload

**Pros:**
- Familiar syntax
- No compilation step
- Direct Hono integration
- Easier debugging

## MoonBit Mode

**Best for:**
- Performance-critical applications
- Complex business logic
- Type-heavy domains
- When you need compile-time guarantees

**Pros:**
- Stronger type system
- Pattern matching
- Better performance for complex logic
- Memory safety

## Hybrid Mode

You can mix both:

\`\`\`
app/
├── client/     # MoonBit (Luna UI)
└── server/     # TypeScript routes
\`\`\`

This gives you:
- TypeScript for flexible routing
- MoonBit for interactive client components

## Our Recommendation

Start with TypeScript mode for quick iteration, then migrate hot paths to MoonBit if needed.
    `.trim(),
  },
  {
    slug: 'deploying-to-cloudflare',
    title: 'Deploying Sol to Cloudflare Workers',
    date: '2024-02-15',
    author: 'Sol Developer',
    tags: ['sol', 'cloudflare', 'deployment'],
    excerpt: 'Guide to deploying your Sol app to Cloudflare Workers.',
    content: `
Sol works great on Cloudflare Workers. Here's how to deploy.

## Configuration

Update your sol.config.ts:

\`\`\`typescript
export default defineConfig({
  routes: 'app/server',
  runtime: 'cloudflare',  // Changed from 'node'
});
\`\`\`

## Worker Entry Point

Create wrangler.toml:

\`\`\`toml
name = "my-sol-app"
main = "worker.ts"
compatibility_date = "2024-01-01"
\`\`\`

## Build and Deploy

\`\`\`bash
# Build for Cloudflare
npm run build:cloudflare

# Deploy
wrangler deploy
\`\`\`

## Edge Performance

On Cloudflare Workers, expect:
- Global edge distribution
- Cold starts under 5ms
- Sub-10ms response times

Your Sol blog will be blazing fast worldwide!
    `.trim(),
  },
];

// Helper functions
export function getAllPosts(): BlogPost[] {
  return [...posts].sort((a, b) =>
    new Date(b.date).getTime() - new Date(a.date).getTime()
  );
}

export function getPostBySlug(slug: string): BlogPost | undefined {
  return posts.find(p => p.slug === slug);
}

export function getPostsByTag(tag: string): BlogPost[] {
  return getAllPosts().filter(p => p.tags.includes(tag));
}

export function getAllTags(): { tag: string; count: number }[] {
  const tagCounts = new Map<string, number>();
  for (const post of posts) {
    for (const tag of post.tags) {
      tagCounts.set(tag, (tagCounts.get(tag) || 0) + 1);
    }
  }
  return Array.from(tagCounts.entries())
    .map(([tag, count]) => ({ tag, count }))
    .sort((a, b) => b.count - a.count);
}

export function getPaginatedPosts(page: number): { posts: BlogPost[]; totalPages: number; currentPage: number } {
  const allPosts = getAllPosts();
  const totalPages = Math.ceil(allPosts.length / blogConfig.postsPerPage);
  const start = (page - 1) * blogConfig.postsPerPage;
  const end = start + blogConfig.postsPerPage;
  return {
    posts: allPosts.slice(start, end),
    totalPages,
    currentPage: page,
  };
}

// Simple markdown to HTML converter (basic implementation)
export function markdownToHtml(markdown: string): string {
  return markdown
    // Code blocks
    .replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>')
    // Inline code
    .replace(/`([^`]+)`/g, '<code>$1</code>')
    // Headers
    .replace(/^### (.+)$/gm, '<h3>$1</h3>')
    .replace(/^## (.+)$/gm, '<h2>$1</h2>')
    .replace(/^# (.+)$/gm, '<h1>$1</h1>')
    // Bold
    .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
    // Italic
    .replace(/\*([^*]+)\*/g, '<em>$1</em>')
    // Lists
    .replace(/^- (.+)$/gm, '<li>$1</li>')
    .replace(/(<li>.*<\/li>\n?)+/g, '<ul>$&</ul>')
    // Paragraphs
    .replace(/\n\n/g, '</p><p>')
    .replace(/^(.+)$/gm, (match) => {
      if (match.startsWith('<')) return match;
      return match;
    });
}
