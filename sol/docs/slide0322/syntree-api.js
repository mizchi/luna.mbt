/**
 * @mizchi/syntree - Syntax highlighting API wrapper
 *
 * Provides syntax highlighting for multiple languages.
 */

import {
  highlight_typescript,
  highlight_moonbit,
  highlight_json,
  highlight_html,
  highlight_css,
  highlight_bash,
  highlight_rust,
} from "./syntree-core.js";

export {
  highlight_typescript as highlightTypeScript,
  highlight_moonbit as highlightMoonBit,
  highlight_json as highlightJSON,
  highlight_html as highlightHTML,
  highlight_css as highlightCSS,
  highlight_bash as highlightBash,
  highlight_rust as highlightRust,
};

/**
 * Highlight code based on language identifier.
 * @param {string} source - Source code to highlight
 * @param {string} lang - Language identifier (ts, typescript, mbt, moonbit, json, html, css, bash, sh)
 * @returns {string} Highlight HTML
 */
export function highlight(source, lang) {
  switch (lang.toLowerCase()) {
    case "ts":
    case "typescript":
    case "tsx":
    case "jsx":
    case "javascript":
    case "js":
      return highlight_typescript(source);
    case "mbt":
    case "moonbit":
      return highlight_moonbit(source);
    case "json":
      return highlight_json(source);
    case "html":
    case "htm":
    case "xml":
    case "svg":
      return highlight_html(source);
    case "css":
    case "scss":
    case "less":
      return highlight_css(source);
    case "bash":
    case "sh":
    case "shell":
    case "zsh":
      return highlight_bash(source);
    case "rust":
    case "rs":
      return highlight_rust(source);
    default:
      // Return plain text wrapped in highlight format
      return `<pre class="highlight" style="background-color: #0d1117; color: #c9d1d9"><code><span class="line"><span style="color: #c9d1d9">${escapeHtml(source)}</span></span></code></pre>`;
  }
}

function escapeHtml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}
