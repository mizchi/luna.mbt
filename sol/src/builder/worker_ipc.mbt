// Sol Builder - Worker IPC Helpers
//
// FFI functions and helpers for worker process communication.
// Used by domain-specific workers (e.g., sol/builder_pool/worker.mbt).

// =============================================================================
// FFI for IPC Communication
// =============================================================================

///|
/// Listen for IPC messages from parent process
extern "js" fn on_message_raw(callback : (@core.Any) -> Unit) -> Unit =
  #| (callback) => {
  #|   process.on("message", (msg) => callback(msg));
  #| }

///|
/// Send IPC message to parent process
extern "js" fn send_message_raw(message : @core.Any) -> Bool =
  #| (message) => {
  #|   return process.send(message);
  #| }

///|
/// Exit the worker process
pub extern "js" fn exit(code : Int) -> Unit =
  #| (code) => {
  #|   process.exit(code);
  #| }

///|
/// Listen for typed IPC messages from parent process.
pub fn on_message(callback : (IpcMessage) -> Unit) -> Unit {
  on_message_raw(fn(raw) { callback(IpcMessage::from_raw(raw)) })
}

///|
/// Send typed IPC message to parent process.
pub fn send_message(message : IpcMessage) -> Bool {
  send_message_raw(message.raw())
}

// =============================================================================
// Message Helpers
// =============================================================================

///|
/// Send ready message to parent
pub fn send_ready() -> Unit {
  let obj = @core.new_object()
  obj["type"] = @core.any("ready")
  send_message(IpcMessage::from_raw(obj)) |> ignore
}

///|
/// Send done message to parent with job result
pub fn send_done(result : JobResult) -> Unit {
  send_message(result.to_json()) |> ignore
}

///|
/// Send error message to parent
pub fn send_error(message : String) -> Unit {
  let obj = @core.new_object()
  obj["type"] = @core.any("error")
  obj["message"] = @core.any(message)
  send_message(IpcMessage::from_raw(obj)) |> ignore
}

// =============================================================================
// Message Parsing
// =============================================================================

///|
/// Parse init data from message
pub fn parse_init_data(msg : IpcMessage) -> String? {
  let raw = msg.raw()
  let msg_type : String = raw["type"].cast()
  if msg_type == "init" {
    Some(raw["data"].cast())
  } else {
    None
  }
}

///|
/// Parse job ID from message
pub fn parse_job_id(msg : IpcMessage) -> Int? {
  let raw = msg.raw()
  let msg_type : String = raw["type"].cast()
  if msg_type == "job" {
    Some(raw["jobId"].cast())
  } else {
    None
  }
}

///|
/// Check if message is shutdown
pub fn is_shutdown(msg : IpcMessage) -> Bool {
  let raw = msg.raw()
  let msg_type : String = raw["type"].cast()
  msg_type == "shutdown"
}
