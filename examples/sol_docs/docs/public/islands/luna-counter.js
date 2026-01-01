// Simple counter Web Component for MDX demo
class LunaCounter extends HTMLElement {
  constructor() {
    super();
    this.count = parseInt(this.getAttribute('initial') || '0', 10);
  }

  connectedCallback() {
    this.render();
    this.querySelector('button[data-action="decrement"]')?.addEventListener('click', () => {
      this.count--;
      this.render();
    });
    this.querySelector('button[data-action="increment"]')?.addEventListener('click', () => {
      this.count++;
      this.render();
    });
  }

  render() {
    const style = this.getAttribute('style') || '';
    this.innerHTML = `
      <div style="display: inline-flex; align-items: center; gap: 8px; padding: 8px; border: 1px solid #ccc; border-radius: 4px; ${style}">
        <button data-action="decrement" style="padding: 4px 12px; cursor: pointer;">-</button>
        <span style="min-width: 40px; text-align: center; font-weight: bold;">${this.count}</span>
        <button data-action="increment" style="padding: 4px 12px; cursor: pointer;">+</button>
      </div>
    `;
    // Re-attach event listeners after innerHTML change
    this.querySelector('button[data-action="decrement"]')?.addEventListener('click', () => {
      this.count--;
      this.render();
    });
    this.querySelector('button[data-action="increment"]')?.addEventListener('click', () => {
      this.count++;
      this.render();
    });
  }
}

customElements.define('luna-counter', LunaCounter);
