// Core utilities
export * from './core';

// Components - matching src/components APG patterns

export { setupCheckbox, getState, setState } from './checkbox';
export type { CheckboxOptions, CheckboxState } from './checkbox';

export { setupSwitch, isChecked, setChecked } from './switch';
export type { SwitchOptions } from './switch';

export { setupAccordion, getItemOpen, setItemOpen, getOpenIds } from './accordion';
export type { AccordionOptions } from './accordion';

export { setupDialog, isOpen as isDialogOpen, setOpen as setDialogOpen, openDialog, closeDialog } from './dialog';
export type { DialogOptions } from './dialog';

export { setupTabs, selectTab, getSelectedTab } from './tabs';
export type { TabsOptions } from './tabs';

export { setupSlider, getValue as getSliderValue, setValue as setSliderValue } from './slider';
export type { SliderOptions } from './slider';

export { setupRadio, getValue as getRadioValue, setValue as setRadioValue } from './radio';
export type { RadioOptions } from './radio';

export { setupTooltip, isVisible, setVisible } from './tooltip';
export type { TooltipOptions } from './tooltip';
