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
import { join } from "path";

// =============================================================================
// Type Definitions
// =============================================================================

type AttrType = "string" | "bool";

interface ElementAttr {
  name: string;
  type: AttrType;
  htmlAttr?: string; // HTML attribute name if different from param name
}

interface ElementDef {
  tag: string;
  fnName?: string; // Function name if different from tag (e.g., main_ for main)
  description?: string;
  attrs?: ElementAttr[];
  hasChildren?: boolean; // default: true
  isVoid?: boolean; // self-closing element (img, br, hr, input, meta, link)
}

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
    attrs: [{ name: "disabled", type: "bool" }],
  },
  {
    tag: "input",
    description: "Create an input element",
    attrs: [
      { name: "type_", type: "string", htmlAttr: "type" },
      { name: "value", type: "string" },
      { name: "placeholder", type: "string" },
      { name: "disabled", type: "bool" },
    ],
    isVoid: true,
    hasChildren: false,
  },
  {
    tag: "textarea",
    description: "Create a textarea element",
    attrs: [
      { name: "placeholder", type: "string" },
      { name: "disabled", type: "bool" },
    ],
  },
  { tag: "form", description: "Create a form element" },
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
];

// Elements only for browser DOM (not server_dom)
const browserOnlyElements = new Set(["button", "input", "textarea", "form", "label"]);

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

  // Target-specific params
  if (opts.target === "dom") {
    params.push("on? : HandlerMap");
    params.push("ref_? : ElementRef");
    params.push("attrs? : Array[(String, Attr)]");
  } else {
    params.push("attrs? : Array[(String, @luna.Attr[Unit])]");
  }

  // Children (required, labeled)
  if (hasChildren) {
    if (opts.target === "dom") {
      params.push("children : Array[DomNode]");
    } else {
      params.push("children~ : Array[@luna.Node[Unit]]");
    }
  }

  // Build return type
  const returnType = opts.target === "dom" ? "DomNode" : "@luna.Node[Unit]";

  // Build function body
  const bodyLines: string[] = [];

  if (opts.target === "dom") {
    bodyLines.push("let props = build_props(id, class, style, on, ref_, attrs)");
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
      bodyLines.push(`match ${attr.name} {`);
      if (opts.target === "dom") {
        bodyLines.push(`  Some(true) => props.push(("${htmlAttr}", Static("true")))`);
      } else {
        bodyLines.push(`  Some(true) => props.push(("${htmlAttr}", static_attr("")))`);
      }
      bodyLines.push("  _ => ()");
      bodyLines.push("}");
    } else {
      bodyLines.push(`match ${attr.name} {`);
      if (opts.target === "dom") {
        bodyLines.push(`  Some(v) => props.push(("${htmlAttr}", Static(v)))`);
      } else {
        bodyLines.push(`  Some(v) => props.push(("${htmlAttr}", static_attr(v)))`);
      }
      bodyLines.push("  None => ()");
      bodyLines.push("}");
    }
  }

  // Handle special content attr for script/style/title (content becomes text child, not HTML attr)
  const hasContentAttr = elem.attrs?.some((a) => a.name === "content");

  if (hasContentAttr && contentAsTextChild && opts.target === "server_dom") {
    if (elem.tag === "style" || elem.tag === "title") {
      // style/title: content is required (positional param)
      bodyLines.push("create_element(\"" + elem.tag + '", props, [text(content)])');
    } else if (elem.tag === "script") {
      // script: content is optional, no children param
      bodyLines.push("let script_children : Array[@luna.Node[Unit]] = match content {");
      bodyLines.push("  Some(c) => [text(c)]");
      bodyLines.push("  None => []");
      bodyLines.push("}");
      bodyLines.push(`create_element("${elem.tag}", props, script_children)`);
    }
  } else {
    // Normal element creation - void elements don't have children
    const childrenArg = hasChildren ? "children" : "[]";
    bodyLines.push(`create_element("${elem.tag}", props, ${childrenArg})`);
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
  match id {
    Some(v) => result.push(("id", static_attr(v)))
    None => ()
  }
  match class {
    Some(v) => result.push(("class", static_attr(v)))
    None => ()
  }
  match style {
    Some(v) => result.push(("style", static_attr(v)))
    None => ()
  }
  match attrs {
    Some(extra) =>
      for attr in extra {
        result.push(attr)
      }
    None => ()
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
  @luna.vtext(content)
}

///|
/// Create a fragment (multiple nodes without wrapper)
pub fn fragment(children : Array[@luna.Node[Unit]]) -> @luna.Node[Unit] {
  @luna.vfragment(children)
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
/// JSX runtime: Fragment (returns children as-is wrapped in a container)
pub fn fragment(children : Array[DomNode]) -> DomNode {
  // Return a document fragment or first child
  // For simplicity, wrap in a span with no attributes
  // In production, this should return a proper fragment
  match children.length() {
    0 => create_element("span", [], [])
    1 => children[0]
    _ => create_element("span", [], children)
  }
}
`;
}

function main() {
  const rootDir = join(__dirname, "..");

  // Generate server_dom elements
  const serverDomPath = join(rootDir, "src/platform/server_dom/__generated.mbt");
  const serverDomContent = generateFile({ target: "server_dom" });
  writeFileSync(serverDomPath, serverDomContent);
  console.log(`Generated: ${serverDomPath}`);

  // Generate dom/element elements
  const domPath = join(rootDir, "src/platform/dom/element/__generated.mbt");
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
