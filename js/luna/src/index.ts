// @ts-nocheck
// Re-export from MoonBit build output (api_js)
// This file wraps MoonBit APIs to provide SolidJS-compatible interface

// Type definitions for SolidJS-compatible API
export type Accessor<T> = () => T;
export type Setter<T> = (value: T | ((prev: T) => T)) => void;
export type Signal<T> = [Accessor<T>, Setter<T>];

export interface ForProps<T> {
  each: Accessor<T[]> | T[];
  fallback?: any;
  children: (item: T, index: Accessor<number>) => any;
}

export interface ShowProps<T> {
  when: T | Accessor<T>;
  fallback?: any;
  children: any | ((item: T) => any);
}

export interface IndexProps<T> {
  each: Accessor<T[]> | T[];
  fallback?: any;
  children: (item: Accessor<T>, index: number) => any;
}

export interface Context<T> {
  id: number;
  default_value: () => T;
  providers: any[];
}

export interface ProviderProps<T> {
  context: Context<T>;
  value: T;
  children: any | (() => any);
}

export interface MatchProps<T> {
  when: T | Accessor<T>;
  children: any | ((item: T) => any);
}

export interface SwitchProps {
  fallback?: any;
  children: any[];
}

export interface PortalProps {
  mount?: Element | string;
  useShadow?: boolean;
  children: any | (() => any);
}

export interface ResourceAccessor<T> {
  (): T | undefined;
  loading: boolean;
  error: string | undefined;
  state: 'pending' | 'ready' | 'errored' | 'unresolved';
  latest: T | undefined;
}

export type SetStoreFunction<T> = (...args: any[]) => void;

import {
  // Signal API (internal)
  createSignal as _createSignal,
  get as _get,
  set as _set,
  update as _update,
  peek as _peek,
  subscribe as _subscribe,
  map as _map,
  createMemo as _createMemo,
  combine as _combine,
  effect as _effect,
  batchStart,
  batchEnd,
  runUntracked,
  batch,
  onCleanup,
  createRoot,
  getOwner,
  runWithOwner,
  hasOwner,
  onMount,
  // DOM API
  text,
  textDyn,
  render,
  mount,
  show,
  jsx,
  jsxs,
  Fragment,
  createElement,
  createElementNs,
  svgNs,
  mathmlNs,
  events,
  forEach,
  // Timer utilities
  debounced as _debounced,
  // Route definitions
  routePage,
  routePageTitled,
  routePageFull,
  createRouter,
  routerNavigate,
  routerReplace,
  routerGetPath,
  routerGetMatch,
  routerGetBase,
  // Context API
  createContext,
  provide,
  useContext,
  // Resource API
  createResource as _createResource,
  createDeferred as _createDeferred,
  resourceGet,
  resourcePeek,
  resourceRefetch,
  resourceIsPending,
  resourceIsSuccess,
  resourceIsFailure,
  resourceValue,
  resourceError,
  stateIsPending,
  stateIsSuccess,
  stateIsFailure,
  stateValue,
  stateError,
  // Portal API
  portalToBody,
  portalToSelector,
  portalWithShadow,
  portalToElementWithShadow,
} from "../../../target/js/release/build/platform/js/api/api.js";

// ============================================================================
// SolidJS-compatible Signal API
// ============================================================================

/**
 * Creates a reactive signal (SolidJS-style)
 */
export function createSignal<T>(initialValue: T): Signal<T> {
  const signal = _createSignal(initialValue);

  const getter: Accessor<T> = () => _get(signal);

  const setter: Setter<T> = (valueOrUpdater) => {
    if (typeof valueOrUpdater === "function") {
      _update(signal, valueOrUpdater);
    } else {
      _set(signal, valueOrUpdater);
    }
  };

  return [getter, setter];
}

/**
 * Creates a reactive effect (SolidJS-style alias)
 */
export function createEffect(fn: () => void): () => void {
  return _effect(fn);
}

/**
 * Creates a memoized computed value (SolidJS-style)
 */
export function createMemo<T>(fn: () => T): Accessor<T> {
  return _createMemo(fn);
}

/**
 * Runs a function without tracking dependencies (SolidJS-style alias)
 */
