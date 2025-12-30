/**
 * Development Mode CSS Runtime
 *
 * Provides runtime CSS injection for development mode.
 * In production, this module should NOT be included.
 *
 * Features:
 * - Dynamic CSS injection when rules are missing
 * - Warning mechanism for missing CSS rules
 * - Can be used as a fallback for hot-reload scenarios
 */

// =============================================================================
// Types
// =============================================================================

export interface CssRuntimeOptions {
  /** Warn in console when generating CSS at runtime (default: true) */
  warnOnGenerate?: boolean;
  /** Style element ID (default: "luna-dev-css") */
  styleId?: string;
  /** Whether to log each rule generation (default: false) */
  verbose?: boolean;
}

export interface CssRuntimeState {
  /** Generated CSS rules */
  rules: Map<string, string>;
  /** Style element for injection */
  styleEl: HTMLStyleElement | null;
  /** Whether initialized */
  initialized: boolean;
}

// =============================================================================
// DJB2 Hash (must match registry.mbt and extract.ts)
// =============================================================================

function djb2Hash(s: string): number {
  let hash = 5381;
  for (let i = 0; i < s.length; i++) {
    const c = s.charCodeAt(i);
    hash = ((hash << 5) + hash + c) >>> 0;
  }
  return hash;
}

function toBase36(n: number): string {
  const chars = "0123456789abcdefghijklmnopqrstuvwxyz";
  n = n & 0xffffff;
  if (n === 0) return "0";
  let result = "";
  while (n > 0) {
    result = chars[n % 36] + result;
    n = Math.floor(n / 36);
  }
  return result;
}

function hashClassName(decl: string): string {
  const hash = djb2Hash(decl);
  return "_" + toBase36(hash);
}

// =============================================================================
// Runtime State
// =============================================================================

const state: CssRuntimeState = {
  rules: new Map(),
  styleEl: null,
  initialized: false,
};

let options: CssRuntimeOptions = {
  warnOnGenerate: true,
  styleId: "luna-dev-css",
  verbose: false,
};

// =============================================================================
// Core Functions
// =============================================================================

/**
 * Initialize the CSS runtime
 */
export function initCssRuntime(opts: CssRuntimeOptions = {}): void {
  options = { ...options, ...opts };

  if (typeof document === "undefined") {
    // SSR mode - no-op
    return;
  }

  if (state.initialized) {
    return;
  }

  // Check if style element already exists
  state.styleEl = document.getElementById(options.styleId!) as HTMLStyleElement;
  if (!state.styleEl) {
    state.styleEl = document.createElement("style");
    state.styleEl.id = options.styleId!;
    state.styleEl.setAttribute("data-luna-dev", "true");
    document.head.appendChild(state.styleEl);
  }

  state.initialized = true;

  if (options.verbose) {
    console.log("[luna-css] Runtime initialized");
  }
}

/**
 * Check if a CSS class exists in stylesheets
 */
export function hasClass(className: string): boolean {
  if (typeof document === "undefined") {
    return true; // Assume exists in SSR
  }

  // Check our generated rules first
  if (state.rules.has(className)) {
    return true;
  }

  // Check all stylesheets
  for (const sheet of document.styleSheets) {
    try {
      const rules = (sheet as CSSStyleSheet).cssRules;
      for (const rule of rules) {
        if (rule instanceof CSSStyleRule) {
          if (rule.selectorText === `.${className}`) {
            return true;
          }
        }
      }
    } catch {
      // Cross-origin stylesheet, skip
    }
  }

  return false;
}

/**
 * Generate CSS for a property:value declaration
 * Returns the class name
 */
export function css(property: string, value: string): string {
  const decl = `${property}:${value}`;
  const className = hashClassName(decl);

  if (!hasClass(className)) {
    injectRule(className, decl);
  }

  return className;
}

/**
 * Generate CSS for multiple property:value pairs
 * Returns space-separated class names
 */
export function styles(pairs: [string, string][]): string {
  return pairs.map(([p, v]) => css(p, v)).join(" ");
}

/**
 * Generate CSS for pseudo-class
 */
