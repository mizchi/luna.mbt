import { execFile } from "node:child_process";
import { once } from "node:events";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { chromium, expect, test } from "@playwright/test";
import { WebSocket, WebSocketServer } from "ws";

const run = promisify(execFile);
const cwd = fileURLToPath(new URL("./mbt_e2e/", import.meta.url));

test("MoonBit Playwright exercises the Sol app over BiDi", async ({ baseURL }) => {
  await run("moon", ["build", "--target", "js"], { cwd, timeout: 60_000 });
  // Resolve beside chromium-bidi's entry point so package layout changes do not
  // duplicate the mapper's build directory in our configuration.
  const mapper = new URL("./bidiServer/BrowserInstance.js", import.meta.resolve("chromium-bidi"));
  const { BrowserInstance } = await import(mapper.href);
  const browser = await BrowserInstance.run({
    chromeBinary: chromium.executablePath(),
    chromeArgs: ["--headless=new"],
  }, false);
  const server = new WebSocketServer({ host: "127.0.0.1", port: 0 });
  try {
    await once(server, "listening");
    const transport = browser.bidiSession();
    server.on("connection", socket => {
      const onMessage = (message: string) => {
        if (socket.readyState === WebSocket.OPEN) socket.send(message);
      };
      transport.on("message", onMessage);
      socket.on("close", () => transport.off("message", onMessage));
      socket.on("message", data => {
        const command = JSON.parse(data.toString());
        // The fixture owns browser lifetime; all DOM commands use the mapper.
        if (command.method === "session.end") {
          socket.send(JSON.stringify({ id: command.id, type: "success", result: {} }));
          return;
        }
        transport.sendCommand(data.toString()).catch((error: Error) => {
          if (socket.readyState === WebSocket.OPEN) {
            socket.send(JSON.stringify({ id: command.id, type: "error", error: "unknown error", message: error.message }));
          }
        });
      });
    });
    const address = server.address();
    if (!address || typeof address === "string") throw new Error("BiDi server has no TCP address");
    const result = run(process.execPath, ["--enable-source-maps", "_build/js/debug/build/sol_e2e.js"], {
      cwd,
      timeout: 310_000,
      env: { ...process.env, SOL_E2E_BASE_URL: baseURL, SOL_E2E_BIDI_URL: `ws://127.0.0.1:${address.port}` },
    });
    result.child.stdout?.on("data", data => process.stdout.write(data));
    result.child.stderr?.on("data", data => process.stderr.write(data));
    const { stdout } = await result;
    expect(stdout).toMatch(/Results: [1-9]\d* passed, 0 failed/);
  } finally {
    for (const socket of server.clients) socket.terminate();
    await new Promise<void>(resolve => server.close(() => resolve()));
    await browser.close();
  }
});
