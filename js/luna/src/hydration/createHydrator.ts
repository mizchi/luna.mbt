/**
 * createHydrator - Wraps hydration logic with automatic guard and cleanup
 *
 * Features:
 * - Prevents double hydration via data-hydrated check
 * - Automatically sets data-hydrated="true" on completion
 * - Optional cleanup function support
 */

export type HydrateFn = (
  element: Element,
  state: unknown,
  name: string
) => void | (() => void);

export type CleanupFn = () => void;

/**
 * Create a hydration function with automatic guards
 *
 * @example
 * ```ts
 * export const hydrate = createHydrator((el, state) => {
 *   // Your hydration logic here
 *   el.querySelector('button').onclick = () => { ... };
 *
 *   // Optional: return cleanup function
 *   return () => { ... };
 * });
 * ```
 */
export function createHydrator(
  fn: (element: Element, state: unknown, name: string) => void | CleanupFn
): HydrateFn {
  // Store cleanup functions by element
  const cleanups = new WeakMap<Element, CleanupFn>();

  return (element: Element, state: unknown, name: string): void => {
    // Skip if already hydrated
    if ((element as HTMLElement).dataset.hydrated) {
      return;
    }

    // Run cleanup if re-hydrating (HMR scenario)
    const existingCleanup = cleanups.get(element);
    if (existingCleanup) {
      existingCleanup();
      cleanups.delete(element);
    }

    // Run hydration
    const cleanup = fn(element, state, name);

    // Store cleanup if provided
    if (typeof cleanup === 'function') {
      cleanups.set(element, cleanup);
    }

    // Mark as hydrated
    (element as HTMLElement).dataset.hydrated = 'true';
  };
}
