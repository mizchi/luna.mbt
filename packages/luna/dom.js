// Re-export DOM API from MoonBit build output
import * as raw from "../../target/js/release/build/browser/dom/dom.js";

// Text
export const text = raw.text;
export const textDyn = raw.textDyn;

// Rendering
export const render = raw.render;
export const mount = raw.mount;
export const show = raw.show;

// JSX support
export const jsx = raw.jsx;
export const jsxs = raw.jsxs;
export const Fragment = raw.Fragment;

// Element creation (low-level)
export const createElement = raw.createElement;

// Event handler helper
export const on = raw.on;
