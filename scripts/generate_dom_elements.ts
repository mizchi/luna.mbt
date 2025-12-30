#!/usr/bin/env npx tsx
/**
 * DOM Element Generator for MoonBit
 *
 * Generates __generated.mbt files for both:
 * - src/platform/dom/element/ (browser DOM with event handlers)
 * - src/platform/server_dom/ (server-side SSR without event handlers)
 *
 * Usage: npx tsx scripts/generate_dom_elements.ts
 */

import { execSync } from "child_process";
import { writeFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// =============================================================================
// Type Definitions
// =============================================================================

type AttrType = "string" | "bool";

interface ElementAttr {
  name: string;
  type: AttrType;
  htmlAttr?: string; // HTML attribute name if different from param name
  hasDynamic?: boolean; // Generate dyn_ prefix version for this attr (DOM only)
}

type ElementNamespace = "html" | "svg";

interface ElementDef {
  tag: string;
  fnName?: string; // Function name if different from tag (e.g., main_ for main)
  description?: string;
  attrs?: ElementAttr[];
  hasChildren?: boolean; // default: true
  isVoid?: boolean; // self-closing element (img, br, hr, input, meta, link)
  namespace?: ElementNamespace; // default: "html"
}

// Attributes that should have dyn_ versions in all elements
const COMMON_DYNAMIC_ATTRS = ["class", "style"];

// =============================================================================
// Element Definitions
// =============================================================================

const COMMON_ATTRS: ElementAttr[] = [
  { name: "id", type: "string" },
  { name: "class", type: "string" },
  { name: "style", type: "string" },
];

const elements: ElementDef[] = [
  // Document structure (server_dom only)
  {
    tag: "html",
    description: "Create an html element",
    attrs: [{ name: "lang", type: "string" }],
  },
  { tag: "head", description: "Create a head element", attrs: [] },
  { tag: "body", description: "Create a body element" },
  {
    tag: "title",
    description: "Create a title element",
    attrs: [{ name: "content", type: "string" }], // special: becomes text child
    hasChildren: false,
  },
  {
    tag: "meta",
    description: "Create a meta element",
    attrs: [
      { name: "charset", type: "string" },
      { name: "name", type: "string" },
      { name: "content", type: "string" },
      { name: "http_equiv", type: "string", htmlAttr: "http-equiv" },
    ],
    isVoid: true,
    hasChildren: false,
  },
  {
    tag: "link",
    description: "Create a link element",
    attrs: [
      { name: "rel", type: "string" },
      { name: "href", type: "string" },
      { name: "type_", type: "string", htmlAttr: "type" },
    ],
    isVoid: true,
    hasChildren: false,
  },
  {
    tag: "script",
    description: "Create a script element",
    attrs: [
      { name: "src", type: "string" },
      { name: "type_", type: "string", htmlAttr: "type" },
      { name: "defer_", type: "bool", htmlAttr: "defer" },
      { name: "async_", type: "bool", htmlAttr: "async" },
      { name: "content", type: "string" }, // special: becomes text child
    ],
    hasChildren: false, // content attr is used instead
  },
  {
    tag: "style",
    fnName: "style_",
    description: "Create a style element",
    attrs: [
      { name: "content", type: "string" }, // special: becomes text child
      { name: "type_", type: "string", htmlAttr: "type" },
    ],
    hasChildren: false,
  },

  // Semantic layout
  { tag: "main", fnName: "main_", description: "Create a main element" },
  { tag: "nav", description: "Create a nav element" },
  { tag: "header", fnName: "header_", description: "Create a header element" },
  { tag: "footer", fnName: "footer_", description: "Create a footer element" },
  { tag: "section", description: "Create a section element" },
  { tag: "article", description: "Create an article element" },
  { tag: "aside", description: "Create an aside element" },

  // Common content
  { tag: "div", description: "Create a div element" },
  { tag: "span", description: "Create a span element" },
  { tag: "p", description: "Create a p element" },
  {
    tag: "a",
    description: "Create an anchor element",
    attrs: [
      { name: "href", type: "string" },
      { name: "target", type: "string" },
    ],
  },

  // Headings
  { tag: "h1", description: "Create h1 element" },
  { tag: "h2", description: "Create h2 element" },
  { tag: "h3", description: "Create h3 element" },
  { tag: "h4", description: "Create h4 element" },
  { tag: "h5", description: "Create h5 element" },
  { tag: "h6", description: "Create h6 element" },

  // Lists
  { tag: "ul", description: "Create ul element" },
  { tag: "ol", description: "Create ol element" },
  { tag: "li", description: "Create li element" },

  // Forms
  {
    tag: "button",
    description: "Create a button element",
    attrs: [{ name: "disabled", type: "bool", hasDynamic: true }],
  },
  {
    tag: "input",
    description: "Create an input element",
    attrs: [
      { name: "type_", type: "string", htmlAttr: "type" },
      { name: "name", type: "string" },
      { name: "value", type: "string", hasDynamic: true },
      { name: "placeholder", type: "string" },
      { name: "disabled", type: "bool", hasDynamic: true },
      { name: "readonly_", type: "bool", htmlAttr: "readonly" },
      { name: "required", type: "bool" },
      { name: "checked", type: "bool", hasDynamic: true },
    ],
    isVoid: true,
    hasChildren: false,
  },
  {
    tag: "textarea",
    description: "Create a textarea element",
    attrs: [
      { name: "name", type: "string" },
      { name: "placeholder", type: "string" },
      { name: "disabled", type: "bool" },
    ],
  },
  {
    tag: "form",
    description: "Create a form element",
    attrs: [
      { name: "action", type: "string" },
      { name: "http_method", type: "string", htmlAttr: "method" },
    ],
  },
  {
    tag: "label",
    description: "Create a label element",
    attrs: [{ name: "for_", type: "string", htmlAttr: "for" }],
  },

  // Media
  {
    tag: "img",
    description: "Create img element",
    attrs: [
      { name: "src", type: "string" },
      { name: "alt", type: "string" },
      { name: "width", type: "string" },
      { name: "height", type: "string" },
    ],
    isVoid: true,
    hasChildren: false,
  },
  { tag: "br", description: "Create br element", attrs: [], isVoid: true, hasChildren: false },
  { tag: "hr", description: "Create hr element", attrs: [], isVoid: true, hasChildren: false },

  // Inline text
  { tag: "strong", description: "Create strong element" },
  { tag: "em", description: "Create em element" },
  { tag: "code", description: "Create code element" },
  { tag: "pre", description: "Create pre element" },

  // =============================================================================
  // SVG Elements (namespace: svg)
  // =============================================================================

  // SVG container
  {
    tag: "svg",
    description: "Create an SVG element",
    attrs: [
      { name: "width", type: "string" },
      { name: "height", type: "string" },
      { name: "viewBox", type: "string" },
      { name: "xmlns", type: "string" },
      { name: "fill", type: "string" },
      { name: "stroke", type: "string" },
      { name: "role", type: "string" },
      { name: "aria_label", type: "string", htmlAttr: "aria-label" },
      { name: "aria_labelledby", type: "string", htmlAttr: "aria-labelledby" },
      { name: "aria_describedby", type: "string", htmlAttr: "aria-describedby" },
    ],
    namespace: "svg",
  },

  // SVG accessibility elements
  {
    tag: "title",
    fnName: "svg_title",
    description: "Create an SVG title element for accessibility",
    namespace: "svg",
  },
  {
    tag: "desc",
    fnName: "svg_desc",
    description: "Create an SVG desc element for accessibility",
    namespace: "svg",
  },

  // SVG grouping
  {
    tag: "g",
    fnName: "svg_g",
    description: "Create an SVG group element",
    attrs: [
      { name: "transform", type: "string" },
      { name: "fill", type: "string" },
      { name: "stroke", type: "string" },
      { name: "opacity", type: "string" },
    ],
    namespace: "svg",
  },
  {
    tag: "defs",
    fnName: "svg_defs",
    description: "Create an SVG defs element",
    namespace: "svg",
  },
  {
    tag: "symbol",
    fnName: "svg_symbol",
    description: "Create an SVG symbol element",
    attrs: [
      { name: "viewBox", type: "string" },
    ],
    namespace: "svg",
  },
  {
    tag: "use",
    fnName: "svg_use",
    description: "Create an SVG use element",
    attrs: [
      { name: "href", type: "string" },
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "width", type: "string" },
      { name: "height", type: "string" },
    ],
    namespace: "svg",
    hasChildren: false,
  },

  // SVG shapes
  {
    tag: "rect",
    fnName: "svg_rect",
    description: "Create an SVG rect element",
    attrs: [
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "width", type: "string" },
      { name: "height", type: "string" },
      { name: "rx", type: "string" },
      { name: "ry", type: "string" },
      { name: "fill", type: "string" },
      { name: "stroke", type: "string" },
      { name: "stroke_width", type: "string", htmlAttr: "stroke-width" },
    ],
    namespace: "svg",
    hasChildren: false,
  },
  {
    tag: "circle",
    fnName: "svg_circle",
    description: "Create an SVG circle element",
    attrs: [
      { name: "cx", type: "string" },
      { name: "cy", type: "string" },
      { name: "r", type: "string" },
      { name: "fill", type: "string" },
      { name: "stroke", type: "string" },
      { name: "stroke_width", type: "string", htmlAttr: "stroke-width" },
    ],
    namespace: "svg",
    hasChildren: false,
  },
  {
    tag: "ellipse",
    fnName: "svg_ellipse",
    description: "Create an SVG ellipse element",
    attrs: [
      { name: "cx", type: "string" },
      { name: "cy", type: "string" },
      { name: "rx", type: "string" },
      { name: "ry", type: "string" },
      { name: "fill", type: "string" },
      { name: "stroke", type: "string" },
      { name: "stroke_width", type: "string", htmlAttr: "stroke-width" },
    ],
    namespace: "svg",
    hasChildren: false,
  },
  {
    tag: "line",
    fnName: "svg_line",
    description: "Create an SVG line element",
    attrs: [
      { name: "x1", type: "string" },
      { name: "y1", type: "string" },
      { name: "x2", type: "string" },
      { name: "y2", type: "string" },
      { name: "stroke", type: "string" },
      { name: "stroke_width", type: "string", htmlAttr: "stroke-width" },
    ],
    namespace: "svg",
    hasChildren: false,
  },
  {
    tag: "polyline",
    fnName: "svg_polyline",
    description: "Create an SVG polyline element",
    attrs: [
      { name: "points", type: "string" },
      { name: "fill", type: "string" },
      { name: "stroke", type: "string" },
      { name: "stroke_width", type: "string", htmlAttr: "stroke-width" },
    ],
    namespace: "svg",
    hasChildren: false,
  },
  {
    tag: "polygon",
    fnName: "svg_polygon",
    description: "Create an SVG polygon element",
    attrs: [
      { name: "points", type: "string" },
      { name: "fill", type: "string" },
      { name: "stroke", type: "string" },
      { name: "stroke_width", type: "string", htmlAttr: "stroke-width" },
    ],
    namespace: "svg",
    hasChildren: false,
  },
  {
    tag: "path",
    fnName: "svg_path",
    description: "Create an SVG path element",
    attrs: [
      { name: "d", type: "string" },
      { name: "fill", type: "string" },
      { name: "stroke", type: "string" },
      { name: "stroke_width", type: "string", htmlAttr: "stroke-width" },
      { name: "stroke_linecap", type: "string", htmlAttr: "stroke-linecap" },
      { name: "stroke_linejoin", type: "string", htmlAttr: "stroke-linejoin" },
      { name: "fill_rule", type: "string", htmlAttr: "fill-rule" },
    ],
    namespace: "svg",
    hasChildren: false,
  },

  // SVG text
  {
    tag: "text",
    fnName: "svg_text",
    description: "Create an SVG text element",
    attrs: [
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "dx", type: "string" },
      { name: "dy", type: "string" },
      { name: "text_anchor", type: "string", htmlAttr: "text-anchor" },
      { name: "dominant_baseline", type: "string", htmlAttr: "dominant-baseline" },
      { name: "fill", type: "string" },
      { name: "font_size", type: "string", htmlAttr: "font-size" },
      { name: "font_family", type: "string", htmlAttr: "font-family" },
    ],
    namespace: "svg",
  },
  {
    tag: "tspan",
    fnName: "svg_tspan",
    description: "Create an SVG tspan element",
    attrs: [
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "dx", type: "string" },
      { name: "dy", type: "string" },
    ],
    namespace: "svg",
  },

  // SVG image
  {
    tag: "image",
    fnName: "svg_image",
    description: "Create an SVG image element",
    attrs: [
      { name: "href", type: "string" },
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "width", type: "string" },
      { name: "height", type: "string" },
      { name: "preserveAspectRatio", type: "string" },
    ],
    namespace: "svg",
    hasChildren: false,
  },

  // SVG clip and mask
  {
    tag: "clipPath",
    fnName: "svg_clip_path",
    description: "Create an SVG clipPath element",
    namespace: "svg",
  },
  {
    tag: "mask",
    fnName: "svg_mask",
    description: "Create an SVG mask element",
    attrs: [
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "width", type: "string" },
      { name: "height", type: "string" },
    ],
    namespace: "svg",
  },

  // SVG gradients and patterns
  {
    tag: "linearGradient",
    fnName: "svg_linear_gradient",
    description: "Create an SVG linearGradient element",
    attrs: [
      { name: "x1", type: "string" },
      { name: "y1", type: "string" },
      { name: "x2", type: "string" },
      { name: "y2", type: "string" },
      { name: "gradientUnits", type: "string" },
    ],
    namespace: "svg",
  },
  {
    tag: "radialGradient",
    fnName: "svg_radial_gradient",
    description: "Create an SVG radialGradient element",
    attrs: [
      { name: "cx", type: "string" },
      { name: "cy", type: "string" },
      { name: "r", type: "string" },
      { name: "fx", type: "string" },
      { name: "fy", type: "string" },
      { name: "gradientUnits", type: "string" },
    ],
    namespace: "svg",
  },
  {
    tag: "stop",
    fnName: "svg_stop",
    description: "Create an SVG stop element for gradients",
    attrs: [
      { name: "offset", type: "string" },
      { name: "stop_color", type: "string", htmlAttr: "stop-color" },
      { name: "stop_opacity", type: "string", htmlAttr: "stop-opacity" },
    ],
    namespace: "svg",
    hasChildren: false,
  },
  {
    tag: "pattern",
    fnName: "svg_pattern",
    description: "Create an SVG pattern element",
    attrs: [
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "width", type: "string" },
      { name: "height", type: "string" },
      { name: "patternUnits", type: "string" },
      { name: "patternContentUnits", type: "string" },
    ],
    namespace: "svg",
  },

  // SVG filters
  {
    tag: "filter",
    fnName: "svg_filter",
    description: "Create an SVG filter element",
    attrs: [
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "width", type: "string" },
      { name: "height", type: "string" },
      { name: "filterUnits", type: "string" },
    ],
    namespace: "svg",
  },

  // SVG animation
  {
    tag: "animate",
    fnName: "svg_animate",
    description: "Create an SVG animate element",
    attrs: [
      { name: "attributeName", type: "string" },
      { name: "from", type: "string" },
      { name: "to", type: "string" },
      { name: "dur", type: "string" },
      { name: "repeatCount", type: "string" },
      { name: "fill_anim", type: "string", htmlAttr: "fill" },
    ],
    namespace: "svg",
    hasChildren: false,
  },
  {
    tag: "animateTransform",
    fnName: "svg_animate_transform",
    description: "Create an SVG animateTransform element",
    attrs: [
      { name: "attributeName", type: "string" },
      { name: "type_", type: "string", htmlAttr: "type" },
      { name: "from", type: "string" },
      { name: "to", type: "string" },
      { name: "dur", type: "string" },
      { name: "repeatCount", type: "string" },
    ],
    namespace: "svg",
    hasChildren: false,
  },

  // SVG foreign object
  {
    tag: "foreignObject",
    fnName: "svg_foreign_object",
    description: "Create an SVG foreignObject element for embedding HTML",
    attrs: [
      { name: "x", type: "string" },
      { name: "y", type: "string" },
      { name: "width", type: "string" },
      { name: "height", type: "string" },
    ],
    namespace: "svg",
  },
];

