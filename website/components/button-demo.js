// Button Demo - Shows different button variants
// SSR-compatible: adopts existing DOM, adds event handlers only
export function hydrate(element, state, name) {
  let clickCount = 0;
  const countDisplay = element.querySelector('[data-click-count]');

  // Update click count display
  const updateCount = () => {
    if (countDisplay) {
      countDisplay.textContent = `Clicks: ${clickCount}`;
    }
  };

  // Attach event handlers to existing buttons (SSR-rendered)
  element.querySelectorAll('button').forEach(btn => {
    btn.style.transition = 'opacity 0.2s';
    btn.onmouseover = () => btn.style.opacity = '0.8';
    btn.onmouseout = () => btn.style.opacity = '1';
    btn.onclick = () => {
      clickCount++;
      updateCount();
    };
  });

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
