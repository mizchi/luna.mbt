/**
 * Sol Framework Configuration Types
 */

export interface StaticDirEntry {
  path_prefix: string;
  source_dir: string;
  title: string;
  nav?: NavItem[];
  sidebar?: 'auto' | NavItem[];
  i18n?: I18nConfig;
  navigation?: NavigationConfig;
  exclude?: string[];
  trailing_slash?: boolean;
  theme?: ThemeConfig;
}

export interface NavItem {
  text: string;
  link?: string;
  items?: NavItem[];
}

export interface I18nConfig {
  defaultLocale?: string;
  locales?: LocaleConfig[];
}

export interface LocaleConfig {
  code: string;
  label: string;
  path?: string;
}

export interface NavigationConfig {
  spa?: boolean;
  viewTransitions?: boolean;
  keyboard?: boolean;
}

export interface ThemeConfig {
  primaryColor?: string;
  footer?: {
    message?: string;
    copyright?: string;
  };
}

export interface SolConfig {
  /** Client island directories (e.g., ['app/client']) */
  islands?: string[];
  /** Server routes directory (default: 'app/server') */
  routes?: string;
  /** Output directory for generated files (default: 'app/__gen__') */
  output?: string;
  /** Server runtime target */
  runtime?: 'node' | 'cloudflare' | 'deno' | 'bun';
  /** Auto-generate exports in moon.pkg.json (default: true) */
  client_auto_exports?: boolean;
  /** Static directories for SSG */
  staticDirs?: StaticDirEntry[];

  // SSG-specific fields (when using sol.config.ts for SSG)
  /** Documentation source directory */
  docs?: string;
  /** SSG output directory */
  out_dir?: string;
  /** Site title */
  title?: string;
  /** Base URL */
  base_url?: string;
  /** Trailing slash in URLs */
  trailing_slash?: boolean;
  /** Deploy target */
  deploy?: 'cloudflare' | 'github' | 'vercel' | 'netlify';
  /** Sidebar configuration */
  sidebar?: 'auto' | NavItem[];
  /** Theme configuration */
  theme?: ThemeConfig;
}

/**
 * Helper function for type-safe configuration
 */
export function defineConfig(config: SolConfig): SolConfig {
  return config;
}

export default { defineConfig };
