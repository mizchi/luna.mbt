import { setupMenu } from '../menu';
export const hydrate = (el: Element, state?: unknown) => setupMenu(el, state as any);
export default hydrate;
