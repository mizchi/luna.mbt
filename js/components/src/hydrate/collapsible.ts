import { setupCollapsible } from '../collapsible';
export const hydrate = (el: Element, state?: unknown) => setupCollapsible(el, state as any);
export default hydrate;
