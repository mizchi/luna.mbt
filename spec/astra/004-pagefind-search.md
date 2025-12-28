# ADR-004: Pagefind Search Integration

## Status

Proposed

## Context

ドキュメントサイトには検索機能が必要だが、以下の制約がある：

1. **バンドルサイズ**: Luna coreは最小サイズを優先
2. **静的サイト**: サーバーサイド検索は使えない
3. **日本語対応**: ステミングなしでも動作する必要がある

検索ライブラリの選択肢：
- **Pagefind**: 静的サイト専用、WASM 70KB + JS 7KB、遅延読み込み
- **Fuse.js**: 軽量だがインデックス全体をロード
- **自前実装**: 完全制御可能だが工数大

## Decision

**Pagefindを採用し、検索専用ページとして分離する**

### 理由

1. 検索ページのみにPagefindを読み込み、他ページのバンドルサイズに影響しない
2. 既存の成熟したソリューションを活用し、工数を削減
3. 将来的に自前実装に置き換え可能な設計

### アーキテクチャ

```
[Astra Build]
    ↓
[HTML生成] → dist/
    ↓
[Pagefind CLI] → dist/pagefind/
                    ├── pagefind.js
                    ├── pagefind.wasm
                    └── index chunks
```

### ビルドパイプライン統合

```bash
# astra build 後に実行
npx pagefind --site dist
```

### 検索ページ実装

`/search` に専用ページを配置：

```html
<!-- search.html -->
<div id="search"></div>
<script type="module">
  const pagefind = await import('/pagefind/pagefind.js');
  // カスタムUIまたはPagefindUI
</script>
```

### 日本語対応

Phase 1（現状）:
- Pagefindのデフォルト動作を使用
- ステミングなし、部分一致で検索

Phase 2（将来）:
- ビルド時にTinySegmenter等でトークナイズ
- `data-pagefind-index-text` で分かち書きテキストを提供

### 設定

`astra.json` に検索設定を追加：

```json
{
  "search": {
    "enabled": true,
    "provider": "pagefind",
    "ui": "custom"  // "pagefind-ui" | "custom"
  }
}
```

## Consequences

### Positive

- **分離されたロード**: 検索ページ以外はPagefindを読み込まない
- **即時利用可能**: 実装工数が最小限
- **将来の移行性**: 自前実装への移行パスが明確

### Negative

- **外部依存**: Pagefindのアップデートに追従が必要
- **WASM 70KB**: 検索ページのみだが、初回は重い
- **日本語**: 完全なトークナイズには追加対応が必要

### Neutral

- 検索ページへのリンクをナビゲーションに追加
- sitemap.xmlに検索ページを含める
