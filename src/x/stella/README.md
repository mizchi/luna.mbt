# Stella

Shard generation module for Island embedding.

## Overview

A Shard is a hydratable HTML fragment in Island Architecture.
Marked with `luna:*` attributes, the loader detects and hydrates them on the client.

## File Structure

| File | Responsibility |
|------|----------------|
| `types.mbt` | Shard config and output type definitions |
| `html_builder.mbt` | HTML generation utilities |
| `serializer.mbt` | JSON/HTML escape processing |

## Shard Output Example

```html
<div luna:id="counter"
     luna:url="/static/counter.js"
     luna:state='{"count":0}'
     luna:client-trigger="load">
  <!-- SSR content -->
</div>
```

## Main Types

### ShardConfig

```moonbit
pub struct ShardConfig {
  id : String              // Component ID (luna:id)
  script_url : String      // Hydration script (luna:url)
  trigger : TriggerType    // Trigger (luna:client-trigger)
  state : StateConfig      // State config
  ssr_content : String?    // SSR HTML
  include_loader : Bool    // Embed loader
  loader_url : String      // Loader URL
}
```

### StateConfig

```moonbit
pub enum StateConfig {
  Empty                  // No state
  Inline(String)         // Embed in luna:state attribute
  ScriptRef(String)      // Reference to <script id="...">
  Url(String)            // Fetch from external URL
}
```

## Security

- XSS escape processing in `serializer.mbt`
- `</script>` in JSON is escaped
- HTML attribute values are properly quoted

## References

- [Luna Core](../luna/README.md) - TriggerType definition
- [Sol](../sol/README.md) - Island integration implementation