export function on(pseudo: string, property: string, value: string): string {
  const key = `${pseudo}:${property}:${value}`;
  const className = hashClassName(key);

  if (!hasClass(className)) {
    injectPseudoRule(className, pseudo, property, value);
  }

  return className;
}

/**
 * Hover shorthand
 */
export function hover(property: string, value: string): string {
  return on(":hover", property, value);
}

/**
 * Focus shorthand
 */
export function focus(property: string, value: string): string {
  return on(":focus", property, value);
}

/**
 * Active shorthand
 */
export function active(property: string, value: string): string {
  return on(":active", property, value);
}

/**
 * Media query CSS generation
 */
export function media(condition: string, property: string, value: string): string {
  const key = `@media(${condition}):${property}:${value}`;
  const className = hashClassName(key);

  if (!hasClass(className)) {
    injectMediaRule(className, condition, property, value);
  }

  return className;
}

/**
 * Responsive breakpoint shortcuts
 */
export const at_sm = (p: string, v: string) => media("min-width:640px", p, v);
export const at_md = (p: string, v: string) => media("min-width:768px", p, v);
export const at_lg = (p: string, v: string) => media("min-width:1024px", p, v);
export const at_xl = (p: string, v: string) => media("min-width:1280px", p, v);
export const dark = (p: string, v: string) =>
  media("prefers-color-scheme:dark", p, v);

// =============================================================================
// Internal Injection
// =============================================================================

function injectRule(className: string, decl: string): void {
  if (!state.initialized) {
    initCssRuntime();
  }

  const rule = `.${className}{${decl}}`;
  state.rules.set(className, rule);

  if (state.styleEl) {
    state.styleEl.textContent += rule;
  }

  if (options.warnOnGenerate) {
    console.warn(
      `[luna-css] Generated at runtime: .${className} { ${decl} }`,
      "\n  → Consider running 'luna css extract' to pre-generate CSS"
    );
  } else if (options.verbose) {
    console.log(`[luna-css] ${rule}`);
  }
}

function injectPseudoRule(
  className: string,
  pseudo: string,
  property: string,
  value: string
): void {
  if (!state.initialized) {
    initCssRuntime();
  }

  const rule = `.${className}${pseudo}{${property}:${value}}`;
  state.rules.set(className, rule);

  if (state.styleEl) {
    state.styleEl.textContent += rule;
  }

  if (options.warnOnGenerate) {
    console.warn(
      `[luna-css] Generated at runtime: .${className}${pseudo} { ${property}: ${value} }`,
      "\n  → Consider running 'luna css extract' to pre-generate CSS"
    );
  } else if (options.verbose) {
    console.log(`[luna-css] ${rule}`);
  }
}

function injectMediaRule(
  className: string,
  condition: string,
  property: string,
  value: string
): void {
  if (!state.initialized) {
    initCssRuntime();
  }

  const rule = `@media(${condition}){.${className}{${property}:${value}}}`;
  state.rules.set(className, rule);

  if (state.styleEl) {
    state.styleEl.textContent += rule;
  }

  if (options.warnOnGenerate) {
    console.warn(
      `[luna-css] Generated at runtime: @media(${condition}) { .${className} { ${property}: ${value} } }`,
      "\n  → Consider running 'luna css extract' to pre-generate CSS"
    );
  } else if (options.verbose) {
    console.log(`[luna-css] ${rule}`);
  }
}

// =============================================================================
// Utility Functions
// =============================================================================

/**
 * Get all generated CSS as a string
 */
export function getGeneratedCss(): string {
  return Array.from(state.rules.values()).join("");
}

/**
 * Get count of generated rules
 */
export function getGeneratedCount(): number {
  return state.rules.size;
}

/**
 * Reset the runtime state (for testing)
 */
export function resetRuntime(): void {
  state.rules.clear();
  if (state.styleEl) {
    state.styleEl.textContent = "";
  }
  state.initialized = false;
}

/**
 * Combine multiple class names
 */
export function combine(classes: string[]): string {
  return classes.filter(Boolean).join(" ");
}
