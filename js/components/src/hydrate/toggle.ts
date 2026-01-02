import { setupToggle } from '../toggle';
export const hydrate = (el: Element, state?: unknown) => setupToggle(el, state as any);
export default hydrate;
