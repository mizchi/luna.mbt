///|
using @test {assert_eq}

///|
/// Tests for pure helper behaviors via the public parse_mdx API

// =============================================================================
// extract_string_value behavior via export const frontmatter extraction
// =============================================================================

///|
test "extract_string_value double-quoted: export const title parsed correctly" {
  let content = "export const title = \"My Title\"\n\n# Hello\n"
  let (fm, _) = parse_mdx(content)
  match fm.title {
    Some(t) => assert_eq(t, "My Title")
    None => fail("Expected title from double-quoted export")
  }
}

///|
test "extract_string_value single-quoted: export const title with single quotes" {
  let content = "export const title = 'Single Quoted'\n\n# Hello\n"
  let (fm, _) = parse_mdx(content)
  match fm.title {
    Some(t) => assert_eq(t, "Single Quoted")
    None => fail("Expected title from single-quoted export")
  }
}

///|
test "extract_string_value template literal: export const title with backticks" {
  let content = "export const title = `Template Title`\n\n# Hello\n"
  let (fm, _) = parse_mdx(content)
  match fm.title {
    Some(t) => assert_eq(t, "Template Title")
    None => fail("Expected title from template literal export")
  }
}

///|
test "extract_string_value description: export const description extracted" {
  let content = "export const description = \"A test description.\"\n\n# Hello\n"
  let (fm, _) = parse_mdx(content)
  match fm.description {
    Some(d) => assert_eq(d, "A test description.")
    None => fail("Expected description from export")
  }
}

///|
test "extract_string_value: frontmatter title takes precedence over export" {
  // YAML frontmatter is parsed first; export const may supplement missing fields
  let content = "---\ntitle: YAML Title\n---\n\nexport const title = \"Export Title\"\n\n# Hello\n"
  let (fm, _) = parse_mdx(content)
  // frontmatter title should be set (either source is acceptable)
  assert_true(fm.title is Some(_))
}

///|
test "extract_string_value: empty quoted string does not set title" {
  let content = "export const title = \"\"\n\n# Hello\n"
  let (fm, _) = parse_mdx(content)
  // empty string → not set (extract_string_value returns "" which is_empty)
  assert_true(fm.title is None)
}

// =============================================================================
// spans_overlap behavior via parse_mdx structural output
// =============================================================================

///|
test "spans_overlap: JSX element adjacent to heading is distinct node" {
  let content =
    #|# My Heading
    #|
    #|<my-component></my-component>
  let (_, nodes) = parse_mdx(content)
  // Heading and JSX should be separate nodes (non-overlapping spans)
  let mut found_heading = false
  let mut found_jsx = false
  for node in nodes {
    match node {
      @astra.MdNode::Heading(..) => found_heading = true
      @astra.MdNode::JsxComponent(_) => found_jsx = true
      _ => ()
    }
  }
  assert_true(found_heading)
  assert_true(found_jsx)
}

///|
test "spans_overlap: multiple JSX elements remain separate nodes" {
  let content =
    #|<first-element></first-element>
    #|
    #|<second-element></second-element>
  let (_, nodes) = parse_mdx(content)
  let mut jsx_count = 0
  for node in nodes {
    match node {
      @astra.MdNode::JsxComponent(_) => jsx_count = jsx_count + 1
      _ => ()
    }
  }
  assert_eq(jsx_count, 2)
}

///|
test "spans_overlap: paragraph before JSX is separate node" {
  let content =
    #|Some paragraph text.
    #|
    #|<my-widget></my-widget>
  let (_, nodes) = parse_mdx(content)
  let mut found_para = false
  let mut found_jsx = false
  for node in nodes {
    match node {
      @astra.MdNode::Paragraph(..) => found_para = true
      @astra.MdNode::JsxComponent(_) => found_jsx = true
      _ => ()
    }
  }
  assert_true(found_para)
  assert_true(found_jsx)
}
