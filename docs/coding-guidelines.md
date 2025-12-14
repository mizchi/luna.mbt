# MoonBit Coding Guidelines

Luna プロジェクトにおける MoonBit コーディング規約。

## 配列操作

### `.map()` / `.mapi()` を使用する

`for` ループで配列を作成して `push` するパターンは `.map()` に置き換える。

```moonbit
// Bad
fn children[T : ToNode](items : Array[T]) -> Array[Node] {
  let result : Array[Node] = []
  for item in items {
    result.push(ToNode::to_node(item))
  }
  result
}

// Good
fn children[T : ToNode](items : Array[T]) -> Array[Node] {
  items.map(ToNode::to_node)
}
```

インデックスが必要な場合は `.mapi()` を使用:

```moonbit
// Good
let items = initial_items.mapi(fn(i, label) {
  { id: i, label }
})
```

### モダンな for-in 構文を使用する

インデックス付きの `for` ループはモダンな構文を使用:

```moonbit
// Bad
for i = 0; i < values.length(); i = i + 1 {
  if i > 0 { buf.write_string(",") }
  write_json(values[i], buf)
}

// Good
for i, value in values {
  if i > 0 { buf.write_string(",") }
  write_json(value, buf)
}
```

## パターンマッチ

### `if ... is ...` 構文を使用する

`match` で `Some`/`None` を処理する場合、片方が空の場合は `if is` を使用:

```moonbit
// Bad
match optional_value {
  Some(v) => result.push(v)
  None => ()
}

// Good
if optional_value is Some(v) {
  result.push(v)
}
```

### `guard` で早期リターンする

条件を満たさない場合に早期リターンするパターンは `guard` を使用:

```moonbit
// Bad
fn parse_query(query : String) -> Array[(String, String)] {
  if query == "" {
    return []
  }
  // ...処理
}

// Good
fn parse_query(query : String) -> Array[(String, String)] {
  guard query != "" else { return [] }
  // ...処理
}
```

`for` ループ内での早期リターン:

```moonbit
// Bad
for item in arr {
  match json_value_to_state_value(item) {
    Some(v) => result.push(v)
    None => return None
  }
}

// Good
for item in arr {
  guard json_value_to_state_value(item) is Some(v) else { return None }
  result.push(v)
}
```

### 文字列パターンマッチを活用する

複数の条件分岐には文字列のパターンマッチを使用:

```moonbit
// Bad
if s != "__remove__" {
  if s == "" {
    // Boolean attribute
    sb.write_char(' ')
    sb.write_string(name)
  } else {
    // Normal attribute
    sb.write_char(' ')
    sb.write_string(name)
    sb.write_string("=\"")
    escape_attr_to(sb, s)
    sb.write_char('"')
  }
}

// Good
match s {
  "__remove__" => () // Skip
  "" => {
    // Boolean attribute
    sb.write_char(' ')
    sb.write_string(name)
  }
  _ => {
    // Normal attribute
    sb.write_char(' ')
    sb.write_string(name)
    sb.write_string("=\"")
    escape_attr_to(sb, s)
    sb.write_char('"')
  }
}
```

### enum の否定チェック

enum が特定の値でないかをチェックする場合:

```moonbit
// Bad
match config.trigger {
  Load => () // default
  _ => {
    sb.write_string(" ln:trigger=\"")
    sb.write_string(config.trigger.to_string())
    sb.write_char('"')
  }
}

// Good
if not(config.trigger is Load) {
  sb.write_string(" ln:trigger=\"")
  sb.write_string(config.trigger.to_string())
  sb.write_char('"')
}
```

## 空のパターンを避ける

何もしない `match` ブランチは削除する:

```moonbit
// Bad - 何もしていない
match config.state {
  ScriptRef(_) => ()
  _ => ()
}

// Good - 削除する
// (コメントで意図を残す場合のみ記述)
```

## 重複コードの抽出

同じパターンが複数箇所で繰り返される場合はヘルパー関数を抽出:

```moonbit
// Bad - VStatic と VDynamic で同じロジックが重複
match value {
  VStatic(s) =>
    if s != "__remove__" {
      if s == "" { ... } else { ... }
    }
  VDynamic(getter) => {
    let s = getter()
    if s != "__remove__" {
      if s == "" { ... } else { ... }
    }
  }
}

// Good - ヘルパー関数に抽出
fn render_attr_value(sb : StringBuilder, name : String, s : String) -> Unit {
  match s {
    "__remove__" => ()
    "" => { /* boolean attr */ }
    _ => { /* normal attr */ }
  }
}

match value {
  VStatic(s) => render_attr_value(sb, name, s)
  VDynamic(getter) => render_attr_value(sb, name, getter())
}
```

