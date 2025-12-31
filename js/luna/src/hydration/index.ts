/**
 * @luna/hydration - SSR Hydration Helpers
 *
 * Composable helpers for hydrating SSR-rendered components.
 * CSS-first approach: JS handles events, CSS handles visuals.
 */

export { createHydrator, type HydrateFn, type CleanupFn } from './createHydrator';
export { toggle, type ToggleOptions } from './toggle';
export { drag, type DragOptions } from './drag';
export { onDelegate, onClick } from './delegate';
export { keyboard, onEscape, type KeyboardHandlers } from './keyboard';
