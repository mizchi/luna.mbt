// Accordion Demo - Expandable sections
export function hydrate(element, state, name) {
  let openItems = new Set(['item-1']);
  const items = [
    { id: 'item-1', title: 'What is Luna?', content: 'Luna is a blazing-fast reactive UI framework written in MoonBit, featuring Island Architecture for optimal performance.' },
    { id: 'item-2', title: 'How does hydration work?', content: 'Luna uses progressive hydration with triggers like "visible", "idle", or "load" to control when components become interactive.' },
    { id: 'item-3', title: 'What are Islands?', content: 'Islands are isolated interactive components within static HTML. Only the islands receive JavaScript, keeping the page lightweight.' },
  ];

  const render = () => {
    element.innerHTML = `
      <div style="display: flex; flex-direction: column; border: 1px solid var(--border-color, #374151); border-radius: 0.75rem; overflow: hidden; position: relative; background: var(--sidebar-bg, #1f2937);">
        <span style="font-size: 0.7rem; color: var(--text-muted, #9ca3af); position: absolute; top: -0.5rem; left: 1rem; background: var(--bg-color, #111827); padding: 0 0.5rem; z-index: 1;">${name}</span>
        ${items.map(item => `
          <div data-state="${openItems.has(item.id) ? 'open' : 'closed'}">
            <button data-id="${item.id}" style="
              width: 100%; padding: 1rem; display: flex; justify-content: space-between; align-items: center;
              background: transparent; border: none; border-bottom: 1px solid var(--border-color, #374151);
              color: var(--text-color, #e5e7eb); cursor: pointer; font-size: 0.875rem; font-weight: 500; text-align: left;
            ">
              ${item.title}
              <span style="transform: rotate(${openItems.has(item.id) ? '180deg' : '0deg'}); transition: transform 0.2s;">▼</span>
            </button>
            <div style="
              max-height: ${openItems.has(item.id) ? '200px' : '0'}; overflow: hidden; transition: max-height 0.3s ease;
              background: var(--bg-color, #111827);
            ">
              <div style="padding: 1rem; color: var(--text-muted, #9ca3af); font-size: 0.875rem; line-height: 1.5;">
                ${item.content}
              </div>
            </div>
          </div>
        `).join('')}
      </div>
    `;

    element.querySelectorAll('button[data-id]').forEach(btn => {
      btn.onclick = () => {
        const id = btn.dataset.id;
        if (openItems.has(id)) {
          openItems.delete(id);
        } else {
          openItems.add(id);
        }
        render();
      };
    });
  };

  render();
}

export default hydrate;
