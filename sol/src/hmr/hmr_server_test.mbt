///|
using @test {assert_eq}

///|
test "HmrMessage::to_json - update includes islands and timestamp" {
  let msg = HmrMessage::Update(islands=["*"], timestamp_ms=1234.0).to_json()
  assert_true(msg.contains("\"type\":\"update\""))
  assert_true(msg.contains("\"islands\":[\"*\"]"))
  assert_true(msg.contains("\"timestamp\":1234"))
}

///|
test "HmrMessage::to_json - full reload" {
  let msg = HmrMessage::FullReload.to_json()
  assert_eq(msg, "{\"type\":\"full-reload\"}")
}

///|
test "HmrMessage::to_json - error message" {
  let msg = HmrMessage::Error(message="bad").to_json()
  assert_true(msg.contains("\"type\":\"error\""))
  assert_true(msg.contains("\"error\":\"bad\""))
}

///|
async test "HmrServer broadcasts over built-in WebSocket server" {
  let server = HmrServer::start(0).wait()
  let received = connect_and_wait_message(server.get_port(), fn() {
    server.notify_full_reload()
  }).wait()
  assert_eq(received, HmrMessage::FullReload.to_json())
  server.close()
}

///|
async test "HmrServer on_connection exposes typed client wrapper" {
  let server = HmrServer::start(0).wait()
  server.on_connection(fn(client) {
    if client.is_open() {
      client.send("typed-client")
    } else {
      client.send("closed-client")
    }
  })
  let received = connect_and_collect_messages(server.get_port(), 2).wait()
  assert_eq(received[0], HmrMessage::Connected.to_json())
  assert_eq(received[1], "typed-client")
  server.close()
}

///|
extern "js" fn connect_and_wait_message(
  port : Int,
  trigger : () -> Unit,
) -> @js.Promise[String] =
  #| (port, trigger) => new Promise((resolve, reject) => {
  #|   const ws = new WebSocket(`ws://127.0.0.1:${port}`);
  #|   const timeout = setTimeout(() => {
  #|     ws.close();
  #|     reject(new Error('Timed out waiting for HMR message'));
  #|   }, 1000);
  #|   const finish = (fn, value) => {
  #|     clearTimeout(timeout);
  #|     ws.close();
  #|     fn(value);
  #|   };
  #|   ws.addEventListener('open', () => trigger(), { once: true });
  #|   ws.addEventListener('message', (event) => {
  #|     finish(resolve, String(event.data));
  #|   }, { once: true });
  #|   ws.addEventListener('error', (event) => {
  #|     finish(reject, new Error(`WebSocket error: ${event.type}`));
  #|   }, { once: true });
  #| })

///|
extern "js" fn connect_and_collect_messages(
  port : Int,
  expected_count : Int,
) -> @js.Promise[Array[String]] =
  #| (port, expectedCount) => new Promise((resolve, reject) => {
  #|   const ws = new WebSocket(`ws://127.0.0.1:${port}`);
  #|   const messages = [];
  #|   const timeout = setTimeout(() => {
  #|     ws.close();
  #|     reject(new Error('Timed out waiting for HMR messages'));
  #|   }, 1000);
  #|   const finish = (fn, value) => {
  #|     clearTimeout(timeout);
  #|     ws.close();
  #|     fn(value);
  #|   };
  #|   ws.addEventListener('message', (event) => {
  #|     messages.push(String(event.data));
  #|     if (messages.length === expectedCount) {
  #|       finish(resolve, messages);
  #|     }
  #|   });
  #|   ws.addEventListener('error', (event) => {
  #|     finish(reject, new Error(`WebSocket error: ${event.type}`));
  #|   }, { once: true });
  #| })
