/**
 * Luna CSS Vite Plugin
 *
 * Automatically extracts and injects Luna CSS utilities during development and build.
 */

import type { Plugin, ResolvedConfig, HtmlTagDescriptor } from "vite";
import fs from "fs";
import path from "path";
import { extract, extractSplit, type SplitExtractResult } from "./css/extract.js";

export type OutputMode = "inline" | "external" | "auto";

export interface LunaCssPluginOptions {
  /**
   * Source directories to extract CSS from
   * @default ["src"]
   */
  src?: string | string[];

  /**
   * Output mode: "inline" embeds in HTML, "external" creates .css file, "auto" chooses by size
   * @default "auto"
   */
  mode?: OutputMode;

  /**
   * Size threshold in bytes for "auto" mode
   * @default 4096
   */
  threshold?: number;

  /**
   * CSS filename for external mode (without hash, Vite will add hash in build)
   * @default "luna.css"
   */
  cssFileName?: string;

  /**
   * Enable verbose logging
   * @default false
   */
  verbose?: boolean;

  /**
   * Enable CSS splitting by directory
   * When enabled, generates per-directory CSS chunks + shared CSS
   * @default false
   */
  split?: boolean;

  /**
   * Minimum usage count for a declaration to be considered "shared"
   * Only used when split is enabled
   * @default 3
   */
  sharedThreshold?: number;

  /**
   * Include runtime CSS fallback in dev mode
   * Generates CSS dynamically for missing rules with console warnings
   * @default true in dev, false in build
   */
  devRuntime?: boolean;
}

// Markers for CSS injection (legacy mode)
const CSS_START_MARKER = "/* LUNA_CSS_START */";
const CSS_END_MARKER = "/* LUNA_CSS_END */";

// Virtual module IDs
const VIRTUAL_CSS_ID = "virtual:luna.css";
const VIRTUAL_SHARED_CSS_ID = "virtual:luna-shared.css";
const VIRTUAL_RUNTIME_ID = "virtual:luna-css-runtime";
const RESOLVED_VIRTUAL_CSS_ID = "\0" + VIRTUAL_CSS_ID;
const RESOLVED_VIRTUAL_SHARED_CSS_ID = "\0" + VIRTUAL_SHARED_CSS_ID;
const RESOLVED_VIRTUAL_RUNTIME_ID = "\0" + VIRTUAL_RUNTIME_ID;

/**
 * Generate inline dev runtime code
 * This is a minimal version that warns on missing CSS and generates rules dynamically
 */
function generateRuntimeCode(): string {
  return `
// Luna CSS Dev Runtime - Auto-generated
const state = { rules: new Map(), styleEl: null, initialized: false };

function djb2Hash(s) {
  let hash = 5381;
  for (let i = 0; i < s.length; i++) {
    hash = ((hash << 5) + hash + s.charCodeAt(i)) >>> 0;
  }
  return hash;
}

function toBase36(n) {
  const chars = "0123456789abcdefghijklmnopqrstuvwxyz";
  n = n & 0xffffff;
  if (n === 0) return "0";
  let result = "";
  while (n > 0) { result = chars[n % 36] + result; n = Math.floor(n / 36); }
  return result;
}

function hashClassName(decl) { return "_" + toBase36(djb2Hash(decl)); }

function init() {
  if (state.initialized || typeof document === "undefined") return;
  state.styleEl = document.createElement("style");
  state.styleEl.id = "luna-dev-css";
  document.head.appendChild(state.styleEl);
  state.initialized = true;
}

function inject(className, rule) {
  init();
  if (state.rules.has(className)) return;
  state.rules.set(className, rule);
  if (state.styleEl) state.styleEl.textContent += rule;
  console.warn("[luna-css] Generated at runtime:", rule, "\\n  → Run 'luna css extract' to pre-generate");
}

export function css(prop, val) {
  const decl = prop + ":" + val;
  const cls = hashClassName(decl);
  inject(cls, "." + cls + "{" + decl + "}");
  return cls;
}

export function styles(pairs) { return pairs.map(([p, v]) => css(p, v)).join(" "); }
export function on(pseudo, prop, val) {
  const key = pseudo + ":" + prop + ":" + val;
  const cls = hashClassName(key);
  inject(cls, "." + cls + pseudo + "{" + prop + ":" + val + "}");
  return cls;
}
export function hover(p, v) { return on(":hover", p, v); }
export function focus(p, v) { return on(":focus", p, v); }
export function active(p, v) { return on(":active", p, v); }
export function combine(classes) { return classes.filter(Boolean).join(" "); }
`;
}

/**
 * Inject dev runtime script into HTML
 */
function injectDevRuntime(html: string): string {
  const script = `<script type="module">
import { css, hover, focus, styles, combine } from "virtual:luna-css-runtime";
window.__lunaCss = { css, hover, focus, styles, combine };
</script>`;

  // Insert before </head>
  return html.replace("</head>", script + "\n</head>");
}

