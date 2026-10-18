/** @jsxImportSource solid-js */
import { createSignal } from "solid-js";

export function SolidCounter(props: { initialCount: number }) {
  const [count, setCount] = createSignal(props.initialCount);
  return (
    <button data-counter="solid" onClick={() => setCount(count() + 1)}>
      Solid {count()}
    </button>
  );
}
