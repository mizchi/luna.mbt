#!/usr/bin/env node
/**
 * Bundle script for standalone Web Component deployment
 * Outputs a single JS file with all dependencies inlined
 */

import { build } from 'esbuild';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(__dirname, '..');
const BUILD_OUT = resolve(ROOT, 'dist');
const MOONBIT_OUT = resolve(ROOT, '_build/js/release/build');

// Load configuration from stella.config.json
function loadConfig() {
  const configPath = resolve(ROOT, 'stella.config.json');
  if (!existsSync(configPath)) {
    console.error('Error: stella.config.json not found');
    process.exit(1);
  }

  const raw = JSON.parse(readFileSync(configPath, 'utf-8'));
  const tag = raw.tag;

  // Derive class name from tag (x-counter -> XCounter)
  const className = tag
    .split('-')
    .map(part => part.charAt(0).toUpperCase() + part.slice(1))
    .join('');

  // Map attribute types for TypeScript
  const typeMap = {
    int: { tsType: 'number | string' },
    float: { tsType: 'number | string' },
    string: { tsType: 'string' },
    bool: { tsType: 'boolean' },
  };

  const attributes = raw.attributes.map(attr => ({
    name: attr.name,
    type: attr.type,
    tsType: typeMap[attr.type]?.tsType || 'string',
    default: attr.default,
  }));

  const events = raw.events || [];

  return {
    tag,
    className,
    // publicPath is only used in embed snippets, not for local preview
    publicPath: raw.publicPath,
    attributes,
    events,
    // Slot support
    slot: raw.slot || false,
    // SSR template generation
    ssr: raw.ssr || { enabled: false },
    // Loader generation
    loader: raw.loader || { enabled: false },
    // Iframe embed generation
    iframe: raw.iframe || { enabled: false, resizable: true },
    // Demo page generation settings
    demo: raw.demo || { enabled: false },
    // CORS settings
    cors: raw.cors || { allowedOrigins: [] },
    outputs: {
      autoRegister: `${tag}.js`,
      define: `${tag}-define.js`,
      loadable: `${tag}-loadable.js`,
      types: `${tag}.d.ts`,
      reactTypes: `${tag}.react.d.ts`,
      loader: 'loader.js',
      iframe: `${tag}-iframe.html`,
      iframeHelper: `${tag}-iframe.js`,
    },
  };
}

const CONFIG = loadConfig();

