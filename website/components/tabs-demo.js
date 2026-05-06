// Tabs Demo - Tabbed interface
// SSR-compatible: adopts existing DOM, adds event handlers only
export function hydrate(element, state, name) {
  // Get initial active tab from SSR state
  let activeTab = null;
  element.querySelectorAll('[data-tab-trigger]').forEach(trigger => {
    if (trigger.getAttribute('aria-selected') === 'true') {
      activeTab = trigger.dataset.tabTrigger;
    }
  });

  // Switch to a tab
  const switchTab = (tabId) => {
    if (tabId === activeTab) return;
    activeTab = tabId;

    // Update triggers
    element.querySelectorAll('[data-tab-trigger]').forEach(trigger => {
      const isActive = trigger.dataset.tabTrigger === tabId;
      trigger.setAttribute('aria-selected', isActive);
      trigger.style.background = isActive ? 'var(--sidebar-bg, #1f2937)' : 'transparent';
      trigger.style.color = isActive ? 'var(--primary-color, #6366f1)' : 'var(--text-muted, #9ca3af)';
      trigger.style.borderBottomColor = isActive ? 'var(--primary-color, #6366f1)' : 'transparent';
    });

    // Update panels
    element.querySelectorAll('[data-tab-panel]').forEach(panel => {
      const isActive = panel.dataset.tabPanel === tabId;
      panel.style.display = isActive ? 'block' : 'none';
    });
  };

  // Attach event handlers to existing triggers (SSR-rendered)
  element.querySelectorAll('[data-tab-trigger]').forEach(trigger => {
    trigger.onclick = () => switchTab(trigger.dataset.tabTrigger);
  });

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
