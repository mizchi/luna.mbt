// Slider Demo - Draggable slider control
// SSR-compatible: adopts existing DOM, adds drag handlers
export function hydrate(element, state, name) {
  element.querySelectorAll('[data-slider]').forEach(slider => {
    const track = slider.querySelector('[data-slider-track]');
    const range = slider.querySelector('[data-slider-range]');
    const thumb = slider.querySelector('[data-slider-thumb]');
    const valueDisplay = slider.querySelector('[data-slider-value]');

    if (!track || !thumb) return;

    const min = parseInt(slider.dataset.min || '0', 10);
    const max = parseInt(slider.dataset.max || '100', 10);
    let currentValue = parseInt(slider.dataset.value || '50', 10);

    const updateSlider = (value) => {
      currentValue = Math.max(min, Math.min(max, value));
      const percentage = ((currentValue - min) / (max - min)) * 100;

      if (range) range.style.width = `${percentage}%`;
      thumb.style.left = `${percentage}%`;
      slider.setAttribute('aria-valuenow', currentValue);
      slider.dataset.value = currentValue;
      if (valueDisplay) valueDisplay.textContent = currentValue;
    };

    const handleDrag = (e) => {
      const rect = track.getBoundingClientRect();
      const clientX = e.touches ? e.touches[0].clientX : e.clientX;
      const percentage = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
      const value = Math.round(min + percentage * (max - min));
      updateSlider(value);
    };

    const startDrag = (e) => {
      e.preventDefault();
      handleDrag(e);

      const moveHandler = (e) => handleDrag(e);
      const upHandler = () => {
        document.removeEventListener('mousemove', moveHandler);
        document.removeEventListener('mouseup', upHandler);
        document.removeEventListener('touchmove', moveHandler);
        document.removeEventListener('touchend', upHandler);
      };

      document.addEventListener('mousemove', moveHandler);
      document.addEventListener('mouseup', upHandler);
      document.addEventListener('touchmove', moveHandler);
      document.addEventListener('touchend', upHandler);
    };

    track.addEventListener('mousedown', startDrag);
    track.addEventListener('touchstart', startDrag);
    thumb.addEventListener('mousedown', startDrag);
    thumb.addEventListener('touchstart', startDrag);

    // Keyboard support
    thumb.addEventListener('keydown', (e) => {
      const step = parseInt(slider.dataset.step || '1', 10);
      if (e.key === 'ArrowRight' || e.key === 'ArrowUp') {
        updateSlider(currentValue + step);
      } else if (e.key === 'ArrowLeft' || e.key === 'ArrowDown') {
        updateSlider(currentValue - step);
      }
    });
  });

  element.dataset.hydrated = 'true';
}

export default hydrate;
