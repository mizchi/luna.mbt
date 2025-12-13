// Re-export DOM API from MoonBit build output (api_js)
// Using named exports for tree-shaking support
export {
  text,
  textDyn,
  render,
  mount,
  show,
  jsx,
  jsxs,
  Fragment,
  createElement,
  events,
  forEach,
} from "../../target/js/release/build/lib/api_js/api_js.js";
