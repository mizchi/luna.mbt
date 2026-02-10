// @ts-nocheck
// Signals-only entrypoint for smaller bundles

export type Accessor<T> = () => T;
export type Setter<T> = (value: T | ((prev: T) => T)) => void;
export type Signal<T> = [Accessor<T>, Setter<T>];

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
  renderEffect as _renderEffect,
  // Batch & owner
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
} from "../../../_build/js/release/build/js/api_signals/api_signals.js";

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
 * Creates a reactive effect (SolidJS-style)
 * Deferred execution via microtask - runs after rendering completes
 */
export function createEffect(fn: () => void): () => void {
  return _effect(fn);
}

/**
 * Creates a render effect (SolidJS-style)
 * Immediate/synchronous execution - runs during rendering
 */
export function createRenderEffect(fn: () => void): () => void {
  return _renderEffect(fn);
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
};

// Low-level/legacy exports (for direct use)
export {
  _get as get,
  _set as set,
  _update as update,
  _peek as peek,
  _subscribe as subscribe,
  _map as map,
  _combine as combine,
  _effect as effect,
  _renderEffect as renderEffect,
  runUntracked,
};
