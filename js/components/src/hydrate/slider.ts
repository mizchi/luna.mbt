import { setupSlider } from '../slider';
export const hydrate = (el: Element, state?: unknown) => setupSlider(el, state as any);
export default hydrate;
