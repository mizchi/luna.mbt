import { setupRadio } from '../radio';
export const hydrate = (el: Element, state?: unknown) => setupRadio(el, state as any);
export default hydrate;
