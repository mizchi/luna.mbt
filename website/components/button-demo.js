// Button Demo - Shows different button variants
export function hydrate(element, state, name) {
  let clickCount = 0;

  const render = () => {
    element.innerHTML = `
      <div style="display: flex; flex-wrap: wrap; gap: 0.75rem; padding: 1rem; border: 1px solid var(--border-color, #e5e7eb); border-radius: 0.75rem; background: var(--sidebar-bg, #1f2937);">
        <button data-variant="primary" style="padding: 0.5rem 1rem; border: none; border-radius: 0.5rem; background: var(--primary-color, #6366f1); color: white; cursor: pointer; font-weight: 500; transition: opacity 0.2s;">Primary</button>
        <button data-variant="secondary" style="padding: 0.5rem 1rem; border: 1px solid var(--border-color, #374151); border-radius: 0.5rem; background: transparent; color: var(--text-color, #e5e7eb); cursor: pointer; font-weight: 500; transition: opacity 0.2s;">Secondary</button>
        <button data-variant="destructive" style="padding: 0.5rem 1rem; border: none; border-radius: 0.5rem; background: #dc2626; color: white; cursor: pointer; font-weight: 500; transition: opacity 0.2s;">Destructive</button>
        <button data-variant="ghost" style="padding: 0.5rem 1rem; border: none; border-radius: 0.5rem; background: transparent; color: var(--text-color, #e5e7eb); cursor: pointer; font-weight: 500; transition: background 0.2s;">Ghost</button>
        <span style="display: flex; align-items: center; color: var(--text-muted, #9ca3af); font-size: 0.875rem; margin-left: 0.5rem;">Clicks: ${clickCount}</span>
      </div>
    `;

    element.querySelectorAll('button').forEach(btn => {
      btn.onmouseover = () => btn.style.opacity = '0.8';
      btn.onmouseout = () => btn.style.opacity = '1';
      btn.onclick = () => { clickCount++; render(); };
    });
  };

  render();
}

export default hydrate;
