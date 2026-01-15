# Luna

MoonBit で実装された Island Architecture ベースの UI ライブラリ。

## 関連リポジトリ

- **Sol** (SSR/SSG フレームワーク): [mizchi/sol.mbt](https://github.com/mizchi/sol.mbt)

## インストール

```json
// moon.mod.json
{
  "deps": {
    "mizchi/luna": "0.6.0"
  }
}
```

## モジュール構成

| パッケージ | 責務 |
|-----------|------|
| `mizchi/luna/signal` | リアクティブシグナル |
| `mizchi/luna/dom` | DOM 操作、Hydration |
| `mizchi/luna/render` | VNode → HTML レンダリング |
| `mizchi/luna/css` | CSS Utilities |
| `mizchi/luna/routes` | ルートマッチング |
| `mizchi/luna/browser_router` | ブラウザルーター |
| `mizchi/luna/components` | UI コンポーネント |

## 開発

```bash
just check      # 型チェック
just fmt        # フォーマット
just test-unit  # MoonBit テスト
just test-e2e   # E2E テスト
```

## License

MIT
