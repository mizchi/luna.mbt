/**
 * Luna CSS Vite Plugin
 *
 * Automatically extracts and injects Luna CSS utilities during development and build.
 */

import type { Plugin, ResolvedConfig, HtmlTagDescriptor } from "vite";
import fs from "fs";
import path from "path";
import { extract } from "./css/extract.js";

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
}

// Markers for CSS injection
const CSS_START_MARKER = "/* LUNA_CSS_START */";
const CSS_END_MARKER = "/* LUNA_CSS_END */";

const VIRTUAL_CSS_ID = "virtual:luna.css";
const RESOLVED_VIRTUAL_CSS_ID = "\0" + VIRTUAL_CSS_ID;

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
 */
export function lunaCss(options: LunaCssPluginOptions = {}): Plugin {
  const {
    src = ["src"],
    mode = "auto",
    threshold = 4096,
    cssFileName = "luna",
    verbose = false,
  } = options;

  const srcDirs = Array.isArray(src) ? src : [src];
  let config: ResolvedConfig;
  let cachedCss: string | null = null;
  let lastExtractTime = 0;

  const log = (msg: string) => {
    if (verbose) {
      console.log(`[luna-css] ${msg}`);
    }
  };

  const extractCss = (): string => {
    const now = Date.now();
    // Cache for 1 second in dev mode
    if (cachedCss && now - lastExtractTime < 1000) {
      return cachedCss;
    }

    let allCss = "";
    const seenRules = new Set<string>();

    for (const dir of srcDirs) {
      const fullPath = path.resolve(config.root, "..", dir);
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
      }
    }

    cachedCss = allCss;
    lastExtractTime = now;
    log(`Extracted ${allCss.length} bytes of CSS from ${srcDirs.join(", ")}`);
    return allCss;
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

    // Resolve virtual CSS module
    resolveId(id) {
      if (id === VIRTUAL_CSS_ID) {
        return RESOLVED_VIRTUAL_CSS_ID;
      }
    },

    // Load virtual CSS module
    load(id) {
      if (id === RESOLVED_VIRTUAL_CSS_ID) {
        return extractCss();
      }
    },

    // Handle HTML transformation
    transformIndexHtml: {
      order: "pre",
      handler(html, ctx) {
        const css = extractCss();
        if (!css) return html;

        const actualMode = determineMode(css);
        const isBuild = config.command === "build";
        log(`Mode: ${actualMode}, Build: ${isBuild} (${css.length} bytes)`);

        // Always inline CSS for reliability (both dev and build)
        return injectInline(html, css);
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
        const fullPath = path.resolve(config.root, "..", dir);
        if (fs.existsSync(fullPath)) {
          server.watcher.add(`${fullPath}/**/*.mbt`);
        }
      }

      server.watcher.on("change", (file) => {
        if (file.endsWith(".mbt")) {
          log(`File changed: ${file}`);
          cachedCss = null; // Invalidate cache
          // Trigger HMR for HTML
          server.ws.send({ type: "full-reload" });
        }
      });
    },
  };
}

export default lunaCss;