export { runUntracked as untrack };

/**
 * Explicit dependency tracking helper (SolidJS-style)
 * Wraps a function to explicitly specify which signals to track
 *
 * @template T
 * @template U
 * @param {(() => T) | Array<() => any>} deps - Signal accessor(s) to track
 * @param {(input: T, prevInput?: T, prevValue?: U) => U} fn - Function to run with dependency values
 * @param {{ defer?: boolean }} [options] - Options (defer: don't run on initial)
 * @returns {(prevValue?: U) => U | undefined}
 */
export function on(deps, fn, options = {}) {
  const { defer = false } = options;
  const isArray = Array.isArray(deps);

  let prevInput;
  let prevValue;
  let isFirst = true;

  return (injectedPrevValue) => {
    // Get current dependency values
    const input = isArray ? deps.map((d) => d()) : deps();

    // Handle deferred execution
    if (defer && isFirst) {
      isFirst = false;
      prevInput = input;
      return undefined;
    }

    // Run the function with current and previous values
    const result = fn(input, prevInput, injectedPrevValue ?? prevValue);

    // Store for next run
    prevInput = input;
    prevValue = result;
    isFirst = false;

    return result;
  };
}

/**
 * Merge multiple props objects, with later objects taking precedence (SolidJS-style)
 * Event handlers and refs are merged, other props are overwritten
 *
 * @template T
 * @param {...T} sources - Props objects to merge
 * @returns {T}
 */
export function mergeProps(...sources) {
  const result = {};

  for (const source of sources) {
    if (!source) continue;

    for (const key of Object.keys(source)) {
      const value = source[key];

      // Merge event handlers (on* props)
      if (key.startsWith("on") && typeof value === "function") {
        const existing = result[key];
        if (typeof existing === "function") {
          result[key] = (...args) => {
            existing(...args);
            value(...args);
          };
        } else {
          result[key] = value;
        }
      }
      // Merge ref callbacks
      else if (key === "ref" && typeof value === "function") {
        const existing = result[key];
        if (typeof existing === "function") {
          result[key] = (el) => {
            existing(el);
            value(el);
          };
        } else {
          result[key] = value;
        }
      }
      // Merge class/className
      else if (key === "class" || key === "className") {
        const existing = result[key];
        if (existing) {
          result[key] = `${existing} ${value}`;
        } else {
          result[key] = value;
        }
      }
      // Merge style objects
      else if (key === "style" && typeof value === "object" && typeof result[key] === "object") {
        result[key] = { ...result[key], ...value };
      }
      // Default: overwrite
      else {
        result[key] = value;
      }
    }
  }

  return result;
}

/**
 * Split props into multiple objects based on key lists (SolidJS-style)
 *
 * @template T
 * @template K
 * @param {T} props - Props object to split
 * @param {...K[]} keys - Arrays of keys to extract
 * @returns {[Pick<T, K>, Omit<T, K>]}
 */
export function splitProps(props, ...keys) {
  const result = [];
  const remaining = { ...props };

  for (const keyList of keys) {
    const extracted = {};
    for (const key of keyList) {
      if (key in remaining) {
        extracted[key] = remaining[key];
        delete remaining[key];
      }
    }
    result.push(extracted);
  }

  result.push(remaining);
  return result;
}

/**
 * Creates a resource for async data (SolidJS-style)
 */
export function createResource<T>(fetcher: (resolve: (v: T) => void, reject: (e: string) => void) => void): [ResourceAccessor<T>, { refetch: () => void }] {
  const resource = _createResource(fetcher);

  // Use resourceGet for tracking dependencies, stateValue for actual value
  const accessor = () => stateValue(resourceGet(resource));
  Object.defineProperties(accessor, {
    loading: { get: () => resourceIsPending(resource) },
    error: { get: () => resourceError(resource) },
    state: {
      get: () => {
        if (resourceIsPending(resource)) return "pending";
        if (resourceIsSuccess(resource)) return "ready";
        if (resourceIsFailure(resource)) return "errored";
        return "unresolved";
      },
    },
    latest: { get: () => resourcePeek(resource) },
  });

  return [accessor, { refetch: () => resourceRefetch(resource) }];
}

