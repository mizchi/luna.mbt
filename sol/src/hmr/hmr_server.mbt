// HMR WebSocket Server
//
// Shared module for Hot Module Replacement WebSocket functionality.
// Used by Sol CLI for development servers.

///|
/// WebSocket server handle (opaque type wrapping Node.js WebSocketServer)
pub struct HmrServer {
  priv inner : @js.Any
  port : Int
}

///|
pub(all) enum HmrMessage {
  Connected
  Reload
  FullReload
  Update(islands~ : Array[String], timestamp_ms~ : Double)
  Error(message~ : String)
}

///|
pub fn HmrMessage::to_json(self : HmrMessage) -> String {
  match self {
    Connected => "{\"type\":\"connected\"}"
    Reload => "{\"type\":\"reload\"}"
    FullReload => "{\"type\":\"full-reload\"}"
    Update(islands~, timestamp_ms~) => {
      let q = "\""
      let islands_json = islands.map(fn(s) { q + s + q }).join(",")
      "{" +
      q +
      "type" +
      q +
      ":" +
      q +
      "update" +
      q +
      "," +
      q +
      "islands" +
      q +
      ":[" +
      islands_json +
      "]," +
      q +
      "timestamp" +
      q +
      ":" +
      timestamp_ms.to_string() +
      "}"
    }
    Error(message~) => {
      let escaped = escape_json_string(message)
      let q = "\""
      "{" +
      q +
      "type" +
      q +
      ":" +
      q +
      "error" +
      q +
      "," +
      q +
      "error" +
      q +
      ":" +
      q +
      escaped +
      q +
      "}"
    }
  }
}

///|
/// Create and start HMR WebSocket server on specified port (async version)
/// Uses Node.js built-ins so moon-installed CLIs do not need npm deps.
/// Returns a Promise that resolves when server is ready
pub fn HmrServer::start(port : Int) -> @js.Promise[HmrServer] {
  create_hmr_server_promise(port)
}

///|
/// Create HMR server promise (internal)
extern "js" fn create_hmr_server_promise(port : Int) -> @js.Promise[HmrServer] =
  #| (port) => {
  #|   const GUID = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
  #|   const env = globalThis?.process?.env ?? {};
  #|   const useColor = !('NO_COLOR' in env) && env.FORCE_COLOR !== '0' && (env.FORCE_COLOR || globalThis?.process?.stdout?.isTTY);
  #|   const color = (code, text) => useColor ? `\x1b[${code}m${text}\x1b[0m` : text;
  #|   const encodeTextFrame = (message) => {
  #|     const payload = Buffer.from(String(message));
  #|     if (payload.length < 126) {
  #|       return Buffer.concat([Buffer.from([0x81, payload.length]), payload]);
  #|     }
  #|     if (payload.length < 65536) {
  #|       const header = Buffer.alloc(4);
  #|       header[0] = 0x81;
  #|       header[1] = 126;
  #|       header.writeUInt16BE(payload.length, 2);
  #|       return Buffer.concat([header, payload]);
  #|     }
  #|     const header = Buffer.alloc(10);
  #|     header[0] = 0x81;
  #|     header[1] = 127;
  #|     header.writeBigUInt64BE(BigInt(payload.length), 2);
  #|     return Buffer.concat([header, payload]);
  #|   };
  #|   return Promise.all([import('node:http'), import('node:crypto')]).then(([http, crypto]) => {
  #|     const clients = new Set();
  #|     const listeners = new Map();
  #|     const wss = {
  #|       clients,
  #|       on(event, handler) {
  #|         const list = listeners.get(event) ?? [];
  #|         list.push(handler);
  #|         listeners.set(event, list);
  #|         return this;
  #|       },
  #|       emit(event, ...args) {
  #|         for (const handler of listeners.get(event) ?? []) handler(...args);
  #|       },
  #|       close() {
  #|         for (const client of [...clients]) client.close();
  #|         server.close();
  #|       },
  #|     };
  #|     const server = http.createServer((_, res) => {
  #|       res.statusCode = 404;
  #|       res.end();
  #|     });
  #|     server.on('upgrade', (req, socket) => {
  #|       const key = req.headers['sec-websocket-key'];
  #|       if (!key) {
  #|         socket.destroy();
  #|         return;
  #|       }
  #|       const accept = crypto.createHash('sha1').update(key + GUID).digest('base64');
  #|       socket.write([
  #|         'HTTP/1.1 101 Switching Protocols',
  #|         'Upgrade: websocket',
  #|         'Connection: Upgrade',
  #|         `Sec-WebSocket-Accept: ${accept}`,
  #|         '',
  #|         '',
  #|       ].join('\r\n'));
  #|       const client = {
  #|         readyState: 1,
  #|         send(message) {
  #|           if (!socket.destroyed) socket.write(encodeTextFrame(message));
  #|         },
  #|         close() {
  #|           socket.destroy();
  #|         },
  #|       };
  #|       clients.add(client);
  #|       socket.on('data', (chunk) => {
  #|         if ((chunk[0] & 0x0f) === 0x8) socket.end();
  #|       });
  #|       socket.on('close', () => clients.delete(client));
  #|       socket.on('error', () => clients.delete(client));
  #|       wss.emit('connection', client);
  #|     });
  #|     server.on('error', (err) => wss.emit('error', err));
  #|     wss.on('connection', () => console.log(color(90, '[HMR] Client connected')));
  #|     wss.on('error', (err) => console.error('[HMR] Server error:', err));
  #|     return new Promise((resolve, reject) => {
  #|       server.once('error', reject);
  #|       server.listen(port, () => {
  #|         server.off('error', reject);
  #|         const address = server.address();
  #|         const actualPort = typeof address === 'object' && address ? address.port : port;
  #|         console.log(color(36, `[HMR] WebSocket server started on port ${actualPort}`));
  #|         resolve({ inner: wss, port: actualPort });
  #|       });
  #|     });
  #|   });
  #| }

