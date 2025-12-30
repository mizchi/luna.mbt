# Shoelace + Luna Integration Experiment

Shoelace (https://shoelace.style/) はWeb Componentsベースのコンポーネントライブラリ。
LunaのUI不足を補うために統合を検討する。

## 目的

1. ShoelaceをLunaプロジェクトで使えるようにする
2. SSR対応を検証する
3. Hydration統合を検討する

## 検証項目

### Phase 1: 基本動作確認 (index.html)

- [x] CDNからの読み込み
- [x] 基本コンポーネント（Button, Input, Checkbox, Switch）
- [x] 対話的コンポーネント（Dialog, Dropdown）
- [x] データ表示（Badge, Progress, Rating）
- [x] JavaScriptイベント連携
- [x] Slotsの動作

### Phase 2: SSR対応 (ssr-test.html)

- [ ] 初期HTMLでのコンポーネント表示
- [ ] Declarative Shadow DOMの検証
- [ ] Flash of Undefined Custom Elements (FOUCE) 対策

### Phase 3: Luna統合

- [ ] Luna DOM DSLからShoelaceコンポーネントを生成
- [ ] LunaのSignalとShoelaceイベントの連携
- [ ] Sol/AstraでのSSR出力

## Shoelaceの特徴

### 利点

1. **Web Standards準拠**: Custom Elements API使用
2. **フレームワーク非依存**: どのJSフレームワークでも使用可能
3. **豊富なコンポーネント**: Button, Input, Dialog, Dropdown, etc.
4. **アクセシビリティ**: WCAG 2.1 AA準拠
5. **カスタマイズ**: CSS Custom Properties使用

### SSRの課題

1. **Shadow DOM**: SSRでは通常Shadow DOMは使えない
2. **Declarative Shadow DOM**: 一部ブラウザでサポート
3. **FOUCEの回避**: コンポーネント定義前の表示問題

## Luna統合のアプローチ

### Option 1: 単純なHTML出力

Shoelaceのカスタム要素タグをそのままHTMLとして出力。
クライアントでShoelace JSが読み込まれると動作開始。

```moonbit
// Luna DSL example
fn sl_button(text: String, variant: String) -> Node {
  h("sl-button", [("variant", attr_static(variant))], [text_node(text)])
}
```

### Option 2: Light DOM フォールバック

SSR時はLight DOMで代替表示、クライアントでShoelaceに置換。

### Option 3: Declarative Shadow DOM

ブラウザがサポートしている場合、Shadow DOMの内容をHTMLに含める。

## ファイル構成

```
experiments/shoelace/
├── README.md              # このファイル
├── index.html             # 基本動作確認
├── ssr-test.html          # SSR/Hydration検証
├── luna-integration.html  # Luna統合プロトタイプ
├── dsd-test.html          # Declarative Shadow DOM/CLS検証
├── comparison.html        # Shoelace vs Luna Button 比較
├── plan.md                # 実装計画
└── src/
    ├── shoelace/
    │   ├── button.js      # Shoelace Button バインディング
    │   └── input.js       # Shoelace Input バインディング
    └── ui/
        ├── button.js      # Luna Native Button
        ├── button.css     # Luna Button CSS
        ├── input.js       # Luna Native Input
        └── input.css      # Luna Input CSS
```

## 検証方法

```bash
# ローカルサーバーを起動
cd experiments/shoelace
npx serve .

# または
python -m http.server 8000
```

ブラウザで http://localhost:3000 (または 8000) を開く。

## 検証結果

### 基本動作 (index.html)
- CDN読み込み: OK
- コンポーネント表示: OK
- イベント連携: OK

### SSR対応 (ssr-test.html)
- 属性のプリセット: OK（value, checked等がSSRで設定可能）
- Hydration: OK（クライアントで正しく動作開始）
- FOUCE対策: `:not(:defined) { visibility: hidden; }` で対応可能

### Luna統合 (luna-integration.html)
- Signal連携: OK（イベント→Signal→UI更新のパターン）
- 双方向バインディング: OK（input連携）
- 動的リスト: OK（for_each相当）
- ダイアログ状態管理: OK（open属性のSignal制御）

## 次のステップ

1. **MoonBit DSL作成**: `src/luna/shoelace/` にShoelaceコンポーネント用のDSLを実装
2. **SSR対応**: Sol/AstraでShoelaceタグを正しく出力
3. **Hydration統合**: Lunaのhydrate機能との統合

## コード例（構想）

```moonbit
// src/luna/shoelace/button.mbt
pub fn sl_button(
  variant? : String,
  size? : String,
  disabled? : Bool,
  on_click? : () -> Unit,
  children : Array[DomNode]
) -> DomNode {
  let attrs = []
  if variant is Some(v) { attrs.push(("variant", Static(v))) }
  if size is Some(s) { attrs.push(("size", Static(s))) }
  if disabled is Some(true) { attrs.push(("disabled", Static(""))) }

  let handlers = match on_click {
    Some(handler) => [("click", handler)]
    None => []
  }

  create_element("sl-button", attrs, handlers, children)
}

// Usage
sl_button(
  variant="primary",
  on_click=fn() { count.update(fn(n) { n + 1 }) },
  [text_sig(count.map(fn(n) { "Count: \{n}" }))]
)
```

## 参考

- https://shoelace.style/
- https://web.dev/declarative-shadow-dom/
- https://lit.dev/docs/ssr/overview/
