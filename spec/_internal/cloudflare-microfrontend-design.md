# Cloudflare Microfrontend 設計検討

## 概要

Cloudflare Workers の Service-Binding を使った Microfrontend パターンを Sol に採用できるか検討。

参考: https://zenn.dev/mizchi/scraps/02bb23fe4a3630

## アーキテクチャ

```
Main Worker (Port 8787)
  ├─ /_fragment/header  → Service A (fetch binding)
  ├─ /_fragment/sidebar → Service B (fetch binding)
  └─ /_fragment/content → Service C (fetch binding)
      ↓
  HTML結合 & ストリーミング → Client
```

### 要点

- サブディレクトリで分割し、パスを合わせて service-binding で結合
- `/_fragment/{service-name}/*` でリクエストを `env.[service].fetch()` に転送
- Service-Binding は同一 Cloudflare アカウント内で 1RTT（ネットワーク経由しない）
- Qwik の SSRStream 的なストリーミング結合

## 現状の Sol との適合性

| 機能 | 現状 | 評価 |
|------|------|------|
| Fragment 応答 | `render_fragment_response()` 実装済み | ✅ |
| ルーティング | Hono v4 ワイルドカード対応 | ✅ |
| ISR キャッシュ | `ISRCache` トレイトで拡張可能 | ✅ |
| Service-Binding | 未実装 | ⚠️ |
| wrangler.toml 生成 | 未実装 | ⚠️ |

## 実装が必要な機能

### Phase 1: 基礎

1. **wrangler.toml 自動生成**
   - service-binding 定義含む
   - `sol build --runtime cloudflare` で生成

2. **CloudflareEnv 型定義**
   ```moonbit
   pub struct CloudflareEnv {
     kv : @js.Any?
     d1 : @js.Any?
     services : Map[String, @js.Any]  // Service-Bindings
   }
   ```

3. **sol.config.json 拡張**
   ```json
   {
     "runtime": "cloudflare",
     "services": {
       "header": "./services/header",
       "sidebar": "./services/sidebar"
     }
   }
   ```

### Phase 2: Fragment Composition

1. **Fragment Composer ミドルウェア**
   - 複数 Service からの fetch を並列実行
   - HTML 結合ロジック

2. **複数 outlet 対応**
   - 現在: `data-sol-outlet="main"` のみ
   - 拡張: `data-sol-outlet="header|sidebar|content"`

3. **wrangler.toml 例**
   ```toml
   name = "main-app"
   main = "dist/worker.js"
   compatibility_date = "2025-12-11"
   compatibility_flags = ["nodejs_compat"]

   [[services]]
   binding = "HEADER"
   service = "header-service"

   [[services]]
   binding = "SIDEBAR"
   service = "sidebar-service"
   ```

### Phase 3: Distributed ISR

```
[Service A]       [Service B]       [Service C]
  ISR Cache        ISR Cache         ISR Cache
       ↓                ↓                  ↓
    [Main Worker ISR Compositor]
      ↓
    Composite Fragment Cache
      ↓
    Client
```

- Service 側: 独立した ISR（既存実装で十分）
- Main 側: Service fragment fetch 結果をキャッシュ
- TTL 管理: Service 側最小 TTL に合わせる

## 関連ファイル

```
src/sol/
├── router/
│   ├── fragment.mbt       ← Fragment 応答（拡張対象）
│   └── router.mbt         ← ルーティング基盤
├── isr/
│   ├── handler.mbt        ← ISR ハンドラ
│   └── types.mbt          ← ISRCache トレイト
├── cli/
│   ├── build.mbt          ← ビルドパイプライン
│   └── templates.mbt      ← wrangler.toml 生成対象
└── runtime.mbt            ← App entry point
```

## 懸念点

1. **レイテンシ**: Service 間 fetch は 1RTT だが、複数サービスで累積
2. **複雑性**: 分散システムのデバッグが困難
3. **キャッシュ整合性**: 各 Service の ISR TTL 管理
4. **開発体験**: ローカルでの miniflare service-binding 連携

## 工数見積もり

| 機能 | 工数 |
|------|------|
| wrangler.toml 生成テンプレート | 2-3日 |
| Service-Binding 型定義 | 3-4日 |
| Fragment Composer ミドルウェア | 5-7日 |
| Distributed ISR | 4-5日 |
| テスト・ドキュメント | 3-4日 |
| **合計** | **17-23日** |

## 結論

**技術的には採用可能**。既存の Fragment 応答・ISR 基盤を活用できる。

まずは簡易な PoC（2サービス構成）で検証するのが現実的。

## 参考リンク

- [Cloudflare Workers and micro-frontends](https://blog.cloudflare.com/better-micro-frontends/)
- [Service bindings - Cloudflare Workers docs](https://developers.cloudflare.com/workers/runtime-apis/bindings/service-bindings/)