/**
 * Creates a deferred resource (SolidJS-style)
 */
export function createDeferred<T>(): [ResourceAccessor<T>, (value: T) => void, (error: string) => void] {
  const result = _createDeferred();
  const resource = result._0;
  const resolve = result._1;
  const reject = result._2;

  // Use resourceGet for tracking dependencies, stateValue for actual value
  const accessor = () => stateValue(resourceGet(resource));
  Object.defineProperties(accessor, {
    loading: { get: () => resourceIsPending(resource) },
    error: { get: () => resourceError(resource) },
  });

  return [accessor, resolve, reject];
}

/**
 * Debounces a signal (returns SolidJS-style signal)
 */
export function debounced<T>(signal: Signal<T>, delayMs: number): Signal<T> {
  const [getter] = signal;
  const innerSignal = _createSignal(getter());
  const debouncedInner = _debounced(innerSignal, delayMs);
  return [() => _get(debouncedInner), (v) => _set(innerSignal, v)];
}

// ============================================================================
// SolidJS-compatible Component API
// ============================================================================

/**
 * For component for list rendering (SolidJS-style)
 */
export function For<T>(props: ForProps<T>): any {
  const { each, fallback, children } = props;

  // If each is not provided or is falsy, show fallback
  if (!each) {
    return fallback ?? null;
  }

  // each should be a getter function
  const getter = typeof each === "function" ? each : () => each;

  return forEach(getter, (item, index) => {
    // Wrap index in a getter for SolidJS compatibility
    return children(item, () => index);
  });
}

/**
 * Show component for conditional rendering (SolidJS-style)
 */
export function Show<T>(props: ShowProps<T>): any {
  const { when, children } = props;
  // TODO: fallback support requires MoonBit-side changes

  // Convert when to a getter if it's not already
  const condition = typeof when === "function" ? when : () => when;

  // If children is a function, we need to call it with the truthy value
  const renderChildren =
    typeof children === "function" ? () => children(condition()) : () => children;

  return show(() => Boolean(condition()), renderChildren);
}

/**
 * Index component for index-based list rendering (SolidJS-style)
 */
export function Index<T>(props: IndexProps<T>): any {
  const { each, fallback, children } = props;

  if (!each) {
    return fallback ?? null;
  }

  const getter = typeof each === "function" ? each : () => each;
  const items = getter();

  if (items.length === 0 && fallback) {
    return fallback;
  }

  // Use index_each from MoonBit if available, otherwise simulate with forEach
  // For now, we'll use forEach with index-based tracking
  return forEach(getter, (_item, index) => {
    // Provide item as a getter for reactivity at that index
    const itemGetter = () => getter()[index];
    return children(itemGetter, index);
  });
}

/**
 * Provider component for Context (SolidJS-style)
 */
export function Provider<T>(props: ProviderProps<T>): any {
  const { context, value, children } = props;

  return provide(context, value, () => {
    return typeof children === "function" ? children() : children;
  });
}

/**
 * Switch component for conditional rendering with multiple branches (SolidJS-style)
 * Reactively updates when conditions change.
 */
export function Switch(props: SwitchProps): any {
  const { fallback, children } = props;

  // children should be Match components, each with { when, children }
  // Since we don't have compile-time JSX, children is an array of Match results

  // Normalize children to a flat array
  let childArray: any[];
  if (!children) {
    childArray = [];
  } else if (!Array.isArray(children)) {
    childArray = [children];
  } else {
    // Flatten nested arrays (JSX can nest them)
    childArray = children.flat();
  }

  // Filter to only Match components
  const matches = childArray.filter((child) => child && child.__isMatch);

  if (matches.length === 0) {
    return fallback ?? null;
  }

  // Track which Match index is currently active (-1 = none, show fallback)
  const matchIndex = createMemo(() => {
    for (let i = 0; i < matches.length; i++) {
      const match = matches[i];
      if (match.when()) {
        return i;
      }
    }
    return -1;
  });

  // Create a show for each Match (only the active one will render)
  const nodes: any[] = [];
  for (let i = 0; i < matches.length; i++) {
    const match = matches[i];
    const idx = i; // Capture index for closure
    nodes.push(
      show(
        () => matchIndex() === idx,
        () => typeof match.children === "function" ? match.children() : match.children
      )
    );
  }

  // Add fallback (renders when no match)
  if (fallback) {
    nodes.push(
      show(
        () => matchIndex() === -1,
        () => fallback
      )
    );
  }

  return Fragment(nodes);
}

