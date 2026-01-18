/**
 * Development server for hybrid mode
 * Run with: npx tsx dev-hybrid.ts
 */
import { serve } from '@hono/node-server';
import app from './.sol/prod/server/main.js';

const port = parseInt(process.env.PORT || '3000', 10);
console.log(`Hybrid mode server running at http://localhost:${port}`);
serve({ fetch: app.fetch, port });
