import { createElement, useState } from "react";

export function ReactCounter({ initialCount }: { initialCount: number }) {
  const [count, setCount] = useState(initialCount);
  return createElement(
    "button",
    { "data-counter": "react", onClick: () => setCount(count + 1) },
    `React ${count}`,
  );
}
