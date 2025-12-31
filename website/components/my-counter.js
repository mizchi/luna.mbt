// my-counter Web Component
// A simple counter component that demonstrates Web Component hydration

export function hydrate(element, _state, name) {
  let count = parseInt(element.getAttribute('initial') || '0', 10);

  const render = () => {
    element.innerHTML = `
      <div style="display: inline-flex; align-items: center; gap: 0.75rem; padding: 1rem 1.5rem; border: 2px solid var(--primary-color, #fbbf24); border-radius: 0.75rem; background: var(--sidebar-bg, #1f2937);">
        <button style="width: 2.5rem; height: 2.5rem; border: none; border-radius: 0.5rem; background: var(--primary-color, #fbbf24); color: #000; cursor: pointer; font-size: 1.5rem; font-weight: bold; transition: opacity 0.2s;" onmouseover="this.style.opacity='0.8'" onmouseout="this.style.opacity='1'">-</button>
        <span style="min-width: 3rem; text-align: center; font-weight: 700; font-size: 1.5rem; color: var(--text-color, #e5e7eb);">${count}</span>
        <button style="width: 2.5rem; height: 2.5rem; border: none; border-radius: 0.5rem; background: var(--primary-color, #fbbf24); color: #000; cursor: pointer; font-size: 1.5rem; font-weight: bold; transition: opacity 0.2s;" onmouseover="this.style.opacity='0.8'" onmouseout="this.style.opacity='1'">+</button>
      </div>
    `;

    const [decBtn, incBtn] = element.querySelectorAll("button");
    decBtn.onclick = () => { count--; render(); };
    incBtn.onclick = () => { count++; render(); };
  };

  render();
}

export default hydrate;
