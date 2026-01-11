import { setupTabs } from '../tabs';
export const hydrate = (el: Element, state?: unknown) => setupTabs(el, state as any);
export default hydrate;
