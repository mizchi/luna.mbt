/**
 * @luna_ui/shoelace - Shoelace component bindings for Luna
 *
 * This package provides Luna-compatible wrappers for Shoelace components.
 * All components support both CSR and SSR contexts.
 */

// Types
export type { Signal, ButtonVariant, Size, InputType } from './types.js';

// Button
export {
  slButton,
  slButtonReactive,
  type SlButtonProps,
  type SlButtonReactiveProps,
} from './button.js';

// Input
export {
  slInput,
  slInputReactive,
  type SlInputProps,
  type SlInputReactiveProps,
} from './input.js';

// Checkbox
export {
  slCheckbox,
  slCheckboxReactive,
  type SlCheckboxProps,
  type SlCheckboxReactiveProps,
} from './checkbox.js';

// Switch
export {
  slSwitch,
  slSwitchReactive,
  type SlSwitchProps,
  type SlSwitchReactiveProps,
} from './switch.js';

/**
 * Shoelace CDN URLs for convenience
 */
export const SHOELACE_VERSION = '2.20.1';
export const SHOELACE_CDN_CSS = `https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@${SHOELACE_VERSION}/cdn/themes/light.css`;
export const SHOELACE_CDN_JS = `https://cdn.jsdelivr.net/npm/@shoelace-style/shoelace@${SHOELACE_VERSION}/cdn/shoelace-autoloader.js`;

/**
 * Generate script/link tags for Shoelace CDN
 */
export function getShoelaceCdnTags(): string {
  return `<link rel="stylesheet" href="${SHOELACE_CDN_CSS}">
<script type="module" src="${SHOELACE_CDN_JS}"></script>`;
}
