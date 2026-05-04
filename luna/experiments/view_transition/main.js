// View Transition API - MPA Demo
// For cross-document transitions, the @view-transition CSS rule handles most of the work.
// This JS file is for additional customization and debugging.

// =============================================================================
// Configuration - Change this to test different direction modes
// =============================================================================
const DIRECTION_MODE = 'history'; // 'history' | 'depth' | 'manual' | 'none'

// =============================================================================
// Direction Strategy Functions
// =============================================================================

/**
 * depth: URL階層で判定
 * 深くなる=forwards、浅くなる=backwards、同階層=辞書順
 */
function getDirectionByDepth(fromUrl, toUrl) {
  if (!fromUrl || !toUrl) return 'forwards';

  try {
    const fromPath = new URL(fromUrl).pathname;
    const toPath = new URL(toUrl).pathname;

    const fromDepth = fromPath.split('/').filter(Boolean).length;
    const toDepth = toPath.split('/').filter(Boolean).length;

    if (toDepth > fromDepth) return 'forwards';
    if (toDepth < fromDepth) return 'backwards';

    // 同階層: アルファベット順
    return fromPath < toPath ? 'forwards' : 'backwards';
  } catch {
    return 'forwards';
  }
}

/**
 * history: ブラウザ履歴のみで判定
 * back_forward なら backwards、それ以外は forwards
 */
function getDirectionByHistory() {
  const navEntry = performance.getEntriesByType('navigation')[0];
  return navEntry?.type === 'back_forward' ? 'backwards' : 'forwards';
}

/**
 * manual: クリックされたリンクの data-sol-direction 属性から取得
 * 属性がなければ forwards
 */
function getDirectionManual(clickedLink) {
  return clickedLink?.dataset?.solDirection || 'forwards';
}

/**
 * 統合: モードに応じて direction を返す
 */
function getDirection(fromUrl, toUrl, clickedLink = null) {
  switch (DIRECTION_MODE) {
    case 'depth':
      return getDirectionByDepth(fromUrl, toUrl);
    case 'history':
      return getDirectionByHistory();
    case 'manual':
      return getDirectionManual(clickedLink);
    case 'none':
    default:
      return null; // direction を設定しない
  }
}

// =============================================================================
// Track clicked link for manual mode
// =============================================================================
let lastClickedLink = null;

document.addEventListener('click', (e) => {
  const link = e.target.closest('a');
  if (link) {
    lastClickedLink = link;
    // Store for cross-page access
    if (link.dataset.solDirection) {
      sessionStorage.setItem('solDirection', link.dataset.solDirection);
    }
  }
});

// =============================================================================
// View Transition Event Handlers
// =============================================================================

// pageswap: fires on the OLD page before navigation
window.addEventListener('pageswap', (event) => {
  const fromUrl = location.href;
  const toUrl = event.activation?.entry?.url;

  console.log(`[pageswap] Mode: ${DIRECTION_MODE}`);
  console.log('[pageswap] From:', fromUrl);
  console.log('[pageswap] To:', toUrl);

  if (event.viewTransition && toUrl) {
    const direction = getDirection(fromUrl, toUrl, lastClickedLink);

    if (direction) {
      event.viewTransition.types.add(direction);
      console.log('[pageswap] Direction:', direction);
    }

    // Save context to sessionStorage for the new page
    sessionStorage.setItem('viewTransitionFrom', fromUrl);
  }
});

// pagereveal: fires on the NEW page after navigation
window.addEventListener('pagereveal', (event) => {
  const activation = navigation.activation;
  const fromUrl = activation?.from?.url;
  const toUrl = activation?.entry?.url;

  console.log(`[pagereveal] Mode: ${DIRECTION_MODE}`);
  console.log('[pagereveal] From:', fromUrl);
  console.log('[pagereveal] To:', toUrl);
  console.log('[pagereveal] Navigation type:', activation?.navigationType);

  if (event.viewTransition) {
    // For manual mode, check sessionStorage (link was on previous page)
    const storedDirection = sessionStorage.getItem('solDirection');
    if (storedDirection) {
      sessionStorage.removeItem('solDirection');
    }

    const direction = DIRECTION_MODE === 'manual' && storedDirection
      ? storedDirection
      : getDirection(fromUrl, toUrl);

    if (direction) {
      event.viewTransition.types.add(direction);
      console.log('[pagereveal] Direction:', direction);
    }

    // Read context from sessionStorage
    const previousPage = sessionStorage.getItem('viewTransitionFrom');
    if (previousPage) {
      console.log('[pagereveal] Previous page was:', previousPage);
      sessionStorage.removeItem('viewTransitionFrom');
    }
  }
});

// =============================================================================
// Prefetch: scan links with data-sol-prefetch
// =============================================================================
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('a[data-sol-prefetch]').forEach(link => {
    const href = link.getAttribute('href');
    if (href && !href.startsWith('http')) {
      const prefetchLink = document.createElement('link');
      prefetchLink.rel = 'prefetch';
      prefetchLink.href = href;
      document.head.appendChild(prefetchLink);
      console.log('[prefetch] Added:', href);
    }
  });
});

// Feature detection
if (!document.startViewTransition) {
  console.log('View Transitions API (SPA) not supported');
}

// Check for cross-document support (Chrome 126+)
if (!('CSSViewTransitionRule' in window)) {
  console.log('Cross-document View Transitions may not be fully supported');
  // Add a notice to the page
  document.addEventListener('DOMContentLoaded', () => {
    const notice = document.createElement('div');
    notice.style.cssText = `
      position: fixed;
      bottom: 1rem;
      left: 1rem;
      right: 1rem;
      padding: 1rem;
      background: #fff3cd;
      border: 1px solid #ffc107;
      border-radius: 8px;
      font-size: 0.875rem;
      z-index: 1000;
    `;
    notice.innerHTML = `
      <strong>Note:</strong> Cross-document View Transitions require Chrome 126+.
      <a href="https://caniuse.com/view-transitions" target="_blank">Check browser support</a>
    `;
    document.body.appendChild(notice);
  });
}

