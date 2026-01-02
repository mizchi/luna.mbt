import { setupProgress } from '../progress';
export const hydrate = (el: Element, state?: unknown) => setupProgress(el, state as any);
export default hydrate;
