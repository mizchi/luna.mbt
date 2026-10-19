let serverRendering = false;

export function isServerRendering(): boolean {
  return serverRendering;
}

export function withServerRendering<T>(render: () => T): T {
  const previous = serverRendering;
  serverRendering = true;
  try {
    return render();
  } finally {
    serverRendering = previous;
  }
}
