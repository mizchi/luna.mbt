# Luna HMR (Hot Module Replacement) 設計

## 背景

LunaはMoonBitで実装されたIsland ArchitectureベースのUIフレームワーク。開発体験向上のためHMRを実装したい。

### 参考実装

- **Vite HMR API**: `import.meta.hot.accept/dispose/data/invalidate`
- **Solid Refresh**: Babelプラグインでコンポーネントをラップ・メモ化し、更新時に置換

### Lunaの特性（Solidとの違い）

| 特性 | Solid | Luna |
|------|-------|------|
| プリコンパイル | JSX → Babel変換 | なし（MoonBit直接コンパイル） |
| 粒度 | コンポーネント単位 | Island単位 |
| 状態管理 | Signal（ランタイム追跡） | Signal（同様） |
| DOM更新 | 細粒度リアクティブ | 細粒度リアクティブ |

**重要**: Lunaにはプリコンパイルがないため、Solid Refreshのような「コンポーネント関数をラップして差し替え」は難しい。

---

## 設計方針

### アプローチ: 外付けHMRランタイム + Island単位再hydration

**決定**: HMRランタイムはluna本体とは完全に分離し、sol dev専用の外付けモジュールとして実装する。

#### 理由

1. luna loader（prod）のサイズ増加ゼロ（現在~4.2KB維持）
2. luna本体にprod/dev分岐が不要
3. 既存のグローバルAPI（`__LUNA_*`）で全て実現可能
4. sol以外の環境でlunaを使う場合に影響なし

#### アーキテクチャ

```
Production:
┌─────────────────────────────────────┐
│  <script src="/luna-loader.js">     │  ← 4.2KB、HMRコードなし
└─────────────────────────────────────┘

Development:
┌─────────────────────────────────────┐
│  <script src="/luna-loader.js">     │  ← 同じloader
│  <script src="/__hmr/client.js">    │  ← sol devが注入（HMR専用）
└─────────────────────────────────────┘
```

### HMRフロー

```
ファイル変更
    ↓
MoonBitコンパイル + Rolldownバンドル
    ↓
WebSocketで変更通知
    ↓
HMRクライアントが __LUNA_UNLOAD__ 呼び出し
    ↓
新モジュールをimport（キャッシュバスト）
    ↓
__LUNA_HYDRATE__ で再hydration
    ↓
状態復元（可能な場合）
```

### 既存の基盤（luna loader）

luna loaderが既に公開しているグローバルAPI:

```typescript
// js/loader/src/loader.ts
w.__LUNA_STATE__ = S;              // 状態マップ
w.__LUNA_HYDRATE__ = hydrate;      // 個別hydration
w.__LUNA_SCAN__ = scan;            // 全Islandスキャン
w.__LUNA_UNLOAD__ = unload;        // 個別unload
w.__LUNA_UNLOAD_ALL__ = unloadAll; // 一括unload
w.__LUNA_CLEAR_LOADED__ = clear;   // loaded状態クリア
```

HMRクライアントはこれらを呼ぶだけで実装できる。

### sol dev側の基盤

1. **ファイルwatch**: `src/sol/cli/dev.mbt` に300msデバウンス付きwatch実装済み
2. **状態シリアライズ**: `luna:state` 属性でJSON化済み
3. **動的import**: ローダーが `luna:url` から動的importでモジュール読み込み

---

## HMRライフサイクル

### Vite HMR APIのおさらい

```typescript
if (import.meta.hot) {
  // 自モジュールの更新を受け入れ
  import.meta.hot.accept((newModule) => {
    // newModuleで再レンダリング
  })

  // クリーンアップ
  import.meta.hot.dispose((data) => {
    // 副作用解除、状態をdataに保存
    data.count = currentCount
  })

  // 更新間でデータ永続化
  const savedCount = import.meta.hot.data.count
}
```

### Luna HMRのライフサイクル

```
1. [Server] ファイル変更検知
2. [Server] MoonBitコンパイル + バンドル
3. [Server] WebSocketで変更モジュール通知
4. [Client] 該当Islandの現在状態を収集
5. [Client] Islandをunload（Effect解除、イベントリスナー削除）
6. [Client] 新モジュールを動的import（キャッシュバスト）
7. [Client] 保存した状態で再hydrate
8. [Client] Signal/Effectが再構築、DOMが更新
```

---

## 実装設計

### Phase 1: 基本的なIsland HMR