async function main() {
  console.log(`Bundling <${CONFIG.tag}>...`);

  const TMP = resolve(BUILD_OUT, '.tmp');
  mkdirSync(BUILD_OUT, { recursive: true });
  mkdirSync(TMP, { recursive: true });

  // Plugin to resolve the MoonBit module and runtime
  const moonbitPlugin = {
    name: 'moonbit-resolve',
    setup(build) {
      build.onResolve({ filter: /\.mbt\.js$/ }, () => ({
        path: resolve(MOONBIT_OUT, 'stella-component.js'),
      }));
      build.onResolve({ filter: /^@mizchi\/luna-wcr$/ }, () => ({
        path: resolve(ROOT, '../../js/wcr/dist/index.js'),
      }));
    },
  };

  // Read the generated wrapper (from stella CLI)
  const stellaOutput = resolve(TMP, `${CONFIG.tag}-wrapper.js`);
  const wrapperCode = readFileSync(stellaOutput, 'utf-8');

  // Helper to bundle a variant
  async function bundleVariant(name, entryCode, outputFile) {
    const entryPath = resolve(TMP, `${CONFIG.tag}-${name}.js`);
    writeFileSync(entryPath, entryCode);
    const result = await build({
      entryPoints: [entryPath],
      bundle: true,
      minify: true,
      format: 'esm',
      target: 'es2022',
      write: false,
      plugins: [moonbitPlugin],
    });
    const code = result.outputFiles[0].text;
    writeFileSync(resolve(BUILD_OUT, outputFile), code);
    console.log(`  ${outputFile} (${(code.length / 1024).toFixed(1)} KB)`);
  }

  // 1. Bundle all JS variants
  await bundleVariant('auto', wrapperCode, CONFIG.outputs.autoRegister);
  await bundleVariant('define', generateDefineVariant(wrapperCode, CONFIG.tag), CONFIG.outputs.define);
  await bundleVariant('loadable', generateLoadableVariant(wrapperCode, CONFIG.tag), CONFIG.outputs.loadable);

  // 2. Generate TypeScript declarations
  writeFileSync(resolve(BUILD_OUT, CONFIG.outputs.types), generateTypes(CONFIG));
  console.log(`  ${CONFIG.outputs.types}`);

  writeFileSync(resolve(BUILD_OUT, CONFIG.outputs.reactTypes), generateReactTypes(CONFIG));
  console.log(`  ${CONFIG.outputs.reactTypes}`);

  // 3. Generate embed snippet (always)
  writeFileSync(resolve(BUILD_OUT, 'embed.html'), generateEmbedSnippet(CONFIG));
  console.log(`  embed.html`);

  // 4. Generate CORS headers file (for Cloudflare Pages, Netlify, etc.)
  if (CONFIG.cors.allowedOrigins.length > 0) {
    const headersContent = generateHeaders(CONFIG);
    writeFileSync(resolve(BUILD_OUT, '_headers'), headersContent);
    console.log(`  _headers`);
  }

  // 5. Generate loader (if enabled)
  if (CONFIG.loader.enabled) {
    const loaderCode = generateLoader(CONFIG);
    writeFileSync(resolve(BUILD_OUT, CONFIG.outputs.loader), loaderCode);
    console.log(`  ${CONFIG.outputs.loader}`);
  }

  // 6. Generate iframe embed (if enabled)
  if (CONFIG.iframe.enabled) {
    const iframeHtml = generateIframeHtml(CONFIG);
    writeFileSync(resolve(BUILD_OUT, CONFIG.outputs.iframe), iframeHtml);
    console.log(`  ${CONFIG.outputs.iframe}`);

    const iframeHelper = generateIframeHelper(CONFIG);
    writeFileSync(resolve(BUILD_OUT, CONFIG.outputs.iframeHelper), iframeHelper);
    console.log(`  ${CONFIG.outputs.iframeHelper}`);
  }

  // 7. Generate demo pages (if enabled)
  if (CONFIG.demo.enabled) {
    writeFileSync(resolve(BUILD_OUT, 'index.html'), generateDemoPage(CONFIG));
    console.log(`  index.html`);

    writeFileSync(resolve(BUILD_OUT, 'examples.html'), generateExamples(CONFIG));
    console.log(`  examples.html`);
  }

  // 8. Generate loader test page (for testing loader behavior without preloaded component)
  writeFileSync(resolve(BUILD_OUT, 'loader-test.html'), generateLoaderTestPage(CONFIG));
  console.log(`  loader-test.html`);

  console.log(`\nOutput: dist/`);
  console.log(`Test locally: npx serve dist -p 3600`);
}

// Generate define variant - exports class without registration
function generateDefineVariant(originalCode, tag) {
  // Extract the class name from the tag (x-counter -> XCounter)
  const className = tag
    .split('-')
    .map(part => part.charAt(0).toUpperCase() + part.slice(1))
    .join('');

  // Remove the customElements.define line and export the class
  const withoutDefine = originalCode.replace(
    /customElements\.define\([^)]+\);?\s*$/,
    ''
  );

  return `${withoutDefine}
export { ${className} as default, ${className} };
export const tagName = '${tag}';
export function register(name = '${tag}') {
  if (!customElements.get(name)) {
    customElements.define(name, ${className});
  }
  return ${className};
}
`;
}

// Generate loadable variant - for island/loader pattern with hydration support
function generateLoadableVariant(originalCode, tag) {
  const className = tag
    .split('-')
    .map(part => part.charAt(0).toUpperCase() + part.slice(1))
    .join('');

  const withoutDefine = originalCode.replace(
    /customElements\.define\([^)]+\);?\s*$/,
    ''
  );

  return `${withoutDefine}
export { ${className} as default, ${className} };
export const tagName = '${tag}';

// Hydrate existing declarative shadow DOM
export function hydrate(root = document) {
  const elements = root.querySelectorAll('${tag}');
  for (const el of elements) {
    // Trigger hydration by upgrading the element
    if (!customElements.get('${tag}')) {
      customElements.define('${tag}', ${className});
    }
  }
  return elements.length;
}

// Register and optionally hydrate
export function load(options = {}) {
  const { hydrate: shouldHydrate = true, root = document } = options;
  if (!customElements.get('${tag}')) {
    customElements.define('${tag}', ${className});
  }
  if (shouldHydrate) {
    return hydrate(root);
  }
  return 0;
}
`;
}

