/**
 * Cleanup function returned by setup functions
 */
export type CleanupFn = () => void;

/**
 * Generic setup function signature
 */
export type SetupFn<T = void> = (el: Element, options?: T) => CleanupFn;

/**
 * Checkbox state
 */
export type CheckboxState = 'checked' | 'unchecked' | 'indeterminate';

/**
 * Combine multiple cleanup functions into one
 */
export function combine(...fns: (CleanupFn | undefined)[]): CleanupFn {
  return () => {
    for (const fn of fns) fn?.();
  };
}
