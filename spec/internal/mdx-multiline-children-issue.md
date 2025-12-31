# Issue: Multi-line JSX children lost in MDX parsing

## Repository
https://github.com/mizchi/markdown.mbt

## Summary
When parsing MDX files with multi-line JSX components, the children content is lost.

## Expected Behavior
Multi-line JSX content should preserve children:

```mdx
<my-component>
  <div>Content here</div>
  <p>More content</p>
</my-component>
```

Should produce `JsxElement` with `children = "\n  <div>Content here</div>\n  <p>More content</p>\n"`

## Actual Behavior
Children is empty string when JSX spans multiple lines.

## Root Cause Analysis
In `src/mdx/block_parser.mbt`:

1. `try_parse_mdx_blocks_from_block` handles `Paragraph` blocks by splitting content by lines (line 43)
2. Each line is processed separately via `try_parse_jsx_element`
3. Multi-line JSX gets split, losing children

```moonbit
// Line 42-43
let lines = split_lines(content)
for line in lines {
  // Each line processed separately - multi-line JSX breaks
}
```

4. `HtmlBlock` (line 74-78) handles the entire content, but multi-line JSX with blank lines may not be recognized as HtmlBlock

## Workaround
Use single-line JSX:
```mdx
<my-component><div>Content</div></my-component>
```

## Proposed Fix
Options:
1. Detect multi-line JSX opening tags and accumulate lines until closing tag
2. Pre-process paragraph content to join multi-line JSX before line splitting
3. Handle JSX in a separate pass that's aware of tag nesting

## Test Case
```moonbit
test "multi-line JSX children" {
  let content = #|---
#|title: Test
#|---
#|
#|<my-comp>
#|  <div>Child content</div>
#|</my-comp>
  let (_, nodes) = @mdx.parse_mdx(content)
  // Find JsxComponent node
  // Assert children is not empty
}
```
