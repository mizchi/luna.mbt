/**
 * CSS Injection into HTML files
 *
 * Replaces CSS between markers in HTML files with extracted CSS.
 * Supports inline embedding or external file generation.
 */

import fs from "fs";
import path from "path";
import { extract } from "./extract.js";

// Markers for CSS injection
const CSS_START_MARKER = "/* LUNA_CSS_START */";
const CSS_END_MARKER = "/* LUNA_CSS_END */";

// Link marker for external CSS
const LINK_MARKER = "<!-- LUNA_CSS_LINK -->";

export type OutputMode = "inline" | "external" | "auto";

export interface InjectHtmlOptions {
  srcDir: string;
  htmlFile: string;
  outputFile?: string;
  /** Output mode: "inline" embeds CSS in HTML, "external" creates separate .css file, "auto" chooses based on threshold */
  mode?: OutputMode;
  /** Size threshold in bytes for "auto" mode (default: 4096) */
  threshold?: number;
  /** CSS filename for external mode (default: "luna.css") */
  cssFileName?: string;
  verbose?: boolean;
}

export interface InjectHtmlResult {
  html: string;
  css: string;
  replaced: boolean;
  /** Path to external CSS file if created */
  cssFile?: string;
  /** Actual mode used */
  mode: OutputMode;
}

/**
 * Inject extracted CSS into HTML file between markers
 */
export function injectCssToHtml(options: InjectHtmlOptions): InjectHtmlResult {
  const {
    srcDir,
    htmlFile,
    mode = "inline",
    threshold = 4096,
    cssFileName = "luna.css",
    verbose = false,
  } = options;

  // Extract CSS from source
  const { css } = extract(srcDir, { warn: false });

  if (verbose) {
    console.error(`Extracted CSS: ${css.length} bytes`);
  }

  // Read HTML file
  const html = fs.readFileSync(htmlFile, "utf-8");

  // Determine actual mode
  let actualMode: OutputMode = mode;
  if (mode === "auto") {
    actualMode = css.length > threshold ? "external" : "inline";
    if (verbose) {
      console.error(
        `Auto mode: ${css.length} bytes ${css.length > threshold ? ">" : "<="} ${threshold} threshold → ${actualMode}`
      );
    }
  }

  if (actualMode === "external") {
    return injectExternal(html, css, htmlFile, cssFileName, verbose);
  } else {
    return injectInline(html, css, htmlFile, verbose);
  }
}

/**
 * Inject CSS inline between markers
 */
function injectInline(
  html: string,
  css: string,
  htmlFile: string,
  verbose: boolean
): InjectHtmlResult {
  // Find markers
  const startIdx = html.indexOf(CSS_START_MARKER);
  const endIdx = html.indexOf(CSS_END_MARKER);

  if (startIdx === -1 || endIdx === -1) {
    if (verbose) {
      console.error(
        `Warning: Markers not found in ${htmlFile}. Add /* LUNA_CSS_START */ and /* LUNA_CSS_END */ to your HTML.`
      );
    }
    return { html, css, replaced: false, mode: "inline" };
  }

  // Replace content between markers
  const before = html.substring(0, startIdx + CSS_START_MARKER.length);
  const after = html.substring(endIdx);
  const newHtml = `${before}\n    ${css}\n    ${after}`;

  if (verbose) {
    console.error(`Injected CSS inline into ${htmlFile}`);
  }

  return { html: newHtml, css, replaced: true, mode: "inline" };
}

/**
 * Create external CSS file and add link tag
 */
function injectExternal(
  html: string,
  css: string,
  htmlFile: string,
  cssFileName: string,
  verbose: boolean
): InjectHtmlResult {
  const htmlDir = path.dirname(htmlFile);
  const cssFilePath = path.join(htmlDir, cssFileName);

  // Check for link marker or style markers
  const hasLinkMarker = html.includes(LINK_MARKER);
  const startIdx = html.indexOf(CSS_START_MARKER);
  const endIdx = html.indexOf(CSS_END_MARKER);

  let newHtml = html;
  let replaced = false;

  if (hasLinkMarker) {
    // Replace link marker with actual link tag
    newHtml = html.replace(
      LINK_MARKER,
      `<link rel="stylesheet" href="${cssFileName}">`
    );
    replaced = true;
  } else if (startIdx !== -1 && endIdx !== -1) {
    // Clear inline markers and add link before </head>
    const before = html.substring(0, startIdx + CSS_START_MARKER.length);
    const after = html.substring(endIdx);
    newHtml = `${before}\n    /* External: ${cssFileName} */\n    ${after}`;

    // Add link tag before </head> if not already present
    if (!newHtml.includes(`href="${cssFileName}"`)) {
      newHtml = newHtml.replace(
        "</head>",
        `  <link rel="stylesheet" href="${cssFileName}">\n</head>`
      );
    }
    replaced = true;
  } else {
    if (verbose) {
      console.error(
        `Warning: No markers found in ${htmlFile}. Add <!-- LUNA_CSS_LINK --> or /* LUNA_CSS_START/END */ markers.`
      );
    }
  }

  if (verbose && replaced) {
    console.error(`Created external CSS: ${cssFilePath}`);
  }

  return {
    html: newHtml,
    css,
    replaced,
    cssFile: cssFilePath,
    mode: "external",
  };
}

/**
 * Inject CSS and write to file(s)
 */
export function injectAndWrite(options: InjectHtmlOptions): InjectHtmlResult {
  const result = injectCssToHtml(options);
  const outputFile = options.outputFile || options.htmlFile;

  if (result.replaced) {
    fs.writeFileSync(outputFile, result.html);
    if (options.verbose) {
      console.error(`Written HTML to: ${outputFile}`);
    }

    // Write external CSS file if needed
    if (result.mode === "external" && result.cssFile) {
      fs.writeFileSync(result.cssFile, result.css);
      if (options.verbose) {
        console.error(`Written CSS to: ${result.cssFile}`);
      }
    }
  }

  return result;
}
