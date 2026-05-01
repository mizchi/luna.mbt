/**
 * Sol Blog - Cloudflare Workers Entry Point
 *
 * Uses KV for ISR caching with stale-while-revalidate
 */

import { Hono } from 'hono';
import { routes, config } from './app/server/routes';
import { registerRoutes, type CloudflareEnv } from '@sol/core/server-runtime';

type Bindings = {
  SOL_CACHE: KVNamespace;
};

const app = new Hono<{ Bindings: Bindings }>();

// Register all routes with ISR enabled
const routerConfig = config();
const appRoutes = routes();

registerRoutes(app, appRoutes, routerConfig);

// Cloudflare Workers export
export default app;
