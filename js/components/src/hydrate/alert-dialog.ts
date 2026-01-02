import { setupAlertDialog } from '../alert-dialog';
export const hydrate = (el: Element, state?: unknown) => setupAlertDialog(el, state as any);
export default hydrate;
