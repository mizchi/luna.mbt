/**
 * Cloudflare Workers Entry Point
 *
 * This is the production entry point for Cloudflare Workers.
 * It combines sol routes with better-auth authentication.
 */

import { Hono } from "hono";
import { cors } from "hono/cors";
import { createAuth, createAuthMiddleware, type Session } from "./auth";
import { configure_app } from "./_build/js/release/build/__gen__/server/server.js";
import type { Env } from "./sol.config";

// Extend Hono's context with session and env
type Variables = {
  session: Session | null;
};

type Bindings = Env;

const app = new Hono<{ Bindings: Bindings; Variables: Variables }>();

// =============================================================================
// Auth Middleware (runs before sol routes)
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

// Session middleware - extracts session for all requests
app.use("*", async (c, next) => {
  const auth = createAuth(c.env.DB);
  const middleware = createAuthMiddleware(auth);
  await middleware(c, next);
});

// Mount better-auth handler
app.on(["POST", "GET"], "/api/auth/*", async (c) => {
  const auth = createAuth(c.env.DB);
  return auth.handler(c.req.raw);
});

// =============================================================================
// Auth API Endpoints
// =============================================================================

// Get current session
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

// Configure sol routes on top of auth-enabled app
configure_app(app);

// =============================================================================
// Export for Cloudflare Workers
// =============================================================================

export default app;