#### 1.1 HMRクライアント（外付けモジュール）

`js/loader/src/hmr-client.ts` を新規作成:

```typescript
// HMR専用クライアント - sol devが注入、prodには含まれない

declare global {
  interface Window {
    __LUNA_STATE__: Record<string, unknown>;
    __LUNA_HYDRATE__: (el: Element) => Promise<void>;
    __LUNA_UNLOAD__: (id: string) => boolean;
  }
}

interface HMRMessage {
  type: 'update' | 'full-reload' | 'error';
  islands?: string[];
  error?: string;
}

const connect = () => {
  const ws = new WebSocket(`ws://${location.host}/__hmr`);

  ws.onmessage = async (e) => {
    const msg: HMRMessage = JSON.parse(e.data);

    switch (msg.type) {
      case 'update':
        await handleUpdate(msg.islands ?? []);
        break;
      case 'full-reload':
        location.reload();
        break;
      case 'error':
        showErrorOverlay(msg.error);
        break;
    }
  };

  ws.onclose = () => {
    // 再接続を試みる
    setTimeout(connect, 1000);
  };
};

const handleUpdate = async (islands: string[]) => {
  for (const id of islands) {
    const el = document.querySelector(`[luna\\:id="${id}"]`);
    if (!el) continue;

    // 1. 現在の状態を保存
    const currentState = window.__LUNA_STATE__[id];

    // 2. Unload
    window.__LUNA_UNLOAD__(id);

    // 3. URLにキャッシュバストを付与
    const url = el.getAttribute('luna:url');
    if (url) {
      const newUrl = url.split('?')[0] + `?t=${Date.now()}`;
      el.setAttribute('luna:url', newUrl);
    }

    // 4. 状態を復元してセット
    if (currentState !== undefined) {
      window.__LUNA_STATE__[id] = currentState;
    }

    // 5. 再hydrate
    await window.__LUNA_HYDRATE__(el);
  }

  console.log(`[HMR] Updated: ${islands.join(', ')}`);
};

const showErrorOverlay = (error?: string) => {
  // Phase 2で実装
  console.error('[HMR] Build error:', error);
};

// 接続開始
connect();
```

#### 1.2 WebSocket通知サーバー

`src/sol/cli/hmr_server.mbt` を新規作成:

```moonbit
// WebSocketサーバー（Node.js ws パッケージを使用）

pub fn start_hmr_server(port : Int) -> @js.Any {
  // ws パッケージでWebSocketサーバーを起動
  let wss = create_websocket_server(port)
  wss
}

pub fn notify_update(wss : @js.Any, islands : Array[String]) -> Unit {
  let msg = @json.stringify({
    "type": "update",
    "islands": islands,
  })
  broadcast(wss, msg)
}

pub fn notify_full_reload(wss : @js.Any) -> Unit {
  broadcast(wss, "{\"type\":\"full-reload\"}")
}

pub fn notify_error(wss : @js.Any, error : String) -> Unit {
  let msg = @json.stringify({
    "type": "error",
    "error": error,
  })
  broadcast(wss, msg)
}
```

通知メッセージ形式:
```json
{ "type": "update", "islands": ["counter", "todo-list"] }
{ "type": "full-reload" }
{ "type": "error", "error": "Compile error: ..." }
```

#### 1.3 sol devへの統合

`src/sol/cli/dev.mbt` の変更:

```moonbit
fn run_dev_watch_mode(config : SolConfig) -> Unit {
  // HMRサーバー起動
  let hmr_wss = start_hmr_server(config.hmr_port) // default: 24678

  // HTMLレンダリング時にHMRクライアントを注入
  let inject_hmr = fn(html : String) -> String {
    html.replace("</body>", "<script src=\"/__hmr/client.js\"></script></body>")
  }

  // ファイルwatch
  fs.watch(watch_path, recursive=true, listener=fn(event, filename) {
    if filename.ends_with(".mbt") && event == "change" {
      // ビルド実行
      match run_build_dev(cwd) {
        Ok(changed_islands) => {
          // 変更されたIslandのみ通知
          notify_update(hmr_wss, changed_islands)
        }
        Err(error) => {
          // コンパイルエラーを通知
          notify_error(hmr_wss, error)
        }
      }
    }
  })
}
```

#### 1.4 変更検知とIslandマッピング

どのファイルがどのIslandに影響するかを判定:

```moonbit
// manifest.jsonから依存関係を取得
fn get_affected_islands(changed_file : String, manifest : Manifest) -> Array[String] {
  let affected = []
  for island in manifest.islands {
    if island.dependencies.contains(changed_file) {
      affected.push(island.id)
    }
  }
  // 依存関係が不明な場合は全Island更新
  if affected.is_empty() {
    return manifest.islands.map(fn(i) { i.id })
  }
  affected
}
```

### Phase 2: 状態保持の改善

#### 2.1 Signal状態の自動収集

問題: `luna:state`は初期状態のみ。ユーザー操作後の状態は反映されていない。

解決策A: **Island側でgetState()を実装**

```moonbit
// Island側で状態取得関数をエクスポート
pub fn get_state() -> @json.JsonValue {
  @json.Object([
    ("count", @json.Number(count.get().to_double())),
  ])
}
```

```typescript
// HMRランタイムで呼び出し
const mod = await import(url)
const currentState = mod.getState?.() ?? parseState(el)
```

解決策B: **Signal Registryパターン**

```moonbit
// グローバルにSignalを登録
let signal_registry : Map[String, @luna.Signal[@json.JsonValue]] = {}

