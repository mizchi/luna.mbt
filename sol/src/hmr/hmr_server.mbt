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
/// Uses Node.js 'ws' package via dynamic import
/// Returns a Promise that resolves when server is ready
pub fn HmrServer::start(port : Int) -> @js.Promise[HmrServer] {
  create_hmr_server_promise(port)
}

///|
/// Create HMR server promise (internal)
extern "js" fn create_hmr_server_promise(port : Int) -> @js.Promise[HmrServer] =
  #| (port) => {
  #|   return import('ws').then(({ WebSocketServer }) => {
  #|     const wss = new WebSocketServer({ port });
  #|     wss.on('connection', () => console.log('\x1b[90m[HMR] Client connected\x1b[0m'));
  #|     wss.on('error', (err) => console.error('[HMR] Server error:', err));
  #|     console.log(`\x1b[36m[HMR] WebSocket server started on port ${port}\x1b[0m`);
  #|     return { inner: wss, port };
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
