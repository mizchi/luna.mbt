/**
 * Sol + Better Auth Configuration
 *
 * This configuration file defines both sol framework settings
 * and authentication configuration for Cloudflare D1.
 */

import type { D1Database } from "@cloudflare/workers-types";

// =============================================================================
// Sol Framework Configuration
// =============================================================================

export const solConfig = {
  islands: ["app/client"],
  routes: "app/server",
  runtime: "cloudflare" as const,
  output: "app/__gen__",
  client_auto_exports: false,
};

// =============================================================================
// Auth Configuration
// =============================================================================

export interface AuthConfig {
  /** Session expiration in seconds (default: 7 days) */
  sessionExpiresIn: number;
  /** Session update age in seconds (default: 1 day) */
  sessionUpdateAge: number;
  /** Trusted origins for CORS */
  trustedOrigins: string[];
}

export const authConfig: AuthConfig = {
  sessionExpiresIn: 60 * 60 * 24 * 7, // 7 days
  sessionUpdateAge: 60 * 60 * 24, // 1 day
  trustedOrigins: [
    "http://localhost:3000",
    "http://localhost:8787",
  ],
};

// =============================================================================
// Cloudflare Environment Types
// =============================================================================

export interface Env {
  /** D1 Database binding */
  DB: D1Database;
  /** Optional: Secret for session signing */
  AUTH_SECRET?: string;
}

// =============================================================================
// Export default for sol CLI compatibility
// =============================================================================

export default solConfig;