// Elements only for browser DOM (not server_dom)
// Note: form elements are now included in server_dom for SSR rendering
const browserOnlyElements = new Set(["textarea"]);

// Elements only for server_dom (document structure)
const serverOnlyElements = new Set(["html", "head", "body", "title", "meta", "link", "script", "style"]);

// =============================================================================
// Code Generator
// =============================================================================

interface GeneratorOptions {
  target: "dom" | "server_dom";
}

function generateElement(elem: ElementDef, opts: GeneratorOptions): string {
  const fnName = elem.fnName ?? elem.tag;
  const hasChildren = elem.hasChildren !== false && !elem.isVoid;
  const allAttrs = [...(elem.attrs ?? []), ...COMMON_ATTRS];

  // Filter attrs based on target
  const filteredAttrs =
    opts.target === "server_dom"
      ? allAttrs
      : allAttrs.filter((a) => !["content"].includes(a.name) || elem.tag !== "script");

  // Collect attrs that need dyn_ versions (DOM only)
  const dynAttrs: ElementAttr[] = [];
  if (opts.target === "dom") {
    // Common dynamic attrs (class, style)
    for (const attr of COMMON_ATTRS) {
      if (COMMON_DYNAMIC_ATTRS.includes(attr.name)) {
        dynAttrs.push(attr);
      }
    }
    // Element-specific dynamic attrs
    for (const attr of elem.attrs ?? []) {
      if (attr.hasDynamic) {
        dynAttrs.push(attr);
      }
    }
  }

  // Build parameter list
  const params: string[] = [];

  // Element-specific attrs first (optional by default)
  // Elements where content becomes text child
  const contentAsTextChildElems = ["script", "style", "title"];
  for (const attr of elem.attrs ?? []) {
    if (attr.name === "content" && contentAsTextChildElems.includes(elem.tag)) {
      // content is special for script/style/title
      if (elem.tag === "style" || elem.tag === "title") {
        params.push(`${attr.name} : String`); // required for style/title
      } else {
        params.push(`${attr.name}? : String`); // optional for script
      }
    } else {
      const type = attr.type === "bool" ? "Bool" : "String";
      params.push(`${attr.name}? : ${type}`);
    }
  }

  // Common attrs (optional)
  for (const attr of COMMON_ATTRS) {
    params.push(`${attr.name}? : String`);
  }

  // Dynamic attrs (DOM only) - dyn_ prefix
  if (opts.target === "dom") {
    for (const attr of dynAttrs) {
      const type = attr.type === "bool" ? "Bool" : "String";
      params.push(`dyn_${attr.name}? : () -> ${type}`);
    }
  }

  // Target-specific params
  if (opts.target === "dom") {
    params.push("on? : HandlerMap");
    params.push("ref_? : ElementRef");
    params.push("attrs? : Array[(String, Attr)]");
    params.push("dyn_attrs? : Array[(String, AttrValue)]"); // escape hatch
  } else {
    params.push("attrs? : Array[(String, @luna.Attr[Unit])]");
  }

  // Children (required, positional - same style for both DOM and server_dom)
  if (hasChildren) {
    if (opts.target === "dom") {
      params.push("children : Array[DomNode]");
    } else {
      params.push("children : Array[@luna.Node[Unit]]");
    }
  }

  // Build return type
  const returnType = opts.target === "dom" ? "DomNode" : "@luna.Node[Unit]";

  // Build function body
  const bodyLines: string[] = [];

  if (opts.target === "dom") {
    bodyLines.push("let props = build_props(id, class, style, on, ref_, attrs, dyn_attrs~)");
  } else {
    bodyLines.push("let props = build_attrs(id, class, style, attrs)");
  }

  // Add element-specific attrs to props
  // Elements where content attr becomes text child, not HTML attr
  const contentAsTextChild = ["script", "style", "title"].includes(elem.tag);
  for (const attr of elem.attrs ?? []) {
    // content attr for script/style/title becomes text child, not HTML attr
    if (attr.name === "content" && contentAsTextChild) continue;

    const htmlAttr = attr.htmlAttr ?? attr.name;
    if (attr.type === "bool") {
      bodyLines.push(`if ${attr.name} is Some(true) {`);
      if (opts.target === "dom") {
        bodyLines.push(`  props.push(("${htmlAttr}", Static("true")))`);
      } else {
        bodyLines.push(`  props.push(("${htmlAttr}", static_attr("")))`);
      }
      bodyLines.push("}");
    } else {
      bodyLines.push(`if ${attr.name} is Some(v) {`);
      if (opts.target === "dom") {
        bodyLines.push(`  props.push(("${htmlAttr}", Static(v)))`);
      } else {
        bodyLines.push(`  props.push(("${htmlAttr}", static_attr(v)))`);
      }
      bodyLines.push("}");
    }
  }

  // Add dynamic attrs to props (DOM only)
  if (opts.target === "dom") {
    for (const attr of dynAttrs) {
      const htmlAttr = attr.htmlAttr ?? attr.name;
      // For class, use className in DOM
      const propName = attr.name === "class" ? "className" : htmlAttr;
      if (attr.type === "bool") {
        // Bool dynamic: convert to string
        bodyLines.push(`if dyn_${attr.name} is Some(getter) {`);
        bodyLines.push(`  props.push(("${propName}", Dynamic(fn() { getter().to_string() })))`);
        bodyLines.push("}");
      } else {
        bodyLines.push(`if dyn_${attr.name} is Some(getter) {`);
        bodyLines.push(`  props.push(("${propName}", Dynamic(getter)))`);
        bodyLines.push("}");
      }
    }
  }

  // Handle special content attr for script/style/title (content becomes text child, not HTML attr)
  const hasContentAttr = elem.attrs?.some((a) => a.name === "content");

  // Determine which create function to use
  const isSvg = elem.namespace === "svg";
  const createFn = isSvg
    ? (opts.target === "dom" ? `create_element_ns(svg_ns, "${elem.tag}"` : `create_svg_element("${elem.tag}"`)
    : `create_element("${elem.tag}"`;

  if (hasContentAttr && contentAsTextChild && opts.target === "server_dom") {
    if (elem.tag === "style" || elem.tag === "title") {
      // style/title: content is required (positional param)
      bodyLines.push(`${createFn}, props, [text(content)])`);
    } else if (elem.tag === "script") {
      // script: content is optional, no children param
      bodyLines.push("let script_children : Array[@luna.Node[Unit]] = if content is Some(c) {");
      bodyLines.push("  [text(c)]");
      bodyLines.push("} else {");
      bodyLines.push("  []");
      bodyLines.push("}");
      bodyLines.push(`${createFn}, props, script_children)`);
    }
  } else {
    // Normal element creation - void elements don't have children
    const childrenArg = hasChildren ? "children" : "[]";
    bodyLines.push(`${createFn}, props, ${childrenArg})`);
  }

  // Join body with proper indentation
  const body = bodyLines.map((line) => "  " + line).join("\n");

  // Build doc comment
  const doc = `///|\n/// ${elem.description ?? `Create ${elem.tag} element`}`;

  return `${doc}
pub fn ${fnName}(
  ${params.join(",\n  ")}
) -> ${returnType} {
${body}
}`;
}

