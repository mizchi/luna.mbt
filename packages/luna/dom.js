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
  forEach,
} from "../../target/js/release/build/platform/dom/element/element.js";
