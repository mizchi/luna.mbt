import { setupSelect } from '../select';
export const hydrate = (el: Element, state?: unknown) => setupSelect(el, state as any);
export default hydrate;
