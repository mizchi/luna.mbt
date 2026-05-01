import {
  SolRoutes,
  type PageProps,
  type SolRoute,
  DEFAULT_ROOT_TEMPLATE,
} from '@sol/core/routes';
import type { ISRRouterConfig } from '@sol/core/server-runtime';
import {
  div,
  h1,
  h2,
  h3,
  p,
  a,
  ul,
  li,
  nav,
  main,
  header,
  footer,
  article,
  section,
  aside,
  span,
  time,
  raw,
  renderToString,
} from '@sol/core/html';
import {
  blogConfig,
  getAllPosts,
  getPostBySlug,
  getPostsByTag,
  getAllTags,
  getPaginatedPosts,
  markdownToHtml,
  type BlogPost,
} from '../data/posts';

// ============================================================================
// Utility: time element helper
// ============================================================================

function time(attrs: Record<string, string | boolean | number> | null, children: (string | ReturnType<typeof span>)[]): ReturnType<typeof span> {
  return { tag: 'time', attrs: attrs || {}, children };
}

// ============================================================================
// Components
// ============================================================================

function postCard(post: BlogPost) {
  return article({ class: 'post-card' }, [
    h2({ class: 'post-title' }, [
      a({ href: `/blog/${post.slug}` }, [post.title]),
    ]),
    div({ class: 'post-meta' }, [
      time({ datetime: post.date }, [formatDate(post.date)]),
      span({ class: 'post-author' }, [` by ${post.author}`]),
    ]),
    p({ class: 'post-excerpt' }, [post.excerpt]),
    div({ class: 'post-tags' }, post.tags.map(tag =>
      a({ href: `/tags/${tag}`, class: 'tag' }, [`#${tag}`])
    )),
  ]);
}

function tagCloud(tags: { tag: string; count: number }[]) {
  return div({ class: 'tag-cloud' }, [
    h3(null, ['Tags']),
    div({ class: 'tags' }, tags.map(({ tag, count }) =>
      a({ href: `/tags/${tag}`, class: 'tag' }, [`#${tag} (${count})`])
    )),
  ]);
}

function pagination(currentPage: number, totalPages: number, basePath: string = '/blog') {
  const links: ReturnType<typeof a>[] = [];

  if (currentPage > 1) {
    links.push(a({ href: `${basePath}/page/${currentPage - 1}`, class: 'page-link prev' }, ['Previous']));
  }

  for (let i = 1; i <= totalPages; i++) {
    links.push(a({
      href: i === 1 ? basePath : `${basePath}/page/${i}`,
      class: i === currentPage ? 'page-link active' : 'page-link',
    }, [String(i)]));
  }

  if (currentPage < totalPages) {
    links.push(a({ href: `${basePath}/page/${currentPage + 1}`, class: 'page-link next' }, ['Next']));
  }

  return nav({ class: 'pagination' }, links);
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });
}

// ============================================================================
// Layouts
// ============================================================================

async function blogLayout(props: PageProps, children: string): Promise<string> {
  const tags = getAllTags();

  const navigation = nav({ class: 'main-nav' }, [
    ul(null, [
      li(null, [a({ href: '/' }, ['Home'])]),
      li(null, [a({ href: '/blog' }, ['Blog'])]),
      li(null, [a({ href: '/tags' }, ['Tags'])]),
      li(null, [a({ href: '/about' }, ['About'])]),
      li(null, [a({ href: '/rss.xml', class: 'rss-link' }, ['RSS'])]),
    ]),
  ]);

  const head = header({ class: 'site-header' }, [
    div({ class: 'container' }, [
      h1({ class: 'site-title' }, [
        a({ href: '/' }, [blogConfig.title]),
      ]),
      p({ class: 'site-description' }, [blogConfig.description]),
      navigation,
    ]),
  ]);

  const sidebar = aside({ class: 'sidebar' }, [
    tagCloud(tags),
    div({ class: 'recent-posts' }, [
      h3(null, ['Recent Posts']),
      ul(null, getAllPosts().slice(0, 5).map(post =>
        li(null, [a({ href: `/blog/${post.slug}` }, [post.title])])
      )),
    ]),
  ]);

  const foot = footer({ class: 'site-footer' }, [
    div({ class: 'container' }, [
      p(null, [`© ${new Date().getFullYear()} ${blogConfig.title}. Built with Sol Framework.`]),
      p(null, [
        a({ href: '/rss.xml' }, ['RSS Feed']),
        ' | ',
        a({ href: 'https://github.com/anthropics/sol' }, ['GitHub']),
      ]),
    ]),
  ]);

  return renderToString(
    div({ class: 'blog-layout' }, [
      head,
      div({ class: 'content-wrapper container' }, [
        main({ class: 'main-content' }, [raw(children)]),
        sidebar,
      ]),
      foot,
    ])
  );
}

