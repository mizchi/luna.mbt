/**
 * Card component - purely structural, no JS behavior needed
 *
 * This is a CSS-only component. The JS module is provided
 * for consistency and potential future interactivity.
 *
 * Expected DOM structure:
 * ```html
 * <div data-card>
 *   <div data-card-header>
 *     <h3 data-card-title>Title</h3>
 *     <p data-card-description>Description</p>
 *   </div>
 *   <div data-card-content>
 *     Content goes here
 *   </div>
 *   <div data-card-footer>
 *     Footer content
 *   </div>
 * </div>
 * ```
 *
 * CSS selectors:
 * - [data-card] - main container
 * - [data-card-header] - header section
 * - [data-card-title] - title element
 * - [data-card-description] - description text
 * - [data-card-content] - main content area
 * - [data-card-footer] - footer section
 */

import type { CleanupFn } from '../core/types';

export interface CardOptions {
  /**
   * Make card clickable (adds hover/focus states)
   */
  clickable?: boolean;

  /**
   * Callback when card is clicked (only if clickable)
   */
  onClick?: () => void;
}

/**
 * Setup card behavior (optional - for interactive cards)
 */
export function setupCard(el: Element, options: CardOptions = {}): CleanupFn {
  const { clickable = false, onClick } = options;

  if (!clickable || !onClick) {
    return () => {};
  }

  el.setAttribute('data-clickable', 'true');
  el.setAttribute('tabindex', '0');
  el.setAttribute('role', 'button');

  const handleClick = () => onClick();
  const handleKeydown = (e: KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      onClick();
    }
  };

  el.addEventListener('click', handleClick);
  el.addEventListener('keydown', handleKeydown as EventListener);

  return () => {
    el.removeEventListener('click', handleClick);
    el.removeEventListener('keydown', handleKeydown as EventListener);
    el.removeAttribute('data-clickable');
    el.removeAttribute('tabindex');
    el.removeAttribute('role');
  };
}
