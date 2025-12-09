/**
 * Type-safe TypeScript definitions for MoonBit signals
 */

/** Reactive signal container */
export interface Signal<T> {
  readonly __brand: unique symbol;
  readonly __type: T;
}

/** Create a reactive signal with an initial value */
export function createSignal<T>(initial: T): Signal<T>;

/** Get the current value of a signal (tracks dependency) */
export function get<T>(signal: Signal<T>): T;

/** Set a new value for a signal */
export function set<T>(signal: Signal<T>, value: T): void;

/** Update a signal's value using a function */
export function update<T>(signal: Signal<T>, fn: (current: T) => T): void;

/** Get the current value without tracking (won't create dependency) */
export function peek<T>(signal: Signal<T>): T;

/** Subscribe to signal changes. Returns unsubscribe function */
export function subscribe<T>(
  signal: Signal<T>,
  callback: (value: T) => void
): () => void;

/** Map a signal to a derived getter */
export function map<T, U>(signal: Signal<T>, fn: (value: T) => U): () => U;

/** Create a memoized computed value */
export function createMemo<T>(compute: () => T): () => T;

/** Combine two signals into a derived getter */
export function combine<A, B, R>(
  a: Signal<A>,
  b: Signal<B>,
  fn: (a: A, b: B) => R
): () => R;

/** Create a reactive effect. Returns cleanup function */
export function effect(fn: () => void): () => void;

/** Start a batch update */
export function batchStart(): void;

/** End a batch update and run pending effects */
export function batchEnd(): void;

/** Run a function without tracking dependencies */
export function runUntracked<T>(fn: () => T): T;

/** Run a function in a batch - all signal updates are batched */
export function batch<T>(fn: () => T): T;

/** Register a cleanup function inside an effect */
export function onCleanup(cleanup: () => void): void;

// ============================================================================
// Owner-based scope management (Solid.js style)
// ============================================================================

/** Opaque Owner type */
export interface Owner {
  readonly __brand: unique symbol;
}

/** Create a new reactive root scope. The function receives a dispose callback */
export function createRoot<T>(fn: (dispose: () => void) => T): T;

/** Get the current owner (if any) */
export function getOwner(): Owner | undefined;

/** Run a function with a specific owner as current */
export function runWithOwner<T>(owner: Owner, fn: () => T): T;

/** Check if currently inside an owner scope */
export function hasOwner(): boolean;

/** Run a function once (Solid.js style onMount) */
export function onMount(fn: () => void): void;
