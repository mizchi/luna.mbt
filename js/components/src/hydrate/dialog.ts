import { setupDialog } from '../dialog';
export const hydrate = (el: Element, state?: unknown) => setupDialog(el, state as any);
export default hydrate;
