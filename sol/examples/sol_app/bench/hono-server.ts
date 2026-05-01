import { Hono } from 'hono';
import { serve } from '@hono/node-server';

const app = new Hono();

// Simple HTML template
const html = (title: string, content: string) => `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
</head>
<body>
  <div id="__sol__">${content}</div>
</body>
</html>`;

// Static routes (equivalent to Sol's static pages)
app.get('/', (c) => {
  return c.html(html('Home', '<h1>Home</h1><p>Welcome to the home page</p>'));
});

app.get('/about', (c) => {
  return c.html(html('About', '<h1>About</h1><p>About page content</p>'));
});

app.get('/form', (c) => {
  return c.html(html('Form', '<h1>Contact Form</h1><form><input type="text" /></form>'));
});

app.get('/admin', (c) => {
  return c.html(html('Admin', '<h1>Admin Dashboard</h1><p>Admin content</p>'));
});

app.get('/admin/settings', (c) => {
  return c.html(html('Admin Settings', '<h1>Settings</h1><p>Settings content</p>'));
});

// Dynamic routes (catch-all)
app.get('/docs/*', (c) => {
  const slug = c.req.path.replace('/docs/', '');
  return c.html(html('Docs', `<h1>Documentation</h1><p>Path: ${slug}</p>`));
});

app.get('/blog/*', (c) => {
  const path = c.req.path.replace('/blog/', '');
  return c.html(html('Blog', `<h1>Blog</h1><p>Path: ${path || 'index'}</p>`));
});

app.get('/blog', (c) => {
  return c.html(html('Blog', '<h1>Blog</h1><p>Blog index</p>'));
});

// API routes
app.get('/api/health', (c) => {
  return c.json({ status: 'ok' });
});

app.get('/api/middleware-test', (c) => {
  return c.json({
    middleware: 'none',
    timestamp: new Date().toISOString(),
    message: 'Hono baseline server',
  });
});

app.get('/api/test/*', (c) => {
  const path = c.req.path.replace('/api/test/', '');
  return c.json({ path, star: path, all_params: `path=${path}` });
});

const port = 3001;
console.log(`Hono server running on http://localhost:${port}`);

serve({ fetch: app.fetch, port });
