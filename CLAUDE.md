# Luna Framework

MoonBitで実装されたIsland ArchitectureベースのUIフレームワーク。

## プロジェクト構成

```
src/
├── core/                      # ターゲット非依存
│   ├── signal/                # Signalプリミティブ
│   ├── vnode.mbt              # VNode定義
│   └── serialize/             # 状態シリアライズ
├── renderer/                  # VNode → HTML文字列 (純粋、DOM非依存)
│   ├── render_to_string.mbt   # HTML文字列生成
│   ├── stream_render.mbt      # ストリーミング対応
│   └── shard/                 # Island埋め込み
├── platform/                  # プラットフォーム固有
│   ├── dom/                   # ブラウザ DOM API
│   │   ├── element/           # 低レベルDOM操作 (render, diff, reconcile)
│   │   ├── hydrate.mbt        # Hydration
│   │   ├── island.mbt         # Island hydration
│   │   └── repair/            # 実験的Hydration
│   ├── js/                    # JS固有
│   │   └── api/               # JS向け公開API (@mizchi/luna)
│   └── server_dom/            # サーバーサイドSSR (イベントハンドラなし)
│       ├── elements.mbt       # html, head, body等の要素ファクトリ
│       ├── island.mbt         # Islandヘルパー
│       └── render.mbt         # レンダリング関数
├── router/                    # ルーティング
├── sol/                       # SSRフレームワーク (将来分離候補)
├── examples/
└── tests/
js/                      # NPMパッケージ
├── luna/                      # @mizchi/luna
├── loader/                    # @mizchi/luna-loader
└── cli/                       # CLIツール
e2e/                           # Playwrightテスト
```

## 用語集

### コア概念
| 用語 | 説明 |
|------|------|
| Signal | リアクティブな値コンテナ。get/set/updateで操作 |
| VNode | 仮想DOMノード。Element/Text/Fragment等のバリアント |
| Shard | Island埋め込み可能なHTML断片。luna:*属性付き |

### 処理フェーズ
| 用語 | 説明 |
|------|------|
| Render | VNode → HTML文字列変換（サーバー側） |
| Hydrate | 既存DOMにイベントハンドラを接続 |
| Repair | Hydration失敗時の自動復旧（実験的） |
| Resume | シリアライズされた状態の復元 |

### フレームワーク
| 用語 | 説明 |
|------|------|
| Luna | UIライブラリ本体 |
| Sol | SSRフレームワーク（Hono統合、将来分離候補） |

## 命名規約

### HTML属性 (luna:*)
- `luna:id` - コンポーネントID
- `luna:url` - Hydration用モジュールURL
- `luna:client-trigger` - Hydrationトリガー (load, idle, visible, media)
- `luna:state` - シリアライズされた状態JSON

### Web Components属性 (luna:wc-*)
- `luna:wc-url` - Web Component Hydration用モジュールURL
- `luna:wc-state` - シリアライズされた状態JSON
- `luna:wc-trigger` - Hydrationトリガー (load, idle, visible, media)

### MoonBit名前空間
- `mizchi/luna` - コアパッケージ
- `@luna.` - Signal, Node, Attr等
- `@element.` - 低レベルDOM操作
- `@renderer.` - SSRレンダリング
- `@server_dom.` - サーバーサイドDOM要素生成
- `@sol.` - SSRフレームワーク

### NPMパッケージ
- `@mizchi/luna` - コアランタイム
- `@mizchi/luna-loader` - Islandローダー

## AI向け開発フロー

### 実装中の確認サイクル
```bash
# MoonBit実装中は頻繁に実行
moon check           # 型チェック（高速）
moon test --target js  # ユニットテスト
```

### コミット前・TS変更時
```bash
just test            # 全テスト実行
just size            # バンドルサイズ確認（大幅増加がないか）
```

### PR作成前
```bash
just ci              # 全CIチェック（check + test + size-check）
```

### サイズ増加の目安
- MoonBitモジュール: 機能追加で数KB増は許容
- ln-loader-v1.js: 5KB以下を維持（現在 ~4.2KB）
- 大幅増加（10KB+）の場合は原因を調査

## 開発コマンド

