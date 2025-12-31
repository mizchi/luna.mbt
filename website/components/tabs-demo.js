// Tabs Demo - Tabbed interface
export function hydrate(element, state, name) {
  let activeTab = 'account';
  const tabs = [
    { id: 'account', label: 'Account', content: 'Manage your account settings, update profile information, and configure preferences.' },
    { id: 'password', label: 'Password', content: 'Change your password, enable two-factor authentication, and manage security keys.' },
    { id: 'notifications', label: 'Notifications', content: 'Configure email notifications, push alerts, and digest preferences.' },
  ];

  const render = () => {
    element.innerHTML = `
      <div style="border: 1px solid var(--border-color, #374151); border-radius: 0.75rem; overflow: hidden; background: var(--sidebar-bg, #1f2937);">
        <div style="display: flex; border-bottom: 1px solid var(--border-color, #374151); background: var(--bg-color, #111827);">
          ${tabs.map(tab => `
            <button data-tab="${tab.id}" style="
              flex: 1; padding: 0.75rem 1rem; border: none; cursor: pointer; font-size: 0.875rem; font-weight: 500;
              background: ${activeTab === tab.id ? 'var(--sidebar-bg, #1f2937)' : 'transparent'};
              color: ${activeTab === tab.id ? 'var(--primary-color, #6366f1)' : 'var(--text-muted, #9ca3af)'};
              border-bottom: 2px solid ${activeTab === tab.id ? 'var(--primary-color, #6366f1)' : 'transparent'};
              transition: all 0.2s;
            ">${tab.label}</button>
          `).join('')}
        </div>
        <div style="padding: 1rem;">
          ${tabs.map(tab => `
            <div data-content="${tab.id}" style="display: ${activeTab === tab.id ? 'block' : 'none'};">
              <p style="color: var(--text-color, #e5e7eb); font-size: 0.875rem; line-height: 1.6; margin: 0;">${tab.content}</p>
            </div>
          `).join('')}
        </div>
      </div>
    `;

    element.querySelectorAll('button[data-tab]').forEach(btn => {
      btn.onclick = () => {
        activeTab = btn.dataset.tab;
        render();
      };
    });
  };

  render();
}

export default hydrate;
