// theme-toggle: small island that flips html[data-theme] between light/dark.
// Used by sol_landing's hero on / and /ja/.
//
// Initial theme is set inline before this script loads (so the toggle's
// label matches first paint). The DOM API used here is deliberately
// minimal — no signals, no luna runtime — because the VRT baseline
// expects deterministic output regardless of hydration order.
class ThemeToggle extends HTMLElement {
  connectedCallback() {
    // Establish initial theme on the document root if it isn't already set.
    const root = document.documentElement;
    if (!root.dataset.theme) {
      root.dataset.theme = "light";
    }
    this.render();
    this.querySelector("button")?.addEventListener("click", () => {
      const next = root.dataset.theme === "dark" ? "light" : "dark";
      root.dataset.theme = next;
      this.render();
    });
  }

  render() {
    const theme = document.documentElement.dataset.theme ?? "light";
    const label = theme === "dark" ? "Light mode" : "Dark mode";
    this.innerHTML = `
      <button
        type="button"
        data-theme-toggle
        aria-label="${label}"
        style="padding:6px 14px;border-radius:6px;border:1px solid currentColor;background:transparent;color:inherit;font-size:13px;cursor:pointer;margin-top:8px;"
      >${label}</button>
    `;
  }
}

if (!customElements.get("theme-toggle")) {
  customElements.define("theme-toggle", ThemeToggle);
}
