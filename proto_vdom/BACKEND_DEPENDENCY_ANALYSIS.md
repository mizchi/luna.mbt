# バックエンド依存性分析

## 現状の問題点

### 1. `hooks.mbt` - JSONシリアライズへの依存

**問題**: フック状態のシリアライズ機能が`@json`パッケージ（JavaScript特化）に依存しています。

**該当箇所**:
```moonbit
// hooks.mbt:333
pub fn HooksState::serialize(self : HooksState) -> String {
  let arr : @core.Any = self.hooks |> @core.identity
  @json.JSON::stringify(arr)  // ← JS特化
}

// hooks.mbt:342, 352
pub fn HooksState::from_serialized(json : String) -> HooksState {
  let arr : Array[@core.Any] = @json.JSON::parse(json)  // ← JS特化
  { hooks: arr, current_index: 0, effects: [] }
}
```

**影響範囲**:
- `HooksState::serialize()`
- `HooksState::from_serialized()`
- `HooksState::restore()`
- `render_to_string_with_state()` (renderer_ssr.mbt)
- `DomRenderer::hydrate_with_state()` (renderer_dom.mbt)

### 2. `reconcile.mbt` - DOM型への直接依存

**問題**: `Patch`型が`@dom.Node`、`@dom.Element`などに直接依存しています。

**該当箇所**:
```moonbit
// reconcile.mbt:14-19
pub enum Patch[H] {
  CreateElement(VNode[H], @dom.Node, @dom.Node?)  // ← DOM特化
  RemoveNode(@dom.Node, @dom.Node)                 // ← DOM特化
  ReplaceNode(@dom.Node, VNode[H], @dom.Node)      // ← DOM特化
  UpdateProps(@dom.Element, Props[H], Props[H])    // ← DOM特化
  UpdateText(@dom.Text, String)                    // ← DOM特化
}
```

**影響範囲**:
- `diff()` 関数
- `apply_patches()` 関数
- `DomRenderer::render()` (renderer_dom.mbt)

### 3. バックエンド非依存のファイル ✅

以下のファイルは既にバックエンド非依存です：

- **`vdom.mbt`** - `VNode[H]`でハンドラ型をパラメータ化
- **`element.mbt`** - 型パラメータを使用
- **`props_builder.mbt`** - 型パラメータを使用
- **`context.mbt`** - 汎用的な実装
- **`context_storage.mbt`** - 汎用的な実装

### 4. バックエンド特化が正しいファイル ✅

以下のファイルは意図的にバックエンド特化であり、問題ありません：

- **`renderer_dom.mbt`** - DOM専用レンダラー
- **`renderer_ssr.mbt`** - SSR専用レンダラー
- **`vdom_js.mbt`** - JS用VNode型定義

## 解決策

### オプション1: シリアライズ機能を別ファイルに分離（推奨）

**メリット**:
- フックのコア機能はバックエンド非依存を維持
- バックエンドごとに最適なシリアライズ実装が可能
- 既存のコードへの影響が最小限

**実装**:
```
src/_experimental/ui/
├── hooks.mbt                    # コアフック機能（バックエンド非依存）
├── hooks_serialization_js.mbt   # JS用シリアライズ実装
├── hooks_serialization_native.mbt  # Native用（将来）
└── ...
```

**変更内容**:

1. `hooks.mbt`から以下を削除:
   - `HooksState::serialize()`
   - `HooksState::from_serialized()`
   - `HooksState::restore()`

2. 新規ファイル`hooks_serialization_js.mbt`を作成:
```moonbit
///| JavaScript backend: State serialization using JSON

///|
/// Serialize hooks state to JSON string
pub fn HooksState::serialize_js(self : HooksState) -> String {
  let arr : @core.Any = self.hooks |> @core.identity
  @json.JSON::stringify(arr)
}

///|
/// Deserialize hooks state from JSON string
pub fn HooksState::from_json(json : String) -> HooksState {
  let arr : Array[@core.Any] = @json.JSON::parse(json)
  { hooks: arr, current_index: 0, effects: [] }
}

///|
/// Restore hooks state from JSON string
pub fn HooksState::restore_from_json(self : HooksState, json : String) -> Unit {
  let arr : Array[@core.Any] = @json.JSON::parse(json)
  for i = 0; i < arr.length(); i = i + 1 {
    if i < self.hooks.length() {
      self.hooks[i] = arr[i]
    } else {
      self.hooks.push(arr[i])
    }
  }
}
```

3. `renderer_ssr.mbt`と`renderer_dom.mbt`を更新して新しいAPI名を使用

### オプション2: トレイトで抽象化

**メリット**:
- より柔軟な設計
- ランタイムでシリアライザーを切り替え可能

**デメリット**:
- MoonBitのトレイトシステムに依存
- 実装が複雑になる

