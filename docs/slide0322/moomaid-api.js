/**
 * @mizchi/moomaid - Mermaid diagram renderer (SVG output)
 */
import {
  experimental_render_to_svg,
  svg_options_from_theme,
} from "./moomaid-core.js";

/**
 * Render mermaid diagram to SVG string.
 * @param {string} source - Mermaid diagram source
 * @param {string} [theme="github-dark"] - Theme name
 * @returns {string} SVG string
 */
export function renderToSvg(source, theme = "github-dark") {
  const options = svg_options_from_theme(theme, "sans-serif", true);
  return experimental_render_to_svg(source, options);
}
