// Progress Demo - Animated progress bars
// SSR-compatible: adopts existing DOM, adds animation
//
// SSR HTML Convention:
//   <progress-demo luna:trigger="visible">
//     <div data-progress data-value="0" data-target="75" data-max="100">
//       <div data-progress-indicator style="transform:translateX(-100%)"></div>
//     </div>
//   </progress-demo>

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
        indicator.style.transform = `translateX(-${100 - pct}%)`;
        bar.setAttribute('aria-valuenow', current);
        bar.dataset.value = current;
        requestAnimationFrame(animate);
      }
    };

    setTimeout(animate, 100);
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
