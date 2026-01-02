import { setupSwitch } from '../switch';
export const hydrate = (el: Element, state?: unknown) => setupSwitch(el, state as any);
export default hydrate;