## コレクション操作

### `.filter()` / `.iter().any()` を使用する

条件に合う要素をフィルタリングする場合:

```moonbit
// Bad
fn get_repairs_by_type(repairs : Array[RepairInfo], t : RepairType) -> Array[RepairInfo] {
  let result : Array[RepairInfo] = []
  for repair in repairs {
    if repair.repair_type == t {
      result.push(repair)
    }
  }
  result
}

// Good
fn get_repairs_by_type(repairs : Array[RepairInfo], t : RepairType) -> Array[RepairInfo] {
  repairs.filter(fn(repair) { repair.repair_type == t })
}
```

条件を満たす要素が存在するか確認する場合:

```moonbit
// Bad
fn has_repair_type(repairs : Array[RepairInfo], t : RepairType) -> Bool {
  for repair in repairs {
    if repair.repair_type == t {
      return true
    }
  }
  false
}

// Good
fn has_repair_type(repairs : Array[RepairInfo], t : RepairType) -> Bool {
  repairs.iter().any(fn(repair) { repair.repair_type == t })
}
```

### `.is_empty()` を使用する

配列や文字列が空かどうかの判定:

```moonbit
// Bad
if arr.length() > 0 { ... }
if str.length() == 0 { ... }

// Good
if not(arr.is_empty()) { ... }
if str.is_empty() { ... }
```

## derive を活用する

手動で比較関数を書く代わりに `derive(Eq)` を使用:

```moonbit
// Bad
pub enum RepairType { TextMismatch, TextMissing, ... }

fn repair_type_eq(a : RepairType, b : RepairType) -> Bool {
  match (a, b) {
    (TextMismatch, TextMismatch) => true
    (TextMissing, TextMissing) => true
    ...
    _ => false
  }
}

// Good
pub enum RepairType { TextMismatch, TextMissing, ... } derive(Eq)

// 使用時: a == b
```

## 標準ライブラリのメソッドを活用する

```moonbit
// Bad
fn starts_with_char(s : String, c : Char) -> Bool {
  let chars = s.to_array()
  chars.length() > 0 && chars[0] == c
}

// Good
fn starts_with_char(s : String, c : Char) -> Bool {
  s.has_prefix(c.to_string())
}
```

### 文字列を配列に変換する

`for` ループで手動で配列を作成する代わりに `.to_array()` を使用:

```moonbit
// Bad
fn to_char_array(s : String) -> Array[Char] {
  let arr : Array[Char] = []
  for c in s {
    arr.push(c)
  }
  arr
}

// Good
let chars = s.to_array()
```

### 述語チェックには `.iter().any()` を使用

特定の条件をチェックする場合:

```moonbit
// Bad
fn needs_html_attr_escape(s : String) -> Bool {
  let chars = to_char_array(s)
  for c in chars {
    if c == '"' || c == '&' || c == '<' || c == '>' {
      return true
    }
  }
  false
}

// Good
fn needs_html_attr_escape(s : String) -> Bool {
  s.iter().any(fn(c) { c == '"' || c == '&' || c == '<' || c == '>' })
}
```

## 述語メソッドの簡略化

Bool を返すメソッドでは `is` パターンを直接使用:

```moonbit
// Bad
pub fn HydrationResult::is_success(self : HydrationResult) -> Bool {
  match self {
    Success => true
    _ => false
  }
}

// Good
pub fn HydrationResult::is_success(self : HydrationResult) -> Bool {
  self is Success
}
```

ワイルドカードパターンも使用可能:

```moonbit
// Good
pub fn HydrationResult::is_mismatch(self : HydrationResult) -> Bool {
  self is Mismatch(_)
}
```

## コード生成スクリプト

`__generated.mbt` ファイルを生成するスクリプトも同じ規約に従う:

```typescript
// Bad - match を生成
bodyLines.push(`match ${attr.name} {`);
bodyLines.push(`  Some(v) => props.push(("${htmlAttr}", static_attr(v)))`);
bodyLines.push("  None => ()");
bodyLines.push("}");

// Good - if is Some を生成
bodyLines.push(`if ${attr.name} is Some(v) {`);
bodyLines.push(`  props.push(("${htmlAttr}", static_attr(v)))`);
bodyLines.push("}");
```