pub fn register_signal(id : String, signal : @luna.Signal[@json.JsonValue]) -> Unit {
  signal_registry[id] = signal
}

pub fn get_signal_state(id : String) -> @json.JsonValue? {
  signal_registry.get(id).map(fn(s) { s.get() })
}
```

#### 2.2 Effect再構築

HMR後にEffectが正しく再実行されるか確認が必要。

現在のSignal実装:
```moonbit
pub fn Signal::get(self : Signal[T]) -> T {
  // 現在のeffectを自動検出して購読
  match get_current_subscriber() {
    Some(runner) => self.subscribers.push(runner)
    None => ()
  }
  self.value
}
```

**HMR時の動作**:
1. 古いEffectはunloadで解除
2. 新モジュールのhydrate()で新しいEffectを作成
3. 新Effectが`signal.get()`を呼ぶと自動的に購読される

→ **既存の仕組みで動作するはず**

### Phase 3: 細粒度HMR（将来）

#### 3.1 コンポーネント関数の差し替え

Solid Refreshのアプローチを参考に、MoonBit側で対応:

```moonbit
// HMR対応コンポーネント
pub fn Counter() -> @luna.Node {
  // __hmr_wrap__ マクロで自動ラップ
  @hmr.wrap("Counter", fn() {
    let count = @luna.signal(0)
    // ...
  })
}
```

```moonbit
// hmrモジュール
let component_registry : Map[String, () -> @luna.Node] = {}

pub fn wrap(name : String, render : () -> @luna.Node) -> @luna.Node {
  component_registry[name] = render
  render()
}

pub fn replace(name : String, new_render : () -> @luna.Node) -> Unit {
  component_registry[name] = new_render
  // 再レンダリングをトリガー
}
```

**課題**: MoonBitにはマクロがないため、手動でwrapを書く必要がある。

#### 3.2 テンプレートのみ更新

VNode生成部分だけ差し替えて、Signal/Effectは維持:

```
変更前: Counter() → VNode1 → DOM
変更後: Counter() → VNode2 → DOM (diff適用)
```

これはReconciler（差分更新）の実装が前提。

---

## 実装優先度

### Must Have (Phase 1)

- [ ] WebSocket通知サーバー
- [ ] クライアントHMRランタイム
- [ ] Island単位の再hydration
- [ ] 基本的な状態復元（luna:stateベース）

### Should Have (Phase 2)

- [ ] Island側のgetState()サポート
- [ ] HMR失敗時のフルリロードフォールバック
- [ ] エラーオーバーレイ

### Nice to Have (Phase 3)

- [ ] 細粒度コンポーネント更新
- [ ] CSS HMR
- [ ] Source Map対応

---

## ファイル構成

```
js/loader/src/
├── loader.ts          # 既存のIslandローダー（変更なし）
├── hmr-client.ts      # NEW: HMRクライアント（外付け、dev専用）
└── hmr-overlay.ts     # NEW: エラー表示UI（Phase 2）

src/sol/cli/
├── dev.mbt            # 既存（HMR統合を追加）
└── hmr_server.mbt     # NEW: HMR WebSocketサーバー