// ============================================================================
// Pages
// ============================================================================

async function homePage(props: PageProps): Promise<string> {
  const { posts } = getPaginatedPosts(1);

  return renderToString(
    div({ class: 'home-page' }, [
      section({ class: 'hero' }, [
        h1(null, [`Welcome to ${blogConfig.title}`]),
        p({ class: 'tagline' }, ['A blog powered by Sol Framework - TypeScript SSR']),
      ]),
      section({ class: 'latest-posts' }, [
        h2(null, ['Latest Posts']),
        div({ class: 'posts-grid' }, posts.map(postCard)),
        div({ class: 'view-all' }, [
          a({ href: '/blog', class: 'btn' }, ['View All Posts']),
        ]),
      ]),
    ])
  );
}

async function blogListPage(props: PageProps): Promise<string> {
  const pageParam = props.params.get_param?.('page');
  const page = pageParam ? parseInt(pageParam, 10) : 1;
  const { posts, totalPages, currentPage } = getPaginatedPosts(page);

  return renderToString(
    div({ class: 'blog-list-page' }, [
      h1(null, ['Blog']),
      div({ class: 'posts-list' }, posts.map(postCard)),
      pagination(currentPage, totalPages),
    ])
  );
}

async function blogPostPage(props: PageProps): Promise<string> {
  const slug = props.params.get_param?.('slug');

  if (!slug) {
    return renderToString(
      div({ class: 'error-page' }, [
        h1(null, ['Post Not Found']),
        p(null, ['The requested blog post does not exist.']),
        a({ href: '/blog' }, ['Back to Blog']),
      ])
    );
  }

  const post = getPostBySlug(slug);

  if (!post) {
    return renderToString(
      div({ class: 'error-page' }, [
        h1(null, ['Post Not Found']),
        p(null, [`No post found with slug: ${slug}`]),
        a({ href: '/blog' }, ['Back to Blog']),
      ])
    );
  }

  const contentHtml = markdownToHtml(post.content);

  return renderToString(
    article({ class: 'blog-post' }, [
      header({ class: 'post-header' }, [
        h1(null, [post.title]),
        div({ class: 'post-meta' }, [
          time({ datetime: post.date }, [formatDate(post.date)]),
          span({ class: 'post-author' }, [` by ${post.author}`]),
        ]),
        div({ class: 'post-tags' }, post.tags.map(tag =>
          a({ href: `/tags/${tag}`, class: 'tag' }, [`#${tag}`])
        )),
      ]),
      div({ class: 'post-content' }, [raw(contentHtml)]),
      footer({ class: 'post-footer' }, [
        a({ href: '/blog', class: 'back-link' }, ['← Back to Blog']),
      ]),
    ])
  );
}

async function tagsListPage(props: PageProps): Promise<string> {
  const tags = getAllTags();

  return renderToString(
    div({ class: 'tags-page' }, [
      h1(null, ['All Tags']),
      div({ class: 'tags-list' }, tags.map(({ tag, count }) =>
        a({ href: `/tags/${tag}`, class: 'tag-item' }, [
          span({ class: 'tag-name' }, [`#${tag}`]),
          span({ class: 'tag-count' }, [`${count} posts`]),
        ])
      )),
    ])
  );
}

async function tagPostsPage(props: PageProps): Promise<string> {
  const tag = props.params.get_param?.('tag');

  if (!tag) {
    return renderToString(
      div({ class: 'error-page' }, [
        h1(null, ['Tag Not Found']),
        a({ href: '/tags' }, ['View All Tags']),
      ])
    );
  }

  const posts = getPostsByTag(tag);

  return renderToString(
    div({ class: 'tag-posts-page' }, [
      h1(null, [`Posts tagged: #${tag}`]),
      p({ class: 'post-count' }, [`${posts.length} post${posts.length !== 1 ? 's' : ''}`]),
      div({ class: 'posts-list' }, posts.map(postCard)),
      a({ href: '/tags', class: 'back-link' }, ['← View All Tags']),
    ])
  );
}