// Generate loader script for auto-loading components
function generateLoader(config) {
  const { tag, publicPath } = config;

  // For now, single component loader
  // TODO: Support manifest.json for multiple components
  return `/**
 * Stella Component Loader
 * Auto-loads Web Components when detected in DOM
 * Generated by Stella
 */
(function() {
  'use strict';

  // Allow overriding BASE_URL via window.STELLA_BASE_URL for local testing
  const BASE_URL = window.STELLA_BASE_URL || '${publicPath}';

  // Registry of known components (use auto-register variant for automatic setup)
  const COMPONENTS = {
    '${tag}': '${tag}.js'
  };

  // Track loading state
  const loading = new Set();
  const loaded = new Set();

  // Load a component script
  async function loadComponent(tag) {
    if (loaded.has(tag) || loading.has(tag)) return;
    if (!COMPONENTS[tag]) return;

    loading.add(tag);

    try {
      const script = document.createElement('script');
      script.type = 'module';
      script.src = BASE_URL + '/' + COMPONENTS[tag];

      await new Promise((resolve, reject) => {
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
      });

      loaded.add(tag);
    } catch (e) {
      console.error('[Stella] Failed to load:', tag, e);
    } finally {
      loading.delete(tag);
    }
  }

  // Check if tag is a custom element (contains hyphen)
  function isCustomElement(tag) {
    return tag.includes('-');
  }

  // Scan DOM for unregistered custom elements
  function scan(root = document) {
    const elements = root.querySelectorAll('*');
    const tags = new Set();

    for (const el of elements) {
      const tag = el.tagName.toLowerCase();
      if (isCustomElement(tag) && !customElements.get(tag)) {
        tags.add(tag);
      }
    }

    return tags;
  }

  // Initial scan and load
  function init() {
    const tags = scan();
    for (const tag of tags) {
      loadComponent(tag);
    }
  }

  // Observe DOM for new elements
  function observe() {
    const observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        for (const node of mutation.addedNodes) {
          if (node.nodeType === Node.ELEMENT_NODE) {
            const tag = node.tagName.toLowerCase();
            if (isCustomElement(tag) && !customElements.get(tag)) {
              loadComponent(tag);
            }
            // Also scan children
            const childTags = scan(node);
            for (const t of childTags) {
              loadComponent(t);
            }
          }
        }
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
      init();
      observe();
    });
  } else {
    init();
    observe();
  }

  // Expose API
  window.Stella = {
    load: loadComponent,
    loaded: () => [...loaded],
    components: () => Object.keys(COMPONENTS)
  };
})();
`;
}

// Generate iframe HTML page
function generateIframeHtml(config) {
  const { tag, publicPath, attributes, iframe } = config;

  const attrParams = attributes
    .map(a => `${a.name}: params.get('${a.name}')`)
    .join(',\n        ');

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; }
    body { display: flex; align-items: center; justify-content: center; }
    ${tag} { display: block; }
  </style>
</head>
<body>
  <${tag} id="component"></${tag}>
  <script type="module">
    import { load } from './${config.outputs.loadable}';

    // Parse URL params for initial attributes
    const params = new URLSearchParams(location.search);
    const el = document.getElementById('component');

    // Set initial attributes from URL
    for (const [key, value] of params) {
      if (value === 'true') {
        el.setAttribute(key, '');
      } else if (value !== 'false' && value !== '') {
        el.setAttribute(key, value);
      }
    }

    // Load and register the component
    load();

    // Listen for attribute updates from parent
    window.addEventListener('message', (e) => {
      if (e.data?.type === 'stella:setAttr') {
        const { name, value } = e.data;
        if (typeof value === 'boolean') {
          value ? el.setAttribute(name, '') : el.removeAttribute(name);
        } else {
          el.setAttribute(name, String(value));
        }
      }
    });

    // Forward events to parent
    el.addEventListener('change', (e) => {
      parent.postMessage({
        type: 'stella:event',
        tag: '${tag}',
        event: 'change',
        detail: e.detail
      }, '*');
    });

    ${iframe.resizable ? `
    // Auto-resize iframe
    const resizeObserver = new ResizeObserver(() => {
      parent.postMessage({
        type: 'stella:resize',
        tag: '${tag}',
        width: el.offsetWidth,
        height: el.offsetHeight
      }, '*');
    });
    resizeObserver.observe(el);
    ` : ''}

    // Notify parent that component is ready
    parent.postMessage({ type: 'stella:ready', tag: '${tag}' }, '*');
  </script>