/**
 * Match component for use inside Switch (SolidJS-style)
 */
export function Match<T>(props: MatchProps<T>): { __isMatch: true; when: () => boolean; children: any } {
  const { when, children } = props;
  const condition = typeof when === "function" ? when : () => when;

  return {
    __isMatch: true,
    when: () => Boolean(condition()),
    children:
      typeof children === "function"
        ? () => children(condition())
        : children,
  };
}

/**
 * Portal component for rendering outside the component tree (SolidJS-style)
 */
export function Portal(props: PortalProps): any {
  const { mount, useShadow = false, children } = props;

  // Resolve children
  const resolvedChildren = typeof children === "function" ? [children()] : Array.isArray(children) ? children : [children];

  // Handle different mount targets
  if (useShadow) {
    if (typeof mount === "string") {
      const target = document.querySelector(mount);
      if (target) {
        return portalToElementWithShadow(target, resolvedChildren);
      }
    } else if (mount) {
      return portalToElementWithShadow(mount, resolvedChildren);
    }
    return portalWithShadow(resolvedChildren);
  }

  if (typeof mount === "string") {
    return portalToSelector(mount, resolvedChildren);
  }

  if (mount) {
    // For custom element mount, use selector approach
    return portalToBody(resolvedChildren);
  }

  return portalToBody(resolvedChildren);
}

// ============================================================================
// Store API (SolidJS-style)
// ============================================================================

/**
 * Creates a reactive store with nested property tracking (SolidJS-style)
 */
export function createStore<T extends object>(initialValue: T): [T, SetStoreFunction<T>] {
  // Store signals for each path
  const signals = new Map();
  // Deep clone the initial value to avoid mutation issues
  const store = structuredClone(initialValue);

  // Get or create a signal for a path
  function getSignal(path) {
    const key = path.join(".");
    if (!signals.has(key)) {
      const value = getValueAtPath(store, path);
      signals.set(key, _createSignal(value));
    }
    return signals.get(key);
  }

  // Get value at a path in an object
  function getValueAtPath(obj, path) {
    let current = obj;
    for (const key of path) {
      if (current == null) return undefined;
      current = current[key];
    }
    return current;
  }

  // Set value at a path in an object
  function setValueAtPath(obj, path, value) {
    if (path.length === 0) return;
    let current = obj;
    for (let i = 0; i < path.length - 1; i++) {
      const key = path[i];
      if (current[key] == null) {
        // Preserve array vs object based on next key
        const nextKey = path[i + 1];
        current[key] = typeof nextKey === "number" || /^\d+$/.test(nextKey) ? [] : {};
      }
      current = current[key];
    }
    current[path[path.length - 1]] = value;
  }

  // Notify all signals that might be affected by a path change
  // Uses batch to ensure effects only run once even if multiple signals are updated
  function notifyPath(path) {
    const pathStr = path.join(".");

    batchStart();
    try {
      for (const [key, signal] of signals.entries()) {
        // Only notify:
        // 1. The exact path that changed
        // 2. Child paths (paths that start with the changed path)
        // Do NOT notify parent paths - they didn't change (object reference is same)
        if (key === pathStr || key.startsWith(pathStr + ".")) {
          const signalPath = key.split(".");
          const newValue = getValueAtPath(store, signalPath);
          _set(signal, newValue);
        }
      }
    } finally {
      batchEnd();
    }
  }

  // Create a proxy for reactive access
  function createProxy(target, path = []) {
    if (target === null || typeof target !== "object") {
      return target;
    }

    return new Proxy(target, {
      get(obj, prop) {
        if (typeof prop === "symbol") {
          return obj[prop];
        }

        const currentPath = [...path, prop];
        const signal = getSignal(currentPath);
        // Track dependency by reading the signal
        _get(signal);

        const value = obj[prop];
        if (value !== null && typeof value === "object") {
          return createProxy(value, currentPath);
        }
        return value;
      },

      set(obj, prop, value) {
        // Direct assignment on proxy - update store and notify
        const currentPath = [...path, prop];
        obj[prop] = value;
        notifyPath(currentPath);
        return true;
      },
    });
  }

  // setState function supporting path-based updates
  function setState(...args) {
    if (args.length === 0) return;

    // Collect path segments and final value/updater
    const path = [];
    let i = 0;

    // Collect string path segments
    while (i < args.length - 1 && typeof args[i] === "string") {
      path.push(args[i]);
      i++;
    }

    const valueOrUpdater = args[i];

    // If no path, treat as root update
    if (path.length === 0 && typeof valueOrUpdater === "object" && valueOrUpdater !== null) {
      // Merge at root
      Object.assign(store, valueOrUpdater);
      // Notify all signals
      for (const [key, signal] of signals.entries()) {
        const signalPath = key.split(".");
        const newValue = getValueAtPath(store, signalPath);
        _set(signal, newValue);
      }
      return;
    }

    // Get current value at path
    const currentValue = getValueAtPath(store, path);

    // Determine new value
    let newValue;
    if (typeof valueOrUpdater === "function") {
      newValue = valueOrUpdater(currentValue);
    } else if (
      Array.isArray(valueOrUpdater)
    ) {
      // Arrays are replaced, not merged
      newValue = valueOrUpdater;
    } else if (
      typeof valueOrUpdater === "object" &&
      valueOrUpdater !== null &&
      typeof currentValue === "object" &&
      currentValue !== null &&
      !Array.isArray(currentValue)
    ) {
      // Merge objects (but not arrays)
      newValue = { ...currentValue, ...valueOrUpdater };
    } else {
      newValue = valueOrUpdater;
    }

    // Set value in store
    setValueAtPath(store, path, newValue);

    // Notify affected signals
    notifyPath(path);
  }

  const proxy = createProxy(store);
  return [proxy, setState];
}

