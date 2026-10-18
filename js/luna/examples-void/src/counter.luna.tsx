/** @jsxImportSource @luna_ui/luna */
import { createSignal } from "@luna_ui/luna";
import { defineLunaIsland } from "@luna_ui/luna/void/client";

function Counter({ initialCount }: { initialCount: number }) {
  const [count, setCount] = createSignal(initialCount);
  return (
    <button data-counter="luna" onClick={() => setCount((value) => value + 1)}>
      {() => `Luna ${count()}`}
    </button>
  );
}

export default defineLunaIsland(Counter);