async function aboutPage(props: PageProps): Promise<string> {
  return renderToString(
    div({ class: 'about-page' }, [
      h1(null, ['About This Blog']),
      section(null, [
        h2(null, ['What is Sol?']),
        p(null, ['Sol is a modern SSR (Server-Side Rendering) framework that combines TypeScript with optional MoonBit support for high-performance web applications.']),
      ]),
      section(null, [
        h2(null, ['Features']),
        ul(null, [
          li(null, ['Pure TypeScript server mode']),
          li(null, ['Fast SSR with minimal overhead']),
          li(null, ['Type-safe route definitions']),
          li(null, ['Flexible layout system']),
          li(null, ['Built-in RSS feed support']),
        ]),
      ]),
      section(null, [
        h2(null, ['About This Template']),
        p(null, ['This blog template demonstrates how to build a full-featured blog with Sol Framework. It includes:']),
        ul(null, [
          li(null, ['Blog post listing with pagination']),
          li(null, ['Individual post pages with Markdown support']),
          li(null, ['Tag-based filtering']),
          li(null, ['RSS feed generation']),
          li(null, ['Responsive design']),
        ]),
      ]),
    ])
  );
}

// ============================================================================
// API Routes
// ============================================================================

async function rssFeed(props: PageProps): Promise<Response> {
  const posts = getAllPosts().slice(0, 20);

  const items = posts.map(post => `
    <item>
      <title><![CDATA[${post.title}]]></title>
      <link>${blogConfig.url}/blog/${post.slug}</link>
      <guid>${blogConfig.url}/blog/${post.slug}</guid>
      <pubDate>${new Date(post.date).toUTCString()}</pubDate>
      <description><![CDATA[${post.excerpt}]]></description>
      <author>${post.author}</author>
      ${post.tags.map(tag => `<category>${tag}</category>`).join('\n      ')}
    </item>
  `).join('\n');

  const rss = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>${blogConfig.title}</title>
    <description>${blogConfig.description}</description>
    <link>${blogConfig.url}</link>
    <atom:link href="${blogConfig.url}/rss.xml" rel="self" type="application/rss+xml"/>
    <language>en-us</language>
    <lastBuildDate>${new Date().toUTCString()}</lastBuildDate>
    ${items}
  </channel>
</rss>`;

  return new Response(rss, {
    headers: {
      'Content-Type': 'application/rss+xml; charset=utf-8',
    },
  });
}

async function apiHealth(props: PageProps): Promise<object> {
  return {
    status: 'ok',
    blog: blogConfig.title,
    posts: getAllPosts().length,
    timestamp: new Date().toISOString(),
  };
}

async function apiPosts(props: PageProps): Promise<object> {
  const posts = getAllPosts().map(({ content, ...rest }) => rest);
  return { posts };
}

// ============================================================================
// Route Definitions
// ============================================================================

export function routes(): SolRoute[] {
  return [
    SolRoutes.Layout({
      segment: '',
      layout: blogLayout,
      children: [
        SolRoutes.Page({
          path: '/',
          handler: homePage,
          title: 'Home',
        }),
        SolRoutes.Page({
          path: '/blog',
          handler: blogListPage,
          title: 'Blog',
        }),
        SolRoutes.Page({
          path: '/blog/page/:page',
          handler: blogListPage,
          title: 'Blog',
        }),
        SolRoutes.Page({
          path: '/blog/:slug',
          handler: blogPostPage,
          title: 'Blog Post',
          revalidate: 3600, // Blog posts: revalidate every hour
        }),
        SolRoutes.Page({
          path: '/tags',
          handler: tagsListPage,
          title: 'Tags',
        }),
        SolRoutes.Page({
          path: '/tags/:tag',
          handler: tagPostsPage,
          title: 'Tag Posts',
        }),
        SolRoutes.Page({
          path: '/about',
          handler: aboutPage,
          title: 'About',
        }),
      ],
    }),
    // RSS Feed (returns raw XML, not wrapped in layout)
    SolRoutes.Get({
      path: '/rss.xml',
      handler: rssFeed as any, // Returns Response directly
    }),
    // API routes
    SolRoutes.Get({
      path: '/api/health',
      handler: apiHealth,
    }),
    SolRoutes.Get({
      path: '/api/posts',
      handler: apiPosts,
    }),
  ];
}

export function config(): ISRRouterConfig {
  return {
    rootTemplate: DEFAULT_ROOT_TEMPLATE,
    defaultHead: getBlogStyles(),
    titlePrefix: `${blogConfig.title} | `,
    // ISR configuration
    enableISR: true,
    defaultRevalidate: 60, // Default: 1 minute
  };
}

// ============================================================================
// Styles
// ============================================================================

function getBlogStyles(): string {
  return `<style>
/* Base */
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
  line-height: 1.6;
  color: #333;
  background: #f8f9fa;
}
.container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }

/* Header */
.site-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 2rem 0;
}
.site-title { margin-bottom: 0.5rem; }
.site-title a { color: white; text-decoration: none; }
.site-description { opacity: 0.9; margin-bottom: 1rem; }

