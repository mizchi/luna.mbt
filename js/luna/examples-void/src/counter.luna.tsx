/** @jsxImportSource @luna_ui/luna/ssr */
import { createSignal } from "@luna_ui/luna";

export default function Counter({ initialCount }: { initialCount: number }) {
  const [count, setCount] = createSignal(initialCount);
  return (
    <div>
      <label>
        Draft
        <input data-luna-draft="" value="server" />
      </label>
      <button data-counter="luna" onClick={() => setCount((value) => value + 1)}>
        {() => `Luna ${count()}`}
      </button>
    </div>
  );
}
