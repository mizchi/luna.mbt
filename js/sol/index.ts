/**
 * Sol Framework - TypeScript API
 *
 * Provides TypeScript support for Sol applications:
 * - Configuration via sol.config.ts
 * - Server routes via routes.ts
 * - HTML helpers for SSR
 *
 * @example
 * // sol.config.ts
 * import { defineConfig } from '@sol';
 *
 * export default defineConfig({
 *   islands: ['app/client'],
 *   routes: 'app/server',
 *   runtime: 'cloudflare',
 * });
 *
 * @example
 * // app/server/routes.ts
 * import { SolRoutes, div, h1, text, renderToString } from '@sol';
 *
 * export function routes() {
 *   return [
 *     SolRoutes.Page({
 *       path: '/',
 *       title: 'Home',
 *       handler: async () => renderToString(
 *         div({}, [h1({}, [text('Hello Sol!')])])
 *       ),
 *     }),
 *   ];
 * }
 */

// Configuration
export { defineConfig } from './config';
export type {
  SolConfig,
  StaticDirEntry,
  NavItem,
  I18nConfig,
  LocaleConfig,
  NavigationConfig,
  ThemeConfig,
} from './config';

// Routes DSL
export { SolRoutes, DEFAULT_ROOT_TEMPLATE } from './routes';
export type {
  SolRoute,
  PageRoute,
  LayoutRoute,
  GetRoute,
  PostRoute,
  WithMiddlewareRoute,
  PageHandler,
  LayoutHandler,
  ApiHandler,
  Middleware,
  PageProps,
  RouteParams,
  RouterConfig,
} from './routes';

// HTML Helpers
export {
  h,
  text,
  fragment,
  renderToString,
  escapeHtml,
  raw,
  // Block elements
  div,
  main,
  section,
  article,
  header,
  footer,
  nav,
  aside,
  // Headings
  h1,
  h2,
  h3,
  h4,
  h5,
  h6,
  // Inline elements
  span,
  a,
  strong,
  em,
  code,
  pre,
  // Lists
  ul,
  ol,
  li,
  // Form elements
  form,
  input,
  textarea,
  button,
  label,
  select,
  option,
  // Media
  img,
  video,
  audio,
  // Table
  table,
  thead,
  tbody,
  tr,
  th,
  td,
  // Other
  p,
  br,
  hr,
} from './html';
export type { VNode, ElementNode } from './html';

// Server Runtime
export {
  registerRoutes,
  createApp,
  createWorkerApp,
  extractParams,
  isFragmentRequest,
  wrapInTemplate,
  revalidateMiddleware,
} from './server-runtime';
export type {
  ISRRouterConfig,
  CloudflareEnv,
  ExecutionContext,
} from './server-runtime';

// ISR Cache
export {
  ISRCacheManager,
  MemoryCacheAdapter,
  CloudflareKVAdapter,
  CloudflareCacheAdapter,
  createCacheAdapter,
  getISRCache,
  resetISRCache,
} from './cache';
export type {
  CacheAdapter,
  CacheEntry,
  CacheMetadata,
  ISRCacheOptions,
  ISRResult,
  ISRContext,
  CloudflareKVNamespace,
} from './cache';