function generateHeader(opts: GeneratorOptions): string {
  const warning = `// =============================================================================
// AUTO-GENERATED FILE - DO NOT EDIT DIRECTLY
// Generated by: scripts/generate_dom_elements.ts
// =============================================================================

`;

  if (opts.target === "dom") {
    return (
      warning +
      `///| Element factories for browser DOM with DSL syntax
///|
///| These functions create DOM elements with event handler support.
///| Uses HandlerMap and build_props from dsl.mbt.
`
    );
  } else {
    return (
      warning +
      `///| Element factories for server-side rendering
///|
///| Provides html, head, body and common HTML elements.
///| No event handlers - use islands for interactivity.
`
    );
  }
}

function generateHelpers(opts: GeneratorOptions): string {
  if (opts.target === "server_dom") {
    return `
// =============================================================================
// Helper functions
// =============================================================================

///|
/// Create a server-side element
fn create_element(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]]
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///|
/// Create an SVG element (same as create_element but marked for clarity)
/// Note: SVG namespace is handled during rendering, VNode is namespace-agnostic
fn create_svg_element(
  tag : String,
  attrs : Array[(String, @luna.Attr[Unit])],
  children : Array[@luna.Node[Unit]]
) -> @luna.Node[Unit] {
  @luna.h(tag, attrs, children)
}

///|
/// Create a static attribute
fn static_attr(value : String) -> @luna.Attr[Unit] {
  @luna.attr_static(value)
}

///|
/// Build attribute array from common properties
fn build_attrs(
  id : String?,
  class : String?,
  style : String?,
  attrs : Array[(String, @luna.Attr[Unit])]?
) -> Array[(String, @luna.Attr[Unit])] {
  let result : Array[(String, @luna.Attr[Unit])] = []
  if id is Some(v) {
    result.push(("id", static_attr(v)))
  }
  if class is Some(v) {
    result.push(("class", static_attr(v)))
  }
  if style is Some(v) {
    result.push(("style", static_attr(v)))
  }
  if attrs is Some(extra) {
    for attr in extra {
      result.push(attr)
    }
  }
  result
}
`;
  }
  return ""; // DOM helpers are in separate file
}