</body>
</html>
`;
}

// Generate iframe helper script for parent page
function generateIframeHelper(config) {
  const { tag, publicPath, attributes } = config;

  const defaultAttrs = attributes
    .map(a => `${a.name}: ${JSON.stringify(a.default)}`)
    .join(', ');

  return `/**
 * Stella Iframe Helper
 * Embeds ${tag} as an iframe with postMessage communication
 * Generated by Stella
 */
(function() {
  'use strict';

  const BASE_URL = '${publicPath}';
  const TAG = '${tag}';

  class StellaIframe {
    constructor(container, options = {}) {
      this.container = typeof container === 'string'
        ? document.querySelector(container)
        : container;

      // Extract baseUrl from options if provided (for local testing)
      const { baseUrl, ...attrs } = options;
      this.baseUrl = baseUrl || BASE_URL;

      this.options = {
        ${defaultAttrs},
        ...attrs
      };

      this.iframe = null;
      this.ready = false;
      this.listeners = {};

      this._create();
    }

    _create() {
      // Build URL with initial attributes
      const params = new URLSearchParams();
      for (const [key, value] of Object.entries(this.options)) {
        if (typeof value === 'boolean') {
          if (value) params.set(key, 'true');
        } else {
          params.set(key, String(value));
        }
      }

      this.iframe = document.createElement('iframe');
      this.iframe.src = this.baseUrl + '/${config.outputs.iframe}?' + params.toString();
      this.iframe.style.border = 'none';
      this.iframe.style.width = '100%';
      this.iframe.style.height = 'auto';
      this.iframe.setAttribute('loading', 'lazy');

      // Listen for messages from iframe
      window.addEventListener('message', (e) => this._onMessage(e));

      this.container.appendChild(this.iframe);
    }

    _onMessage(e) {
      const data = e.data;
      if (!data?.type?.startsWith('stella:')) return;
      if (e.source !== this.iframe.contentWindow) return;

      switch (data.type) {
        case 'stella:ready':
          this.ready = true;
          this._emit('ready');
          break;
        case 'stella:event':
          this._emit(data.event, data.detail);
          break;
        case 'stella:resize':
          this.iframe.style.height = data.height + 'px';
          break;
      }
    }

    setAttr(name, value) {
      this.iframe.contentWindow.postMessage({
        type: 'stella:setAttr',
        name,
        value
      }, '*');
    }

    on(event, callback) {
      if (!this.listeners[event]) {
        this.listeners[event] = [];
      }
      this.listeners[event].push(callback);
      return () => this.off(event, callback);
    }

    off(event, callback) {
      if (!this.listeners[event]) return;
      this.listeners[event] = this.listeners[event].filter(cb => cb !== callback);
    }

    _emit(event, detail) {
      if (!this.listeners[event]) return;
      for (const cb of this.listeners[event]) {
        cb(detail);
      }
    }

    destroy() {
      this.iframe.remove();
      this.listeners = {};
    }
  }

  // Factory function
  window.createStellaIframe = (container, options) => new StellaIframe(container, options);

  // Auto-init for declarative usage
  document.querySelectorAll('[data-stella-iframe="${tag}"]').forEach(el => {
    const options = { ...el.dataset };
    delete options.stellaIframe;
    new StellaIframe(el, options);
  });
})();
`;
}

// Generate CORS headers file (Cloudflare Pages / Netlify format)
function generateHeaders(config) {
  const origins = config.cors.allowedOrigins;
  const allowOrigin = origins.includes('*') ? '*' : origins.join(', ');

  return `# CORS headers for Web Component distribution
# Generated by Stella

