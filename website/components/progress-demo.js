// Progress Demo - Animated progress bars
// SSR-compatible: adopts existing DOM, adds animation
// Uses CSS custom property --progress for dynamic values
//
// SSR HTML Convention:
//   <progress-demo luna:trigger="visible">
//     <div data-progress data-value="0" data-target="75" data-max="100" aria-valuenow="0">
//       <div data-progress-indicator></div>
//     </div>
//   </progress-demo>
//
// Required CSS:
//   [data-progress-indicator] {
//     transform: translateX(calc(-100% + var(--progress, 0) * 1%));
//     transition: transform 0.1s ease;
//   }

export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  element.querySelectorAll('[data-progress]').forEach(bar => {
    const indicator = bar.querySelector('[data-progress-indicator]');
    const target = parseInt(bar.dataset.target || bar.dataset.value || '0', 10);
    const max = parseInt(bar.dataset.max || '100', 10);

    if (!indicator) return;

    let current = 0;
    const animate = () => {
      if (current < target) {
        current = Math.min(current + 2, target);
        const pct = max > 0 ? (current * 100 / max) : 0;
        bar.style.setProperty('--progress', String(pct));
        bar.setAttribute('aria-valuenow', String(current));
        bar.dataset.value = String(current);
        requestAnimationFrame(animate);
      }
    };

    setTimeout(animate, 100);
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
