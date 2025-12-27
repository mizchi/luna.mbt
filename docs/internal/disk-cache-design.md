# Disk Cache Design for Astra

ビルド時間短縮のための永続キャッシュ設計。

## 目的

- 変更のないファイルの再レンダリングをスキップ
- インクリメンタルビルドによる高速化
- 大規模サイト（100+ ページ）での実用的なビルド時間

## キャッシュ戦略

### キャッシュキー生成

各ページのキャッシュキーは以下から計算:

```
hash = fnv1a(
  source_content +      // Markdown/HTML ソース
  frontmatter_json +    // frontmatter を JSON 化
  config_hash           // グローバル設定のハッシュ
)
```

### キャッシュストレージ

```
.astra-cache/
├── meta.json           # キャッシュメタデータ
└── pages/
    ├── {hash}.html     # レンダリング済み HTML
    └── ...
```

**meta.json**:
```json
{
  "version": 1,
  "config_hash": "abc123",
  "pages": {
    "/guide/intro/": {
      "source_hash": "def456",
      "html_hash": "ghi789",
      "cached_at": "2024-12-27T12:00:00Z"
    }
  }
}
```

## キャッシュ判定フロー

```
1. ソースファイル読み込み
2. コンテンツハッシュ計算
3. キャッシュ meta.json 参照
4. ハッシュ一致?
   - YES → キャッシュから HTML 読み込み
   - NO → レンダリング実行 → キャッシュ保存
5. 出力ディレクトリに書き込み
```

## 無効化トリガー

キャッシュ全体を無効化:
- `sol.config.json` の変更
- Astra バージョン更新
- `--no-cache` フラグ

ページ単位で無効化:
- ソースファイルの変更
- frontmatter の変更
- レイアウトテンプレートの変更

## API 設計

```moonbit
/// キャッシュマネージャー
pub struct CacheManager {
  cache_dir : String
  meta : CacheMeta
  config_hash : String
}

/// キャッシュメタデータ
pub struct CacheMeta {
  version : Int
  config_hash : String
  pages : Map[String, PageCacheEntry]
}

/// ページキャッシュエントリ
pub struct PageCacheEntry {
  source_hash : String
  html_hash : String
  cached_at : String
}

/// キャッシュ操作
pub fn CacheManager::new(cwd: String, config: SsgConfig) -> CacheManager
pub fn CacheManager::get(self, url_path: String, source_hash: String) -> String?
pub fn CacheManager::set(self, url_path: String, source_hash: String, html: String) -> Unit
pub fn CacheManager::save(self) -> Unit
pub fn CacheManager::clear(self) -> Unit
```

## ハッシュアルゴリズム

FNV-1a (32-bit) を採用:
- 実装がシンプル
- 衝突確率が十分低い
- 高速

```moonbit
pub fn fnv1a(data: String) -> String {
  let mut hash: UInt = 2166136261  // FNV offset basis
  for byte in data.iter_bytes() {
    hash = hash ^ byte.to_uint()
    hash = hash * 16777619  // FNV prime
  }
  hash.to_hex()
}
```

## 設定オプション

```json
{
  "cache": {
    "enabled": true,
    "dir": ".astra-cache"
  }
}
```

## 実装フェーズ

### Phase 1: 基本キャッシュ ✅
- [x] FNV-1a ハッシュ実装 (`src/astra/cache/hash.mbt`)
- [x] CacheManager 実装 (`src/astra/cache/manager.mbt`)
- [x] シーケンシャルビルド統合

### Phase 2: 最適化
- [ ] 並列ビルドでのキャッシュ対応
- [ ] 圧縮オプション (gzip)
- [ ] TTL ベースの自動クリーンアップ

### Phase 3: 高度な機能
- [ ] 依存関係追跡 (レイアウト変更時の連鎖無効化)
- [ ] リモートキャッシュ (CI/CD 間共有)

## 使用方法

シーケンシャルビルド（キャッシュ有効）:
```bash
astra build
```

並列ビルド（キャッシュ無し、初回ビルド高速）:
```bash
astra build --parallel
```

インクリメンタルビルドにはシーケンシャルビルドを推奨。
