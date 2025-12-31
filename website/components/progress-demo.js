// Progress Demo - Progress bar with animation
// SSR-compatible: adopts existing DOM, adds animation
export function hydrate(element, state, name) {
  // Find progress bars and animate them
  element.querySelectorAll('[data-progress]').forEach(bar => {
    const indicator = bar.querySelector('[data-progress-indicator]');
    const targetValue = parseInt(bar.dataset.target || bar.dataset.value || '0', 10);
    const maxValue = parseInt(bar.dataset.max || '100', 10);

    if (!indicator) return;

    // Animate to target value
    let currentValue = 0;
    const animate = () => {
      if (currentValue < targetValue) {
        currentValue = Math.min(currentValue + 2, targetValue);
        const percentage = maxValue > 0 ? (currentValue * 100 / maxValue) : 0;
        const translate = 100 - percentage;
        indicator.style.transform = `translateX(-${translate}%)`;
        bar.setAttribute('aria-valuenow', currentValue);
        bar.dataset.value = currentValue;
        requestAnimationFrame(animate);
      }
    };

    // Start animation after a short delay
    setTimeout(animate, 100);
  });

  // Mark as hydrated
  element.dataset.hydrated = 'true';
}

export default hydrate;
