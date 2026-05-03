---
title: "ライフサイクル: onCleanup"
---

# onCleanup

コンポーネントがアンマウントされるか Effect が再実行されるときに実行されるクリーンアップ関数を登録します。

## 基本的な使い方

```typescript
import { onCleanup } from '@luna_ui/luna';

function Timer() {
  const [count, setCount] = createSignal(0);

  const interval = setInterval(() => {
    setCount(c => c + 1);
  }, 1000);

  // コンポーネントアンマウント時にクリーンアップ
  onCleanup(() => {
    clearInterval(interval);
  });

  return <p>Count: {count()}</p>;
}
```

## onCleanup が実行されるタイミング

### コンポーネント内

コンポーネントが DOM から削除されるときに実行：

```typescript
function Parent() {
  const [show, setShow] = createSignal(true);

  return (
    <>
      <button onClick={() => setShow(s => !s)}>トグル</button>
      <Show when={show()}>
        <Child />  {/* 非表示時に onCleanup 実行 */}
      </Show>
    </>
  );
}

function Child() {
  onCleanup(() => {
    console.log("Child unmounted!");
  });

  return <p>ここにいます</p>;
}
```

### Effect 内

Effect が再実行または破棄される前に実行：

```typescript
const [url, setUrl] = createSignal("/api/data");

createEffect(() => {
  const currentUrl = url();
  const controller = new AbortController();

  fetch(currentUrl, { signal: controller.signal })
    .then(res => res.json())
    .then(setData);

  // url が変更されたとき（次の fetch 前）にクリーンアップ実行
  onCleanup(() => {
    controller.abort();
  });
});
```

## 一般的なユースケース

### タイマー

```typescript
function Countdown(props) {
  const [remaining, setRemaining] = createSignal(props.seconds);

  const interval = setInterval(() => {
    setRemaining(r => {
      if (r <= 0) {
        clearInterval(interval);
        return 0;
      }
      return r - 1;
    });
  }, 1000);

  onCleanup(() => clearInterval(interval));

  return <p>{remaining()} 秒</p>;
}
```

### イベントリスナー

```typescript
function WindowResize() {
  const [size, setSize] = createSignal({
    width: window.innerWidth,
    height: window.innerHeight,
  });

  const handler = () => {
    setSize({
      width: window.innerWidth,
      height: window.innerHeight,
    });
  };

  window.addEventListener("resize", handler);

  onCleanup(() => {
    window.removeEventListener("resize", handler);
  });

  return <p>ウィンドウ: {size().width}x{size().height}</p>;
}
```

### WebSocket 接続

```typescript
function Chat(props) {
  const [messages, setMessages] = createSignal([]);

  const ws = new WebSocket(`wss://chat.example.com/${props.room}`);

  ws.onmessage = (event) => {
    setMessages(prev => [...prev, JSON.parse(event.data)]);
  };

  onCleanup(() => {
    ws.close();
  });

  return (
    <For each={messages()}>
      {(msg) => <p>{msg.text}</p>}
    </For>
  );
}
```

## よくある間違い

### クリーンアップの忘れ

```typescript
// 悪い: メモリリーク！
function BadComponent() {
  setInterval(() => {
    console.log("アンマウント後も実行中！");
  }, 1000);

  return <div>...</div>;
}

// 良い: 適切なクリーンアップ
function GoodComponent() {
  const interval = setInterval(() => {
    console.log("アンマウント時にクリーンアップ");
  }, 1000);

  onCleanup(() => clearInterval(interval));

  return <div>...</div>;
}
```

## 試してみよう

以下を行うコンポーネントを作成：

1. マウント時に WebSocket 接続を開く
2. 受信メッセージを表示
3. アンマウント時に接続を適切に閉じる

<details>
<summary>解答</summary>

```typescript
function WebSocketDemo() {
  const [messages, setMessages] = createSignal([]);
  const [status, setStatus] = createSignal("connecting");

  let ws;

  onMount(() => {
    ws = new WebSocket("wss://echo.websocket.org");

    ws.onopen = () => {
      setStatus("connected");
    };

    ws.onmessage = (event) => {
      setMessages(prev => [...prev, event.data]);
    };

    ws.onerror = () => {
      setStatus("error");
    };

    ws.onclose = () => {
      setStatus("disconnected");
    };
  });

  onCleanup(() => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.close();
    }
  });

  const sendMessage = () => {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send("Hello!");
    }
  };

  return (
    <div>
      <p>Status: {status()}</p>
      <button onClick={sendMessage} disabled={status() !== "connected"}>
        Send Hello
      </button>
      <ul>
        <For each={messages()}>
          {(msg) => <li>{msg}</li>}
        </For>
      </ul>
    </div>
  );
}
```

</details>

## 次へ

[Islands アーキテクチャ →](./islands_basics) について学ぶ
