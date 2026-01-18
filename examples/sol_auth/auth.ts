/**
 * Better Auth Configuration for Cloudflare D1
 *
 * This module provides authentication using better-auth with Cloudflare D1.
 * Use `createAuth(db)` to create an auth instance with a D1 database.
 */

import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { drizzle } from "drizzle-orm/d1";
import type { D1Database } from "@cloudflare/workers-types";
import { authConfig } from "./sol.config";

// =============================================================================
// Auth Factory
// =============================================================================

/**
 * Create a better-auth instance with Cloudflare D1
 */
export function createAuth(db: D1Database) {
  const drizzleDb = drizzle(db);

  return betterAuth({
    database: drizzleAdapter(drizzleDb, {
      provider: "sqlite",
    }),
    emailAndPassword: {
      enabled: true,
    },
    session: {
      expiresIn: authConfig.sessionExpiresIn,
      updateAge: authConfig.sessionUpdateAge,
    },
    trustedOrigins: authConfig.trustedOrigins,
  });
}

// =============================================================================
// Types
// =============================================================================

export type Auth = ReturnType<typeof createAuth>;
export type Session = Auth["$Infer"]["Session"];

// =============================================================================
// Hono Middleware Helper
// =============================================================================

/**
 * Create auth middleware for Hono
 * Sets session on context and globalThis for MoonBit FFI access
 */
export function createAuthMiddleware(auth: Auth) {
  return async (c: any, next: () => Promise<void>) => {
    const session = await auth.api.getSession({
      headers: c.req.raw.headers,
    });
    c.set("session", session);

    // Expose to globalThis for MoonBit FFI
    (globalThis as any).__sol_session = session;

    await next();
  };
}

// =============================================================================
// Development: SQLite fallback
// =============================================================================

import Database from "better-sqlite3";

let devAuth: Auth | null = null;

/**
 * Get auth instance for local development (uses SQLite)
 */
export function getDevAuth(): Auth {
  if (devAuth) return devAuth;

  const db = new Database("./sqlite.db");

  devAuth = betterAuth({
    database: db,
    emailAndPassword: {
      enabled: true,
    },
    session: {
      expiresIn: authConfig.sessionExpiresIn,
      updateAge: authConfig.sessionUpdateAge,
    },
  }) as Auth;

  return devAuth;
}
