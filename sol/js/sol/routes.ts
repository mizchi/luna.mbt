/**
 * Sol Framework Routes DSL for TypeScript
 *
 * Mirrors MoonBit's SolRoutes API for type-safe route definitions
 */

import type { Context } from 'hono';

// ============================================================================
// Core Types
// ============================================================================

export interface RouteParams {
  /** Path parameters (e.g., [['id', '123']]) */
  params: [string, string][];
  /** Query parameters */
  query: [string, string][];
  /** Full path */
  path: string;
  /** Get a path parameter by name */
  get_param?: (name: string) => string | undefined;
  /** Get a query parameter by name */
  get_query?: (name: string) => string | undefined;
}

export interface PageProps {
  /** Hono context */
  ctx: Context;
  /** Route parameters */
  params: RouteParams;
  /** Whether this is a fragment request (CSR navigation) */
  is_fragment: boolean;
}

// ============================================================================
// Handler Types
// ============================================================================

/** Page handler - returns HTML string */
export type PageHandler = (props: PageProps) => string | Promise<string>;

/** Layout handler - wraps children with layout HTML */
export type LayoutHandler = (props: PageProps, children: string) => string | Promise<string>;

/** API handler - returns JSON-serializable data */
export type ApiHandler = (props: PageProps) => unknown | Promise<unknown>;

/** Middleware function */
export type Middleware = (ctx: Context, next: () => Promise<Response>) => Promise<Response>;

// ============================================================================
// Route Types (mirrors MoonBit SolRoutes)
// ============================================================================

export type SolRoute =
  | PageRoute
  | LayoutRoute
  | GetRoute
  | PostRoute
  | WithMiddlewareRoute;

export interface PageRoute {
  type: 'page';
  path: string;
  handler: PageHandler;
  title: string;
  meta?: [string, string][];
  revalidate?: number;
  cache?: 'always-fetch' | 'stale-while-revalidate';
}

export interface LayoutRoute {
  type: 'layout';
  segment: string;
  layout: LayoutHandler;
  children: SolRoute[];
}

export interface GetRoute {
  type: 'get';
  path: string;
  handler: ApiHandler;
}

export interface PostRoute {
  type: 'post';
  path: string;
  handler: ApiHandler;
}

export interface WithMiddlewareRoute {
  type: 'withMiddleware';
  middleware: Middleware[];
  children: SolRoute[];
}

// ============================================================================
// DSL Functions
// ============================================================================

export const SolRoutes = {
  /**
   * Define a page route
   */
  Page: (opts: {
    path: string;
    handler: PageHandler;
    title: string;
    meta?: [string, string][];
    revalidate?: number;
    cache?: 'always-fetch' | 'stale-while-revalidate';
  }): PageRoute => ({
    type: 'page',
    ...opts,
  }),

  /**
   * Define a layout wrapper
   */
  Layout: (opts: {
    segment: string;
    layout: LayoutHandler;
    children: SolRoute[];
  }): LayoutRoute => ({
    type: 'layout',
    ...opts,
  }),

  /**
   * Define a GET API route
   */
  Get: (opts: {
    path: string;
    handler: ApiHandler;
  }): GetRoute => ({
    type: 'get',
    ...opts,
  }),

  /**
   * Define a POST API route
   */
  Post: (opts: {
    path: string;
    handler: ApiHandler;
  }): PostRoute => ({
    type: 'post',
    ...opts,
  }),

  /**
   * Wrap routes with middleware
   */
  WithMiddleware: (opts: {
    middleware: Middleware[];
    children: SolRoute[];
  }): WithMiddlewareRoute => ({
    type: 'withMiddleware',
    ...opts,
  }),
};

// ============================================================================
// Router Config
// ============================================================================

export interface RouterConfig {
  /** Title prefix for all pages */
  titlePrefix?: string;
  /** Default page title */
  defaultTitle?: string;
  /** Default head HTML */
  defaultHead?: string;
  /** Root HTML template with placeholders */
  rootTemplate?: string;
}

export const DEFAULT_ROOT_TEMPLATE = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>__LUNA_TITLE__</title>
  __LUNA_PRELOAD__
  __LUNA_HEAD__
</head>
<body>
  <div id="__sol__">__LUNA_MAIN__</div>
</body>
</html>`;
