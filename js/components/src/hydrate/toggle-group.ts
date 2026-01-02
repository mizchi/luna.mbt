import { setupToggleGroup } from '../toggle-group';
export const hydrate = (el: Element, state?: unknown) => setupToggleGroup(el, state as any);
export default hydrate;