/*.js
  Access-Control-Allow-Origin: ${allowOrigin}
  Access-Control-Allow-Methods: GET, OPTIONS
  Access-Control-Allow-Headers: Content-Type
  Cache-Control: public, max-age=31536000, immutable

/*.d.ts
  Access-Control-Allow-Origin: ${allowOrigin}
  Content-Type: text/plain; charset=utf-8
  Cache-Control: public, max-age=31536000, immutable
`;
}

// Generate TypeScript declarations for the component
function generateTypes(config) {
  const { tag, className, attributes } = config;

  const propsInterface = attributes
    .map(attr => `  ${attr.name}?: ${attr.tsType};`)
    .join('\n');

  return `/**
 * TypeScript declarations for <${tag}>
 * Generated by Stella
 */

export interface ${className}Props {
${propsInterface}
}

export interface ${className}EventMap {
  change: CustomEvent<{ value: number }>;
}

export declare class ${className} extends HTMLElement {
  static readonly observedAttributes: readonly string[];
  connectedCallback(): void;
  disconnectedCallback(): void;
  attributeChangedCallback(name: string, oldValue: string | null, newValue: string | null): void;
  addEventListener<K extends keyof ${className}EventMap>(
    type: K,
    listener: (this: ${className}, ev: ${className}EventMap[K]) => void,
    options?: boolean | AddEventListenerOptions
  ): void;
}

export declare const tagName: '${tag}';
export declare function register(name?: string): typeof ${className};

// For loadable variant
export declare function hydrate(root?: Document | Element): number;
export declare function load(options?: { hydrate?: boolean; root?: Document | Element }): number;

export default ${className};
`;
}

// Generate React-specific type declarations
function generateReactTypes(config) {
  const { tag, className, attributes } = config;

  const reactProps = attributes
    .map(attr => `      ${attr.name}?: ${attr.tsType};`)
    .join('\n');

  return `/**
 * React type declarations for <${tag}>
 * Generated by Stella
 *
 * Usage:
 *   // Add to your global.d.ts or types.d.ts
 *   /// <reference path="./x-counter.react.d.ts" />
 *
 *   // Or import directly in your component
 *   import type {} from './x-counter.react.d.ts';
 */

import type { DetailedHTMLProps, HTMLAttributes } from 'react';

declare global {
  namespace JSX {
    interface IntrinsicElements {
      '${tag}': DetailedHTMLProps<
        HTMLAttributes<HTMLElement> & {
${reactProps}
          // Event handlers
          onChange?: (event: CustomEvent<{ value: number }>) => void;
        },
        HTMLElement
      >;
    }
  }
}

// Re-export component types for convenience
export type { ${className}Props, ${className}EventMap, ${className} } from './${config.outputs.types.replace('.d.ts', '')}';
`;
}

function generateEmbedSnippet(config) {
  return `<!--
  Embed Snippets for ${config.tag}
  Multiple variants available - choose based on your use case.
-->

<!-- ============================================================ -->
<!-- VARIANT 0: Loader (Recommended for Multiple Components) -->
<!-- ============================================================ -->
<!-- Include once - auto-detects and loads components as needed -->
<script src="${config.publicPath}/loader.js"></script>

<!-- Just use components - they load automatically -->
<${config.tag}></${config.tag}>

<!-- Loader API -->
<script>
  // Check loaded components
  console.log(Stella.loaded());

  // Manually load a component
  Stella.load('${config.tag}');

  // List available components
  console.log(Stella.components());
</script>


<!-- ============================================================ -->
<!-- VARIANT 0.5: Iframe (Sandboxed Embed) -->
<!-- ============================================================ -->
<!-- Include the helper script -->
<script src="${config.publicPath}/${config.outputs.iframeHelper}"></script>

<!-- Declarative usage -->
<div data-stella-iframe="${config.tag}" data-initial="10" data-label="Score"></div>

<!-- Programmatic usage -->
<div id="counter-container"></div>
<script>
  const counter = createStellaIframe('#counter-container', {
    initial: 10,
    label: 'Score'
  });

  // Listen for events
  counter.on('change', (detail) => {
    console.log('Value:', detail.value);
  });

  // Update attributes
  counter.setAttr('label', 'New Label');
</script>