```bash
# CI
just ci              # 全CIチェック（PR前に実行）
just check           # 型チェックのみ
just size-check      # バンドルサイズ閾値チェック

# テスト
just test            # 全テスト実行
just test-moonbit    # MoonBitユニットテスト
just test-vitest     # Vitestテスト
just test-browser    # ブラウザテスト
just test-e2e        # E2Eテスト（Playwright）
just test-e2e-ui     # E2Eテスト（UI付き）
just test-sol-new    # sol new テンプレートテスト

# ビルド
just build           # MoonBit + Vite build
just build-moon      # MoonBitのみ
just clean           # ビルド成果物削除
just fmt             # コードフォーマット

# ユーティリティ
just size            # バンドルサイズ表示
just bench           # ベンチマーク実行
just watch           # ファイル監視ビルド
just minify-loader   # ローダーのminify

# Sol CLI
just sol --help      # sol CLIヘルプ
just sol new myapp   # 新規プロジェクト作成

# メトリクス（ローカル計測・履歴トラッキング）
just metrics-record        # ビルド時間+サイズ記録
just metrics-record-clean  # クリーンビルドで記録
just metrics-record-bench  # ベンチマーク付きで記録
just metrics-report        # 直近の記録を表示
just metrics-compare       # 前回との差分比較
just metrics-trend         # トレンドグラフ表示
```

## 開発ポリシー

### パフォーマンス要件
- **luna-loader-v1.js**: < 5KB（現在 ~4.2KB）
- **loader.min.js**: < 1KB（現在 ~933B）
- Hydration は非同期で実行し、メインスレッドをブロックしない
- 不要なリフローを避ける

### バンドルサイズ方針
- ローダーは最小限に保つ（外部依存なし）
- Tree-shaking可能な構造を維持
- MoonBitのデッドコード削除を活用

### セキュリティ
- XSSエスケープは `src/mercurius/serializer.mbt` で処理
- luna:state に含まれるJSONは必ずエスケープ
- `</script>` インジェクション対策済み

### コード品質
- `moon check` を通過すること
- `moon fmt` でフォーマット統一
- テストカバレッジを下げない

## CIチェック項目

PRマージ前に以下を確認：

1. **型チェック**: `moon check --target js`
2. **ユニットテスト**: `moon test --target js`
3. **Signalテスト（全ターゲット）**: `moon test --target all src/core/signal`
4. **Vitestテスト**: `pnpm test`
5. **ブラウザテスト**: `pnpm test:browser`
6. **E2Eテスト**: `pnpm test:e2e`
7. **バンドルサイズ**: ローダーが閾値以下であること

## トリガータイプ

| トリガー | 説明 |
|---------|------|
| `load` | ページロード時即座 |
| `idle` | requestIdleCallback時 |
| `visible` | IntersectionObserver検知時 |
| `media` | メディアクエリマッチ時 |
| `none` | 手動トリガー（__LUNA_HYDRATE__経由） |

## テストポリシー

テストピラミッドに基づき、可能な限り低レイヤーでテストする。

### テストレイヤー

```
        /\
       /  \  E2E (Playwright)
      /----\  - SSR + Hydration統合
     /      \  - 複数ページ遷移
    /--------\  - サーバー必須シナリオ
   /          \
  /  Browser   \  Vitest Browser Mode
 /   (DOM)      \  - DOM操作、イベント
/----------------\  - Hydration単体
/                  \
/    MoonBit Unit   \  moon test
/    (純粋ロジック)    \  - Signal, VNode, Routes, Serialize
/______________________\  - カバレッジ100%目標
```

### テスト配置

| レイヤー | ディレクトリ | 対象 |
|---------|-------------|------|
| MoonBit Unit | `src/**/*_test.mbt` | 純粋ロジック（DOM非依存） |
| Browser | `js/luna/tests/*.test.ts` | DOM操作、Hydration |
| E2E | `e2e/**/*.test.ts` | SSR統合、複数ページ |

### 判断基準

**MoonBit Unit で書く:**
- Signal/Effect のロジック
- VNode 生成・変換
- Routes マッチング
- 状態シリアライズ/デシリアライズ
- `src/core/` 配下は**カバレッジ100%目標**

**Browser Test で書く:**
- DOM要素の生成・更新
- イベントハンドラの動作
- Hydration (単一コンポーネント)
- CSS クラス・スタイルの反映

**E2E で書く:**
- SSR → Hydration の統合フロー
- ページ間ナビゲーション
- Island間の連携
- ストリーミングSSR

### テスト追加時のルール

1. **まず MoonBit Unit を検討** - DOM不要なら `*_test.mbt` に追加
2. **DOM必須なら Browser Test** - `js/luna/tests/` に追加
3. **統合が必要なら E2E** - `e2e/` に追加（件数は最小限に）

### 重複禁止

- 同じロジックを複数レイヤーでテストしない
- MoonBit でカバー済みの Signal ロジックを TS で再テストしない
- Browser Test でカバー済みの DOM 操作を E2E で再テストしない

## 参照ドキュメント

- [Architecture](./docs/architecture.md) - モジュール構成の詳細
- [Shard Architecture](./src/mercurius/ARCHITECTURE.md) - Island埋め込みの仕組み