/**
 * Produce helper for immer-style mutations (SolidJS-style)
 * @template T
 * @param {(draft: T) => void} fn - Mutation function
 * @returns {(state: T) => T} - Function that applies mutations to a copy
 */
export function produce(fn) {
  return (state) => {
    const draft = structuredClone(state);
    fn(draft);
    return draft;
  };
}

/**
 * Reconcile helper for efficient array/object updates (SolidJS-style)
 * @template T
 * @param {T} value - New value to reconcile
 * @returns {(state: T) => T} - Function that returns the new value
 */
export function reconcile(value) {
  return () => value;
}

// Re-export unchanged APIs
export {
  // Batch control
  batchStart,
  batchEnd,
  batch,
  // Cleanup
  onCleanup,
  // Owner/Root
  createRoot,
  getOwner,
  runWithOwner,
  hasOwner,
  onMount,
  // DOM API
  text,
  textDyn,
  render,
  mount,
  show,
  jsx,
  jsxs,
  Fragment,
  createElement,
  createElementNs,
  svgNs,
  mathmlNs,
  events,
  forEach,
  // Route definitions
  routePage,
  routePageTitled,
  routePageFull,
  createRouter,
  routerNavigate,
  routerReplace,
  routerGetPath,
  routerGetMatch,
  routerGetBase,
  // Context API
  createContext,
  provide,
  useContext,
  // Resource helpers (for direct access)
  resourceGet,
  resourcePeek,
  resourceRefetch,
  resourceIsPending,
  resourceIsSuccess,
  resourceIsFailure,
  resourceValue,
  resourceError,
  stateIsPending,
  stateIsSuccess,
  stateIsFailure,
  stateValue,
  stateError,
  // Portal API (low-level)
  portalToBody,
  portalToSelector,
  portalWithShadow,
  portalToElementWithShadow,
};

// Legacy API exports (for backwards compatibility during migration)
export {
  _get as get,
  _set as set,
  _update as update,
  _peek as peek,
  _subscribe as subscribe,
  _map as map,
  _combine as combine,
  _effect as effect,
  runUntracked,
};

// Event utilities (tree-shakeable, also available via "@luna_ui/luna/event-utils")
export * from "./event-utils";