ビルド成果物:
├── luna-loader.js     # prod/dev共通（~4.2KB、HMRなし）
└── __hmr/client.js    # dev専用（sol devが配信）
```

### luna本体への変更

**なし**。既存の `__LUNA_*` APIで全て実現可能。

オプションで追加すると便利なAPI（後方互換）:
```typescript
// loader.ts に追加検討
w.__LUNA_GET_STATE__ = (id: string) => S[id];  // 状態取得用
```

---

## 比較: 他フレームワークのHMR

| フレームワーク | アプローチ | 状態保持 |
|--------------|----------|---------|
| React Fast Refresh | Babelプラグイン + ランタイム | useState/useRef保持 |
| Solid Refresh | Babelプラグイン + メモ化 | Signal保持 |
| Vue HMR | SFCコンパイラ統合 | data/computed保持 |
| Svelte HMR | コンパイラ統合 | 状態リセット（オプションで保持） |
| **Luna HMR** | Island単位再hydration | luna:state + getState() |

---

## 未解決の課題

### 1. MoonBitコンパイル時間

現在のwatch → rebuild は全体コンパイル。増分コンパイルが必要かも。

```
現在: ファイル変更 → moon build (全体) → バンドル
理想: ファイル変更 → 増分コンパイル → 該当モジュールのみバンドル
```

### 2. Island依存関係

Island AがIsland Bに依存する場合、Bの変更でAも更新が必要？

```
island-a.mbt imports utils.mbt
utils.mbt changes
→ island-a も再hydrate必要
```

解決策: Rolldownの依存グラフを利用して影響範囲を特定

### 3. サーバーコンポーネントの変更

SSRのみのコンポーネントが変更された場合は、フルリロードが必要。

```typescript
if (changedFiles.some(f => isServerOnly(f))) {
  location.reload()
}
```

---

## 実装状況

### 完了

- [x] HMRクライアント (`js/loader/src/hmr-client.ts`)
- [x] HMRサーバー (`src/sol/cli/hmr_server.mbt`)
- [x] sol dev統合 (`src/sol/cli/dev.mbt`)
- [x] rolldown設定追加

### 残作業

- [ ] HMRクライアントの自動注入（sol generateまたはランタイム）
- [ ] `ws` パッケージのインストール確認/ドキュメント
- [ ] 特定Island検出の改善（`*` ではなく実際の変更Island）
- [ ] エラーオーバーレイUI改善

---

## 使用方法（手動テスト）

### 1. wsパッケージのインストール

```bash
pnpm add ws
```

### 2. HMRクライアントをHTMLに追加

開発中のHTMLに以下を追加:

```html
<!-- HMRクライアント（開発時のみ） -->
<script>
// HMR WebSocket port
const HMR_PORT = 24678;
const ws = new WebSocket(`ws://${location.hostname}:${HMR_PORT}`);
ws.onmessage = async (e) => {
  const msg = JSON.parse(e.data);
  if (msg.type === 'update') {
    // Reload all islands
    const islands = document.querySelectorAll('[luna\\:id]');
    for (const el of islands) {
      const id = el.getAttribute('luna:id');
      window.__LUNA_UNLOAD__?.(id);
      const url = el.getAttribute('luna:url');
      if (url) {
        el.setAttribute('luna:url', url.split('?')[0] + '?t=' + Date.now());
      }
      await window.__LUNA_HYDRATE__?.(el);
    }
    console.log('[HMR] Updated');
  } else if (msg.type === 'full-reload') {
    location.reload();
  }
};
ws.onopen = () => console.log('[HMR] Connected');
ws.onclose = () => setTimeout(() => location.reload(), 1000);
</script>
```

### 3. sol devを起動

```bash
sol dev
```

出力例:
```
Starting Sol development server...
✓ Generate complete
✓ Build complete
[HMR] WebSocket server started on port 24678
Starting server: .sol/dev/server/main.js...
Watching for .mbt file changes... (Ctrl+C to stop)
```

### 4. ファイルを編集

- `app/client/*.mbt` を編集 → HMR更新（Island再hydration）
- `app/server/*.mbt` を編集 → フルリロード

---

## 次のステップ

1. **自動注入**: sol generateでHTMLにHMRスクリプトを自動挿入
2. **状態保持テスト**: Signal値がHMR後も維持されるか確認
3. **パフォーマンス計測**: HMRサイクル時間を測定
4. **エラーオーバーレイ改善**: スタックトレース、ファイル名表示
