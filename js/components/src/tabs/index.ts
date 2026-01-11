import type { CleanupFn } from '../core/types';
import { combine } from '../core/types';
import { on, attr, query, queryAll } from '../core/dom';
import { onArrowNav } from '../core/keyboard';

export interface TabsOptions {
  /**
   * ID of the default selected tab
   */
  defaultTab?: string;

  /**
   * Callback when selected tab changes
   */
  onChange?: (tabId: string) => void;

  /**
   * Orientation for keyboard navigation (default: horizontal)
   */
  orientation?: 'horizontal' | 'vertical';
}

/**
 * Setup tabs behavior
 *
 * Expected DOM structure:
 * ```html
 * <div data-tabs>
 *   <div data-tablist role="tablist">
 *     <button data-tab data-tab-id="tab1" role="tab" aria-selected="true">
 *       Tab 1
 *     </button>
 *     <button data-tab data-tab-id="tab2" role="tab" aria-selected="false">
 *       Tab 2
 *     </button>
 *   </div>
 *   <div data-tabpanel data-panel-id="tab1" role="tabpanel">
 *     Content 1
 *   </div>
 *   <div data-tabpanel data-panel-id="tab2" role="tabpanel" hidden>
 *     Content 2
 *   </div>
 * </div>
 * ```
 */
export function setupTabs(el: Element, options: TabsOptions = {}): CleanupFn {
  const { defaultTab, onChange, orientation = 'horizontal' } = options;

  // Initialize default tab
  if (defaultTab) {
    selectTab(el, defaultTab);
  }

  const cleanups: CleanupFn[] = [];

  // Handle tab clicks
  const handleTabClick = (e: Event) => {
    const tab = (e.target as Element).closest('[data-tab]');
    if (!tab) return;

    const tabId = attr(tab, 'data-tab-id');
    if (!tabId) return;

    selectTab(el, tabId);
    onChange?.(tabId);
  };

  const tablist = query(el, '[data-tablist]');
  if (tablist) {
    cleanups.push(on(tablist as HTMLElement, 'click', handleTabClick));

    // Arrow key navigation
    cleanups.push(onArrowNav(tablist, '[data-tab]', {
      orientation,
      loop: true
    }));
  }

  return combine(...cleanups);
}

/**
 * Select a tab by ID
 */
export function selectTab(tabs: Element, tabId: string): void {
  // Update all tabs
  const allTabs = queryAll(tabs, '[data-tab]');
  for (const tab of allTabs) {
    const id = attr(tab, 'data-tab-id');
    const isSelected = id === tabId;
    attr(tab, 'aria-selected', isSelected ? 'true' : 'false');
    attr(tab, 'tabindex', isSelected ? '0' : '-1');
    attr(tab, 'data-state', isSelected ? 'active' : 'inactive');
  }

  // Update all panels
  const allPanels = queryAll(tabs, '[data-tabpanel]');
  for (const panel of allPanels) {
    const id = attr(panel, 'data-panel-id');
    const isActive = id === tabId;
    attr(panel, 'data-state', isActive ? 'active' : 'inactive');
    attr(panel, 'aria-hidden', isActive ? 'false' : 'true');
    if (isActive) {
      (panel as HTMLElement).removeAttribute('hidden');
    } else {
      (panel as HTMLElement).setAttribute('hidden', '');
    }
  }
}

/**
 * Get the currently selected tab ID
 */
export function getSelectedTab(tabs: Element): string | null {
  const selected = query(tabs, '[data-tab][aria-selected="true"]');
  if (selected) {
    return attr(selected, 'data-tab-id');
  }

  const active = query(tabs, '[data-tab][data-state="active"]');
  if (active) {
    return attr(active, 'data-tab-id');
  }

  return null;
}
