---
title: "リアクティビティ: ネストした Effects"
---

# ネストした Effects

Effect をネストしてスコープ付きリアクティブコンテキストを作成できます。

## Effect の所有権

別の Effect 内で Effect を作成すると、内側の Effect は外側の「所有」になります：

```typescript
const [showPanel, setShowPanel] = createSignal(false);
const [count, setCount] = createSignal(0);

createEffect(() => {
  if (showPanel()) {
    console.log("Panel shown");

    // この Effect は showPanel が true の間のみ存在
    createEffect(() => {
      console.log("Count:", count());
    });
  }
});

setShowPanel(true);   // "Panel shown", "Count: 0"
setCount(1);          // "Count: 1"
setShowPanel(false);  // "Panel shown"（内側の Effect は破棄）
setCount(2);          // 何も出力されない（内側の Effect はもう存在しない）
```

## 自動クリーンアップ

外側の Effect が再実行されると、すべての内側の Effect は自動的に破棄されます：

```typescript
const [page, setPage] = createSignal("home");
const [data, setData] = createSignal(null);

createEffect(() => {
  const currentPage = page();
  console.log("Loading page:", currentPage);

  // この Effect は page が変更されると破棄される
  createEffect(() => {
    console.log("Data updated:", data());
  });
});

setData({ title: "Home" });  // "Data updated: {title: Home}"
setPage("about");            // "Loading page: about"（内側の Effect 破棄）
setData({ title: "About" }); // "Data updated: {title: About}"（新しい内側の Effect）
```

## ユースケース

### 条件付き購読

```typescript
const [isLoggedIn, setIsLoggedIn] = createSignal(false);
const [notifications, setNotifications] = createSignal([]);

createEffect(() => {
  if (isLoggedIn()) {
    // ログイン時のみ通知を購読
    createEffect(() => {
      const notifs = notifications();
      updateNotificationBadge(notifs.length);
    });
  }
});
```

### スコープ付きリソース

```typescript
const [selectedUser, setSelectedUser] = createSignal(null);

createEffect(() => {
  const user = selectedUser();
  if (!user) return;

  // 選択されたユーザーにスコープされた WebSocket 接続
  const ws = new WebSocket(`/ws/user/${user.id}`);

  // メッセージ用の内側の Effect
  createEffect(() => {
    ws.onmessage = (e) => {
      handleMessage(JSON.parse(e.data));
    };
  });

  onCleanup(() => {
    ws.close();
  });
});
```

## 注意：メモリリーク

リアクティブコンテキスト外で作成された Effect に注意：

```typescript
// 間違い: Effect がクリーンアップされない
document.addEventListener("click", () => {
  createEffect(() => {
    console.log(count());  // メモリリーク！
  });
});

// 正しい: ライフサイクルを管理
let dispose;
document.addEventListener("click", () => {
  dispose?.();  // 前のをクリーンアップ
  dispose = createEffect(() => {
    console.log(count());
  });
});
```

## 試してみよう

各タブが独自のカウンターを持ち、そのタブがアクティブな間のみ追跡される「タブ」コンポーネントを作成：

<details>
<summary>解答</summary>

```typescript
const [activeTab, setActiveTab] = createSignal("a");
const [countA, setCountA] = createSignal(0);
const [countB, setCountB] = createSignal(0);

createEffect(() => {
  const tab = activeTab();
  console.log("Switched to tab:", tab);

  if (tab === "a") {
    createEffect(() => {
      console.log("Tab A count:", countA());
    });
  } else {
    createEffect(() => {
      console.log("Tab B count:", countB());
    });
  }
});

// アクティブなタブのみログ
setCountA(1);  // "Tab A count: 1"（タブ A がアクティブな場合）
setActiveTab("b");  // "Switched to tab: b"
setCountA(2);  // 何も出力されない（タブ A の Effect 破棄）
setCountB(1);  // "Tab B count: 1"
```

</details>

## 次へ

[Show（条件付きレンダリング）→](./flow_show) について学ぶ
