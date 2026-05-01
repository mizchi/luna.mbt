/**
 * Sol Framework HTML Helpers for SSR
 *
 * Simple VNode structure for server-side rendering
 */

// ============================================================================
// VNode Types
// ============================================================================

export type VNode = ElementNode | string;

export interface ElementNode {
  tag: string;
  attrs: Record<string, string | boolean | number>;
  children: VNode[];
}

// ============================================================================
// Core Functions
// ============================================================================

/**
 * Create an element node
 */
export function h(
  tag: string,
  attrs: Record<string, string | boolean | number> | null,
  children: VNode[] = []
): ElementNode {
  return { tag, attrs: attrs || {}, children };
}

/**
 * Create a text node (just returns the string)
 */
export function text(s: string | number): string {
  return String(s);
}

/**
 * Create a fragment (array of nodes)
 */
export function fragment(children: VNode[]): VNode[] {
  return children;
}

// ============================================================================
// HTML Tag Helpers
// ============================================================================

// Block elements
export const div = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('div', attrs, children);
export const main = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('main', attrs, children);
export const section = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('section', attrs, children);
export const article = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('article', attrs, children);
export const header = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('header', attrs, children);
export const footer = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('footer', attrs, children);
export const nav = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('nav', attrs, children);
export const aside = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('aside', attrs, children);

// Headings
export const h1 = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('h1', attrs, children);
export const h2 = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('h2', attrs, children);
export const h3 = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('h3', attrs, children);
export const h4 = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('h4', attrs, children);
export const h5 = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('h5', attrs, children);
export const h6 = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('h6', attrs, children);

// Inline elements
export const span = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('span', attrs, children);
export const a = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('a', attrs, children);
export const strong = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('strong', attrs, children);
export const em = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('em', attrs, children);
export const code = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('code', attrs, children);
export const pre = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('pre', attrs, children);

// Lists
export const ul = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('ul', attrs, children);
export const ol = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('ol', attrs, children);
export const li = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('li', attrs, children);

// Form elements
export const form = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('form', attrs, children);
export const input = (attrs: Record<string, string | boolean | number> | null) => h('input', attrs, []);
export const textarea = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('textarea', attrs, children);
export const button = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('button', attrs, children);
export const label = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('label', attrs, children);
export const select = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('select', attrs, children);
export const option = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('option', attrs, children);

// Media
export const img = (attrs: Record<string, string | boolean | number> | null) => h('img', attrs, []);
export const video = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('video', attrs, children);
export const audio = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('audio', attrs, children);

// Table
export const table = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('table', attrs, children);
export const thead = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('thead', attrs, children);
export const tbody = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('tbody', attrs, children);
export const tr = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('tr', attrs, children);
export const th = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('th', attrs, children);
export const td = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('td', attrs, children);

// Other
export const p = (attrs: Record<string, string | boolean | number> | null, children: VNode[] = []) => h('p', attrs, children);
export const br = () => h('br', null, []);
export const hr = () => h('hr', null, []);

// ============================================================================
// Rendering
// ============================================================================

const VOID_ELEMENTS = new Set([
  'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input',
  'link', 'meta', 'param', 'source', 'track', 'wbr'
]);

/**
 * Escape HTML special characters
 */
export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/**
 * Render VNode to HTML string
 */
export function renderToString(node: VNode | VNode[]): string {
  if (Array.isArray(node)) {
    return node.map(renderToString).join('');
  }

  if (typeof node === 'string') {
    return escapeHtml(node);
  }

  const { tag, attrs, children } = node;

  // Handle raw HTML nodes
  if (tag === '__raw__') {
    return String(attrs.html || '');
  }

  // Build attributes string
  const attrStr = Object.entries(attrs)
    .filter(([_, v]) => v !== false && v !== null && v !== undefined)
    .map(([k, v]) => {
      if (v === true) return k;
      return `${k}="${escapeHtml(String(v))}"`;
    })
    .join(' ');

  const openTag = attrStr ? `<${tag} ${attrStr}>` : `<${tag}>`;

  // Void elements don't have closing tags
  if (VOID_ELEMENTS.has(tag)) {
    return openTag;
  }

  const childrenHtml = children.map(renderToString).join('');
  return `${openTag}${childrenHtml}</${tag}>`;
}

/**
 * Raw HTML (no escaping) - use with caution
 */
export function raw(html: string): VNode {
  // Return as a special object that renderToString will recognize
  return { tag: '__raw__', attrs: { html }, children: [] };
}

// Override renderToString to handle raw HTML
const originalRenderToString = renderToString;
export { originalRenderToString };