<!-- ============================================================ -->
<!-- VARIANT 1: Auto-Register (Single Component) -->
<!-- ============================================================ -->
<!-- Just add the script - custom element is registered automatically -->
<script async src="${config.publicPath}/${config.outputs.autoRegister}"></script>
<${config.tag}></${config.tag}>


<!-- ============================================================ -->
<!-- VARIANT 2: Define (ESM, Manual Registration) -->
<!-- ============================================================ -->
<!-- Import as ESM module - you control when/how to register -->
<script type="module">
  import { register, XCounter } from '${config.publicPath}/${config.outputs.define}';

  // Option A: Register with default tag name
  register();

  // Option B: Register with custom tag name
  register('my-custom-counter');

  // Option C: Use the class directly
  customElements.define('another-counter', XCounter);
</script>


<!-- ============================================================ -->
<!-- VARIANT 3: Loadable (SSR + Hydration) -->
<!-- ============================================================ -->
<!-- For server-rendered content with declarative shadow DOM -->
<script type="module">
  import { load, hydrate } from '${config.publicPath}/${config.outputs.loadable}';

  // Register and hydrate all existing elements
  const count = load();
  console.log(\`Hydrated \${count} elements\`);

  // Or hydrate a specific container
  hydrate(document.getElementById('my-container'));
</script>


<!-- ============================================================ -->
<!-- USAGE EXAMPLES (works with any variant) -->
<!-- ============================================================ -->

<!-- Basic -->
<${config.tag}></${config.tag}>

<!-- With Attributes -->
<${config.tag} initial="10" label="Score"></${config.tag}>

<!-- Disabled State -->
<${config.tag} initial="5" label="Fixed" disabled></${config.tag}>

<!-- Listen to Change Events -->
<${config.tag} id="my-counter"></${config.tag}>
<script>
  document.getElementById('my-counter').addEventListener('change', (e) => {
    console.log('Counter value:', e.detail.value);
  });
</script>
`;
}

