import { setupRadioGroup } from '../radio-group';
export const hydrate = (el: Element, state?: unknown) => setupRadioGroup(el, state as any);
export default hydrate;
