import { definePage, html, type Html } from "@luna_ui/luna/void/server";

export default definePage<{ children: Html }>(
  ({ children }) => html`<main data-layout="root">${children}</main>`,
);
