// Slider Demo - Draggable range slider
// SSR-compatible: adopts existing DOM, adds drag handlers
//
// SSR HTML Convention:
//   <slider-demo luna:trigger="visible">
//     <div data-slider data-value="50" data-min="0" data-max="100">
//       <div data-slider-track>
//         <div data-slider-range style="width:50%"></div>
//       </div>
//       <div data-slider-thumb style="left:50%"></div>
//     </div>
//     <span data-slider-value>50</span>
//   </slider-demo>

export function hydrate(element, state, name) {
  if (element.dataset.hydrated) return;

  element.querySelectorAll('[data-slider]').forEach(slider => {
    const track = slider.querySelector('[data-slider-track]');
    const range = slider.querySelector('[data-slider-range]');
    const thumb = slider.querySelector('[data-slider-thumb]');
    const display = slider.querySelector('[data-slider-value]');

    if (!track || !thumb) return;

    const min = parseInt(slider.dataset.min || '0', 10);
    const max = parseInt(slider.dataset.max || '100', 10);
    let value = parseInt(slider.dataset.value || '50', 10);

    const update = (val) => {
      value = Math.max(min, Math.min(max, val));
      const pct = ((value - min) / (max - min)) * 100;

      slider.dataset.value = value;
      slider.setAttribute('aria-valuenow', value);
      if (range) range.style.width = `${pct}%`;
      thumb.style.left = `${pct}%`;
      if (display) display.textContent = value;
    };

    const drag = (e) => {
      const rect = track.getBoundingClientRect();
      const x = e.touches ? e.touches[0].clientX : e.clientX;
      const pct = Math.max(0, Math.min(1, (x - rect.left) / rect.width));
      update(Math.round(min + pct * (max - min)));
    };

    const start = (e) => {
      e.preventDefault();
      drag(e);
      const move = (e) => drag(e);
      const end = () => {
        document.removeEventListener('mousemove', move);
        document.removeEventListener('mouseup', end);
        document.removeEventListener('touchmove', move);
        document.removeEventListener('touchend', end);
      };
      document.addEventListener('mousemove', move);
      document.addEventListener('mouseup', end);
      document.addEventListener('touchmove', move);
      document.addEventListener('touchend', end);
    };

    track.addEventListener('mousedown', start);
    track.addEventListener('touchstart', start);
    thumb.addEventListener('mousedown', start);
    thumb.addEventListener('touchstart', start);

    // Keyboard
    thumb.addEventListener('keydown', (e) => {
      const step = parseInt(slider.dataset.step || '1', 10);
      if (e.key === 'ArrowRight' || e.key === 'ArrowUp') update(value + step);
      if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') update(value - step);
    });
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