function generateTextHelpers(opts: GeneratorOptions): string {
  if (opts.target === "server_dom") {
    return `
// =============================================================================
// Text and Fragment helpers
// =============================================================================

///|
/// Create a text node
pub fn text(content : String) -> @luna.Node[Unit] {
  @luna.text(content)
}

///|
/// Create a fragment (multiple nodes without wrapper)
pub fn fragment(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.fragment(children)
}

///|
/// Create static attribute
pub fn attr(value : String) -> @luna.Attr[Unit] {
  @luna.attr_static(value)
}
`;
  }
  return ""; // DOM text helpers are in separate file
}

function generateFile(opts: GeneratorOptions): string {
  const relevantElements = elements.filter((e) => {
    const fnName = e.fnName ?? e.tag;
    // SVG elements are available in both DOM and server_dom
    if (e.namespace === "svg") {
      return true;
    }
    if (opts.target === "dom") {
      return !serverOnlyElements.has(fnName) && !serverOnlyElements.has(e.tag);
    } else {
      return !browserOnlyElements.has(fnName) && !browserOnlyElements.has(e.tag);
    }
  });

  const sections: string[] = [
    generateHeader(opts),
    generateHelpers(opts),
    "// =============================================================================",
    "// Element factories",
    "// =============================================================================",
    "",
    ...relevantElements.map((e) => generateElement(e, opts)),
    generateTextHelpers(opts),
  ];

  return sections.join("\n\n");
}

