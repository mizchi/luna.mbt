// my-counter: small island that increments a count on click.
// Used by /index.md's third section to demonstrate a client-side Web
// Component hydrated by astra's island loader.
//
// The element ships zero state from the server (the initial label is
// rendered by `connectedCallback`), so VRT baselines stay deterministic
// regardless of hydration timing — the loader fires on first visibility
// and the rendered DOM is identical on every run.
class MyCounter extends HTMLElement {
  connectedCallback() {
    const initial = Number(this.getAttribute("start") ?? "0") || 0;
    this._count = initial;
    this.render();
    this.querySelector("button[data-act=dec]")?.addEventListener("click", () => {
      this._count -= 1;
      this.update();
    });
    this.querySelector("button[data-act=inc]")?.addEventListener("click", () => {
      this._count += 1;
      this.update();
    });
  }

  update() {
    const out = this.querySelector(".count");
    if (out) out.textContent = String(this._count);
  }

  render() {
    this.innerHTML = `
      <button type="button" data-act="dec" aria-label="decrement">-</button>
      <span class="count">${this._count}</span>
      <button type="button" data-act="inc" aria-label="increment">+</button>
    `;
  }
}

if (!customElements.get("my-counter")) {
  customElements.define("my-counter", MyCounter);
}