/* Navigation */
.main-nav ul {
  display: flex;
  gap: 1.5rem;
  list-style: none;
}
.main-nav a {
  color: white;
  text-decoration: none;
  font-weight: 500;
  opacity: 0.9;
  transition: opacity 0.2s;
}
.main-nav a:hover { opacity: 1; }
.rss-link::before { content: "📡 "; }

/* Layout */
.blog-layout { min-height: 100vh; display: flex; flex-direction: column; }
.content-wrapper {
  display: grid;
  grid-template-columns: 1fr 300px;
  gap: 2rem;
  padding: 2rem 20px;
  flex: 1;
}
.main-content { min-width: 0; }

/* Sidebar */
.sidebar { position: sticky; top: 20px; height: fit-content; }
.sidebar h3 { margin-bottom: 1rem; color: #667eea; }
.tag-cloud, .recent-posts {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.recent-posts ul { padding-left: 1.2rem; }
.recent-posts li { margin-bottom: 0.5rem; }
.recent-posts a { color: #667eea; text-decoration: none; }

/* Tags */
.tags, .post-tags { display: flex; flex-wrap: wrap; gap: 0.5rem; }
.tag {
  display: inline-block;
  background: #e8eaf6;
  color: #667eea;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  text-decoration: none;
  font-size: 0.875rem;
  transition: background 0.2s;
}
.tag:hover { background: #c5cae9; }

/* Post Card */
.post-card {
  background: white;
  padding: 1.5rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.post-title { margin-bottom: 0.5rem; }
.post-title a { color: #333; text-decoration: none; }
.post-title a:hover { color: #667eea; }
.post-meta { color: #666; font-size: 0.875rem; margin-bottom: 0.75rem; }
.post-excerpt { color: #555; margin-bottom: 1rem; }

/* Blog Post */
.blog-post { background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.post-header { margin-bottom: 2rem; padding-bottom: 1rem; border-bottom: 1px solid #eee; }
.post-content { line-height: 1.8; }
.post-content h2 { margin: 2rem 0 1rem; color: #333; }
.post-content h3 { margin: 1.5rem 0 0.75rem; color: #444; }
.post-content p { margin-bottom: 1rem; }
.post-content ul, .post-content ol { margin: 1rem 0 1rem 1.5rem; }
.post-content li { margin-bottom: 0.5rem; }
.post-content pre {
  background: #1e1e1e;
  color: #d4d4d4;
  padding: 1rem;
  border-radius: 4px;
  overflow-x: auto;
  margin: 1rem 0;
}
.post-content code {
  font-family: 'Fira Code', 'Consolas', monospace;
  background: #f0f0f0;
  padding: 0.2rem 0.4rem;
  border-radius: 3px;
  font-size: 0.9em;
}
.post-content pre code { background: none; padding: 0; }
.post-footer { margin-top: 2rem; padding-top: 1rem; border-top: 1px solid #eee; }
.back-link { color: #667eea; text-decoration: none; }

/* Pagination */
.pagination {
  display: flex;
  justify-content: center;
  gap: 0.5rem;
  margin: 2rem 0;
}
.page-link {
  padding: 0.5rem 1rem;
  background: white;
  border-radius: 4px;
  text-decoration: none;
  color: #667eea;
}
.page-link:hover, .page-link.active {
  background: #667eea;
  color: white;
}

/* Hero */
.hero {
  text-align: center;
  padding: 2rem;
  background: white;
  border-radius: 8px;
  margin-bottom: 2rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.tagline { color: #666; font-size: 1.2rem; }

/* Tags Page */
.tags-list { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 1rem; }
.tag-item {
  display: flex;
  justify-content: space-between;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  text-decoration: none;
  color: #333;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  transition: transform 0.2s;
}
.tag-item:hover { transform: translateY(-2px); }
.tag-name { font-weight: 600; color: #667eea; }
.tag-count { color: #666; }

/* About Page */
.about-page section { background: white; padding: 1.5rem; border-radius: 8px; margin-bottom: 1.5rem; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
.about-page h2 { color: #667eea; margin-bottom: 1rem; }
.about-page ul { padding-left: 1.5rem; }
.about-page li { margin-bottom: 0.5rem; }

/* Button */
.btn {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  background: #667eea;
  color: white;
  border-radius: 4px;
  text-decoration: none;
  transition: background 0.2s;
}
.btn:hover { background: #5a6fd6; }

/* Footer */
.site-footer {
  background: #333;
  color: white;
  padding: 2rem 0;
  text-align: center;
  margin-top: auto;
}
.site-footer a { color: #b8b8ff; }

/* Responsive */
@media (max-width: 900px) {
  .content-wrapper { grid-template-columns: 1fr; }
  .sidebar { position: static; }
}
</style>`;
}
