# Scoped CSS Minifier

MoonBit WebComponent出力のCSS圧縮実験。

## 機能

1. **CSSクラス名マングリング**: Scoped CSSなのでクラス名を短縮可能
2. **CSS空白圧縮**: `<style>` ブロック内の不要な空白を除去
3. **セレクタ文字列置換**: JS内の `".classname"` セレクタも追従

## 使い方

```bash
# 基本
node minify-scoped-css.js input.js > output.js

# オプション付き
node minify-scoped-css.js input.js -v -o output.js

# オプション
#   -v, --verbose    詳細情報を表示
#   -o, --output     出力ファイル指定
#   --no-mangle      クラス名マングリングをスキップ
#   --no-minify      CSS圧縮をスキップ
```

## 効果

min.js (17.2KB) での結果:
- クラス名短縮: -420 bytes
- 空白圧縮: -248 bytes
- **合計: -668 bytes (3.89%削減)**

## マングリング例

| 元のクラス名 | 短縮後 |
|-------------|--------|
| buttons     | b      |
| count       | f      |
| todo-list   | z      |
| total-clicks| c1     |

## 制限事項

- `<style>...</style>` ブロック内のCSSのみ対象
- JS変数名と誤検出しないよう、CSSコンテキストからのみクラス名抽出
- タグ名（button, input等）と予約語は除外

## TODO

- [ ] esbuildプラグイン化
- [ ] MoonBit側での統合（`scoped_html!()` マクロ等）
- [ ] 複数クラス属性の完全対応 (`class="a b c"`)
- [ ] CSS変数の短縮
