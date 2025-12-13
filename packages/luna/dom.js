// Re-export DOM API from MoonBit build output
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
} from "../../target/js/release/build/platform/dom/element/element.js";

// forEach is exported from api_js (type-erased wrapper for generic function)
export { forEach } from "../../target/js/release/build/lib/api_js/api_js.js";
