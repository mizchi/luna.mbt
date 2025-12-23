import { signal, computed } from '@preact/signals';
import { render } from 'preact';

function Counter() {
  const count = signal(0);
  const doubled = computed(() => count.value * 2);

  return (
    <div>
      <p>Count: {count}</p>
      <p>Doubled: {doubled}</p>
      <button onClick={() => count.value++}>+</button>
      <button onClick={() => count.value--}>-</button>
      <button onClick={() => count.value = 0}>Reset</button>
    </div>
  );
}

render(<Counter />, document.getElementById('app')!);