**実装例**:
```moonbit
///| Serializer trait
pub trait Serializer {
  serialize(Array[@core.Any]) -> String
  deserialize(String) -> Array[@core.Any]
}

///| JSON serializer (JS backend)
pub struct JsonSerializer
impl Serializer for JsonSerializer {
  fn serialize(arr : Array[@core.Any]) -> String {
    let any_arr : @core.Any = arr |> @core.identity
    @json.JSON::stringify(any_arr)
  }
  fn deserialize(json : String) -> Array[@core.Any] {
    @json.JSON::parse(json)
  }
}

///| HooksState with generic serializer
pub fn[S : Serializer] HooksState::serialize_with(
  self : HooksState,
  serializer : S
) -> String {
  serializer.serialize(self.hooks)
}
```

### オプション3: reconcile.mbtをジェネリックにする

**現状**:
```moonbit
pub enum Patch[H] {
  CreateElement(VNode[H], @dom.Node, @dom.Node?)
  // ...
}
```

**変更後**:
```moonbit
pub enum Patch[H, N] {  // Nをノード型として追加
  CreateElement(VNode[H], N, N?)
  RemoveNode(N, N)
  ReplaceNode(N, VNode[H], N)
  UpdateProps(/* Element型も抽象化が必要 */)
  UpdateText(/* TextNode型も抽象化が必要 */)
}
```

**問題点**:
- Element型、TextNode型など、多数の型パラメータが必要になる
- 型が複雑になりすぎる
- `apply_patches`の実装がバックエンドごとに必要

**代替案**: `reconcile.mbt`をDOMレンダラー専用として`renderer_dom.mbt`に統合する

## 推奨アクション

### 短期的対応（優先度: 高）

1. **hooks.mbtのシリアライズ機能を分離**
   - 新規ファイル `hooks_serialization_js.mbt` を作成
   - `hooks.mbt`からシリアライズ関連の関数を削除
   - `renderer_ssr.mbt`と`renderer_dom.mbt`を更新

2. **moon.pkg.jsonの整理**
   - コアパッケージ（バックエンド非依存）と JS特化パッケージを分離検討

### 長期的対応（優先度: 中）

1. **reconcile.mbtの位置づけを明確化**
   - オプションA: `renderer_dom.mbt`に統合（DOM専用として）
   - オプションB: ジェネリック化（複雑度が高い）

2. **マルチバックエンド対応の設計**
   - Native、WASM向けのレンダラー実装時の設計指針を策定

## 現在の依存関係マップ

```
[バックエンド非依存]
├── vdom.mbt (VNode[H])
├── element.mbt
├── props_builder.mbt
├── context.mbt
└── hooks.mbt ❌ → @json依存あり

[JS特化]
├── vdom_js.mbt (JSVNode = VNode[JSHandler])
├── renderer_ssr.mbt
├── renderer_dom.mbt
└── reconcile.mbt ❌ → @dom依存あり
```

## 結論

**現状**: ✅ **実装完了** (2025-12-07)

シリアライズ機能を`hooks_serialization_js.mbt`に分離し、`hooks.mbt`をバックエンド非依存に戻しました。

### 実装された変更

1. **新規ファイル作成**
   - `hooks_serialization_js.mbt` - JavaScriptバックエンド専用のシリアライズ実装
     - `HooksState::serialize_js()`
     - `HooksState::from_json()`
     - `HooksState::restore_from_json()`

2. **hooks.mbtの変更**
   - シリアライズ関連の3関数を削除
   - `@json`への依存を完全削除
   - ✅ バックエンド非依存を達成

3. **API名の変更**
   - `serialize()` → `serialize_js()` (JS特化を明示)
   - `from_serialized()` → `from_json()` (JSON形式を明示)
   - `restore()` → `restore_from_json()` (JSON形式を明示)

4. **依存ファイルの更新**
   - `renderer_ssr.mbt` - 新しいAPI名に更新
   - `renderer_dom.mbt` - 新しいAPI名に更新
   - `hooks_test.mbt` - テスト名とAPI名を更新
   - `RESUMABLE_STATE.md` - ドキュメント更新

### 検証結果

- ✅ 全104テストが成功
- ✅ `hooks.mbt`にバックエンド依存性なし
- ✅ `hooks_serialization_js.mbt`が適切に`@json`を使用
- ✅ APIの一貫性を維持

### メリット

1. **バックエンド非依存性の確保**
   - `hooks.mbt`は完全にバックエンド非依存
   - 将来のNative/WASMバックエンド対応が容易

2. **明確な責任分離**
   - コア機能とバックエンド特化機能が分離
   - ファイル名から依存関係が明確

3. **拡張性の向上**
   - 新しいバックエンドの追加が容易
   - 例: `hooks_serialization_native.mbt`, `hooks_serialization_wasm.mbt`

### 今後の対応

**短期的対応** - ✅ 完了
- ✅ hooks.mbtのシリアライズ機能を分離
- ✅ 新規ファイル `hooks_serialization_js.mbt` を作成
- ✅ 関連ファイルとドキュメントを更新

**長期的対応** - 未着手
- reconcile.mbtの位置づけを明確化（DOM専用 vs ジェネリック化）
- マルチバックエンド対応の設計指針を策定
