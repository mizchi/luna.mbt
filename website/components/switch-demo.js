// Switch Demo - Toggle switches with labels
export function hydrate(element, state, name) {
  let switches = { notifications: true, darkMode: false, autoSave: true };

  const render = () => {
    element.innerHTML = `
      <div style="display: flex; flex-direction: column; gap: 1rem; padding: 1rem; border: 1px solid var(--border-color, #e5e7eb); border-radius: 0.75rem; background: var(--sidebar-bg, #1f2937);">
        ${Object.entries(switches).map(([key, value]) => `
          <label style="display: flex; align-items: center; justify-content: space-between; cursor: pointer;">
            <span style="color: var(--text-color, #e5e7eb); font-size: 0.875rem;">${key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase())}</span>
            <button data-key="${key}" role="switch" aria-checked="${value}" style="
              width: 44px; height: 24px; border-radius: 12px; border: none; cursor: pointer; position: relative;
              background: ${value ? 'var(--primary-color, #6366f1)' : '#4b5563'}; transition: background 0.2s;
            ">
              <span style="
                position: absolute; top: 2px; left: ${value ? '22px' : '2px'}; width: 20px; height: 20px;
                background: white; border-radius: 50%; transition: left 0.2s;
              "></span>
            </button>
          </label>
        `).join('')}
      </div>
    `;

    element.querySelectorAll('button[role="switch"]').forEach(btn => {
      btn.onclick = () => {
        const key = btn.dataset.key;
        switches[key] = !switches[key];
        render();
      };
    });
  };

  render();
}

export default hydrate;
