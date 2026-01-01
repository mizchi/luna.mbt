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
/// Create and start HMR WebSocket server on specified port
/// Uses Node.js 'ws' package via dynamic import
pub async fn HmrServer::start(port : Int) -> HmrServer {
  let inner = create_ws_server_async(port)
  let server = HmrServer::{ inner, port }
  // Log connections
  inner._call("on", [
    @js.any("connection"),
    @js.any(fn(_ws : @js.Any) {
      println(@colorette.gray("[HMR] Client connected"))
    }),
  ])
  |> ignore
  inner._call("on", [
    @js.any("error"),
    @js.any(fn(err : @js.Any) {
      @console.error(@js.any("[HMR] Server error: \{err}"))
    }),
  ])
  |> ignore
  println(@colorette.cyan("[HMR] WebSocket server started on port \{port}"))
  server
}

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
  let timestamp = @cli_common.date_now().to_int()
  let q = "\""
  let islands_json = islands.map(fn(s) { q + s + q }).join(",")
  let msg = "{" +
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
    timestamp.to_string() +
    "}"
  self.broadcast(msg)
  let islands_str = islands.join(", ")
  println(@colorette.green("[HMR] Sent update: \{islands_str}"))
}

///|
/// Send full reload request
pub fn HmrServer::notify_reload(self : HmrServer) -> Unit {
  self.broadcast("{\"type\":\"reload\"}")
  println(@colorette.green("[HMR] Sent reload"))
}

///|
/// Send full reload request (alias for notify_reload)
pub fn HmrServer::notify_full_reload(self : HmrServer) -> Unit {
  self.broadcast("{\"type\":\"full-reload\"}")
  println(@colorette.yellow("[HMR] Sent full-reload"))
}

///|
/// Send error notification
pub fn HmrServer::notify_error(self : HmrServer, error : String) -> Unit {
  let escaped = escape_json_string(error)
  let q = "\""
  let msg = "{" +
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
  self.broadcast(msg)
  println(@colorette.red("[HMR] Sent error notification"))
}

///|
/// Send connected message to new clients
pub fn HmrServer::on_connection(
  self : HmrServer,
  handler : (@js.Any) -> Unit,
) -> Unit {
  self.inner._call("on", [
    @js.any("connection"),
    @js.any(fn(ws : @js.Any) {
      // Send connected message
      ws._call("send", [@js.any("{\"type\":\"connected\"}")]) |> ignore
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
/// Create WebSocket server using 'ws' package (async for ESM compatibility)
async fn create_ws_server_async(port : Int) -> @js.Any {
  let ws = import_ws().wait()
  let wss_class = ws["WebSocketServer"]
  create_wss_instance(wss_class, port)
}

///|
/// Dynamic import for 'ws' module (ESM compatible)
extern "js" fn import_ws() -> @js.Promise[@js.Any] =
  #| () => import('ws')

///|
extern "js" fn create_wss_instance(wss_class : @js.Any, port : Int) -> @js.Any =
  #| (WSSClass, port) => new WSSClass({ port })

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
