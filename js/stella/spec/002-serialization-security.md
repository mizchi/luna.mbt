# ADR-002: Secure State Serialization

## Status

Accepted

## Context

Embedding state in HTML poses security risks:

1. **XSS via JSON**: Malicious data in state could execute
2. **Script injection**: `</script>` in JSON breaks out
3. **Attribute injection**: Quotes in values break attributes

Must handle:
- User-generated content in state
- Complex nested data structures
- Unicode and special characters

## Decision

Implement multi-layer escaping in the serializer.

### JSON Escaping

```moonbit
pub fn escape_json_string(s: String) -> String
```

Escapes:
- `"` → `\"`
- `\` → `\\`
- Newlines → `\n`
- Control characters → `\uXXXX`

### Script Tag Escaping

```moonbit
pub fn escape_script_content(json: String) -> String
```

Prevents breaking out of `<script>` tags:
- `</script>` → `<\/script>`
- `<!--` → `<\!--`

### HTML Attribute Escaping

```moonbit
pub fn escape_attr(s: String) -> String
```

For use in attribute values:
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&#x27;`

### State Serialization Pipeline

```
State Object
    ↓ JSON.stringify
Raw JSON String
    ↓ escape_script_content (if in <script>)
    ↓ escape_attr (if in attribute)
Safe HTML Output
```

### Inline vs Script Block

For small state (< 1KB):
```html
<div luna:state='{"escaped":"data"}'>
```

For large state:
```html
<script type="application/json" id="state-counter">
{"large":"data","with":"many","fields":true}
</script>
<div luna:state-ref="state-counter">
```

## Consequences

### Positive

- **XSS-safe**: All user content properly escaped
- **Flexible**: Multiple storage strategies
- **Standard**: Uses JSON for serialization
- **Debuggable**: State visible in HTML

### Negative

- **Size overhead**: Escaping increases size
- **Performance**: Escape/unescape at runtime
- **Complexity**: Multiple escape contexts

### Neutral

- Similar to React's dangerouslySetInnerHTML safeguards
- Can add compression for large states in future