///|
/// Broadcast message to all connected clients
pub fn HmrServer::broadcast(self : HmrServer, message : String) -> Unit {
  broadcast_to_clients(self.inner, message)
}

///|
/// Send update notification for specific islands (sol-style granular HMR)
pub fn HmrServer::notify_update(
  self : HmrServer,
  islands : Array[String],
) -> Unit {
  let timestamp_ms = @cli_common.date_now()
  let msg = HmrMessage::Update(islands~, timestamp_ms~).to_json()
  self.broadcast(msg)
  let islands_str = islands.join(", ")
  println(@colorette.green("[HMR] Sent update: \{islands_str}"))
}

///|
/// Send full reload request
pub fn HmrServer::notify_reload(self : HmrServer) -> Unit {
  self.broadcast(HmrMessage::Reload.to_json())
  println(@colorette.green("[HMR] Sent reload"))
}

///|
/// Send full reload request (alias for notify_reload)
pub fn HmrServer::notify_full_reload(self : HmrServer) -> Unit {
  self.broadcast(HmrMessage::FullReload.to_json())
  println(@colorette.yellow("[HMR] Sent full-reload"))
}

///|
/// Send error notification
pub fn HmrServer::notify_error(self : HmrServer, error : String) -> Unit {
  let msg = HmrMessage::Error(message=error).to_json()
  self.broadcast(msg)
  println(@colorette.red("[HMR] Sent error notification"))
}

///|
/// Send connected message to new clients
pub fn HmrServer::on_connection(
  self : HmrServer,
  handler : (@js.Any) -> Unit,
) -> Unit {
  let connected_message = HmrMessage::Connected.to_json()
  self.inner._call("on", [
    @js.any("connection"),
    @js.any(fn(ws : @js.Any) {
      // Send connected message
      ws._call("send", [@js.any(connected_message)]) |> ignore
      handler(ws)
    }),
  ])
  |> ignore
}

///|
/// Close the server
pub fn HmrServer::close(self : HmrServer) -> Unit {
  self.inner._call("close", []) |> ignore
  println(@colorette.gray("[HMR] Server closed"))
}

///|
/// Get client count
pub fn HmrServer::client_count(self : HmrServer) -> Int {
  get_client_count(self.inner)
}

///|
/// Get the port this server is listening on
pub fn HmrServer::get_port(self : HmrServer) -> Int {
  self.port
}

// =============================================================================
// Utilities
// =============================================================================

///|
fn escape_json_string(s : String) -> String {
  s
  .replace(old="\\", new="\\\\")
  .replace(old="\"", new="\\\"")
  .replace(old="\n", new="\\n")
  .replace(old="\r", new="\\r")
  .replace(old="\t", new="\\t")
}

// =============================================================================
// FFI Functions
// =============================================================================

///|
/// Broadcast message to all clients
extern "js" fn broadcast_to_clients(wss : @js.Any, message : String) -> Unit =
  #| (wss, message) => {
  #|   wss.clients.forEach((client) => {
  #|     if (client.readyState === 1) { // WebSocket.OPEN
  #|       client.send(message);
  #|     }
  #|   });
  #| }

///|
/// Get number of connected clients
extern "js" fn get_client_count(wss : @js.Any) -> Int =
  #| (wss) => wss.clients.size
