/**
 * Event utilities for common event handling patterns
 *
 * These utilities are tree-shakeable - only import what you use.
 *
 * @example
 * import { getTargetValue, getDataId, stopEvent } from "@luna_ui/luna/event-utils";
 *
 * on=events().input(fn(e) {
 *   const value = getTargetValue(e);
 *   setValue(value);
 * })
 */

/**
 * Get value from input/textarea/select element
 */
export function getTargetValue(e: Event): string {
  return (e.target as HTMLInputElement)?.value ?? "";
}

/**
 * Get checked state from checkbox/radio input
 */
export function getTargetChecked(e: Event): boolean {
  return (e.target as HTMLInputElement)?.checked ?? false;
}

/**
 * Get selected index from select element
 */
export function getSelectedIndex(e: Event): number {
  return (e.target as HTMLSelectElement)?.selectedIndex ?? -1;
}

/**
 * Get client position (relative to viewport) from mouse/pointer/touch event
 */
export function getClientPos(e: MouseEvent | PointerEvent | TouchEvent): { x: number; y: number } {
  if ("touches" in e && e.touches.length > 0) {
    return { x: e.touches[0].clientX, y: e.touches[0].clientY };
  }
  const me = e as MouseEvent;
  return { x: me.clientX, y: me.clientY };
}

/**
 * Get offset position (relative to target element) from mouse/pointer event
 */
export function getOffsetPos(e: MouseEvent | PointerEvent): { x: number; y: number } {
  return { x: e.offsetX, y: e.offsetY };
}

/**
 * Get page position (relative to document) from mouse/pointer/touch event
 */
export function getPagePos(e: MouseEvent | PointerEvent | TouchEvent): { x: number; y: number } {
  if ("touches" in e && e.touches.length > 0) {
    return { x: e.touches[0].pageX, y: e.touches[0].pageY };
  }
  const me = e as MouseEvent;
  return { x: me.pageX, y: me.pageY };
}

/**
 * Get movement delta from mouse/pointer event
 */
export function getMovement(e: MouseEvent | PointerEvent): { dx: number; dy: number } {
  return { dx: e.movementX, dy: e.movementY };
}

/**
 * Get data attribute from event target or closest ancestor
 */
export function getDataAttr(e: Event, key: string): string | null {
  const target = e.target as HTMLElement;
  return target?.closest(`[data-${key}]`)?.getAttribute(`data-${key}`) ?? null;
}

/**
 * Get data-id from closest ancestor (common pattern for list items)
 */
export function getDataId(e: Event): string | null {
  return getDataAttr(e, "id");
}

/**
 * Get all data attributes from event target as object
 */
export function getDataset(e: Event): DOMStringMap {
  return (e.target as HTMLElement)?.dataset ?? {};
}

/**
 * Check if event target matches a CSS selector
 */
export function matchesSelector(e: Event, selector: string): boolean {
  const target = e.target as HTMLElement;
  return target?.matches?.(selector) ?? false;
}

/**
 * Get closest ancestor matching selector from event target
 */
export function getClosest<T extends Element = HTMLElement>(e: Event, selector: string): T | null {
  const target = e.target as HTMLElement;
  return target?.closest?.(selector) as T | null;
}

/**
 * Prevent default behavior
 */
export function preventDefault(e: Event): void {
  e.preventDefault();
}

/**
 * Stop event propagation
 */
export function stopPropagation(e: Event): void {
  e.stopPropagation();
}

/**
 * Prevent default and stop propagation (convenience)
 */
export function stopEvent(e: Event): void {
  e.preventDefault();
  e.stopPropagation();
}

/**
 * Check if IME is composing (for input/keyboard events)
 * Use this to avoid handling partial IME input
 */
export function isComposing(e: Event): boolean {
  return (e as InputEvent | KeyboardEvent).isComposing ?? false;
}

/**
 * Check if modifier key is pressed
 */
export function hasModifier(e: KeyboardEvent | MouseEvent, modifier: "ctrl" | "alt" | "shift" | "meta"): boolean {
  switch (modifier) {
    case "ctrl": return e.ctrlKey;
    case "alt": return e.altKey;
    case "shift": return e.shiftKey;
    case "meta": return e.metaKey;
  }
}

/**
 * Check if Cmd (Mac) or Ctrl (Windows/Linux) is pressed
 */
export function hasCmdOrCtrl(e: KeyboardEvent | MouseEvent): boolean {
  // Mac uses metaKey (Cmd), others use ctrlKey
  return e.metaKey || e.ctrlKey;
}

/**
 * Get keyboard key with normalized names
 */
export function getKey(e: KeyboardEvent): string {
  return e.key;
}

/**
 * Check if Enter key was pressed (outside IME composition)
 */
export function isEnterKey(e: KeyboardEvent): boolean {
  return e.key === "Enter" && !isComposing(e);
}

/**
 * Check if Escape key was pressed
 */
export function isEscapeKey(e: KeyboardEvent): boolean {
  return e.key === "Escape";
}

/**
 * Get wheel delta (normalized across browsers)
 */
export function getWheelDelta(e: WheelEvent): { deltaX: number; deltaY: number; deltaZ: number } {
  return {
    deltaX: e.deltaX,
    deltaY: e.deltaY,
    deltaZ: e.deltaZ,
  };
}

/**
 * Get which mouse button was pressed
 * 0 = primary (left), 1 = auxiliary (middle), 2 = secondary (right)
 */
export function getButton(e: MouseEvent): number {
  return e.button;
}

/**
 * Check if primary (left) mouse button was pressed
 */
export function isPrimaryButton(e: MouseEvent): boolean {
  return e.button === 0;
}

/**
 * Check if secondary (right) mouse button was pressed
 */
export function isSecondaryButton(e: MouseEvent): boolean {
  return e.button === 2;
}

/**
 * Get files from drag event
 */
export function getDroppedFiles(e: DragEvent): FileList | null {
  return e.dataTransfer?.files ?? null;
}

/**
 * Get text data from drag/clipboard event
 */
export function getTextData(e: DragEvent | ClipboardEvent): string {
  const dt = "dataTransfer" in e ? e.dataTransfer : e.clipboardData;
  return dt?.getData("text/plain") ?? "";
}