/**
 * Luna CSS Vite Plugin
 *
 * @example
 * ```ts
 * // vite.config.ts
 * import { lunaCss } from "@luna_ui/luna/vite-plugin";
 *
 * export default defineConfig({
 *   plugins: [
 *     lunaCss({
 *       src: ["src/examples/todomvc"],
 *       mode: "auto",
 *       threshold: 4096,
 *     }),
 *   ],
 * });
 * ```
 *
 * @example
 * ```ts
 * // main.ts - Import virtual CSS like Tailwind
 * import "virtual:luna.css";
 * ```
 *
 * @example
 * ```ts
 * // Split mode with per-directory chunks
 * lunaCss({
 *   src: ["src"],
 *   split: true,
 *   sharedThreshold: 3,
 * })
 *
 * // In your entry:
 * import "virtual:luna.css";           // All CSS
 * // Or for fine-grained control:
 * import "virtual:luna-shared.css";    // Shared CSS only
 * import "virtual:luna-chunk/todomvc.css"; // Per-directory chunk
 * ```
 */
export function lunaCss(options: LunaCssPluginOptions = {}): Plugin {
  const {
    src = ["src"],
    mode = "auto",
    threshold = 4096,
    cssFileName = "luna",
    verbose = false,
    split = false,
    sharedThreshold = 3,
    devRuntime,
  } = options;

  const srcDirs = Array.isArray(src) ? src : [src];
  let config: ResolvedConfig;
  let cachedCss: string | null = null;
  let cachedSplitResult: SplitExtractResult | null = null;
  let lastExtractTime = 0;
  // Capture cwd at plugin creation time (before Vite changes it)
  const pluginCwd = process.cwd();

  const log = (msg: string) => {
    if (verbose) {
      console.log(`[luna-css] ${msg}`);
    }
  };

  // Resolve source directory path
  const resolveSrcDir = (dir: string): string => {
    // If absolute path, use as-is
    if (path.isAbsolute(dir)) {
      return dir;
    }
    // Resolve relative to the vite config file directory if available,
    // otherwise use the cwd captured at plugin creation time
    const configDir = config.configFile
      ? path.dirname(config.configFile)
      : pluginCwd;
    return path.resolve(configDir, dir);
  };

  // Extract CSS (combined mode)
  const extractCss = (): string => {
    const now = Date.now();
    // Cache for 1 second in dev mode
    if (cachedCss && now - lastExtractTime < 1000) {
      return cachedCss;
    }

    let allCss = "";
    const seenRules = new Set<string>();

    for (const dir of srcDirs) {
      const fullPath = resolveSrcDir(dir);
      if (fs.existsSync(fullPath)) {
        const { css } = extract(fullPath, { warn: false });
        // Deduplicate rules
        for (const rule of css.split("}")) {
          const trimmed = rule.trim();
          if (trimmed && !seenRules.has(trimmed)) {
            seenRules.add(trimmed);
            allCss += trimmed + "}";
          }
        }
      } else {
        log(`Warning: Source directory not found: ${fullPath}`);
      }
    }

    cachedCss = allCss;
    lastExtractTime = now;
    log(`Extracted ${allCss.length} bytes of CSS from ${srcDirs.join(", ")}`);
    return allCss;
  };

  // Extract CSS with splitting
  const extractSplitCss = (): SplitExtractResult => {
    const now = Date.now();
    if (cachedSplitResult && now - lastExtractTime < 1000) {
      return cachedSplitResult;
    }

    // Combine results from all source directories
    const combinedChunks = new Map<string, { css: string; styles: any }>();
    let combinedSharedCss = "";
    let combinedCss = "";
    const combinedMapping: Record<string, string> = {};
    const combinedStats = new Map<string, { base: number; pseudo: number; media: number }>();

    for (const dir of srcDirs) {
      const fullPath = resolveSrcDir(dir);
      if (fs.existsSync(fullPath)) {
        const result = extractSplit(fullPath, "dir", {
          warn: false,
          sharedThreshold,
        });

        // Merge chunks
        for (const [key, chunk] of result.chunks) {
          const prefixedKey = srcDirs.length > 1 ? `${dir}/${key}` : key;
          combinedChunks.set(prefixedKey, chunk);
        }

        // Merge shared (just concatenate for now)
        if (result.shared.css) {
          combinedSharedCss += result.shared.css;
        }

        // Merge combined
        combinedCss += result.combined;

        // Merge mapping
        Object.assign(combinedMapping, result.mapping);

        // Merge stats
        for (const [key, stat] of result.stats) {
          const prefixedKey = srcDirs.length > 1 ? `${dir}/${key}` : key;
          combinedStats.set(prefixedKey, stat);
        }
      }
    }

    cachedSplitResult = {
      chunks: combinedChunks,
      shared: { css: combinedSharedCss, styles: { base: new Set(), pseudo: [], media: [] } },
      combined: combinedCss,
      mapping: combinedMapping,
      stats: combinedStats,
    };
    lastExtractTime = now;

    log(`Split extracted: ${combinedChunks.size} chunks, ${combinedSharedCss.length} bytes shared`);
    return cachedSplitResult;
  };

  const determineMode = (css: string): "inline" | "external" => {
    if (mode === "auto") {
      return css.length > threshold ? "external" : "inline";
    }
    return mode === "external" ? "external" : "inline";
  };

  const injectInline = (html: string, css: string): string => {
    const startIdx = html.indexOf(CSS_START_MARKER);
    const endIdx = html.indexOf(CSS_END_MARKER);

    if (startIdx === -1 || endIdx === -1) {
      log("Warning: CSS markers not found in HTML");
      return html;
    }

    const before = html.substring(0, startIdx + CSS_START_MARKER.length);
    const after = html.substring(endIdx);
    return `${before}\n    ${css}\n    ${after}`;
  };

  return {
    name: "luna-css",

    configResolved(resolvedConfig) {
      config = resolvedConfig;
    },

    // Resolve virtual modules
    resolveId(id) {
      if (id === VIRTUAL_CSS_ID) {
        return RESOLVED_VIRTUAL_CSS_ID;
      }
      if (id === VIRTUAL_SHARED_CSS_ID) {
        return RESOLVED_VIRTUAL_SHARED_CSS_ID;
      }
      if (id === VIRTUAL_RUNTIME_ID) {
        return RESOLVED_VIRTUAL_RUNTIME_ID;
      }
      // Support split chunk CSS: virtual:luna-chunk/[chunk-name].css
      if (id.startsWith("virtual:luna-chunk/")) {
        return "\0" + id;
      }
    },

    // Load virtual modules
    load(id) {
      // Main CSS (all combined)
      if (id === RESOLVED_VIRTUAL_CSS_ID) {
        if (split) {
          const result = extractSplitCss();
          return result.combined;
        }
        return extractCss();
      }

      // Shared CSS only (for split mode)
      if (id === RESOLVED_VIRTUAL_SHARED_CSS_ID) {
        if (!split) {
          log("Warning: virtual:luna-shared.css used without split mode");
          return "";
        }
        const result = extractSplitCss();
        return result.shared.css;
      }

      // Dev runtime (JavaScript)
      if (id === RESOLVED_VIRTUAL_RUNTIME_ID) {
        return generateRuntimeCode();
      }

      // Split chunk CSS
      if (id.startsWith("\0virtual:luna-chunk/")) {
        const chunkName = id.replace("\0virtual:luna-chunk/", "").replace(".css", "");
        if (!split) {
          log(`Warning: virtual:luna-chunk/${chunkName}.css used without split mode`);
          return "";
        }
        const result = extractSplitCss();
        const chunk = result.chunks.get(chunkName);
        if (chunk) {
          return chunk.css;
        }
        log(`Warning: Chunk "${chunkName}" not found`);
        return "";
      }
    },

    // Handle HTML transformation
    transformIndexHtml: {
      order: "pre",
      handler(html, ctx) {
        const isBuild = config.command === "build";
        const isDev = !isBuild;
        const useDevRuntime = devRuntime ?? isDev;

        // In split mode during build, we'll handle CSS differently
        if (split && isBuild) {
          const result = extractSplitCss();
          // For split build, inject shared CSS and add data attributes for chunk loading
          const sharedCss = result.shared.css;
          const combinedCss = result.combined;

          log(`Split mode build: ${result.chunks.size} chunks, ${sharedCss.length} bytes shared`);

          // For now, inject combined CSS (full split with lazy loading would need more work)
          return injectInline(html, combinedCss);
        }

        // Normal mode
        const css = extractCss();
        if (!css) {
          // If no CSS and dev runtime enabled, inject runtime loader
          if (useDevRuntime && isDev) {
            return injectDevRuntime(html);
          }
          return html;
        }

        const actualMode = determineMode(css);
        log(`Mode: ${actualMode}, Build: ${isBuild} (${css.length} bytes)`);

        let result = injectInline(html, css);

        // Inject dev runtime script in development mode
        if (useDevRuntime && isDev) {
          result = injectDevRuntime(result);
        }

        return result;
      },
    },

    // Serve virtual CSS file in dev mode
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (req.url === `/${cssFileName}.css`) {
          const css = extractCss();
          res.setHeader("Content-Type", "text/css");
          res.setHeader("Cache-Control", "no-cache");
          res.end(css);
          return;
        }
        next();
      });

      // Watch .mbt files for changes
      for (const dir of srcDirs) {
        const fullPath = resolveSrcDir(dir);
        if (fs.existsSync(fullPath)) {
          server.watcher.add(`${fullPath}/**/*.mbt`);
        }
      }

      server.watcher.on("change", (file) => {
        if (file.endsWith(".mbt")) {
          log(`File changed: ${file}`);
          // Invalidate both caches
          cachedCss = null;
          cachedSplitResult = null;

          // Invalidate virtual modules
          const mod = server.moduleGraph.getModuleById(RESOLVED_VIRTUAL_CSS_ID);
          if (mod) {
            server.moduleGraph.invalidateModule(mod);
          }
          const sharedMod = server.moduleGraph.getModuleById(RESOLVED_VIRTUAL_SHARED_CSS_ID);
          if (sharedMod) {
            server.moduleGraph.invalidateModule(sharedMod);
          }

          // Trigger HMR
          server.ws.send({ type: "full-reload" });
        }
      });
    },
  };
}

export default lunaCss;