function generateDemoPage(config) {
  const title = config.demo.title || `${config.tag} - Web Component Demo`;
  const description = config.demo.description || `A Web Component built with MoonBit + Stella`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: system-ui, -apple-system, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
      line-height: 1.6;
      color: #212529;
    }
    h1 { color: #0d6efd; margin-bottom: 0.5rem; }
    .subtitle { color: #6c757d; margin-bottom: 2rem; }
    section {
      margin-bottom: 2rem;
      padding: 1.5rem;
      background: #fff;
      border: 1px solid #dee2e6;
      border-radius: 0.5rem;
    }
    h2 { margin-top: 0; color: #495057; }
    .demo-row {
      display: flex;
      align-items: center;
      gap: 1rem;
      margin: 1rem 0;
    }
    pre {
      background: #f8f9fa;
      padding: 1rem;
      border-radius: 0.375rem;
      overflow-x: auto;
      font-size: 0.875rem;
    }
    code { font-family: 'SF Mono', Consolas, monospace; }
    .controls {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
      margin-top: 1rem;
    }
    .controls button {
      padding: 0.5rem 1rem;
      font-size: 0.875rem;
      background: #e9ecef;
      border: 1px solid #ced4da;
      border-radius: 0.375rem;
      cursor: pointer;
    }
    .controls button:hover { background: #dee2e6; }
    #event-log {
      font-family: monospace;
      font-size: 0.875rem;
      color: #198754;
      min-height: 1.5rem;
    }
    footer {
      margin-top: 3rem;
      padding-top: 1rem;
      border-top: 1px solid #dee2e6;
      color: #6c757d;
      font-size: 0.875rem;
    }
  </style>
</head>
<body>
  <h1>&lt;${config.tag}&gt;</h1>
  <p class="subtitle">${description}</p>

  <section>
    <h2>Basic Usage</h2>
    <div class="demo-row">
      <${config.tag}></${config.tag}>
    </div>
    <pre><code>&lt;${config.tag}&gt;&lt;/${config.tag}&gt;</code></pre>
  </section>

  <section>
    <h2>With Attributes</h2>
    <div class="demo-row">
      <${config.tag} initial="42" label="Score"></${config.tag}>
      <${config.tag} initial="100" label="Points"></${config.tag}>
    </div>
    <pre><code>&lt;${config.tag} initial="42" label="Score"&gt;&lt;/${config.tag}&gt;
&lt;${config.tag} initial="100" label="Points"&gt;&lt;/${config.tag}&gt;</code></pre>
  </section>

  <section>
    <h2>Disabled State</h2>
    <div class="demo-row">
      <${config.tag} initial="10" label="Fixed" disabled></${config.tag}>
    </div>
    <pre><code>&lt;${config.tag} initial="10" label="Fixed" disabled&gt;&lt;/${config.tag}&gt;</code></pre>
  </section>

  <section>
    <h2>Dynamic Control</h2>
    <div class="demo-row">
      <${config.tag} id="dynamic" initial="0" label="Dynamic"></${config.tag}>
    </div>
    <div class="controls">
      <button onclick="document.getElementById('dynamic').setAttribute('initial', '50')">
        Set initial=50
      </button>
      <button onclick="document.getElementById('dynamic').setAttribute('label', 'Updated')">
        Set label="Updated"
      </button>
      <button onclick="document.getElementById('dynamic').toggleAttribute('disabled')">
        Toggle disabled
      </button>
    </div>
  </section>

  <section>
    <h2>Event Handling</h2>
    <div class="demo-row">
      <${config.tag} id="evented" initial="0" label="Evented"></${config.tag}>
    </div>
    <div id="event-log">Click buttons to see events...</div>
    <pre><code>element.addEventListener('change', (e) => {
  console.log('Value:', e.detail.value);
});</code></pre>
  </section>

  <footer>
    <p>Built with <a href="https://github.com/aspect/luna">Luna</a> + <a href="https://www.moonbitlang.com/">MoonBit</a></p>
  </footer>

  <script type="module" src="./${config.outputs.autoRegister}"></script>
  <script>
    document.getElementById('evented').addEventListener('change', (e) => {
      document.getElementById('event-log').textContent =
        'change event: value = ' + e.detail.value;
    });
  </script>
</body>
</html>
`;
}

function generateExamples(config) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${config.tag} - Embedding Examples</title>
  <style>
    body {
      font-family: system-ui, -apple-system, sans-serif;
      max-width: 900px;
      margin: 0 auto;
      padding: 2rem;
      line-height: 1.6;
    }
    h1 { color: #0d6efd; }
    h2 { margin-top: 2rem; color: #495057; }
    pre {
      background: #1e1e1e;
      color: #d4d4d4;
      padding: 1rem;
      border-radius: 0.5rem;
      overflow-x: auto;
    }
    code { font-family: 'SF Mono', Consolas, monospace; }
    .tag { color: #569cd6; }
    .attr { color: #9cdcfe; }
    .str { color: #ce9178; }
    .cmt { color: #6a9955; }
    .copy-btn {
      float: right;
      padding: 0.25rem 0.5rem;
      font-size: 0.75rem;
      background: #3c3c3c;
      color: #fff;
      border: none;
      border-radius: 0.25rem;
      cursor: pointer;
    }
    .copy-btn:hover { background: #4c4c4c; }
  </style>
</head>
<body>
  <h1>Embedding &lt;${config.tag}&gt;</h1>
  <p>Copy these snippets to embed the counter component in your website.</p>

  <h2>1. Script Tag (Recommended)</h2>
  <p>Add this script tag to your HTML. The component will be registered automatically.</p>
  <pre><button class="copy-btn" onclick="copyCode(this)">Copy</button><code><span class="cmt">&lt;!-- Add to &lt;head&gt; or end of &lt;body&gt; --&gt;</span>
<span class="tag">&lt;script</span> <span class="attr">async</span> <span class="attr">src</span>=<span class="str">"${config.publicPath}/${config.outputs.autoRegister}"</span><span class="tag">&gt;&lt;/script&gt;</span></code></pre>

  <h2>2. Basic Usage</h2>
  <pre><button class="copy-btn" onclick="copyCode(this)">Copy</button><code><span class="tag">&lt;${config.tag}&gt;&lt;/${config.tag}&gt;</span></code></pre>

  <h2>3. With Attributes</h2>
  <pre><button class="copy-btn" onclick="copyCode(this)">Copy</button><code><span class="cmt">&lt;!-- Set initial value and label --&gt;</span>
<span class="tag">&lt;${config.tag}</span> <span class="attr">initial</span>=<span class="str">"10"</span> <span class="attr">label</span>=<span class="str">"Score"</span><span class="tag">&gt;&lt;/${config.tag}&gt;</span>

<span class="cmt">&lt;!-- Disabled state --&gt;</span>
<span class="tag">&lt;${config.tag}</span> <span class="attr">initial</span>=<span class="str">"5"</span> <span class="attr">disabled</span><span class="tag">&gt;&lt;/${config.tag}&gt;</span></code></pre>

  <h2>4. Listen to Events</h2>
  <pre><button class="copy-btn" onclick="copyCode(this)">Copy</button><code><span class="tag">&lt;${config.tag}</span> <span class="attr">id</span>=<span class="str">"my-counter"</span><span class="tag">&gt;&lt;/${config.tag}&gt;</span>

<span class="tag">&lt;script&gt;</span>
  document.getElementById('my-counter')
    .addEventListener('change', (e) => {
      console.log('New value:', e.detail.value);
    });
<span class="tag">&lt;/script&gt;</span></code></pre>

  <h2>5. Dynamic Control via JavaScript</h2>
  <pre><button class="copy-btn" onclick="copyCode(this)">Copy</button><code><span class="tag">&lt;${config.tag}</span> <span class="attr">id</span>=<span class="str">"counter"</span><span class="tag">&gt;&lt;/${config.tag}&gt;</span>

<span class="tag">&lt;script&gt;</span>
  const counter = document.getElementById('counter');

  <span class="cmt">// Change initial value</span>
  counter.setAttribute('initial', '100');

  <span class="cmt">// Change label</span>
  counter.setAttribute('label', 'Points');

  <span class="cmt">// Disable/Enable</span>
  counter.setAttribute('disabled', '');
  counter.removeAttribute('disabled');
<span class="tag">&lt;/script&gt;</span></code></pre>

  <h2>6. Complete Example</h2>
  <pre><button class="copy-btn" onclick="copyCode(this)">Copy</button><code><span class="tag">&lt;!DOCTYPE html&gt;</span>
<span class="tag">&lt;html</span> <span class="attr">lang</span>=<span class="str">"en"</span><span class="tag">&gt;</span>
<span class="tag">&lt;head&gt;</span>
  <span class="tag">&lt;meta</span> <span class="attr">charset</span>=<span class="str">"UTF-8"</span><span class="tag">&gt;</span>
  <span class="tag">&lt;title&gt;</span>Counter Demo<span class="tag">&lt;/title&gt;</span>
  <span class="tag">&lt;script</span> <span class="attr">async</span> <span class="attr">src</span>=<span class="str">"${config.publicPath}/${config.outputs.autoRegister}"</span><span class="tag">&gt;&lt;/script&gt;</span>
<span class="tag">&lt;/head&gt;</span>
<span class="tag">&lt;body&gt;</span>
  <span class="tag">&lt;h1&gt;</span>My Counter<span class="tag">&lt;/h1&gt;</span>
  <span class="tag">&lt;${config.tag}</span> <span class="attr">initial</span>=<span class="str">"0"</span> <span class="attr">label</span>=<span class="str">"Count"</span><span class="tag">&gt;&lt;/${config.tag}&gt;</span>
<span class="tag">&lt;/body&gt;</span>
<span class="tag">&lt;/html&gt;</span></code></pre>

  <script>
    function copyCode(btn) {
      const code = btn.parentElement.querySelector('code').textContent;
      navigator.clipboard.writeText(code);
      btn.textContent = 'Copied!';
      setTimeout(() => btn.textContent = 'Copy', 1500);
    }
  </script>
</body>
</html>
`;
}

// Generate loader test page (for testing loader without preloaded component)
function generateLoaderTestPage(config) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Loader Test</title>
</head>
<body>
  <h1>Loader Test Page</h1>
  <p>This page uses only the loader - component is not preloaded.</p>
  <div id="container"></div>
  <script>
    // For local testing
    window.STELLA_BASE_URL = window.location.origin;
  </script>
  <script src="./loader.js"></script>
</body>
</html>
`;
}

main().catch(console.error);
