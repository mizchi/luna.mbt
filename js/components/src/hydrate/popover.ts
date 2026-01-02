import { setupPopover } from '../popover';
export const hydrate = (el: Element, state?: unknown) => setupPopover(el, state as any);
export default hydrate;
