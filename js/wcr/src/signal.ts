/**
 * Minimal Signal implementation for Web Components
 * With automatic dependency tracking
 */

type Subscriber = () => void;

// Current effect being tracked
let currentEffect: Subscriber | null = null;

export class Signal<T> {
  #value: T;
  #subscribers: Set<Subscriber> = new Set();

  constructor(initial: T) {
    this.#value = initial;
  }

  get(): T {
    // Auto-track: if we're inside an effect, subscribe to this signal
    if (currentEffect) {
      this.#subscribers.add(currentEffect);
    }
    return this.#value;
  }

  set(value: T): void {
    if (this.#value === value) return;
    this.#value = value;
    this.#notify();
  }

  update(fn: (current: T) => T): void {
    this.set(fn(this.#value));
  }

  peek(): T {
    return this.#value;
  }

  subscribe(callback: Subscriber): () => void {
    this.#subscribers.add(callback);
    callback(); // Run immediately
    return () => this.#subscribers.delete(callback);
  }

  #notify(): void {
    // Copy to avoid mutation during iteration
    const subs = [...this.#subscribers];
    for (const sub of subs) {
      sub();
    }
  }
}

/**
 * Create effect with automatic dependency tracking
 */
export function effect(fn: () => void | (() => void)): () => void {
  let cleanup: void | (() => void);
  let disposed = false;

  const run = () => {
    if (disposed) return;

    // Cleanup previous
    if (cleanup) cleanup();

    // Track dependencies
    const prevEffect = currentEffect;
    currentEffect = run;
    try {
      cleanup = fn();
    } finally {
      currentEffect = prevEffect;
    }
  };

  run(); // Initial run

  return () => {
    disposed = true;
    if (cleanup) cleanup();
  };
}

/**
 * Run function without tracking dependencies
 */
export function untrack<T>(fn: () => T): T {
  const prevEffect = currentEffect;
  currentEffect = null;
  try {
    return fn();
  } finally {
    currentEffect = prevEffect;
  }
}
