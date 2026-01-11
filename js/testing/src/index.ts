/**
 * Luna Testing Library
 *
 * Testing utilities for Luna UI components following APG patterns
 *
 * @example
 * ```ts
 * import { render, getByRole, click, isChecked } from '@luna_ui/testing';
 *
 * // Render a checkbox
 * const { container } = render(`
 *   <div role="checkbox" aria-checked="false" aria-label="Accept terms">
 *     Accept terms
 *   </div>
 * `);
 *
 * // Find and interact
 * const checkbox = getByRole('checkbox', { name: 'Accept terms' });
 * click(checkbox);
 *
 * // Assert
 * expect(isChecked(checkbox)).toBe(true);
 * ```
 */

// Render utilities
export {
  render,
  renderTemplate,
  createContainer,
  cleanup,
  // HTML builders
  buildCheckbox,
  buildSwitch,
  buildButton,
  buildTabs,
  buildAccordion,
  buildSlider,
  buildRadioGroup,
  buildDialog,
} from './render';

export type { RenderResult } from './render';

// Query utilities
export {
  // By Role (primary)
  getByRole,
  queryByRole,
  getAllByRole,
  // By Text
  getByText,
  queryByText,
  getAllByText,
  // By Label
  getByLabelText,
  queryByLabelText,
  // By TestId
  getByTestId,
  queryByTestId,
  // APG-specific
  getTab,
  getTabPanel,
  getCheckbox,
  getSwitch,
  getButton,
  getSlider,
  getRadio,
  getDialog,
  // Utilities
  getAccessibleName,
  isVisible,
  waitFor,
} from './queries';

// Event utilities
export {
  // Mouse
  click,
  dblClick,
  // Keyboard
  keyDown,
  keyUp,
  keyPress,
  type,
  // Common keys
  pressEnter,
  pressSpace,
  pressEscape,
  pressTab,
  pressArrowUp,
  pressArrowDown,
  pressArrowLeft,
  pressArrowRight,
  pressHome,
  pressEnd,
  pressPageUp,
  pressPageDown,
  // Focus
  focus,
  blur,
  // Form
  change,
  clear,
  selectOption,
  // User helper object
  user,
} from './events';

export type { KeyOptions } from './events';

// Assertion utilities
export {
  // State checks
  isChecked,
  isMixed,
  isPressed,
  isSelected,
  isExpanded,
  isDisabled,
  isHidden,
  hasFocus,
  // Value getters
  getSliderValue,
  getSliderMin,
  getSliderMax,
  getRadioValue,
  getSelectedTabIndex,
  // Accessibility
  hasAccessibleName,
  hasRequiredAriaAttributes,
  isFocusable,
  // Custom matchers
  customMatchers,
} from './assertions';

// Re-export getAccessibleName from assertions (used for assertions)
export { getAccessibleName as getAriaName } from './assertions';
