import { setupCard } from '../card';
export const hydrate = (el: Element, state?: unknown) => setupCard(el, state as any);
export default hydrate;
