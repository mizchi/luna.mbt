# [RESOLVED] Issue: Multi-line JSX children lost in MDX parsing

## Status: FIXED

This issue has been resolved in `markdown.mbt` repository.

## Repository
https://github.com/mizchi/markdown.mbt

## Summary
When parsing MDX files with multi-line JSX components, the children content was lost.

## Resolution

The fix was implemented in `src/mdx/block_parser.mbt`:

1. **`parse_mdx_content`** (lines 57-133): Changed from line-by-line processing to character-based processing
2. **`find_jsx_element_end`** (lines 147-246): Added proper handling for:
   - Multi-line JSX elements
   - Nested tags with depth tracking
   - Self-closing tags
   - Brace matching for attributes

## Tests Added

Three new tests confirm the fix:

```moonbit
test "multi-line JSX children are preserved"
test "multi-line JSX with nested components"
test "web component with multi-line children"
```

All 30 MDX tests pass.

## Example (now works correctly)

```mdx
<my-component>
  <div>Content here</div>
  <p>More content</p>
</my-component>
```

Produces `JsxElement` with `children = "\n  <div>Content here</div>\n  <p>More content</p>\n"`
