import { setupAccordion } from '../accordion';
export const hydrate = (el: Element, state?: unknown) => setupAccordion(el, state as any);
export default hydrate;
