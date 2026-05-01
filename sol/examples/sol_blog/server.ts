import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import { routes, config } from './app/server/routes';
import { registerRoutes } from '@sol/core/server-runtime';

const app = new Hono();
const routerConfig = config();
const appRoutes = routes();

// Register all routes from the DSL
registerRoutes(app, appRoutes, routerConfig);

const port = parseInt(process.env.PORT || '3000', 10);

console.log(`Sol Blog running on http://localhost:${port}`);

serve({ fetch: app.fetch, port });
