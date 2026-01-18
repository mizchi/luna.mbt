/**
 * Development server with better-auth integration
 *
 * Uses SQLite for local development.
 * Run with: npm run dev:auth
 */

import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { getDevAuth, createAuthMiddleware, type Session } from "./auth";

// Import sol's configure_app function from MoonBit-compiled output
import { configure_app } from "./target/js/release/build/__gen__/server/server.js";

// Get dev auth instance (uses SQLite)
const auth = getDevAuth();

// Extend Hono's context with session data
type Variables = {
  session: Session | null;
};

// Create base Hono app with typed variables
const app = new Hono<{ Variables: Variables }>();

// =============================================================================
// Auth Middleware
// =============================================================================

// CORS for auth endpoints
app.use(
  "/api/auth/*",
  cors({
    origin: (origin) => origin,
    allowHeaders: ["Content-Type", "Authorization"],
    allowMethods: ["POST", "GET", "OPTIONS"],
    credentials: true,
  })
);

// Session middleware
app.use("*", createAuthMiddleware(auth));

// Mount better-auth handler
app.on(["POST", "GET"], "/api/auth/*", (c) => {
  return auth.handler(c.req.raw);
});

// =============================================================================
// Auth API Endpoints
// =============================================================================

app.get("/api/me", (c) => {
  const session = c.get("session");
  if (!session) {
    return c.json({ authenticated: false }, 401);
  }
  return c.json({
    authenticated: true,
    user: {
      id: session.user.id,
      name: session.user.name,
      email: session.user.email,
    },
  });
});

// =============================================================================
// Sol Routes
// =============================================================================

configure_app(app);

// =============================================================================
// Start Server
// =============================================================================

const port = parseInt(process.env.PORT || "3000", 10);
console.log(`Sol + Auth (dev) running at http://localhost:${port}`);
console.log(`Auth endpoints: http://localhost:${port}/api/auth/*`);
console.log(`Session API: http://localhost:${port}/api/me`);

serve({ fetch: app.fetch, port });