// =============================================================================
// Main
// =============================================================================

function generateDomTextHelpers(): string {
  return `
// =============================================================================
// Text helpers
// =============================================================================

///|
/// Create a static text node
pub fn text(content : String) -> DomNode {
  ToDomNode::to_dom_node(content)
}

///|
/// Create a reactive text node from a getter function
pub fn text_dyn(content : () -> String) -> DomNode {
  text_node(content)
}

///|
/// Create a reactive text node from a signal
pub fn[T : Show] text_sig(sig : @signal.Signal[T]) -> DomNode {
  text_from_signal(sig)
}

///|
/// Create a reactive text node from a signal (alias for text_sig)
pub fn[T : Show] text_of(sig : @signal.Signal[T]) -> DomNode {
  text_from_signal(sig)
}

// =============================================================================
// AttrValue factory functions for external use
// =============================================================================

///|
/// Create a static attribute value
pub fn attr_static(value : String) -> AttrValue {
  Static(value)
}

///|
/// Create a dynamic attribute value
pub fn attr_dynamic(getter : () -> String) -> AttrValue {
  Dynamic(getter)
}

///|
/// Create an event handler attribute
pub fn attr_handler(handler : (@js.Any) -> Unit) -> AttrValue {
  Handler(handler)
}

///|
/// Create a static style attribute (string form, e.g. "color: red; margin: 10px")
pub fn attr_style(style : String) -> AttrValue {
  Static(style)
}

///|
/// Create a dynamic style attribute
pub fn attr_dynamic_style(getter : () -> String) -> AttrValue {
  Dynamic(getter)
}

// =============================================================================
// JSX Runtime - For TSX/JSX compatibility
// =============================================================================

///|
/// JSX runtime: jsx function (maps directly to create_element)
/// Usage in TSX: <div class="foo">children</div>
pub fn jsx(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[DomNode]
) -> DomNode {
  create_element(tag, attrs, children)
}

///|
/// JSX runtime: jsxs function (same as jsx, for static children)
pub fn jsxs(
  tag : String,
  attrs : Array[(String, AttrValue)],
  children : Array[DomNode]
) -> DomNode {
  create_element(tag, attrs, children)
}

///|
/// JSX runtime: Fragment (returns children as a DocumentFragment)
pub fn fragment(children : Array[DomNode]) -> DomNode {
  // Return single child directly for optimization
  match children.length() {
    0 => {
      // Empty fragment: return empty DocumentFragment
      let doc = @js_dom.document()
      let frag = doc.createDocumentFragment()
      Raw(frag.as_node())
    }
    1 => children[0]
    _ => {
      // Multiple children: use real DocumentFragment
      let doc = @js_dom.document()
      let frag = doc.createDocumentFragment()
      for child in children {
        frag.as_node().appendChild(child.to_dom()) |> ignore
      }
      Raw(frag.as_node())
    }
  }
}
`;
}

function main() {
  const rootDir = join(__dirname, "..");

  // Generate static_dom/element elements (server-side SSR)
  const serverDomPath = join(rootDir, "src/luna/static_dom/element/__generated.mbt");
  const serverDomContent = generateFile({ target: "server_dom" });
  writeFileSync(serverDomPath, serverDomContent);
  console.log(`Generated: ${serverDomPath}`);

  // Generate dom/element elements (browser-side)
  const domPath = join(rootDir, "src/luna/dom/element/__generated.mbt");
  const domContent = generateFile({ target: "dom" }) + generateDomTextHelpers();
  writeFileSync(domPath, domContent);
  console.log(`Generated: ${domPath}`);

  // Run moon fmt
  console.log("Running moon fmt...");
  try {
    execSync("moon fmt", { cwd: rootDir, stdio: "inherit" });
    console.log("Formatted successfully");
  } catch (e) {
    console.error("moon fmt failed:", e);
    process.exit(1);
  }

  console.log("Done!");
}

main();
