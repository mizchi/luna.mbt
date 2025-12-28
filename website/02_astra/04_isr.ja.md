---
title: ISR (Incremental Static Regeneration)
description: Stale-While-Revalidateキャッシングによる動的コンテンツの鮮度維持
---

# ISR (Incremental Static Regeneration)

ISRを使用すると、サイト全体を再ビルドすることなく、デプロイ後に静的ページを更新できます。

## 概要

ISRは静的生成の利点と動的コンテンツの鮮度を組み合わせます:

1. **ビルド時に静的生成** - ページはビルド時に事前レンダリング
2. **キャッシュ配信** - 最小限のレイテンシでキャッシュから配信
3. **バックグラウンド再検証** - 古いコンテンツは非同期で再生成をトリガー
4. **再ビルド不要** - フルサイト再ビルドなしでコンテンツ更新

## 動作の仕組み

```
リクエスト → キャッシュ確認
               ↓
         ┌─────┴─────┐
         │           │
      Fresh?      Stale?      Miss?
         │           │           │
      キャッシュ   キャッシュ +    生成
       を返す    再検証スケジュール  + キャッシュ
```

### キャッシュ状態

| 状態 | 条件 | 動作 |
|------|------|------|
| **Fresh** | `現在時刻 < 生成時刻 + TTL` | キャッシュを即座に返す |
| **Stale** | `現在時刻 >= 生成時刻 + TTL` | キャッシュを返す + バックグラウンドで再検証 |
| **Miss** | キャッシュエントリなし | 生成、キャッシュ、返却 |

## 設定

### フロントマター

`revalidate`をフロントマターに追加してISRを有効化:

```markdown
---
title: マイページ
revalidate: 60
---

# コンテンツはここに
```

`revalidate`の値は**秒単位**です。

### TTLガイドライン

| コンテンツタイプ | 推奨TTL | 例 |
|-----------------|---------|-----|
| **ホット** (高トラフィック) | 300-600秒 | ホームページ、人気記事 |
| **ウォーム** (中程度) | 60-300秒 | チュートリアル、APIドキュメント |
| **コールド** (低トラフィック) | 30-60秒 | アーカイブ、古い記事 |
| **リアルタイム** | 0 | 常に再生成 |

## ビルド出力

`revalidate`が設定されたページがある場合、AstraはISRマニフェストを生成:

```
dist/
└── _luna/
    └── isr.json
```

### マニフェスト形式

```json
{
  "version": 1,
  "pages": {
    "/blog/": {
      "revalidate": 300,
      "renderer": "markdown",
      "source": "blog/index.md"
    },
    "/blog/post-1/": {
      "revalidate": 120,
      "renderer": "markdown",
      "source": "blog/post-1.md"
    }
  }
}
```

## ランタイム動作

### Solサーバー統合

SolはISRマニフェストを自動的にロードしてキャッシングを処理:

```moonbit
// ISRハンドラーを初期化
let handler = init_isr(dist_dir)

// リクエストを処理
let (html, needs_revalidation) = handler.handle(path)

if needs_revalidation {
  schedule_revalidation(path)
}
```

### キャッシュキー形式

キャッシュキーにはパスとクエリパラメータが含まれます:

```
isr:/blog/                     # シンプルなパス
isr:/search/?q=luna&sort=date  # ソートされたクエリパラメータ付き
```

クエリパラメータは一貫したキャッシュキーのためにアルファベット順にソートされます。

## パフォーマンス

ISRは高スループットに最適化されています:

| 操作 | スループット | レイテンシ |
|------|------------|---------|
| キャッシュ読み取り | ~6.7M ops/sec | 0.15μs |
| キャッシュ書き込み | ~2.7M ops/sec | 0.36μs |
| ステータス確認 | ~4.4M ops/sec | 0.23μs |
| フルハンドル | ~2.4M req/sec | 0.41μs |

キャッシュオーバーヘッドはネットワークI/Oと比較して無視できるレベルです。

## 例: 階層化TTLのブログ

```
docs/
├── blog/
│   ├── index.md           # revalidate: 300 (ホット)
│   ├── post-1.md          # revalidate: 120 (ウォーム)
│   ├── post-2.md          # revalidate: 120 (ウォーム)
│   └── archive/
│       ├── index.md       # revalidate: 60 (コールド)
│       └── old-post.md    # revalidate: 60 (コールド)
```

### トラフィックパターンシミュレーション

80/20ルールに従う50,000ページの場合:

| 階層 | ページ数 | TTL | トラフィック割合 |
|------|---------|-----|-----------------|
| ホット | 100 | 300秒 | 80% |
| ウォーム | 900 | 120秒 | 15% |
| コールド | 49,000 | 60秒 | 5% |

ホットページは頻繁なアクセスにより常に新鮮。コールドページは一時的に古いコンテンツを配信後、再検証。

## Stale-While-Revalidateパターン

ISRはSWRパターンを実装:

1. **ユーザーA** が古いページをリクエスト → 古いコンテンツを即座に取得（待ち時間なし）
2. **バックグラウンド** で再生成開始
3. **ユーザーB** が同じページをリクエスト → 新しいコンテンツを取得

これにより、ユーザーは再生成を待つ必要がありません。

## デプロイ考慮事項

### Cloudflare Workers

ISRはCloudflareのエッジキャッシングと連携:

```json
{
  "deploy": "cloudflare"
}
```

ISRハンドラーはバックグラウンド再検証のために`waitUntil`と統合されます。

### メモリキャッシュ

開発およびシングルインスタンスデプロイ用:

```moonbit
let cache = MemoryCache::new()
```

注: メモリキャッシュは再起動時に失われます。本番環境では分散キャッシュを使用してください。

## APIリファレンス

### フロントマターオプション

| オプション | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| `revalidate` | `Int` | None | TTL（秒単位、0 = 常にstale） |

### ISRHandler

```moonbit
// ハンドラーを作成
fn ISRHandler::new(cache, manifest, dist_dir) -> ISRHandler

// リクエストを処理 - (html?, needs_revalidation)を返す
fn handle(path: String) -> (String?, Bool)

// 再検証後にキャッシュを更新
fn update_cache(path: String, html: String) -> Unit
```

### CacheEntry

```moonbit
struct CacheEntry {
  html: String         // キャッシュされたHTMLコンテンツ
  generated_at: Int64  // Unixタイムスタンプ（ミリ秒）
  revalidate: Int      // TTL（秒単位）
}
```

### CacheStatus

```moonbit
enum CacheStatus {
  Fresh  // TTL内
  Stale  // TTL超過だがコンテンツあり
  Miss   // キャッシュされたコンテンツなし
}
```

## ベストプラクティス

1. **適切なTTLを使用** - TTLをコンテンツ更新頻度に合わせる
2. **キャッシュヒット率を監視** - 実際の使用状況に基づいてTTLを調整
3. **エラーを適切に処理** - 再生成失敗時は古いコンテンツを配信
4. **トラフィックパターンを考慮** - ホットページは長いTTLから最も恩恵を受ける
5. **現実的なデータでテスト** - 本番トラフィックパターンをシミュレート

## 制限事項

- メモリキャッシュは再起動後に永続化されない
- 再検証にはサーバーサイド実行が必要
- クエリパラメータのバリエーションは別々のキャッシュエントリを作成
- パスマッチングは大文字小文字を区別し、完全一致（末尾スラッシュが重要）
