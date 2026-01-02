import { setupTooltip } from '../tooltip';
export const hydrate = (el: Element, state?: unknown) => setupTooltip(el, state as any);
export default hydrate;
