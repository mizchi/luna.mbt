import { setupCheckbox } from '../checkbox';
export const hydrate = (el: Element, state?: unknown) => setupCheckbox(el, state as any);
export default hydrate;
