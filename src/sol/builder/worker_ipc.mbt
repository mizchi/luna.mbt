// Sol Builder - Worker IPC Helpers
//
// FFI functions and helpers for worker process communication.
// Used by domain-specific workers (e.g., sol/builder_pool/worker.mbt).

// =============================================================================
// FFI for IPC Communication
// =============================================================================

///|
/// Listen for IPC messages from parent process
pub extern "js" fn on_message(callback : (@core.Any) -> Unit) -> Unit =
  #| (callback) => {
  #|   process.on("message", (msg) => callback(msg));
  #| }

///|
/// Send IPC message to parent process
pub extern "js" fn send_message(message : @core.Any) -> Bool =
  #| (message) => {
  #|   return process.send(message);
  #| }

///|
/// Exit the worker process
pub extern "js" fn exit(code : Int) -> Unit =
  #| (code) => {
  #|   process.exit(code);
  #| }

// =============================================================================
// Message Helpers
// =============================================================================

///|
/// Send ready message to parent
pub fn send_ready() -> Unit {
  let obj = @core.new_object()
  obj["type"] = @core.any("ready")
  send_message(obj) |> ignore
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
  send_message(obj) |> ignore
}

// =============================================================================
// Message Parsing
// =============================================================================

///|
/// Parse init data from message
pub fn parse_init_data(msg : @core.Any) -> String? {
  let msg_type : String = msg["type"].cast()
  if msg_type == "init" {
    Some(msg["data"].cast())
  } else {
    None
  }
}

///|
/// Parse job ID from message
pub fn parse_job_id(msg : @core.Any) -> Int? {
  let msg_type : String = msg["type"].cast()
  if msg_type == "job" {
    Some(msg["jobId"].cast())
  } else {
    None
  }
}

///|
/// Check if message is shutdown
pub fn is_shutdown(msg : @core.Any) -> Bool {
  let msg_type : String = msg["type"].cast()
  msg_type == "shutdown"
}
